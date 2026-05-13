//
//  LegacyModels.swift
//  TrainerMatch
//

import SwiftUI
import PhotosUI

// MARK: - Workout Exercise JSON

struct WorkoutExerciseJSON: Codable {
    var name:     String
    var sets:     Int?
    var reps:     Int?
    var duration: Int?
    var restTime: Int?
    var notes:    String?

    enum CodingKeys: String, CodingKey {
        case name, sets, reps, duration, notes
        case restTime = "rest_time"
    }
}

// MARK: - Weight unit enum

enum SBWeightUnit: String, CaseIterable {
    case lbs = "lbs"
    case kg  = "kg"
}

// MARK: - Computed properties on SBWeightEntryRow

extension SBWeightEntryRow {
    var weightInLbs: Double { unit == "lbs" ? weight : weight * 2.20462 }
    var weightInKg:  Double { unit == "kg"  ? weight : weight / 2.20462 }
    var loggedAtDate: Date  { loggedAt ?? Date.distantPast }
}

// MARK: - Computed properties on CheckInRow

extension CheckInRow {
    var frontURL:  URL? { photoUrls[safe: 0].flatMap { URL(string: $0) } }
    var rearURL:   URL? { photoUrls[safe: 1].flatMap { URL(string: $0) } }
    var rightURL:  URL? { photoUrls[safe: 2].flatMap { URL(string: $0) } }
    var leftURL:   URL? { photoUrls[safe: 3].flatMap { URL(string: $0) } }
    var isReviewed: Bool { !notes.isEmpty }
        var trainerFeedback: String? { notes.isEmpty ? nil : notes }
    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: checkedInAt ?? Date())
    }
    var formattedWeight: String {
        guard let w = weight else { return "No weight" }
        return String(format: "%.1f lbs", w)
    }
}

// MARK: - TMWorkout

struct TMWorkout: Identifiable, Codable {
    let id: String
    var trainerId:        String
    var clientId:         String
    var clientName:       String
    var name:             String
    var exercises:        [TMExercise]
    var difficulty:       WorkoutDifficulty
    var estimatedMinutes: Int
    var status:           WorkoutStatus
    var assignedDate:     Date
    var dueDate:          Date?
    var completedAt:      Date?
    var notes:            String

    enum WorkoutStatus: String, Codable, CaseIterable {
        case assigned   = "Assigned"
        case inProgress = "In Progress"
        case completed  = "Completed"
        case skipped    = "Skipped"
    }

    enum WorkoutDifficulty: String, Codable, CaseIterable {
        case beginner     = "Beginner"
        case intermediate = "Intermediate"
        case advanced     = "Advanced"
    }

    var difficultyColor: Color {
        switch difficulty {
        case .beginner:     return .green
        case .intermediate: return .tmGold
        case .advanced:     return .red
        }
    }
    var statusIcon: String {
        switch status {
        case .assigned:   return "dumbbell"
        case .inProgress: return "figure.run"
        case .completed:  return "checkmark.circle.fill"
        case .skipped:    return "xmark.circle"
        }
    }
}

struct TMExercise: Identifiable, Codable {
    let id: String
    var name: String; var sets: Int; var reps: String
    var weight: String; var notes: String; var restSeconds: Int
}

// MARK: - MealPlan

struct MealPlan: Identifiable, Codable {
    let id: String
    var trainerId:     String
    var clientId:      String
    var clientName:    String
    var title:         String
    var description:   String
    var meals:         [PlannedMeal]
    var dailyCalories: Int
    var proteinGrams:  Double
    var carbGrams:     Double
    var fatGrams:      Double
    var weekStartDate: Date
    var isActive:      Bool
    var createdAt:     Date
}

struct PlannedMeal: Identifiable, Codable {
    let id: String
    var mealType: MealType
    var name: String; var calories: Int
    var protein: Double; var carbs: Double; var fat: Double; var notes: String

    enum MealType: String, Codable, CaseIterable {
        case breakfast   = "Breakfast"
        case lunch       = "Lunch"
        case dinner      = "Dinner"
        case snack       = "Snack"
        case preworkout  = "Pre-Workout"
        case postworkout = "Post-Workout"
    }
}

// MARK: - ClientCheckIn

struct ClientCheckIn: Identifiable, Codable {
    let id: String
    var trainerId:       String
    var clientId:        String
    var clientName:      String
    var weight:          Double
    var weightUnit:      WeightUnit
    var frontPhotoPath:  String?
    var rearPhotoPath:   String?
    var rightPhotoPath:  String?
    var leftPhotoPath:   String?
    var notes:           String
    var trainerFeedback: String?
    var isReviewed:      Bool
    var submittedAt:     Date

    enum WeightUnit: String, Codable { case lbs, kg }

    var weightInLbs: Double { weightUnit == .lbs ? weight : weight * 2.20462 }
    var frontURL: URL? { frontPhotoPath.flatMap { URL(string: $0) } }
    var rearURL:  URL? { rearPhotoPath.flatMap  { URL(string: $0) } }
    var rightURL: URL? { rightPhotoPath.flatMap { URL(string: $0) } }
    var leftURL:  URL? { leftPhotoPath.flatMap  { URL(string: $0) } }
    var formattedDate: String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: submittedAt)
    }
    var formattedWeight: String {
        String(format: "%.1f %@", weight, weightUnit.rawValue)
    }
}

// MARK: - WeightEntry

struct WeightEntry: Identifiable, Codable {
    let id: String
    var clientId: String
    var weight:   Double
    var unit:     WeightUnit
    var note:     String
    var loggedAt: Date

    enum WeightUnit: String, Codable, CaseIterable {
        case lbs = "lbs"
        case kg  = "kg"
    }
    var weightInLbs: Double { unit == .lbs ? weight : weight * 2.20462 }
    var weightInKg:  Double { unit == .kg  ? weight : weight / 2.20462 }
}

struct WeightGoal: Identifiable, Codable {
    let id: String
    var clientId:     String
    var targetWeight: Double
    var unit:         WeightEntry.WeightUnit
    var startDate:    Date
    var targetDate:   Date?
    var isActive:     Bool
}

// MARK: - Stub stores

class WorkoutStore: ObservableObject {
    static let shared = WorkoutStore()
    @Published var workouts: [TMWorkout] = []
    private init() {}
    func workouts(forClient clientId: String)   -> [TMWorkout] { [] }
    func workouts(forTrainer trainerId: String) -> [TMWorkout] { [] }
    func pendingWorkouts(forClient clientId: String) -> [TMWorkout] { [] }
    func pendingCount(forTrainer trainerId: String) -> Int { 0 }
    func delete(_ workout: TMWorkout) {}
}

class MealPlanStore: ObservableObject {
    static let shared = MealPlanStore()
    @Published var mealPlans: [MealPlan] = []
    private init() {}
    func plans(forClient clientId: String)   -> [MealPlan] { [] }
    func plans(forTrainer trainerId: String) -> [MealPlan] { [] }
    func activePlan(forClient clientId: String) -> MealPlan? { nil }
    func delete(_ plan: MealPlan) {}
}

class CheckInStore: ObservableObject {
    static let shared = CheckInStore()
    @Published var checkIns: [ClientCheckIn] = []
    private init() {}
    func checkIns(forClient clientId: String)   -> [ClientCheckIn] { [] }
    func checkIns(forTrainer trainerId: String) -> [ClientCheckIn] { [] }
    func pendingCheckIns(forTrainer trainerId: String) -> [ClientCheckIn] { [] }
}

class WeightTrackingStore: ObservableObject {
    static let shared = WeightTrackingStore()
    @Published var entries: [WeightEntry] = []
    private init() {}
    func entries(forClient clientId: String) -> [WeightEntry] { [] }
    func latestWeight(forClient clientId: String) -> WeightEntry? { nil }
    func startingWeight(forClient clientId: String) -> WeightEntry? { nil }
    func activeGoal(forClient clientId: String) -> WeightGoal? { nil }
}

// MARK: - Card views

struct WorkoutCardRow: View {
    let workout: TMWorkout
    var showClient: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(workout.difficultyColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: workout.statusIcon)
                    .font(.system(size: 14))
                    .foregroundColor(workout.difficultyColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                if showClient {
                    Text(workout.clientName).font(.caption).foregroundColor(.tmGold)
                }
                HStack(spacing: 6) {
                    Text("\(workout.exercises.count) exercises")
                    Text("·")
                    Text("\(workout.estimatedMinutes) min")
                }.font(.caption).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text(workout.status.rawValue)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(workout.status == .completed ? .black : .white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Capsule().fill(
                    workout.status == .completed ? Color.green :
                    workout.status == .assigned  ? Color.tmGold : Color.orange))
        }.padding(.vertical, 4)
    }
}

struct MealPlanCardRow: View {
    let plan: MealPlan
    var showClient: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.tmGold.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "fork.knife")
                    .font(.system(size: 14)).foregroundColor(.tmGold)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(plan.title)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                if showClient {
                    Text(plan.clientName).font(.caption).foregroundColor(.tmGold)
                }
                Text("\(plan.dailyCalories) cal/day · \(plan.meals.count) meals")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            if plan.isActive {
                Text("ACTIVE").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(Color.tmGold))
            }
        }.padding(.vertical, 4)
    }
}

struct ClientCheckInCard: View {
    let checkIn: ClientCheckIn
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.purple.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: "camera.fill")
                    .font(.system(size: 14)).foregroundColor(.purple)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.formattedDate)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(checkIn.formattedWeight).font(.caption).foregroundColor(.tmGold)
                Text(checkIn.isReviewed ? "✓ Reviewed" : "⏳ Pending review")
                    .font(.caption2)
                    .foregroundColor(checkIn.isReviewed ? .green : .orange)
            }
            Spacer()
        }.padding(.vertical, 4)
    }
}

struct TrainerCheckInCard: View {
    let checkIn: ClientCheckIn
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(checkIn.formattedDate)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                Spacer()
                Text(checkIn.formattedWeight).font(.caption).foregroundColor(.tmGold)
                Text(checkIn.isReviewed ? "✓" : "⏳").font(.caption)
                    .foregroundColor(checkIn.isReviewed ? .green : .orange)
            }
            if !checkIn.notes.isEmpty {
                Text(checkIn.notes).font(.caption).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - ✅ TrainerCheckInsView — Supabase powered

struct TrainerCheckInsView: View {
    let trainerId: String
    @ObservedObject private var store = SBCheckInStore.shared
    @State private var selectedFilter: FilterMode = .pending

    enum FilterMode: String, CaseIterable {
        case pending  = "Pending"
        case reviewed = "Reviewed"
        case all      = "All"
    }

    private var allCheckIns: [CheckInRow] {
        store.checkIns.filter { $0.trainerId.uuidString == trainerId }
    }

    private var filteredCheckIns: [CheckInRow] {
            switch selectedFilter {
            case .pending:  return allCheckIns.filter { $0.notes.isEmpty }
            case .reviewed: return allCheckIns.filter { !$0.notes.isEmpty }
            case .all:      return allCheckIns
            }
        }
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(FilterMode.allCases, id: \.self) { mode in
                        Button(action: { selectedFilter = mode }) {
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedFilter == mode
                                                 ? .black : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(selectedFilter == mode
                                            ? Color.tmGold : Color.clear)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))

                if filteredCheckIns.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                        Text("No \(selectedFilter.rawValue.lowercased()) check-ins")
                            .font(.title3).foregroundColor(.white.opacity(0.4))
                        Text("Check-ins will appear here once clients submit them.")
                            .font(.subheadline).foregroundColor(.white.opacity(0.3))
                            .multilineTextAlignment(.center).padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredCheckIns) { ci in
                                SBTrainerCheckInCard(checkIn: ci)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Client Check-Ins")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { store.loadForTrainer(trainerId) }
    }
}

// MARK: - Trainer Check-In Card (Supabase)

struct SBTrainerCheckInCard: View {
    let checkIn: CheckInRow
    @ObservedObject private var store = SBCheckInStore.shared
    @State private var feedback        = ""
    @State private var showingFeedback = false
    @State private var isSaving        = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(checkIn.formattedDate)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(checkIn.formattedWeight)
                        .font(.caption).foregroundColor(.tmGold)
                }
                Spacer()
                Text(checkIn.isReviewed ? "✓ Reviewed" : "⏳ Pending")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(checkIn.isReviewed ? .black : .white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(
                        checkIn.isReviewed ? Color.green : Color.orange))
            }

            if !checkIn.photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(checkIn.photoUrls, id: \.self) { urlStr in
                            if let url = URL(string: urlStr) {
                                AsyncCheckInPhoto(url: url)
                            }
                        }
                    }
                }
            }

            if checkIn.energyLevel != nil ||
               checkIn.sleepHours  != nil ||
               checkIn.waterOz     != nil {
                HStack(spacing: 0) {
                    if let e = checkIn.energyLevel { statPill("⚡️ \(e)/10", "Energy") }
                    if let s = checkIn.sleepHours  { statPill("😴 \(String(format: "%.1f", s))h", "Sleep") }
                    if let w = checkIn.waterOz     { statPill("💧 \(w)oz", "Water") }
                }
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            }

            if !checkIn.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("CLIENT NOTE").font(.system(size: 9, weight: .bold))
                                    .tracking(1).foregroundColor(.white.opacity(0.4))
                                Text(checkIn.notes).font(.caption).foregroundColor(.white.opacity(0.7))
                            }
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                        }

            if !checkIn.isReviewed {
                Button(action: { showingFeedback = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.fill")
                        Text("Leave Feedback").font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.tmGold))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(checkIn.isReviewed
                        ? Color.green.opacity(0.2) : Color.tmGold.opacity(0.2), lineWidth: 1)))
        .sheet(isPresented: $showingFeedback) { feedbackSheet }
    }

    private var feedbackSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Leave feedback for this check-in.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    TextField("Great progress! Keep pushing...", text: $feedback, axis: .vertical)
                        .foregroundColor(.white).lineLimit(4...8).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    Button(action: saveFeedback) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "checkmark.circle.fill")
                                Text("MARK REVIEWED").font(.system(size: 14, weight: .heavy))
                            }
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26)
                            .fill(feedback.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
                    }
                    .disabled(feedback.isEmpty || isSaving)
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingFeedback = false }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func saveFeedback() {
            isSaving = true
            let notes     = feedback
            let checkInId = checkIn.id
            Task {
                let allRows = SBCheckInStore.shared.checkIns
                for row in allRows where row.id == checkInId {
                    var updated = row
                    updated.notes = notes
                    try? await SBCheckInStore.shared.update(updated)
                    break
                }
                await MainActor.run {
                    isSaving        = false
                    showingFeedback = false
                }
            }
        }
    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Async Photo Loader

struct AsyncCheckInPhoto: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Color.white.opacity(0.06).overlay(ProgressView().tint(.tmGold))
            }
        }
        .frame(width: 100, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task {
            if let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { image = UIImage(data: data) }
            }
        }
    }
}

// MARK: - ✅ TrainerClientWorkoutsView — Supabase powered

struct TrainerClientWorkoutsView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBWorkoutStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingBuilder  = false
    @State private var selectedFilter  = "all"

    private var allWorkouts: [WorkoutRow] {
        store.workouts.filter { $0.clientId.uuidString == clientId }
    }
    private var filteredWorkouts: [WorkoutRow] {
        switch selectedFilter {
        case "assigned":  return allWorkouts.filter { $0.status == "assigned" }
        case "completed": return allWorkouts.filter { $0.status == "completed" }
        default:          return allWorkouts
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    filterChip("All",       key: "all")
                    filterChip("Assigned",  key: "assigned")
                    filterChip("Completed", key: "completed")
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.white.opacity(0.03))

                if filteredWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 48)).foregroundColor(.white.opacity(0.15))
                            .padding(.top, 60)
                        Text("No workouts yet").font(.title3).foregroundColor(.white.opacity(0.4))
                        Button(action: { showingBuilder = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Assign Workout")
                            }
                            .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredWorkouts) { w in
                            SBWorkoutRow(workout: w, isTrainerView: true)
                                .listRowBackground(Color.white.opacity(0.03))
                                .listRowSeparatorTint(Color.white.opacity(0.06))
                        }
                        .onDelete { idx in
                            let items = idx.map { filteredWorkouts[$0] }
                            Task { for w in items { try? await store.delete(w.id) } }
                        }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("\(clientName)'s Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Assign")
                    }.fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                WorkoutBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func filterChip(_ label: String, key: String) -> some View {
        Button(action: { selectedFilter = key }) {
            Text(label).font(.system(size: 12, weight: .bold))
                .foregroundColor(selectedFilter == key ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(
                    selectedFilter == key ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

// MARK: - ✅ WorkoutBuilderView — Supabase powered

struct WorkoutBuilderView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = SBWorkoutStore.shared

    @State private var title         = ""
    @State private var description   = ""
    @State private var difficulty    = "intermediate"
    @State private var estimatedMins = 45
    @State private var dueDate       = Date().addingTimeInterval(7 * 86400)
    @State private var exercises: [WorkoutExerciseJSON] = []
    @State private var isSaving      = false
    @State private var showingAddExercise = false
    @State private var newExName     = ""
    @State private var newExSets     = "3"
    @State private var newExReps     = "10"
    @State private var newExRest     = "60"
    @State private var newExNotes    = ""

    let difficulties = ["beginner", "intermediate", "advanced"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    formBlock("WORKOUT TITLE") {
                        TextField("e.g. Upper Body Strength", text: $title)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    formBlock("DESCRIPTION (OPTIONAL)") {
                        TextField("What should the client focus on?",
                                  text: $description, axis: .vertical)
                            .foregroundColor(.white).lineLimit(2...4).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    HStack(spacing: 12) {
                        formBlock("DIFFICULTY") {
                            Menu {
                                ForEach(difficulties, id: \.self) { d in
                                    Button(d.capitalized) { difficulty = d }
                                }
                            } label: {
                                HStack {
                                    Text(difficulty.capitalized).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .font(.caption).foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06)))
                            }
                        }
                        formBlock("EST. MINUTES") {
                            HStack {
                                Button(action: { if estimatedMins > 5 { estimatedMins -= 5 } }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.tmGold).font(.title3)
                                }
                                Text("\(estimatedMins)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white).frame(minWidth: 40)
                                Button(action: { estimatedMins += 5 }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.tmGold).font(.title3)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06)))
                        }
                    }
                    formBlock("DUE DATE") {
                        DatePicker("", selection: $dueDate, in: Date()...,
                                   displayedComponents: .date)
                            .datePickerStyle(.compact).colorScheme(.dark)
                            .tint(.tmGold).labelsHidden().padding(8)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06)))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("EXERCISES").font(.system(size: 10, weight: .bold))
                                .tracking(1.2).foregroundColor(.tmGold)
                            Spacer()
                            Button(action: { showingAddExercise = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill").font(.caption)
                                    Text("Add").font(.caption).fontWeight(.semibold)
                                }.foregroundColor(.tmGold)
                            }
                        }
                        if exercises.isEmpty {
                            Text("No exercises yet — tap Add to build your workout.")
                                .font(.caption).foregroundColor(.white.opacity(0.35)).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.03)))
                        } else {
                            ForEach(Array(exercises.enumerated()), id: \.offset) { i, ex in
                                HStack(spacing: 12) {
                                    Text("\(i + 1)")
                                        .font(.system(size: 12, weight: .black)).foregroundColor(.black)
                                        .frame(width: 26, height: 26).background(Circle().fill(Color.tmGold))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(ex.name).font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(.white)
                                        HStack(spacing: 6) {
                                            if let s = ex.sets, let r = ex.reps {
                                                Text("\(s) sets × \(r) reps")
                                            }
                                            if let rest = ex.restTime { Text("· \(rest)s rest") }
                                        }
                                        .font(.caption).foregroundColor(.white.opacity(0.45))
                                    }
                                    Spacer()
                                    Button(action: { exercises.remove(at: i) }) {
                                        Image(systemName: "trash")
                                            .font(.caption).foregroundColor(.red.opacity(0.6))
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.04)))
                            }
                        }
                    }
                    Button(action: saveWorkout) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "paperplane.fill")
                                Text("ASSIGN TO \(clientName.uppercased())")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(title.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
                    }
                    .disabled(title.isEmpty || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Assign Workout").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .sheet(isPresented: $showingAddExercise) { addExerciseSheet }
    }

    private var addExerciseSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        formBlock("EXERCISE NAME") {
                            TextField("e.g. Bench Press", text: $newExName)
                                .foregroundColor(.white).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        HStack(spacing: 12) {
                            formBlock("SETS") {
                                TextField("3", text: $newExSets).keyboardType(.numberPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06)))
                            }
                            formBlock("REPS") {
                                TextField("10", text: $newExReps).keyboardType(.numberPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06)))
                            }
                            formBlock("REST (sec)") {
                                TextField("60", text: $newExRest).keyboardType(.numberPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.06)))
                            }
                        }
                        formBlock("NOTES (OPTIONAL)") {
                            TextField("Form tips, tempo, etc.", text: $newExNotes, axis: .vertical)
                                .foregroundColor(.white).lineLimit(2...3).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        Button(action: addExercise) {
                            Text("ADD EXERCISE").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                                .background(RoundedRectangle(cornerRadius: 27)
                                    .fill(newExName.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
                        }
                        .disabled(newExName.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Exercise").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingAddExercise = false }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func addExercise() {
        exercises.append(WorkoutExerciseJSON(
            name: newExName, sets: Int(newExSets), reps: Int(newExReps),
            duration: nil, restTime: Int(newExRest),
            notes: newExNotes.isEmpty ? nil : newExNotes
        ))
        newExName = ""; newExSets = "3"; newExReps = "10"; newExRest = "60"; newExNotes = ""
        showingAddExercise = false
    }

    private func saveWorkout() {
        guard let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isSaving = true
        let desc = description.isEmpty ? "" : description
        let now = Date(); let due = dueDate; let exs = exercises
        let diff = difficulty; let mins = estimatedMins; let ttl = title
        let exItems = exs.map { ex in
            ExerciseItem(id: UUID(), name: ex.name, sets: ex.sets ?? 3,
                         reps: ex.reps.map { "\($0)" } ?? "10",
                         weight: "", notes: ex.notes ?? "", restSeconds: ex.restTime ?? 60)
        }
        let row = WorkoutRow(id: UUID(), trainerId: tUUID, clientId: cUUID,
                             title: ttl, description: desc, exercises: exItems,
                             difficulty: diff, estimatedMins: mins, status: "assigned",
                             assignedDate: now, dueDate: due, completedAt: nil, createdAt: now)
        Task {
            do {
                try await SBWorkoutStore.shared.create(row)
                await MainActor.run { isSaving = false; dismiss() }
            } catch {
                print("❌ Workout save error: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }

    private func formBlock<Content: View>(
        _ label: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - ✅ ClientWorkoutsSection — Supabase powered

struct ClientWorkoutsSection: View {
    let clientId:   String
    let clientName: String
    let trainerId:  String
    @ObservedObject private var store = SBWorkoutStore.shared

    private var workouts: [WorkoutRow] {
        store.workouts.filter { $0.clientId.uuidString == clientId }
    }
    private var pending: [WorkoutRow] { workouts.filter { $0.status == "assigned" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts").font(.title2).fontWeight(.bold).foregroundColor(.white)
            if workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell").font(.system(size: 40))
                        .foregroundColor(.tmGold.opacity(0.2))
                    Text("No workouts assigned yet")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Your trainer will assign workouts here.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
            } else {
                HStack(spacing: 0) {
                    wkStat("\(workouts.count)", "Total")
                    Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                    wkStat("\(pending.count)", "Pending")
                    Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                    wkStat("\(workouts.filter { $0.status == "completed" }.count)", "Done")
                }
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                ForEach(workouts.prefix(5)) { w in SBWorkoutRow(workout: w, isTrainerView: false) }
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }

    private func wkStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Shared Workout Row

struct SBWorkoutRow: View {
    let workout:       WorkoutRow
    let isTrainerView: Bool
    @ObservedObject private var store = SBWorkoutStore.shared
    @State private var isCompleting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(difficultyColor.opacity(0.15)).frame(width: 38, height: 38)
                    Image(systemName: statusIcon).font(.system(size: 14)).foregroundColor(difficultyColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    HStack(spacing: 6) {
                        Text("\(workout.estimatedMins) min"); Text("·")
                        Text(workout.difficulty.capitalized); Text("·")
                        Text("\(workout.exercises.count) exercises")
                    }
                    .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text(workout.status.capitalized).font(.system(size: 9, weight: .bold))
                    .foregroundColor(workout.status == "completed" ? .black : .white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(
                        workout.status == "completed" ? Color.green :
                        workout.status == "assigned"  ? Color.tmGold : Color.orange))
            }
            .padding(12)
            if !isTrainerView && workout.status == "assigned" {
                Button(action: markComplete) {
                    HStack(spacing: 6) {
                        if isCompleting { ProgressView().tint(.black).scaleEffect(0.8) }
                        else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark Complete").font(.system(size: 13, weight: .bold))
                        }
                    }
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.tmGold))
                }
                .padding(.horizontal, 12).padding(.bottom, 12).disabled(isCompleting)
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }

    private var difficultyColor: Color {
        switch workout.difficulty {
        case "beginner": return .green
        case "advanced": return .red
        default:         return .tmGold
        }
    }
    private var statusIcon: String {
        switch workout.status {
        case "completed": return "checkmark.circle.fill"
        case "skipped":   return "xmark.circle"
        default:          return "dumbbell"
        }
    }
    private func markComplete() {
        isCompleting = true
        Task {
            try? await store.markComplete(workout.id)
            await MainActor.run { isCompleting = false }
        }
    }
}

// MARK: - ✅ TrainerClientMealPlansView — Supabase powered

struct TrainerClientMealPlansView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBMealPlanStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingBuilder = false

    private var plans: [MealPlanRow] {
        store.mealPlans.filter { $0.clientId.uuidString == clientId }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if plans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 48)).foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No meal plans yet").font(.title3).foregroundColor(.white.opacity(0.4))
                    Button(action: { showingBuilder = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Meal Plan")
                        }
                        .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(plans) { p in
                        SBMealPlanRow(plan: p)
                            .listRowBackground(Color.white.opacity(0.03))
                            .listRowSeparatorTint(Color.white.opacity(0.06))
                    }
                    .onDelete { idx in
                        let items = idx.map { plans[$0] }
                        Task { for p in items { try? await store.delete(p.id) } }
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("\(clientName)'s Nutrition").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Create")
                    }.fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                MealPlanBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Meal Plan Row

struct SBMealPlanRow: View {
    let plan: MealPlanRow
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(plan.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    Text("\(plan.dailyCalories) cal/day · \(plan.meals.count) meals")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                if plan.isActive {
                    Text("ACTIVE").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.tmGold))
                }
            }
            HStack(spacing: 0) {
                macroCell(String(format: "%.0fg", plan.proteinG ?? 0), "protein", .red)
                macroCell(String(format: "%.0fg", plan.carbsG   ?? 0), "carbs",   .blue)
                macroCell(String(format: "%.0fg", plan.fatG     ?? 0), "fat",     .yellow)
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
        }
        .padding(.vertical, 6)
    }
    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ✅ MealPlanBuilderView — Supabase powered

struct MealPlanBuilderView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @Environment(\.dismiss) var dismiss

    @State private var title          = ""
    @State private var description    = ""
    @State private var dailyCalories  = 2000
    @State private var proteinG       = 150.0
    @State private var carbsG         = 200.0
    @State private var fatG           = 65.0
    @State private var meals: [MealItem] = []
    @State private var isSaving       = false
    @State private var showingAddMeal = false
    @State private var newMealType    = "Breakfast"
    @State private var newMealName    = ""
    @State private var newMealCals    = ""
    @State private var newMealProtein = ""
    @State private var newMealCarbs   = ""
    @State private var newMealFat     = ""
    @State private var newMealNotes   = ""

    let mealTypes = ["Breakfast","Lunch","Dinner","Snack","Pre-Workout","Post-Workout"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    formBlock("PLAN TITLE") {
                        TextField("e.g. Lean Bulk Phase 1", text: $title)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    formBlock("DESCRIPTION (OPTIONAL)") {
                        TextField("Goals, notes, instructions...", text: $description, axis: .vertical)
                            .foregroundColor(.white).lineLimit(2...4).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("DAILY TARGETS").font(.system(size: 10, weight: .bold))
                            .tracking(1.2).foregroundColor(.tmGold)
                        macroStepper("Calories", value: $dailyCalories, step: 50, color: .tmGold)
                        HStack(spacing: 12) {
                            macroDoubleStepper("Protein (g)", value: $proteinG, step: 5, color: .red)
                            macroDoubleStepper("Carbs (g)",   value: $carbsG,   step: 5, color: .blue)
                            macroDoubleStepper("Fat (g)",     value: $fatG,     step: 5, color: .yellow)
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("MEALS").font(.system(size: 10, weight: .bold))
                                .tracking(1.2).foregroundColor(.tmGold)
                            Spacer()
                            Button(action: { showingAddMeal = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill").font(.caption)
                                    Text("Add Meal").font(.caption).fontWeight(.semibold)
                                }.foregroundColor(.tmGold)
                            }
                        }
                        if meals.isEmpty {
                            Text("No meals yet — tap Add Meal to build the plan.")
                                .font(.caption).foregroundColor(.white.opacity(0.35)).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.03)))
                        } else {
                            ForEach(Array(meals.enumerated()), id: \.offset) { i, meal in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: 6) {
                                            Text(meal.mealType)
                                                .font(.system(size: 10, weight: .bold)).foregroundColor(.tmGold)
                                            Text(meal.name)
                                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                        }
                                        Text("\(meal.calories) cal · P:\(Int(meal.protein))g C:\(Int(meal.carbs))g F:\(Int(meal.fat))g")
                                            .font(.caption).foregroundColor(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Button(action: { meals.remove(at: i) }) {
                                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
                                    }
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                            }
                        }
                    }
                    Button(action: savePlan) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "paperplane.fill")
                                Text("ASSIGN TO \(clientName.uppercased())")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(title.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
                    }
                    .disabled(title.isEmpty || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Create Meal Plan").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .sheet(isPresented: $showingAddMeal) { addMealSheet }
    }

    private var addMealSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        formBlock("MEAL TYPE") {
                            Menu {
                                ForEach(mealTypes, id: \.self) { t in Button(t) { newMealType = t } }
                            } label: {
                                HStack {
                                    Text(newMealType).foregroundColor(.white); Spacer()
                                    Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }
                        formBlock("MEAL NAME") {
                            TextField("e.g. Oatmeal with berries", text: $newMealName)
                                .foregroundColor(.white).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        HStack(spacing: 12) {
                            formBlock("CALORIES") {
                                TextField("400", text: $newMealCals).keyboardType(.numberPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                            formBlock("PROTEIN (g)") {
                                TextField("30", text: $newMealProtein).keyboardType(.decimalPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }
                        HStack(spacing: 12) {
                            formBlock("CARBS (g)") {
                                TextField("50", text: $newMealCarbs).keyboardType(.decimalPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                            formBlock("FAT (g)") {
                                TextField("10", text: $newMealFat).keyboardType(.decimalPad)
                                    .foregroundColor(.white).padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }
                        formBlock("NOTES (OPTIONAL)") {
                            TextField("Preparation tips, timing...", text: $newMealNotes, axis: .vertical)
                                .foregroundColor(.white).lineLimit(2...3).padding(14)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        Button(action: addMeal) {
                            Text("ADD MEAL").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                                .background(RoundedRectangle(cornerRadius: 27)
                                    .fill(newMealName.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold))
                        }
                        .disabled(newMealName.isEmpty)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Meal").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingAddMeal = false }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func addMeal() {
        meals.append(MealItem(
            id:       UUID(),
            mealType: newMealType,
            name:     newMealName,
            calories: Int(newMealCals) ?? 0,
            protein:  Double(newMealProtein) ?? 0,
            carbs:    Double(newMealCarbs) ?? 0,
            fat:      Double(newMealFat) ?? 0,
            notes:    newMealNotes
        ))
        newMealName = ""; newMealCals = ""; newMealProtein = ""
        newMealCarbs = ""; newMealFat = ""; newMealNotes = ""
        showingAddMeal = false
    }

    private func savePlan() {
        guard let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isSaving = true
        let now = Date()
        let plan = MealPlanRow(
            id:            UUID(),
            trainerId:     tUUID,
            clientId:      cUUID,
            title:         title,
            description:   description.isEmpty ? "" : description,
            meals:         meals,
            dailyCalories: dailyCalories,
            proteinG:      proteinG,
            carbsG:        carbsG,
            fatG:          fatG,
            weekStart:     now,
            isActive:      true,
            createdAt:     now
        )
        Task {
            do {
                try await SBMealPlanStore.shared.create(plan)
                await MainActor.run { isSaving = false; dismiss() }
            } catch {
                print("❌ Meal plan save error: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }

    private func macroStepper(
        _ label: String, value: Binding<Int>, step: Int, color: Color
    ) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.6))
            Spacer()
            Button(action: { if value.wrappedValue > step { value.wrappedValue -= step } }) {
                Image(systemName: "minus.circle.fill").foregroundColor(color).font(.title3)
            }
            Text("\(value.wrappedValue)").font(.system(size: 18, weight: .black))
                .foregroundColor(color).frame(minWidth: 55)
            Button(action: { value.wrappedValue += step }) {
                Image(systemName: "plus.circle.fill").foregroundColor(color).font(.title3)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
    }

    private func macroDoubleStepper(
        _ label: String, value: Binding<Double>, step: Double, color: Color
    ) -> some View {
        VStack(spacing: 6) {
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            HStack(spacing: 4) {
                Button(action: { if value.wrappedValue > step { value.wrappedValue -= step } }) {
                    Image(systemName: "minus.circle.fill").foregroundColor(color).font(.caption)
                }
                Text("\(Int(value.wrappedValue))").font(.system(size: 15, weight: .black))
                    .foregroundColor(.white).frame(minWidth: 30)
                Button(action: { value.wrappedValue += step }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(color).font(.caption)
                }
            }
        }
        .frame(maxWidth: .infinity).padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
    }

    private func formBlock<Content: View>(
        _ label: String, @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - Stub views

struct LogWeightView: View {
    let clientId: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Log Weight").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Button("Close") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }
}

struct SetWeightGoalView: View {
    let clientId: String
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Set Weight Goal").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Button("Close") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }
}

struct WeightHistoryView: View {
    let clientId: String
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            Text("Weight History").foregroundColor(.white)
        }
        .navigationTitle("Weight History").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct CheckInCameraView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            VStack(spacing: 16) {
                Text("Check-In Camera").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Button("Close") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }
}

struct ClientAllMealPlansView: View {
    let clientId: String
    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            Text("My Meal Plans").foregroundColor(.white)
        }
        .navigationTitle("Meal Plans").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ClientMealRow: View {
    let meal: PlannedMeal
    var body: some View {
        HStack {
            Text(meal.name).foregroundColor(.white)
            Spacer()
            Text("\(meal.calories) cal").font(.caption).foregroundColor(.tmGold)
        }
        .padding(.vertical, 4)
    }
}
