//
//  SupabaseConnectionStore.swift
//  TrainerMatch
//
//  trainer_clients table columns: id, trainer_id, client_id, status, notes, joined_at
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Supabase row model — matches EXACT table schema

struct SBTrainerClientRow: Codable, Identifiable {
    var id:        UUID
    var trainerId: UUID
    var clientId:  UUID
    var status:    String
    var notes:     String?
    var joinedAt:  Date?

    // Enriched locally after fetch — not in table
    var clientName:      String?
    var trainerName:     String?
    var clientImageUrl:  String?

    enum CodingKeys: String, CodingKey {
        case id, status, notes
        case trainerId = "trainer_id"
        case clientId  = "client_id"
        case joinedAt  = "joined_at"
        // clientName and trainerName are NOT in CodingKeys — enriched locally
    }

    var asRequest: TrainerRequest {
        TrainerRequest(
            id:          id.uuidString,
            trainerId:   trainerId.uuidString,
            clientId:    clientId.uuidString,
            clientName:  clientName  ?? "Client",
            clientEmail: "",
            message:     notes       ?? "",
            sentAt:      joinedAt    ?? Date(),
            status:      status == "active" || status == "accepted" ? .accepted :
                         status == "declined" ? .declined : .pending
        )
    }

    var asConnection: TrainerClientConnection {
        TrainerClientConnection(
            id:          id.uuidString,
            trainerId:   trainerId.uuidString,
            clientId:    clientId.uuidString,
            clientName:  clientName  ?? "Client",
            trainerName: trainerName ?? "Trainer",
            connectedAt: joinedAt    ?? Date()
        )
    }
}

// MARK: - Connection Status

enum TrainerConnectionStatus {
    case notConnected
    case pending
    case connected
}

// MARK: - Store

@MainActor
class SBConnectionStore: ObservableObject {
    static let shared = SBConnectionStore()

    @Published var rows:              [SBTrainerClientRow] = []
    @Published var myTrainerIds:      Set<String>          = []
    @Published var pendingTrainerIds: Set<String>          = []

    private init() {}

    // MARK: - Load

    func loadForTrainer(_ trainerId: String) {
        guard let uuid = UUID(uuidString: trainerId) else { return }
        Task {
            if let result = try? await supabase
                .from("trainer_clients")
                .select()
                .eq("trainer_id", value: uuid)
                .execute()
                .value as [SBTrainerClientRow] {
                self.rows = result
                self.syncToLocal()
                self.enrichConnectionNames()
            }
        }
    }

    func loadForClient(_ clientId: String) {
        guard let uuid = UUID(uuidString: clientId) else { return }
        Task {
            if let result = try? await supabase
                .from("trainer_clients")
                .select()
                .eq("client_id", value: uuid)
                .execute()
                .value as [SBTrainerClientRow] {
                self.rows = result
                self.syncToLocal()
                self.enrichConnectionNames()
                let active  = result.filter { $0.status == "active" || $0.status == "accepted" }
                                    .map { $0.trainerId.uuidString }
                let pending = result.filter { $0.status == "pending" }
                                    .map { $0.trainerId.uuidString }
                self.myTrainerIds      = Set(active)
                self.pendingTrainerIds = Set(pending)
            }
        }
    }

    // MARK: - Status check

    func status(for trainerId: String) -> TrainerConnectionStatus {
        if myTrainerIds.contains(trainerId)      { return .connected }
        if pendingTrainerIds.contains(trainerId) { return .pending   }
        return .notConnected
    }

    // MARK: - Request connection (inserts as pending)

    func requestConnection(clientId: String, trainerId: String) async throws {
        guard let cUUID = UUID(uuidString: clientId),
              let tUUID = UUID(uuidString: trainerId) else { return }

        // Check for existing row
        let existing = try? await supabase
            .from("trainer_clients")
            .select()
            .eq("trainer_id", value: tUUID)
            .eq("client_id",  value: cUUID)
            .execute()
            .value as [SBTrainerClientRow]

        if let existing, !existing.isEmpty {
            // Already exists — update local state
            let isActive = existing.first?.status == "active" || existing.first?.status == "accepted"
            if isActive {
                myTrainerIds.insert(trainerId)
            } else {
                pendingTrainerIds.insert(trainerId)
            }
            loadForClient(clientId)
            return
        }

        struct NewConn: Encodable {
            let trainerId: UUID
            let clientId:  UUID
            let status:    String
            enum CodingKeys: String, CodingKey {
                case trainerId = "trainer_id"
                case clientId  = "client_id"
                case status
            }
        }
        try await supabase
            .from("trainer_clients")
            .insert(NewConn(trainerId: tUUID, clientId: cUUID, status: "pending"))
            .execute()

        pendingTrainerIds.insert(trainerId)
        loadForClient(clientId)
    }

    // MARK: - Release by clientId + trainerId

    func releaseConnection(clientId: String, trainerId: String) async throws {
        guard let cUUID = UUID(uuidString: clientId),
              let tUUID = UUID(uuidString: trainerId) else { return }
        try await supabase
            .from("trainer_clients")
            .delete()
            .eq("trainer_id", value: tUUID)
            .eq("client_id",  value: cUUID)
            .execute()
        myTrainerIds.remove(trainerId)
        pendingTrainerIds.remove(trainerId)
        rows.removeAll {
            $0.trainerId.uuidString == trainerId &&
            $0.clientId.uuidString  == clientId
        }
        syncToLocal()
    }

    // MARK: - Accept (trainer accepts pending request)

    func acceptRequest(_ requestId: String, trainerName: String) async throws {
        guard let uuid = UUID(uuidString: requestId) else { return }
        struct Update: Encodable { let status: String }
        try await supabase
            .from("trainer_clients")
            .update(Update(status: "active"))
            .eq("id", value: uuid)
            .execute()
        if let i = rows.firstIndex(where: { $0.id == uuid }) {
            rows[i].status = "active"
        }
        syncToLocal()

        if let row = rows.first(where: { $0.id == uuid }) {
            NotificationManager.shared.send(
                recipientId:   row.clientId.uuidString,
                recipientRole: .client,
                senderId:      row.trainerId.uuidString,
                senderName:    trainerName,
                category:      .appointmentAccepted,
                title:         "\(trainerName) accepted your request!",
                body:          "You can now message and schedule sessions."
            )
        }
    }

    // MARK: - Decline

    func declineRequest(_ requestId: String) async throws {
        guard let uuid = UUID(uuidString: requestId) else { return }
        struct Update: Encodable { let status: String }
        try await supabase
            .from("trainer_clients")
            .update(Update(status: "declined"))
            .eq("id", value: uuid)
            .execute()
        if let i = rows.firstIndex(where: { $0.id == uuid }) {
            rows[i].status = "declined"
        }
        syncToLocal()
    }

    // MARK: - Release by connection ID

    func releaseConnection(_ connectionId: String) async throws {
        guard let uuid = UUID(uuidString: connectionId) else { return }
        try await supabase
            .from("trainer_clients")
            .delete()
            .eq("id", value: uuid)
            .execute()
        rows.removeAll { $0.id == uuid }
        syncToLocal()
    }

    // MARK: - Legacy send request

    func sendRequest(
        trainerId: String, trainerName: String,
        clientId: String, clientName: String,
        clientEmail: String, message: String
    ) async throws {
        try await requestConnection(clientId: clientId, trainerId: trainerId)
    }

    // MARK: - Queries

    func pendingRequests(forTrainer trainerId: String) -> [TrainerRequest] {
        rows.filter { $0.trainerId.uuidString == trainerId && $0.status == "pending" }
            .map { $0.asRequest }
    }

    func activeClients(forTrainer trainerId: String) -> [TrainerClientConnection] {
        rows.filter {
            $0.trainerId.uuidString == trainerId &&
            ($0.status == "active" || $0.status == "accepted")
        }.map { $0.asConnection }
    }

    func myTrainers(forClient clientId: String) -> [TrainerClientConnection] {
        rows.filter {
            $0.clientId.uuidString == clientId &&
            ($0.status == "active" || $0.status == "accepted")
        }.map { $0.asConnection }
    }

    func requestStatus(trainerId: String, clientId: String) -> TrainerRequest.RequestStatus? {
        guard let row = rows.last(where: {
            $0.trainerId.uuidString == trainerId &&
            $0.clientId.uuidString  == clientId
        }) else { return nil }
        if row.status == "active" || row.status == "accepted" { return .accepted }
        if row.status == "declined" { return .declined }
        return .pending
    }

    func connection(trainerId: String, clientId: String) -> TrainerClientConnection? {
        rows.first(where: {
            $0.trainerId.uuidString == trainerId &&
            $0.clientId.uuidString  == clientId  &&
            ($0.status == "active" || $0.status == "accepted")
        })?.asConnection
    }

    // MARK: - Sync to local cache

    private func syncToLocal() {
        let store         = TrainerConnectionStore.shared
        store.requests    = rows.map { $0.asRequest }
        store.connections = rows.filter {
            $0.status == "active" || $0.status == "accepted"
        }.map { $0.asConnection }
    }

    // MARK: - Enrich with real names from Supabase

    func enrichConnectionNames() {
        Task {
            struct ClientName: Decodable {
                let firstName:      String
                let lastName:       String
                let profileImageUrl: String?
                var fullName:       String { "\(firstName) \(lastName)" }
                enum CodingKeys: String, CodingKey {
                    case firstName       = "first_name"
                    case lastName        = "last_name"
                    case profileImageUrl = "profile_image_url"
                }
            }
            struct TrainerName: Decodable {
                let firstName:    String
                let lastName:     String
                let businessName: String?
                var displayName:  String { businessName ?? "\(firstName) \(lastName)" }
                enum CodingKeys: String, CodingKey {
                    case firstName    = "first_name"
                    case lastName     = "last_name"
                    case businessName = "business_name"
                }
            }

            for i in rows.indices {
                if rows[i].clientName == nil || rows[i].clientName == "Client" {
                    if let result = try? await supabase
                        .from("clients")
                        .select("first_name,last_name,profile_image_url")
                        .eq("id", value: rows[i].clientId)
                        .single().execute()
                        .value as ClientName {
                        rows[i].clientName     = result.fullName
                        rows[i].clientImageUrl = result.profileImageUrl
                    }
                }
                if rows[i].trainerName == nil || rows[i].trainerName == "Trainer" {
                    if let result = try? await supabase
                        .from("trainers")
                        .select("first_name,last_name,business_name")
                        .eq("id", value: rows[i].trainerId)
                        .single().execute()
                        .value as TrainerName {
                        rows[i].trainerName = result.displayName
                    }
                }
            }
            syncToLocal()
        }
    }
}
