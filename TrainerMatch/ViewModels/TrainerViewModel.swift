//
//  TrainerViewModel.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

import Foundation
import SwiftUI

class TrainerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var clients: [Client] = []
    @Published var workouts: [Workout] = []
    @Published var progressEntries: [ProgressEntry] = []
    @Published var currentUserRole: UserRole = .trainer
    @Published var currentTrainerId: String = AuthManager.shared.currentUserId ?? ""
    
    // MARK: - Initialization
    init() {
        loadPersistedData()
    }

    // MARK: - Load persisted data
    private func loadPersistedData() {
        // Clients are added manually by the trainer — no fake data
        self.clients = []
        self.workouts = []
        self.progressEntries = []
    }
    
    // MARK: - Client Management
    
    func addClient(_ client: Client) {
        clients.append(client)
        // TODO: Save to database
    }
    
    func updateClient(_ client: Client) {
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
            // TODO: Update in database
        }
    }
    
    func deleteClient(_ client: Client) {
        clients.removeAll { $0.id == client.id }
        // TODO: Delete from database
    }
    
    func getClient(byId id: String) -> Client? {
        return clients.first { $0.id == id }
    }
    
    // MARK: - Workout Management
    
    func assignWorkout(_ workout: Workout, to client: Client) {
        var newWorkout = workout
        newWorkout.clientId = client.id
        newWorkout.trainerId = currentTrainerId
        workouts.append(newWorkout)
        // TODO: Save to database
    }
    
    func getWorkouts(for client: Client) -> [Workout] {
        return workouts.filter { $0.clientId == client.id }
            .sorted { $0.assignedDate > $1.assignedDate }
    }
    
    func getActiveWorkouts(for client: Client) -> [Workout] {
        return getWorkouts(for: client).filter { !$0.isCompleted }
    }
    
    func getCompletedWorkouts(for client: Client) -> [Workout] {
        return getWorkouts(for: client).filter { $0.isCompleted }
    }
    
    func updateWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
            // TODO: Update in database
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        // TODO: Delete from database
    }
    
    func markWorkoutComplete(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index].isCompleted = true
            workouts[index].completedDate = Date()
            // TODO: Update in database
        }
    }
    
    // MARK: - Progress Tracking
    
    func addProgressEntry(_ entry: ProgressEntry) {
        progressEntries.append(entry)
        // TODO: Save to database
    }
    
    func getProgressEntries(for client: Client) -> [ProgressEntry] {
        return progressEntries.filter { $0.clientId == client.id }
            .sorted { $0.date > $1.date }
    }
    
    func getLatestProgress(for client: Client) -> ProgressEntry? {
        return getProgressEntries(for: client).first
    }
    
    func updateProgressEntry(_ entry: ProgressEntry) {
        if let index = progressEntries.firstIndex(where: { $0.id == entry.id }) {
            progressEntries[index] = entry
            // TODO: Update in database
        }
    }
    
    func deleteProgressEntry(_ entry: ProgressEntry) {
        progressEntries.removeAll { $0.id == entry.id }
        // TODO: Delete from database
    }
    
    // MARK: - Statistics & Analytics
    
    func getClientStats(for client: Client) -> ClientStats {
        let clientWorkouts = getWorkouts(for: client)
        let completedCount = clientWorkouts.filter { $0.isCompleted }.count
        let activeCount = clientWorkouts.filter { !$0.isCompleted }.count
        let completionRate = clientWorkouts.isEmpty ? 0.0 : Double(completedCount) / Double(clientWorkouts.count) * 100
        
        let progressHistory = getProgressEntries(for: client)
        let weightChange = calculateWeightChange(for: client, from: progressHistory)
        
        return ClientStats(
            totalWorkouts: clientWorkouts.count,
            completedWorkouts: completedCount,
            activeWorkouts: activeCount,
            completionRate: completionRate,
            weightChange: weightChange,
            daysActive: calculateDaysActive(client: client)
        )
    }
    
    private func calculateWeightChange(for client: Client, from entries: [ProgressEntry]) -> Double? {
        guard entries.count >= 2 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.weight,
              let last = sorted.last?.weight else { return nil }
        return last - first
    }
    
    private func calculateDaysActive(client: Client) -> Int {
        let calendar = Calendar.current
        let today = Date()
        let joined = client.dateJoined
        let days = calendar.dateComponents([.day], from: joined, to: today).day ?? 0
        return days
    }
    
    // MARK: - Search & Filter
    
    func searchClients(query: String) -> [Client] {
        if query.isEmpty {
            return clients
        }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    func filterClientsByActivity(status: String) -> [Client] {
        return clients.filter { $0.activityStatus == status }
    }
    
    func sortClients(by sortOption: ClientSortOption) -> [Client] {
        switch sortOption {
        case .nameAscending:
            return clients.sorted { $0.name < $1.name }
        case .nameDescending:
            return clients.sorted { $0.name > $1.name }
        case .recentlyAdded:
            return clients.sorted { $0.dateJoined > $1.dateJoined }
        case .mostActive:
            return clients.sorted { $0.dailySteps > $1.dailySteps }
        }
    }
}

// MARK: - Supporting Types

struct ClientStats {
    let totalWorkouts: Int
    let completedWorkouts: Int
    let activeWorkouts: Int
    let completionRate: Double
    let weightChange: Double?
    let daysActive: Int
}

enum ClientSortOption: String, CaseIterable {
    case nameAscending = "Name (A-Z)"
    case nameDescending = "Name (Z-A)"
    case recentlyAdded = "Recently Added"
    case mostActive = "Most Active"
}
