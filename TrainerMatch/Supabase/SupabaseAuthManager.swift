//
//  SupabaseAuthManager.swift
//  TrainerMatch
//

import Foundation
import SwiftUI
import Supabase
import Auth
import AuthenticationServices

// MARK: - Supabase row models

struct TrainerRow: Codable, Identifiable {
    var id:                  UUID
    var authId:              UUID?
    var businessName:        String?
    var firstName:           String
    var lastName:            String
    var email:               String
    var city:                String
    var state:               String
    var gender:              String
    var bio:                 String
    var yearsOfExperience:   Int
    var hourlyRate:          Double?
    var monthlyRate:         Double?
    var specialties:         [String]
    var certifications:      [String]
    var schools:             [String]
    var serviceTypes:        [String]
    var profileImageUrl:     String?
    var bannerImageUrl:      String?
    var isActive:            Bool
    var createdAt:           Date?

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id, email, city, state, gender, bio
        case authId              = "auth_id"
        case businessName        = "business_name"
        case firstName           = "first_name"
        case lastName            = "last_name"
        case yearsOfExperience   = "years_of_experience"
        case hourlyRate          = "hourly_rate"
        case monthlyRate         = "monthly_rate"
        case specialties, certifications, schools
        case serviceTypes        = "service_types"
        case profileImageUrl     = "profile_image_url"
        case bannerImageUrl      = "banner_image_url"
        case isActive            = "is_active"
        case createdAt           = "created_at"
    }
}

struct ClientRow: Codable, Identifiable {
    var id:                UUID
    var authId:            UUID?
    var firstName:         String
    var lastName:          String
    var email:             String
    var city:              String
    var state:             String
    var fitnessGoals:      [String]
    var fitnessLevel:      String
    var targetWeight:      Double?
    var medicalConditions: String
    var injuries:          String
    var allergies:         String
    var medications:       String
    var profileImageUrl:   String?
    var isActive:          Bool
    var createdAt:         Date?

    var fullName: String { "\(firstName) \(lastName)" }

    enum CodingKeys: String, CodingKey {
        case id, email, city, state
        case authId            = "auth_id"
        case firstName         = "first_name"
        case lastName          = "last_name"
        case fitnessGoals      = "fitness_goals"
        case fitnessLevel      = "fitness_level"
        case targetWeight      = "target_weight"
        case medicalConditions = "medical_conditions"
        case injuries, allergies, medications
        case profileImageUrl   = "profile_image_url"
        case isActive          = "is_active"
        case createdAt         = "created_at"
    }
}

// MARK: - Auth State Changed Notification
extension Notification.Name {
    static let tmAuthStateChanged = Notification.Name("TMAuthStateChanged")
}

// MARK: - Auth Manager

@MainActor
class SupabaseAuthManager: ObservableObject {

    static let shared = SupabaseAuthManager()

    @Published var isAuthenticated   = false
    @Published var currentUserRole:  UserRole? = nil
    @Published var isLoading         = false
    @Published var errorMessage:     String? = nil
    @Published var currentTrainer:   TrainerRow? = nil
    @Published var currentClient:    ClientRow?  = nil

    var currentUserId: UUID? {
        currentTrainer?.id ?? currentClient?.id
    }

    private init() {
        Task { await restoreSession() }
    }

    // MARK: - Session restore

    func restoreSession() async {
        isLoading = true
        do {
            let session = try await supabase.auth.session
            let authId  = session.user.id
            await loadProfileForAuthId(authId)
            PushNotificationManager.shared.loginUser(userId: authId.uuidString)
        } catch {
            isAuthenticated = false
        }
        isLoading = false
    }

    private func loadProfileForAuthId(_ authId: UUID) async {
        if let trainer = try? await supabase
            .from("trainers")
            .select()
            .eq("auth_id", value: authId)
            .single()
            .execute()
            .value as TrainerRow {
            currentTrainer    = trainer
            currentUserRole   = .trainer
            isAuthenticated   = true
            return
        }
        if let client = try? await supabase
            .from("clients")
            .select()
            .eq("auth_id", value: authId)
            .single()
            .execute()
            .value as ClientRow {
            currentClient   = client
            currentUserRole = .client
            isAuthenticated = true
            return
        }
        isAuthenticated = false
    }

    // MARK: - Email Sign Up

    func signUpTrainer(
        email: String, password: String,
        businessName: String?, firstName: String, lastName: String,
        city: String, state: String, gender: String,
        yearsOfExperience: Int, hourlyRate: Double?, monthlyRate: Double?,
        bio: String, certifications: [String], schools: [String],
        specialties: [String], serviceTypes: [String]
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let authResponse = try await supabase.auth.signUp(email: email, password: password)
        let trainer = TrainerRow(
            id: UUID(), authId: authResponse.user.id,
            businessName: businessName,
            firstName: firstName, lastName: lastName,
            email: email, city: city, state: state,
            gender: gender, bio: bio,
            yearsOfExperience: yearsOfExperience,
            hourlyRate: hourlyRate, monthlyRate: monthlyRate,
            specialties: specialties, certifications: certifications,
            schools: schools, serviceTypes: serviceTypes,
            profileImageUrl: nil, bannerImageUrl: nil,
            isActive: true, createdAt: Date()
        )
        try await supabase.from("trainers").insert(trainer).execute()
        currentTrainer  = trainer
        currentUserRole = .trainer
        isAuthenticated = true
    }

    func signUpClient(
        email: String, password: String,
        firstName: String, lastName: String,
        city: String, state: String,
        fitnessGoals: [String], fitnessLevel: String,
        targetWeight: Double?,
        medicalConditions: String, injuries: String,
        allergies: String, medications: String
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let authResponse = try await supabase.auth.signUp(email: email, password: password)
        let client = ClientRow(
            id: UUID(), authId: authResponse.user.id,
            firstName: firstName, lastName: lastName,
            email: email, city: city, state: state,
            fitnessGoals: fitnessGoals, fitnessLevel: fitnessLevel,
            targetWeight: targetWeight,
            medicalConditions: medicalConditions, injuries: injuries,
            allergies: allergies, medications: medications,
            profileImageUrl: nil, isActive: true, createdAt: Date()
        )
        try await supabase.from("clients").insert(client).execute()
        currentClient   = client
        currentUserRole = .client
        isAuthenticated = true
    }

    // MARK: - Email Sign In

    func signIn(email: String, password: String, role: UserRole) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let session = try await supabase.auth.signIn(email: email, password: password)
        let authId = session.user.id

        if role == .trainer {
            guard let trainer = try? await supabase
                .from("trainers")
                .select()
                .eq("auth_id", value: authId)
                .single()
                .execute()
                .value as TrainerRow else {
                throw TMError.profileNotFound
            }
            currentTrainer  = trainer
            currentUserRole = .trainer
        } else {
            guard let client = try? await supabase
                .from("clients")
                .select()
                .eq("auth_id", value: authId)
                .single()
                .execute()
                .value as ClientRow else {
                throw TMError.profileNotFound
            }
            currentClient   = client
            currentUserRole = .client
        }
        isAuthenticated = true
        PushNotificationManager.shared.loginUser(userId: authId.uuidString)
    }

    // MARK: - Apple Sign In

    func signInWithApple(
        idToken: String, nonce: String, role: UserRole,
        firstName: String, lastName: String
    ) async throws -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        let authId = session.user.id
        let email  = session.user.email ?? "\(authId)@privaterelay.appleid.com"

        if role == .trainer {
            if let trainer = try? await supabase
                .from("trainers").select()
                .eq("auth_id", value: authId)
                .single().execute().value as TrainerRow {
                currentTrainer  = trainer
                currentUserRole = .trainer
                isAuthenticated = true
                PushNotificationManager.shared.loginUser(userId: authId.uuidString)
                return false
            }
            if let trainer = try? await supabase
                .from("trainers").select()
                .eq("email", value: email)
                .single().execute().value as TrainerRow {
                var updated = trainer
                updated.authId = authId
                try? await supabase.from("trainers").update(updated).eq("id", value: trainer.id).execute()
                currentTrainer  = updated
                currentUserRole = .trainer
                isAuthenticated = true
                PushNotificationManager.shared.loginUser(userId: authId.uuidString)
                return false
            }
        } else {
            if let client = try? await supabase
                .from("clients").select()
                .eq("auth_id", value: authId)
                .single().execute().value as ClientRow {
                currentClient   = client
                currentUserRole = .client
                isAuthenticated = true
                PushNotificationManager.shared.loginUser(userId: authId.uuidString)
                return false
            }
            if let client = try? await supabase
                .from("clients").select()
                .eq("email", value: email)
                .single().execute().value as ClientRow {
                var updated = client
                updated.authId = authId
                try? await supabase.from("clients").update(updated).eq("id", value: client.id).execute()
                currentClient   = updated
                currentUserRole = .client
                isAuthenticated = true
                PushNotificationManager.shared.loginUser(userId: authId.uuidString)
                return false
            }
        }

        // ✅ New user — set pending state AND mark authenticated
        // so AppEntryView shows the setup screen
        pendingAppleAuthId    = authId
        pendingAppleEmail     = email
        pendingAppleFirstName = firstName
        pendingAppleLastName  = lastName
        pendingAppleRole      = role
        isAuthenticated       = true  // ✅ KEY FIX
        return true
    }

    var pendingAppleAuthId:    UUID?    = nil
    var pendingAppleEmail:     String   = ""
    var pendingAppleFirstName: String   = ""
    var pendingAppleLastName:  String   = ""
    var pendingAppleRole:      UserRole = .client

    // MARK: - Complete Apple Trainer Setup

    func completeAppleTrainerSetup(
        businessName: String?, city: String, state: String, gender: String,
        yearsOfExperience: Int, hourlyRate: Double?, bio: String,
        specialties: [String], serviceTypes: [String]
    ) async throws {
        guard let authId = pendingAppleAuthId else { throw TMError.notAuthenticated }
        isLoading = true
        defer { isLoading = false }

        let trainer = TrainerRow(
            id: UUID(), authId: authId,
            businessName: businessName.flatMap { $0.isEmpty ? nil : $0 },
            firstName: pendingAppleFirstName.isEmpty ? "Trainer" : pendingAppleFirstName,
            lastName:  pendingAppleLastName,
            email:     pendingAppleEmail,
            city: city, state: state, gender: gender, bio: bio,
            yearsOfExperience: yearsOfExperience,
            hourlyRate: hourlyRate, monthlyRate: nil,
            specialties: specialties, certifications: [], schools: [],
            serviceTypes: serviceTypes,
            profileImageUrl: nil, bannerImageUrl: nil,
            isActive: true, createdAt: Date()
        )
        try await supabase.from("trainers").insert(trainer).execute()
        currentTrainer  = trainer
        currentUserRole = .trainer
        isAuthenticated = true
        PushNotificationManager.shared.loginUser(userId: authId.uuidString)
        clearPendingApple()
    }

    // MARK: - Complete Apple Client Setup

    func completeAppleClientSetup(
        displayName: String, city: String, state: String,
        fitnessLevel: String, fitnessGoals: [String]
    ) async throws {
        guard let authId = pendingAppleAuthId else { throw TMError.notAuthenticated }
        isLoading = true
        defer { isLoading = false }

        let parts = displayName.split(separator: " ")
        let fName = parts.first.map(String.init) ?? (pendingAppleFirstName.isEmpty ? "Client" : pendingAppleFirstName)
        let lName = parts.dropFirst().joined(separator: " ")

        let client = ClientRow(
            id: UUID(), authId: authId,
            firstName: fName, lastName: lName,
            email: pendingAppleEmail,
            city: city, state: state,
            fitnessGoals: fitnessGoals, fitnessLevel: fitnessLevel,
            targetWeight: nil,
            medicalConditions: "", injuries: "",
            allergies: "", medications: "",
            profileImageUrl: nil, isActive: true, createdAt: Date()
        )
        try await supabase.from("clients").insert(client).execute()
        currentClient   = client
        currentUserRole = .client
        isAuthenticated = true
        PushNotificationManager.shared.loginUser(userId: authId.uuidString)
        clearPendingApple()
    }

    private func clearPendingApple() {
        pendingAppleAuthId    = nil
        pendingAppleEmail     = ""
        pendingAppleFirstName = ""
        pendingAppleLastName  = ""
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }

    // MARK: - Sign Out

    func signOut() async {
        try? await supabase.auth.signOut()
        PushNotificationManager.shared.logoutUser()
        currentTrainer  = nil
        currentClient   = nil
        currentUserRole = nil
        isAuthenticated = false
        clearPendingApple()
    }

    // MARK: - Update Profile

    func updateTrainerProfile(_ trainer: TrainerRow) async throws {
        try await supabase.from("trainers").update(trainer).eq("id", value: trainer.id).execute()
        currentTrainer = trainer
    }

    func updateClientProfile(_ client: ClientRow) async throws {
        try await supabase.from("clients").update(client).eq("id", value: client.id).execute()
        currentClient = client
    }

    // MARK: - Upload Profile Photo

    func uploadProfilePhoto(imageData: Data) async throws -> String {
        guard let userId = currentUserId else { throw TMError.notAuthenticated }
        await SupabaseStorage.deleteProfilePhoto(userId: userId.uuidString)
        let path = "\(userId)/profile.jpg"
        let url  = try await SupabaseStorage.uploadImage(data: imageData, bucket: .profilePhotos, path: path)
        if currentUserRole == .trainer {
            var t = currentTrainer!
            t.profileImageUrl = url
            try await updateTrainerProfile(t)
        } else {
            var c = currentClient!
            c.profileImageUrl = url
            try await updateClientProfile(c)
        }
        return url
    }

    func uploadBannerPhoto(imageData: Data) async throws -> String {
        guard let userId = currentUserId, currentUserRole == .trainer else { throw TMError.notAuthenticated }
        await SupabaseStorage.deleteBannerPhoto(userId: userId.uuidString)
        let path = "\(userId)/banner.jpg"
        let url  = try await SupabaseStorage.uploadImage(data: imageData, bucket: .bannerPhotos, path: path)
        var t = currentTrainer!
        t.bannerImageUrl = url
        try await updateTrainerProfile(t)
        return url
    }

    // MARK: - Delete Photos

    func deleteProfilePhoto() async throws {
        guard let userId = currentUserId else { throw TMError.notAuthenticated }
        await SupabaseStorage.deleteProfilePhoto(userId: userId.uuidString)
        if currentUserRole == .trainer {
            var t = currentTrainer!; t.profileImageUrl = nil
            try await updateTrainerProfile(t)
        } else {
            var c = currentClient!; c.profileImageUrl = nil
            try await updateClientProfile(c)
        }
    }

    func deleteBannerPhoto() async throws {
        guard let userId = currentUserId, currentUserRole == .trainer else { throw TMError.notAuthenticated }
        await SupabaseStorage.deleteBannerPhoto(userId: userId.uuidString)
        var t = currentTrainer!; t.bannerImageUrl = nil
        try await updateTrainerProfile(t)
    }

    // MARK: - Fetch Trainers

    func fetchAllTrainers() async throws -> [TrainerRow] {
        try await supabase.from("trainers").select()
            .eq("is_active", value: true)
            .order("created_at", ascending: false)
            .execute().value
    }

    func searchTrainers(
        city: String? = nil, specialties: [String] = [],
        serviceType: String? = nil, gender: String? = nil
    ) async throws -> [TrainerRow] {
        var query = supabase.from("trainers").select().eq("is_active", value: true)
        if let city = city, !city.isEmpty { query = query.ilike("city", pattern: "%\(city)%") }
        if let gender = gender, gender != "Any", !gender.isEmpty { query = query.eq("gender", value: gender) }
        if !specialties.isEmpty { query = query.contains("specialties", value: specialties) }
        if let serviceType = serviceType { query = query.contains("service_types", value: [serviceType]) }
        return try await query.order("created_at", ascending: false).execute().value
    }

    // MARK: - Fetch Trainer's Clients

    func fetchTrainerClients() async throws -> [ClientRow] {
        guard let trainerId = currentTrainer?.id else { throw TMError.notAuthenticated }
        let connections: [SBTrainerClientRow] = try await supabase
            .from("trainer_clients").select()
            .eq("trainer_id", value: trainerId)
            .eq("status", value: "active")
            .execute().value
        let clientIds = connections.map { $0.clientId.uuidString }
        guard !clientIds.isEmpty else { return [] }
        return try await supabase.from("clients").select().in("id", values: clientIds).execute().value
    }

    func addClientToRoster(clientId: UUID) async throws {
        guard let trainerId = currentTrainer?.id else { throw TMError.notAuthenticated }
        struct Connection: Encodable {
            let trainerId: UUID; let clientId: UUID; let status: String
            enum CodingKeys: String, CodingKey {
                case trainerId = "trainer_id"; case clientId = "client_id"; case status
            }
        }
        try await supabase.from("trainer_clients")
            .upsert(Connection(trainerId: trainerId, clientId: clientId, status: "active"))
            .execute()
    }
}

// MARK: - Trainer-Client row model
