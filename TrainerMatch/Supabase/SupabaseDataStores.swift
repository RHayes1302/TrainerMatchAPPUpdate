//
//  SupabaseDataStores.swift
//  TrainerMatch
//
//  All data stores migrated to Supabase:
//  - WorkoutStore
//  - MealPlanStore
//  - CheckInStore
//  - WeightStore
//  - BookingStore (Supabase layer)
//  - MessageStore
//  - SharedFileStore
//  - GymAdStore (Supabase layer)
//

import Foundation
import SwiftUI
import Supabase

// MARK: ─────────────────────────────────────────────────────────
// MARK: WORKOUT STORE
// MARK: ─────────────────────────────────────────────────────────

struct WorkoutRow: Codable, Identifiable {
    var id:              UUID
    var trainerId:       UUID
    var clientId:        UUID
    var title:           String
    var description:     String
    var exercises:       [ExerciseItem]
    var difficulty:      String
    var estimatedMins:   Int
    var status:          String
    var assignedDate:    Date?
    var dueDate:         Date?
    var completedAt:     Date?
    var createdAt:       Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, exercises, difficulty, status
        case trainerId     = "trainer_id"
        case clientId      = "client_id"
        case estimatedMins = "estimated_mins"
        case assignedDate  = "assigned_date"
        case dueDate       = "due_date"
        case completedAt   = "completed_at"
        case createdAt     = "created_at"
    }
}

struct ExerciseItem: Codable, Identifiable {
    var id:          UUID = UUID()
    var name:        String
    var sets:        Int
    var reps:        String
    var weight:      String
    var notes:       String
    var restSeconds: Int
}

@MainActor
class SBWorkoutStore: ObservableObject {
    static let shared = SBWorkoutStore()
    @Published var workouts: [WorkoutRow] = []
    private init() {}

    func fetchForClient(_ clientId: UUID) async throws {
        workouts = try await supabase
            .from("workouts")
            .select()
            .eq("client_id", value: clientId)
            .order("assigned_date", ascending: false)
            .execute()
            .value
    }

    func fetchForTrainer(_ trainerId: UUID) async throws {
        workouts = try await supabase
            .from("workouts")
            .select()
            .eq("trainer_id", value: trainerId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func create(_ workout: WorkoutRow) async throws {
        try await supabase.from("workouts").insert(workout).execute()
        workouts.insert(workout, at: 0)
    }

    func update(_ workout: WorkoutRow) async throws {
        try await supabase.from("workouts").update(workout)
            .eq("id", value: workout.id).execute()
        if let i = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[i] = workout
        }
    }

    func markComplete(_ workoutId: UUID) async throws {
        struct Update: Encodable {
            let status: String; let completedAt: Date
            enum CodingKeys: String, CodingKey {
                case status; case completedAt = "completed_at"
            }
        }
        try await supabase.from("workouts")
            .update(Update(status: "completed", completedAt: Date()))
            .eq("id", value: workoutId).execute()
        if let i = workouts.firstIndex(where: { $0.id == workoutId }) {
            workouts[i].status = "completed"
        }
    }

    func delete(_ workoutId: UUID) async throws {
        try await supabase.from("workouts").delete()
            .eq("id", value: workoutId).execute()
        workouts.removeAll { $0.id == workoutId }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: MEAL PLAN STORE
// MARK: ─────────────────────────────────────────────────────────

struct MealPlanRow: Codable, Identifiable {
    var id:             UUID
    var trainerId:      UUID
    var clientId:       UUID
    var title:          String
    var description:    String
    var meals:          [MealItem]
    var dailyCalories:  Int
    var proteinG:       Double
    var carbsG:         Double
    var fatG:           Double
    var weekStart:      Date?
    var isActive:       Bool
    var createdAt:      Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, meals
        case trainerId    = "trainer_id"
        case clientId     = "client_id"
        case dailyCalories = "daily_calories"
        case proteinG     = "protein_g"
        case carbsG       = "carbs_g"
        case fatG         = "fat_g"
        case weekStart    = "week_start"
        case isActive     = "is_active"
        case createdAt    = "created_at"
    }
}

struct MealItem: Codable, Identifiable {
    var id:         UUID = UUID()
    var mealType:   String   // Breakfast, Lunch, Dinner, Snack
    var name:       String
    var calories:   Int
    var protein:    Double
    var carbs:      Double
    var fat:        Double
    var notes:      String
}

@MainActor
class SBMealPlanStore: ObservableObject {
    static let shared = SBMealPlanStore()
    @Published var mealPlans: [MealPlanRow] = []
    private init() {}

    func fetchForClient(_ clientId: UUID) async throws {
        mealPlans = try await supabase
            .from("meal_plans")
            .select()
            .eq("client_id", value: clientId)
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func create(_ plan: MealPlanRow) async throws {
        try await supabase.from("meal_plans").insert(plan).execute()
        mealPlans.insert(plan, at: 0)
    }

    func update(_ plan: MealPlanRow) async throws {
        try await supabase.from("meal_plans").update(plan)
            .eq("id", value: plan.id).execute()
        if let i = mealPlans.firstIndex(where: { $0.id == plan.id }) {
            mealPlans[i] = plan
        }
    }

    func delete(_ planId: UUID) async throws {
        try await supabase.from("meal_plans").delete()
            .eq("id", value: planId).execute()
        mealPlans.removeAll { $0.id == planId }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: CHECK-IN STORE
// MARK: ─────────────────────────────────────────────────────────

struct CheckInRow: Codable, Identifiable {
    var id:           UUID
    var trainerId:    UUID
    var clientId:     UUID
    var weight:       Double?
    var notes:        String
    var photoUrls:    [String]
    var energyLevel:  Int?
    var sleepHours:   Double?
    var waterOz:      Int?
    var checkedInAt:  Date?
    var createdAt:    Date?

    enum CodingKeys: String, CodingKey {
        case id, notes, weight
        case trainerId   = "trainer_id"
        case clientId    = "client_id"
        case photoUrls   = "photo_urls"
        case energyLevel = "energy_level"
        case sleepHours  = "sleep_hours"
        case waterOz     = "water_oz"
        case checkedInAt = "checked_in_at"
        case createdAt   = "created_at"
    }
}

@MainActor
class SBCheckInStore: ObservableObject {
    static let shared = SBCheckInStore()
    @Published var checkIns: [CheckInRow] = []
    private init() {}

    func fetchForClient(_ clientId: UUID) async throws {
        checkIns = try await supabase
            .from("check_ins")
            .select()
            .eq("client_id", value: clientId)
            .order("checked_in_at", ascending: false)
            .execute()
            .value
    }

    func submit(_ checkIn: CheckInRow, photos: [Data]) async throws {
        var c = checkIn
        // Upload photos first
        var urls: [String] = []
        for (i, photoData) in photos.enumerated() {
            let path = "\(checkIn.clientId)/checkin_\(checkIn.id)_\(i).jpg"
            let url  = try await SupabaseStorage.uploadImage(
                data: photoData, bucket: .checkInPhotos, path: path
            )
            urls.append(url)
        }
        c.photoUrls = urls
        try await supabase.from("check_ins").insert(c).execute()
        checkIns.insert(c, at: 0)
    }
    func delete(_ checkInId: UUID) async throws {
            if let checkIn = checkIns.first(where: { $0.id == checkInId }) {
                await SupabaseStorage.deleteCheckInPhotos(
                    clientId: checkIn.clientId.uuidString,
                    checkInId: checkInId.uuidString,
                    count: checkIn.photoUrls.count
                )
            }
            try await supabase.from("check_ins").delete()
                .eq("id", value: checkInId).execute()
            checkIns.removeAll { $0.id == checkInId }
        }

    func update(_ checkIn: CheckInRow) async throws {
                struct Update: Encodable {
                    let notes: String
                    enum CodingKeys: String, CodingKey { case notes }
                }
                try await supabase.from("check_ins")
                    .update(Update(notes: checkIn.notes))
                    .eq("id", value: checkIn.id)
                    .execute()
                if let i = checkIns.firstIndex(where: { $0.id == checkIn.id }) {
                    checkIns[i] = checkIn
                }
            }

    }

// MARK: ─────────────────────────────────────────────────────────
// MARK: WEIGHT STORE
// MARK: ─────────────────────────────────────────────────────────

struct SBWeightEntryRow: Codable, Identifiable {
    var id:        UUID
    var clientId:  UUID
    var trainerId: UUID?
    var weight:    Double
    var unit:      String
    var note:      String
    var loggedAt:  Date?

    enum CodingKeys: String, CodingKey {
        case id, weight, unit, note
        case clientId  = "client_id"
        case trainerId = "trainer_id"
        case loggedAt  = "logged_at"
    }
}

@MainActor
class SBWeightStore: ObservableObject {
    static let shared = SBWeightStore()
    @Published var entries: [SBWeightEntryRow] = []
    private init() {}

    func fetchForClient(_ clientId: UUID) async throws {
        entries = try await supabase
            .from("weight_entries")
            .select()
            .eq("client_id", value: clientId)
            .order("logged_at", ascending: false)
            .execute()
            .value
    }

    func log(_ entry: SBWeightEntryRow) async throws {
        try await supabase.from("weight_entries").insert(entry).execute()
        entries.insert(entry, at: 0)
    }

    func delete(_ entryId: UUID) async throws {
        try await supabase.from("weight_entries").delete()
            .eq("id", value: entryId).execute()
        entries.removeAll { $0.id == entryId }
    }

    var latestWeight: Double? { entries.first?.weight }

    var weightHistory: [(date: Date, weight: Double)] {
        entries.compactMap { e in
            guard let d = e.loggedAt else { return nil }
            return (date: d, weight: e.weight)
        }
        .sorted { $0.date < $1.date }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: MESSAGE STORE
// MARK: ─────────────────────────────────────────────────────────

struct MessageRow: Codable, Identifiable {
    var id:         UUID
    var trainerId:  UUID
    var clientId:   UUID
    var senderId:   UUID
    var senderRole: String
    var content:    String
    var mediaUrl:   String?
    var mediaType:  String?
    var isRead:     Bool
    var sentAt:     Date?

    enum CodingKeys: String, CodingKey {
        case id, content
        case trainerId  = "trainer_id"
        case clientId   = "client_id"
        case senderId   = "sender_id"
        case senderRole = "sender_role"
        case mediaUrl   = "media_url"
        case mediaType  = "media_type"
        case isRead     = "is_read"
        case sentAt     = "sent_at"
    }
}

@MainActor
class SBMessageStore: ObservableObject {
    static let shared = SBMessageStore()
    @Published var messages: [MessageRow] = []
    private var realtimeChannel: RealtimeChannelV2? = nil
    private init() {}

    func fetchMessages(trainerId: UUID, clientId: UUID) async throws {
        messages = try await supabase
            .from("messages")
            .select()
            .eq("trainer_id", value: trainerId)
            .eq("client_id",  value: clientId)
            .order("sent_at", ascending: true)
            .execute()
            .value
        await markAllRead(trainerId: trainerId, clientId: clientId)
        await subscribeRealtime(trainerId: trainerId, clientId: clientId)
    }

    func send(_ message: MessageRow) async throws {
        try await supabase.from("messages").insert(message).execute()
        messages.append(message)
    }

    private func markAllRead(trainerId: UUID, clientId: UUID) async {
        struct Update: Encodable { let isRead: Bool; enum CodingKeys: String, CodingKey { case isRead = "is_read" } }
        try? await supabase.from("messages")
            .update(Update(isRead: true))
            .eq("trainer_id", value: trainerId)
            .eq("client_id",  value: clientId)
            .eq("is_read", value: false)
            .execute()
    }

    func unreadCount(trainerId: UUID, clientId: UUID, myRole: String) async -> Int {
        let opposite = myRole == "trainer" ? "client" : "trainer"
        let result = try? await supabase
            .from("messages")
            .select("id", count: .exact)
            .eq("trainer_id",  value: trainerId)
            .eq("client_id",   value: clientId)
            .eq("sender_role", value: opposite)
            .eq("is_read",     value: false)
            .execute()
        return result?.count ?? 0
    }

    private func subscribeRealtime(trainerId: UUID, clientId: UUID) async {
        let channel = await supabase.realtimeV2.channel("messages_\(trainerId)_\(clientId)")
        let changes = await channel.postgresChange(
            InsertAction.self, schema: "public", table: "messages"
        )
        await channel.subscribe()
        realtimeChannel = channel
        Task {
            for await _ in changes {
                // Refresh messages on new insert
                if let updated = try? await supabase
                    .from("messages")
                    .select()
                    .eq("trainer_id", value: trainerId)
                    .eq("client_id",  value: clientId)
                    .order("sent_at", ascending: true)
                    .execute()
                    .value as [MessageRow] {
                    await MainActor.run { self.messages = updated }
                }
            }
        }
    }

    func unsubscribe() async {
        if let ch = realtimeChannel { await supabase.realtimeV2.removeChannel(ch) }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: SHARED FILE STORE
// MARK: ─────────────────────────────────────────────────────────

struct SharedFileRow: Codable, Identifiable {
    var id:          UUID
    var trainerId:   UUID
    var clientId:    UUID
    var uploadedBy:  String
    var fileName:    String
    var fileUrl:     String
    var fileSize:    Int?
    var fileType:    String?
    var createdAt:   Date?

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId  = "trainer_id"
        case clientId   = "client_id"
        case uploadedBy = "uploaded_by"
        case fileName   = "file_name"
        case fileUrl    = "file_url"
        case fileSize   = "file_size"
        case fileType   = "file_type"
        case createdAt  = "created_at"
    }
}

@MainActor
class SBSharedFileStore: ObservableObject {
    static let shared = SBSharedFileStore()
    @Published var files: [SharedFileRow] = []
    private init() {}

    func fetchFiles(trainerId: UUID, clientId: UUID) async throws {
        files = try await supabase
            .from("shared_files")
            .select()
            .eq("trainer_id", value: trainerId)
            .eq("client_id",  value: clientId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func upload(data: Data, fileName: String, fileType: String,
                trainerId: UUID, clientId: UUID, uploadedBy: String) async throws {
        let path = "\(trainerId)/\(clientId)/\(UUID().uuidString)_\(fileName)"
        let url  = try await SupabaseStorage.uploadImage(
            data: data, bucket: .sharedFiles, path: path, contentType: fileType
        )
        let file = SharedFileRow(
            id: UUID(), trainerId: trainerId, clientId: clientId,
            uploadedBy: uploadedBy, fileName: fileName,
            fileUrl: url, fileSize: data.count, fileType: fileType,
            createdAt: Date()
        )
        try await supabase.from("shared_files").insert(file).execute()
        files.insert(file, at: 0)
    }

    func delete(_ fileId: UUID) async throws {
        // Remove file from Supabase Storage first
        if let file = files.first(where: { $0.id == fileId }) {
            await SupabaseStorage.deleteByURL(file.fileUrl, bucket: .sharedFiles)
        }
        try await supabase.from("shared_files").delete()
            .eq("id", value: fileId).execute()
        files.removeAll { $0.id == fileId }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: GYM AD STORE (Supabase)
// MARK: ─────────────────────────────────────────────────────────

struct GymAdRow: Codable, Identifiable {
    var id:               UUID
    var businessName:     String
    var tagline:          String
    var category:         String
    var phone:            String?
    var websiteUrl:       String?
    var imageUrl:         String?
    var address:          String?
    var city:             String?
    var state:            String?
    var status:           String
    var plan:             String
    var amenities:        [String]
    var advertiserEmail:  String?
    var createdAt:        Date?

    enum CodingKeys: String, CodingKey {
        case id, tagline, category, phone, address, city, state, status, plan, amenities
        case businessName    = "business_name"
        case websiteUrl      = "website_url"
        case imageUrl        = "image_url"
        case advertiserEmail = "advertiser_email"
        case createdAt       = "created_at"
    }
}

@MainActor
class SBGymAdStore: ObservableObject {
    static let shared = SBGymAdStore()
    @Published var activeAds: [GymAdRow] = []
    private init() { Task { try? await fetchActiveAds() } }

    func fetchActiveAds() async throws {
        activeAds = try await supabase
            .from("gym_ads")
            .select()
            .eq("status", value: "active")
            .order("plan", ascending: false) // premium first
            .execute()
            .value
    }

    func fetchActiveAds(city: String) async throws {
        activeAds = try await supabase
            .from("gym_ads")
            .select()
            .eq("status", value: "active")
            .ilike("city", pattern: "%\(city)%")
            .order("plan", ascending: false)
            .execute()
            .value
    }

    func deleteAd(_ adId: UUID) async throws {
        // Remove logo from Supabase Storage
        await SupabaseStorage.deleteGymAdImage(adId: adId.uuidString)
        // Remove from DB
        try await supabase.from("gym_ads").delete()
            .eq("id", value: adId).execute()
        activeAds.removeAll { $0.id == adId }
    }

    func submitAd(_ ad: GymAdRow, logoData: Data?) async throws {
        var a = ad
        if let logoData = logoData {
            let path = "\(ad.id)/logo.jpg"
            let url  = try await SupabaseStorage.uploadImage(
                data: logoData, bucket: .gymAds, path: path
            )
            a.imageUrl = url
        }
        try await supabase.from("gym_ads").insert(a).execute()
    }
}
