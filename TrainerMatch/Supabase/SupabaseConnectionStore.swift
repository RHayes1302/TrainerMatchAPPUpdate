//
//  SupabaseConnectionStore.swift
//  TrainerMatch
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Supabase row model

struct SBTrainerClientRow: Codable, Identifiable {
    var id:          UUID
    var trainerId:   UUID
    var clientId:    UUID
    var clientName:  String
    var trainerName: String
    var status:      String
    var message:     String
    var clientEmail: String
    var createdAt:   Date?
    var updatedAt:   Date?

    enum CodingKeys: String, CodingKey {
        case id, message, status
        case trainerId   = "trainer_id"
        case clientId    = "client_id"
        case clientName  = "client_name"
        case trainerName = "trainer_name"
        case clientEmail = "client_email"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    var asRequest: TrainerRequest {
        TrainerRequest(
            id:          id.uuidString,
            trainerId:   trainerId.uuidString,
            clientId:    clientId.uuidString,
            clientName:  clientName,
            clientEmail: clientEmail,
            message:     message,
            sentAt:      createdAt ?? Date(),
            status:      status == "accepted" ? .accepted :
                         status == "declined" ? .declined : .pending
        )
    }

    var asConnection: TrainerClientConnection {
        TrainerClientConnection(
            id:          id.uuidString,
            trainerId:   trainerId.uuidString,
            clientId:    clientId.uuidString,
            clientName:  clientName,
            trainerName: trainerName,
            connectedAt: updatedAt ?? createdAt ?? Date()
        )
    }
}

// MARK: - Store

@MainActor
class SBConnectionStore: ObservableObject {
    static let shared = SBConnectionStore()
    @Published var rows: [SBTrainerClientRow] = []
    private init() {}

    // MARK: - Load

    func loadForTrainer(_ trainerId: String) {
        guard let uuid = UUID(uuidString: trainerId) else { return }
        Task {
            if let result = try? await supabase
                .from("trainer_clients")
                .select()
                .eq("trainer_id", value: uuid)
                .order("created_at", ascending: false)
                .execute()
                .value as [SBTrainerClientRow] {
                self.rows = result
                self.syncToLocal()
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
                .order("created_at", ascending: false)
                .execute()
                .value as [SBTrainerClientRow] {
                self.rows = result
                self.syncToLocal()
            }
        }
    }

    // MARK: - Send request

    func sendRequest(
        trainerId:   String,
        trainerName: String,
        clientId:    String,
        clientName:  String,
        clientEmail: String,
        message:     String
    ) async throws {
        guard let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }

        let existing = try? await supabase
            .from("trainer_clients")
            .select()
            .eq("trainer_id", value: tUUID)
            .eq("client_id",  value: cUUID)
            .eq("status",     value: "pending")
            .execute()
            .value as [SBTrainerClientRow]
        guard existing?.isEmpty != false else { return }

        let rowId    = UUID()
        let now      = Date()
        let tId      = tUUID
        let cId      = cUUID
        let cName    = clientName
        let tName    = trainerName
        let cEmail   = clientEmail
        let msg      = message

        let row = SBTrainerClientRow(
            id:          rowId,
            trainerId:   tId,
            clientId:    cId,
            clientName:  cName,
            trainerName: tName,
            status:      "pending",
            message:     msg,
            clientEmail: cEmail,
            createdAt:   now,
            updatedAt:   now
        )
        try await supabase.from("trainer_clients").insert(row).execute()
        rows.insert(row, at: 0)
        syncToLocal()

        NotificationManager.shared.send(
            recipientId:   trainerId,
            recipientRole: .trainer,
            senderId:      clientId,
            senderName:    clientName,
            category:      .message,
            title:         "New connection request",
            body:          "\(clientName) wants to connect with you as their trainer."
        )
    }

    // MARK: - Accept

    func acceptRequest(_ requestId: String, trainerName: String) async throws {
        guard let uuid = UUID(uuidString: requestId) else { return }
        struct Update: Encodable {
            let status:    String
            let updatedAt: Date
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        try await supabase.from("trainer_clients")
            .update(Update(status: "accepted", updatedAt: Date()))
            .eq("id", value: uuid)
            .execute()
        if let i = rows.firstIndex(where: { $0.id == uuid }) {
            rows[i].status    = "accepted"
            rows[i].updatedAt = Date()
        }
        syncToLocal()

        if let row = rows.first(where: { $0.id == uuid }) {
            let cId    = row.clientId.uuidString
            let tId    = row.trainerId.uuidString
            let tName  = trainerName
            NotificationManager.shared.send(
                recipientId:   cId,
                recipientRole: .client,
                senderId:      tId,
                senderName:    tName,
                category:      .appointmentAccepted,
                title:         "\(tName) accepted your request!",
                body:          "You can now message and schedule sessions."
            )
        }
    }

    // MARK: - Decline

    func declineRequest(_ requestId: String) async throws {
        guard let uuid = UUID(uuidString: requestId) else { return }
        struct Update: Encodable {
            let status: String
            enum CodingKeys: String, CodingKey { case status }
        }
        try await supabase.from("trainer_clients")
            .update(Update(status: "declined"))
            .eq("id", value: uuid)
            .execute()
        if let i = rows.firstIndex(where: { $0.id == uuid }) {
            rows[i].status = "declined"
        }
        syncToLocal()
    }

    // MARK: - Release

    func releaseConnection(_ connectionId: String) async throws {
        guard let uuid = UUID(uuidString: connectionId) else { return }
        try await supabase.from("trainer_clients")
            .delete()
            .eq("id", value: uuid)
            .execute()
        rows.removeAll { $0.id == uuid }
        syncToLocal()
    }

    // MARK: - Queries

    func pendingRequests(forTrainer trainerId: String) -> [TrainerRequest] {
        rows
            .filter { $0.trainerId.uuidString == trainerId && $0.status == "pending" }
            .map    { $0.asRequest }
    }

    func activeClients(forTrainer trainerId: String) -> [TrainerClientConnection] {
        rows
            .filter { $0.trainerId.uuidString == trainerId && $0.status == "accepted" }
            .map    { $0.asConnection }
    }

    func myTrainers(forClient clientId: String) -> [TrainerClientConnection] {
        rows
            .filter { $0.clientId.uuidString == clientId && $0.status == "accepted" }
            .map    { $0.asConnection }
    }

    func requestStatus(trainerId: String, clientId: String) -> TrainerRequest.RequestStatus? {
        guard let row = rows.last(where: {
            $0.trainerId.uuidString == trainerId &&
            $0.clientId.uuidString  == clientId
        }) else { return nil }
        if row.status == "accepted" { return .accepted }
        if row.status == "declined" { return .declined }
        return .pending
    }

    func connection(trainerId: String, clientId: String) -> TrainerClientConnection? {
        rows.first(where: {
            $0.trainerId.uuidString == trainerId &&
            $0.clientId.uuidString  == clientId  &&
            $0.status == "accepted"
        })?.asConnection
    }

    // MARK: - Sync to local

    private func syncToLocal() {
        let store       = TrainerConnectionStore.shared
        store.requests    = rows.map { $0.asRequest }
        store.connections = rows.filter { $0.status == "accepted" }.map { $0.asConnection }
    }
}
