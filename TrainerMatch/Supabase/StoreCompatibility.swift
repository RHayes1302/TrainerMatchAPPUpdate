//
//  StoreCompatibility.swift
//  TrainerMatch
//
//  Compatibility layer bridging existing views to new Supabase stores.
//  Existing views call sync methods — this provides cached sync access
//  while fetching from Supabase in the background.
//
//  This lets ClientFolderView, EnhancedClientView etc. keep working
//  without rewriting every view at once.
//

import SwiftUI
import Foundation

// MARK: ─────────────────────────────────────────────────────────
// MARK: CHECK-IN COMPATIBILITY
// MARK: ─────────────────────────────────────────────────────────

extension SBCheckInStore {

    /// Sync access to cached check-ins for a client
    func checkIns(forClient clientId: String) -> [CheckInRow] {
        checkIns.filter { $0.clientId.uuidString == clientId }
    }

    /// Sync access to cached check-ins for a trainer
    func checkIns(forTrainer trainerId: String) -> [CheckInRow] {
        checkIns.filter { $0.trainerId.uuidString == trainerId }
    }

    /// Pending check-ins (no trainer response yet — using notes as proxy)
    func pendingCheckIns(forTrainer trainerId: String) -> [CheckInRow] {
        checkIns.filter { $0.trainerId.uuidString == trainerId && $0.notes.isEmpty }
    }

    /// Load check-ins for a client in the background
    func loadForClient(_ clientId: String) {
        guard let uuid = UUID(uuidString: clientId) else { return }
        Task { try? await fetchForClient(uuid) }
    }

    /// Load check-ins for a trainer in the background
    func loadForTrainer(_ trainerId: String) {
        // Fetch all check-ins across all clients for this trainer
        // using the trainer_id column
        guard let uuid = UUID(uuidString: trainerId) else { return }
        Task {
            if let rows = try? await supabase
                .from("check_ins")
                .select()
                .eq("trainer_id", value: uuid)
                .order("checked_in_at", ascending: false)
                .execute()
                .value as [CheckInRow] {
                await MainActor.run { self.checkIns = rows }
            }
        }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: WORKOUT COMPATIBILITY
// MARK: ─────────────────────────────────────────────────────────

extension SBWorkoutStore {

    func workouts(forClient clientId: String) -> [WorkoutRow] {
        workouts.filter { $0.clientId.uuidString == clientId }
    }

    func workouts(forTrainer trainerId: String) -> [WorkoutRow] {
        workouts.filter { $0.trainerId.uuidString == trainerId }
    }

    func pendingWorkouts(forClient clientId: String) -> [WorkoutRow] {
        workouts.filter { $0.clientId.uuidString == clientId && $0.status == "assigned" }
    }

    func pendingCount(forTrainer trainerId: String) -> Int {
        workouts.filter { $0.trainerId.uuidString == trainerId && $0.status == "assigned" }.count
    }

    func loadForClient(_ clientId: String) {
        guard let uuid = UUID(uuidString: clientId) else { return }
        Task { try? await fetchForClient(uuid) }
    }

    func loadForTrainer(_ trainerId: String) {
        guard let uuid = UUID(uuidString: trainerId) else { return }
        Task { try? await fetchForTrainer(uuid) }
    }

    func delete(_ workout: WorkoutRow) {
        Task { try? await delete(workout.id) }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: MEAL PLAN COMPATIBILITY
// MARK: ─────────────────────────────────────────────────────────

extension SBMealPlanStore {

    func plans(forClient clientId: String) -> [MealPlanRow] {
        mealPlans.filter { $0.clientId.uuidString == clientId }
    }

    func plans(forTrainer trainerId: String) -> [MealPlanRow] {
        mealPlans.filter { $0.trainerId.uuidString == trainerId }
    }

    func activePlan(forClient clientId: String) -> MealPlanRow? {
        mealPlans.first { $0.clientId.uuidString == clientId && $0.isActive }
    }

    func loadForClient(_ clientId: String) {
        guard let uuid = UUID(uuidString: clientId) else { return }
        Task { try? await fetchForClient(uuid) }
    }

    func delete(_ plan: MealPlanRow) {
        Task { try? await delete(plan.id) }
    }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: WEIGHT STORE COMPATIBILITY
// MARK: ─────────────────────────────────────────────────────────

extension SBWeightStore {

    func entries(forClient clientId: String) -> [SBWeightEntryRow] {
        entries.filter { $0.clientId.uuidString == clientId }
    }

    func latestWeight(forClient clientId: String) -> SBWeightEntryRow? {
        entries.filter { $0.clientId.uuidString == clientId }
               .sorted { ($0.loggedAt ?? Date.distantPast) > ($1.loggedAt ?? Date.distantPast) }
               .first
    }

    func startingWeight(forClient clientId: String) -> SBWeightEntryRow? {
        entries.filter { $0.clientId.uuidString == clientId }
               .sorted { ($0.loggedAt ?? Date.distantPast) < ($1.loggedAt ?? Date.distantPast) }
               .first
    }

    /// Weight goal — not in Supabase yet, returns nil for now
    func activeGoal(forClient clientId: String) -> SBWeightGoal? { nil }

    func loadForClient(_ clientId: String) {
        guard let uuid = UUID(uuidString: clientId) else { return }
        Task { try? await fetchForClient(uuid) }
    }
}

/// Placeholder goal model until we add the weight_goals table
struct SBWeightGoal {
    var targetWeight: Double
    var unit: WeightUnit

    enum WeightUnit: String { case lbs, kg }
}

// MARK: ─────────────────────────────────────────────────────────
// MARK: VIEW EXTENSION — auto-load on appear
// MARK: ─────────────────────────────────────────────────────────

/// Convenience modifier to load Supabase data when a view appears
struct LoadClientDataModifier: ViewModifier {
    let clientId: String
    let trainerId: String

    func body(content: Content) -> some View {
        content.onAppear {
            SBCheckInStore.shared.loadForClient(clientId)
            SBCheckInStore.shared.loadForTrainer(trainerId)
            SBWorkoutStore.shared.loadForClient(clientId)
            SBMealPlanStore.shared.loadForClient(clientId)
            SBWeightStore.shared.loadForClient(clientId)
        }
    }
}

extension View {
    func loadClientData(clientId: String, trainerId: String) -> some View {
        modifier(LoadClientDataModifier(clientId: clientId, trainerId: trainerId))
    }
}


// MARK: - Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
