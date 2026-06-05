//
//  NutritionLogRequestStore.swift
//  TrainerMatch
//
//  Manages nutrition log requests between trainers and clients.
//  Trainer requests → OneSignal push → Client logs meals for 3 days → Trainer reviews.
//

import Foundation

// MARK: - Model

struct NutritionLogRequest: Codable, Identifiable {
    var id:          UUID
    var trainerId:   UUID
    var clientId:    UUID
    var trainerName: String
    var status:      String   // active / completed / expired
    var requestedAt: Date?
    var expiresAt:   Date?
    var createdAt:   Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case trainerId   = "trainer_id"
        case clientId    = "client_id"
        case trainerName = "trainer_name"
        case requestedAt = "requested_at"
        case expiresAt   = "expires_at"
        case createdAt   = "created_at"
    }

    var isExpired: Bool {
        guard let exp = expiresAt else { return false }
        return Date() > exp
    }

    var daysRemaining: Int {
        guard let exp = expiresAt else { return 0 }
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: exp).day ?? 0)
    }
}

// MARK: - Store

@MainActor
class NutritionLogRequestStore: ObservableObject {
    static let shared = NutritionLogRequestStore()
    @Published var activeRequest: NutritionLogRequest? = nil
    private init() {}

    // MARK: Client — check for active log request

    func fetchActiveRequest(forClient clientId: String) async {
        guard let uuid = UUID(uuidString: clientId) else { return }
        let requests: [NutritionLogRequest] = (try? await supabase
            .from("nutrition_log_requests")
            .select()
            .eq("client_id", value: uuid)
            .eq("status", value: "active")
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value) ?? []
        activeRequest = requests.first
    }

    // MARK: Trainer — send a log request via Edge Function

    func requestLog(
        clientId:          String,
        clientOneSignalId: String,
        trainerName:       String
    ) async throws {
        let session = try await supabase.auth.session

        let url = URL(string: "https://axmxhxdqfxedltjclssz.supabase.co/functions/v1/request-nutrition-log")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "clientId":          clientId,
            "clientOneSignalId": clientOneSignalId,
            "trainerName":       trainerName,
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        print("🔔 Edge Function response: \(statusCode)")
        if let body = String(data: data, encoding: .utf8) {
            print("🔔 Edge Function body: \(body)")
        }
        guard statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: Trainer — fetch client's meal log entries from last 3 days

    func fetchLogEntries(forClient clientId: String) async -> [MealLogEntry] {
        guard let uuid = UUID(uuidString: clientId) else { return [] }
        let since = Date().addingTimeInterval(-3 * 86400)
        return (try? await supabase
            .from("meal_logs")
            .select()
            .eq("client_id", value: uuid)
            .gte("logged_at", value: since.ISO8601Format())
            .order("logged_at", ascending: false)
            .execute()
            .value) ?? []
    }

    // MARK: Fetch client's OneSignal ID — queries by id column (lowercase UUID)

    static func fetchClientOneSignalId(clientId: String) async -> String {
        print("🔍 fetchClientOneSignalId for clientId: \(clientId)")
        struct Row: Codable {
            var onesignalId: String?
            enum CodingKeys: String, CodingKey { case onesignalId = "onesignal_id" }
        }
        do {
            let row: Row = try await supabase
                .from("clients")
                .select("onesignal_id")
                .eq("id", value: clientId.lowercased())
                .single()
                .execute()
                .value
            print("🔍 client onesignal_id: '\(row.onesignalId ?? "nil")'")
            return row.onesignalId ?? ""
        } catch {
            print("❌ fetchClientOneSignalId error: \(error)")
            return ""
        }
    }

    // MARK: Fetch trainer's display name — queries by id first, falls back to auth_id

    static func fetchTrainerName(trainerId: String) async -> String {
        print("🔍 fetchTrainerName for trainerId: \(trainerId)")
        struct Row: Codable {
            var firstName: String?
            var lastName:  String?
            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName  = "last_name"
            }
        }
        // Try by id first (this is what TrainerClientConnection.trainerId contains)
        do {
            let row: Row = try await supabase
                .from("trainers")
                .select("first_name, last_name")
                .eq("id", value: trainerId.lowercased())
                .single()
                .execute()
                .value
            let name = "\(row.firstName ?? "") \(row.lastName ?? "")".trimmingCharacters(in: .whitespaces)
            print("🔍 trainer name (by id): '\(name)'")
            return name.isEmpty ? "Your Trainer" : name
        } catch {
            print("⚠️ fetchTrainerName by id failed: \(error)")
        }
        // Fallback: try by auth_id
        do {
            let row: Row = try await supabase
                .from("trainers")
                .select("first_name, last_name")
                .eq("auth_id", value: trainerId.lowercased())
                .single()
                .execute()
                .value
            let name = "\(row.firstName ?? "") \(row.lastName ?? "")".trimmingCharacters(in: .whitespaces)
            print("🔍 trainer name (by auth_id): '\(name)'")
            return name.isEmpty ? "Your Trainer" : name
        } catch {
            print("❌ fetchTrainerName both lookups failed: \(error)")
            return "Your Trainer"
        }
    }
}
