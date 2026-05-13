//
//  AuthManager.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/12/26.
//
//

import Foundation
import Combine
import AuthenticationServices

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUserRole: UserRole?
    @Published var currentUserId: String?
    @Published var currentUserEmail: String?
    
    // For trainers
    @Published var currentTrainerProfile: SavedTrainerProfile?
    
    // For clients
    @Published var currentClientProfile: SavedClientProfile?
    
    private let userDefaults = UserDefaults.standard
    
    // UserDefaults Keys
    private let isAuthenticatedKey = "isAuthenticated"
    private let currentUserRoleKey = "currentUserRole"
    private let currentUserIdKey = "currentUserId"
    private let currentUserEmailKey = "currentUserEmail"
    private let trainersKey = "savedTrainers"
    private let clientsKey = "savedClients"
    
    init() {
        loadSession()
    }
    
    // MARK: - Session Management
    
    func loadSession() {
        isAuthenticated = userDefaults.bool(forKey: isAuthenticatedKey)
        currentUserId = userDefaults.string(forKey: currentUserIdKey)
        currentUserEmail = userDefaults.string(forKey: currentUserEmailKey)
        
        if let roleString = userDefaults.string(forKey: currentUserRoleKey),
           let role = UserRole(rawValue: roleString) {
            currentUserRole = role
            
            // Load the user's profile
            if role == .trainer {
                loadCurrentTrainerProfile()
            } else {
                loadCurrentClientProfile()
            }
        }
    }
    
    func saveSession() {
        userDefaults.set(isAuthenticated, forKey: isAuthenticatedKey)
        userDefaults.set(currentUserRole?.rawValue, forKey: currentUserRoleKey)
        userDefaults.set(currentUserId, forKey: currentUserIdKey)
        userDefaults.set(currentUserEmail, forKey: currentUserEmailKey)
    }
    
    func logout() {
        isAuthenticated = false
        currentUserRole = nil
        currentUserId = nil
        currentUserEmail = nil
        currentTrainerProfile = nil
        currentClientProfile = nil
        saveSession()
    }
    
    // MARK: - Registration
    
    func registerTrainer(
        businessName: String?,
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        city: String,
        state: String,
        yearsOfExperience: String,
        hourlyRate: String,
        monthlyRate: String,
        bio: String,
        certifications: Set<TrainerCertification>,
        schools: Set<TrainingSchool>,
        specialties: Set<TrainerSpecialty>,
        serviceTypes: Set<ServiceType>
    ) -> Bool {
        
        // Check if email already exists
        if getTrainerByEmail(email) != nil {
            return false // Email already registered
        }
        
        let userId = UUID().uuidString
        
        let trainer = SavedTrainerProfile(
            id: userId,
            businessName: businessName,
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password, // In production, HASH this!
            city: city,
            state: state,
            gender: "",
            yearsOfExperience: Int(yearsOfExperience) ?? 0,
            hourlyRate: Double(hourlyRate),
            monthlyRate: Double(monthlyRate),
            bio: bio,
            certifications: Array(certifications),
            schools: Array(schools),
            specialties: Array(specialties),
            serviceTypes: Array(serviceTypes),
            dateCreated: Date()
        )
        
        saveTrainer(trainer)
        
        // Auto-login after registration
        loginTrainer(email: email, password: password)
        
        return true
    }
    
    func registerClient(
        firstName: String,
        lastName: String,
        email: String,
        password: String,
        city: String,
        state: String,
        birthDate: Date,
        fitnessGoals: Set<FitnessGoal>,
        fitnessLevel: String,
        targetWeight: String,
        medicalConditions: String,
        injuries: String,
        allergies: String,
        medications: String
    ) -> Bool {
        
        // Check if email already exists
        if getClientByEmail(email) != nil {
            return false // Email already registered
        }
        
        let userId = UUID().uuidString
        
        let client = SavedClientProfile(
            id: userId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            password: password, // In production, HASH this!
            city: city,
            state: state,
            birthDate: birthDate,
            fitnessGoals: Array(fitnessGoals),
            fitnessLevel: fitnessLevel,
            targetWeight: Double(targetWeight),
            medicalConditions: medicalConditions,
            injuries: injuries,
            allergies: allergies,
            medications: medications,
            dateCreated: Date()
        )
        
        saveClient(client)
        
        // Auto-login after registration
        loginClient(email: email, password: password)
        
        return true
    }
    
    // MARK: - Login
    
    func loginTrainer(email: String, password: String) -> Bool {
        guard let trainer = getTrainerByEmail(email),
              trainer.password == password else {
            return false
        }
        
        isAuthenticated = true
        currentUserRole = .trainer
        currentUserId = trainer.id
        currentUserEmail = trainer.email
        currentTrainerProfile = trainer
        saveSession()
        
        return true
    }
    
    func updateClientProfile(_ client: SavedClientProfile) {
        saveClient(client)
        if currentUserId == client.id {
            currentClientProfile = client
        }
    }

    func updateTrainerProfile(_ trainer: SavedTrainerProfile) {
        saveTrainer(trainer)
        if currentUserId == trainer.id {
            currentTrainerProfile = trainer
        }
    }

    func loginClient(email: String, password: String) -> Bool {
        guard let client = getClientByEmail(email),
              client.password == password else {
            return false
        }
        
        isAuthenticated = true
        currentUserRole = .client
        currentUserId = client.id
        currentUserEmail = client.email
        currentClientProfile = client
        saveSession()
        
        return true
    }
    
    // MARK: - Storage
    
    private func saveTrainer(_ trainer: SavedTrainerProfile) {
        var trainers = getAllTrainers()
        if let index = trainers.firstIndex(where: { $0.id == trainer.id }) {
            trainers[index] = trainer
        } else {
            trainers.append(trainer)
        }
        
        if let encoded = try? JSONEncoder().encode(trainers) {
            userDefaults.set(encoded, forKey: trainersKey)
        }
    }
    
    private func saveClient(_ client: SavedClientProfile) {
        var clients = getAllClients()
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        } else {
            clients.append(client)
        }
        
        if let encoded = try? JSONEncoder().encode(clients) {
            userDefaults.set(encoded, forKey: clientsKey)
        }
    }
    
    func getAllTrainers() -> [SavedTrainerProfile] {
        guard let data = userDefaults.data(forKey: trainersKey),
              let trainers = try? JSONDecoder().decode([SavedTrainerProfile].self, from: data) else {
            return []
        }
        return trainers
    }
    
    func getAllClients() -> [SavedClientProfile] {
        guard let data = userDefaults.data(forKey: clientsKey),
              let clients = try? JSONDecoder().decode([SavedClientProfile].self, from: data) else {
            return []
        }
        return clients
    }
    
    private func getTrainerByEmail(_ email: String) -> SavedTrainerProfile? {
        return getAllTrainers().first { $0.email.lowercased() == email.lowercased() }
    }
    
    private func getClientByEmail(_ email: String) -> SavedClientProfile? {
        return getAllClients().first { $0.email.lowercased() == email.lowercased() }
    }
    
    private func loadCurrentTrainerProfile() {
        guard let userId = currentUserId else { return }
        currentTrainerProfile = getAllTrainers().first { $0.id == userId }
    }
    
    private func loadCurrentClientProfile() {
        guard let userId = currentUserId else { return }
        currentClientProfile = getAllClients().first { $0.id == userId }
    }

    // MARK: - Public helpers (used by AppleSignInSetupView)

    func saveTrainerPublic(_ trainer: SavedTrainerProfile) {
        saveTrainer(trainer)
    }

    func saveClientPublic(_ client: SavedClientProfile) {
        saveClient(client)
    }

    func getAllTrainersPublic() -> [SavedTrainerProfile] {
        getAllTrainers()
    }

    func getAllClientsPublic() -> [SavedClientProfile] {
        getAllClients()
    }

    // MARK: - Apple Sign In

    func loginOrRegisterWithApple(userId: String, email: String,
                                   firstName: String, lastName: String,
                                   role: UserRole) {
        if role == .trainer {
            if let existing = getAllTrainers().first(where: { $0.id == userId }) {
                isAuthenticated = true
                currentUserRole = .trainer
                currentUserId = existing.id
                currentUserEmail = existing.email
                currentTrainerProfile = existing
                saveSession()
                return
            }
            let trainer = SavedTrainerProfile(
                id: userId,
                businessName: firstName.isEmpty ? nil : "\(firstName) \(lastName) Fitness",
                firstName: firstName.isEmpty ? "Trainer" : firstName,
                lastName: lastName,
                email: email,
                password: "apple_sso_\(userId)",
                city: "", state: "",
                gender: "",
                yearsOfExperience: 0,
                hourlyRate: nil, monthlyRate: nil, bio: "",
                certifications: [], schools: [], specialties: [],
                serviceTypes: [], dateCreated: Date()
            )
            saveTrainer(trainer)
            isAuthenticated = true
            currentUserRole = .trainer
            currentUserId = userId
            currentUserEmail = email
            currentTrainerProfile = trainer
            saveSession()
        } else {
            if let existing = getAllClients().first(where: { $0.id == userId }) {
                isAuthenticated = true
                currentUserRole = .client
                currentUserId = existing.id
                currentUserEmail = existing.email
                currentClientProfile = existing
                saveSession()
                return
            }
            let client = SavedClientProfile(
                id: userId,
                firstName: firstName.isEmpty ? "Client" : firstName,
                lastName: lastName,
                email: email,
                password: "apple_sso_\(userId)",
                city: "", state: "",
                birthDate: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
                fitnessGoals: [.generalFitness],
                fitnessLevel: "Beginner",
                targetWeight: nil,
                medicalConditions: "", injuries: "",
                allergies: "", medications: "",
                dateCreated: Date()
            )
            saveClient(client)
            isAuthenticated = true
            currentUserRole = .client
            currentUserId = userId
            currentUserEmail = email
            currentClientProfile = client
            saveSession()
        }
    }
}

// MARK: - Saved Profile Models

struct SavedTrainerProfile: Codable, Identifiable {
    let id: String
    let businessName: String?
    let firstName: String
    let lastName: String
    let email: String
    let password: String // WARNING: In production, use proper password hashing!
    let city: String
    let state: String
    var gender: String
    let yearsOfExperience: Int
    let hourlyRate: Double?
    let monthlyRate: Double?
    let bio: String
    let certifications: [TrainerCertification]
    let schools: [TrainingSchool]
    let specialties: [TrainerSpecialty]
    let serviceTypes: [ServiceType]
    let dateCreated: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}

struct SavedClientProfile: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let email: String
    let password: String // WARNING: In production, use proper password hashing!
    let city: String
    let state: String
    let birthDate: Date
    let fitnessGoals: [FitnessGoal]
    let fitnessLevel: String
    let targetWeight: Double?
    let medicalConditions: String
    let injuries: String
    let allergies: String
    let medications: String
    let dateCreated: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var age: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }
}
