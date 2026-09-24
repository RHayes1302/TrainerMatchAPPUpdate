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
// NOTE: trainerFeedback is a stored property on CheckInRow in SupabaseDataStores.swift
// decoded from the trainer_feedback column. Do NOT redeclare it here.

extension CheckInRow {
    var frontURL:  URL? { photoUrls[safe: 0].flatMap { URL(string: $0) } }
    var rearURL:   URL? { photoUrls[safe: 1].flatMap { URL(string: $0) } }
    var rightURL:  URL? { photoUrls[safe: 2].flatMap { URL(string: $0) } }
    var leftURL:   URL? { photoUrls[safe: 3].flatMap { URL(string: $0) } }
    var isReviewed: Bool { !(trainerFeedback ?? "").isEmpty }

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

// MARK: - ClientCheckIn (legacy local model)

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

// MARK: - TrainerCheckInsView

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
        case .pending:  return allCheckIns.filter { ($0.trainerFeedback ?? "").isEmpty }
        case .reviewed: return allCheckIns.filter { !($0.trainerFeedback ?? "").isEmpty }
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
                                .foregroundColor(selectedFilter == mode ? .black : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(selectedFilter == mode ? Color.tmGold : Color.clear)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))
                if filteredCheckIns.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "camera.viewfinder").font(.system(size: 48))
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
                            ForEach(filteredCheckIns) { ci in SBTrainerCheckInCard(checkIn: ci) }
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

// MARK: - SBTrainerCheckInCard

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
                    Text(checkIn.formattedDate).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(checkIn.formattedWeight).font(.caption).foregroundColor(.tmGold)
                }
                Spacer()
                Text(checkIn.isReviewed ? "✓ Reviewed" : "⏳ Pending")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(checkIn.isReviewed ? .black : .white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(checkIn.isReviewed ? Color.green : Color.orange))
            }
            if !checkIn.photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(checkIn.photoUrls, id: \.self) { urlStr in
                            if let url = URL(string: urlStr) { AsyncCheckInPhoto(url: url) }
                        }
                    }
                }
            }
            if checkIn.energyLevel != nil || checkIn.sleepHours != nil || checkIn.waterOz != nil {
                HStack(spacing: 0) {
                    if let e = checkIn.energyLevel { statPill("⚡️ \(e)/5", "Energy") }
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
                .stroke(checkIn.isReviewed ? Color.green.opacity(0.2) : Color.tmGold.opacity(0.2), lineWidth: 1)))
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
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
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
        let fb = feedback
        let checkInId = checkIn.id
        Task {
            do {
                struct Update: Encodable {
                    let trainerFeedback: String
                    enum CodingKeys: String, CodingKey { case trainerFeedback = "trainer_feedback" }
                }
                try await supabase.from("check_ins")
                    .update(Update(trainerFeedback: fb))
                    .eq("id", value: checkInId).execute()
                store.loadForTrainer(
                    store.checkIns.first(where: { $0.id == checkInId })?.trainerId.uuidString ?? ""
                )
            } catch { print("❌ Feedback save failed: \(error)") }
            await MainActor.run { isSaving = false; showingFeedback = false }
        }
    }

    private func statPill(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - AsyncCheckInPhoto

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

// MARK: - TrainerClientWorkoutsView

struct TrainerClientWorkoutsView: View {
    let trainerId: String; let clientId: String; let clientName: String
    @ObservedObject private var store = SBWorkoutStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingBuilder = false
    @State private var selectedFilter = "all"

    private var allWorkouts: [WorkoutRow] { store.workouts.filter { $0.clientId.uuidString == clientId } }
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
                    filterChip("All", key: "all")
                    filterChip("Assigned", key: "assigned")
                    filterChip("Completed", key: "completed")
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.white.opacity(0.03))
                if filteredWorkouts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell").font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                        Text("No workouts yet").font(.title3).foregroundColor(.white.opacity(0.4))
                        Button(action: { showingBuilder = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill"); Text("Assign Workout")
                            }
                            .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    }.listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("\(clientName)'s Workouts").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("Assign") }
                        .fontWeight(.semibold).foregroundColor(.tmGold)
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
                .background(Capsule().fill(selectedFilter == key ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

// MARK: - ClientWorkoutsSection

struct ClientWorkoutsSection: View {
    let clientId: String; let clientName: String; let trainerId: String
    @Binding var selectedWorkout: WorkoutRow?
    @ObservedObject private var store = SBWorkoutStore.shared
    @State private var isLoading = false
    @State private var expandedProgram: String? = nil

    private var workouts: [WorkoutRow] {
        store.workouts.filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() }
    }

    // Group workouts by program (same createdAt minute = same program)
    private var programs: [(String, [WorkoutRow])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: workouts) { w -> String in
            guard let date = w.createdAt else { return "unknown" }
            let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)-\(comps.hour ?? 0)-\(comps.minute ?? 0)"
        }
        return grouped
            .map { key, days in (key, days.sorted { ($0.dayNumber ?? 0) < ($1.dayNumber ?? 0) }) }
            .sorted { $0.1.first?.createdAt ?? .distantPast > $1.1.first?.createdAt ?? .distantPast }
    }

    private var pending:   [WorkoutRow] { workouts.filter { $0.status == "assigned" } }
    private var completed: [WorkoutRow] { workouts.filter { $0.status == "completed" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts").font(.title2).fontWeight(.bold).foregroundColor(.white)
            HStack(spacing: 0) {
                wkStat("\(workouts.count)", "Total")
                Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                wkStat("\(pending.count)", "Pending")
                Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                wkStat("\(completed.count)", "Done")
            }
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))

            if isLoading {
                HStack { Spacer(); ProgressView().tint(.tmGold); Spacer() }.padding(.vertical, 20)
            } else if workouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "dumbbell").font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.2))
                    Text("No workouts assigned yet").font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Your trainer will assign workouts here.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
            } else {
                VStack(spacing: 12) {
                    ForEach(programs, id: \.0) { key, days in
                        WeeklyProgramCard(
                            days: days,
                            isExpanded: expandedProgram == key,
                            onTap: { expandedProgram = expandedProgram == key ? nil : key },
                            onSelectWorkout: { workout in
                                if workout.isRestDay != true { selectedWorkout = workout }
                            }
                        )
                    }
                }
            }
        }
        .onAppear {
            guard let uuid = UUID(uuidString: clientId) else { return }
            isLoading = true
            Task {
                try? await store.fetchForClient(uuid)
                await MainActor.run { isLoading = false }
            }
        }

    }

    private func wkStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }
    private func sectionLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(color)
            Text(title).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(color)
        }
    }
}

// MARK: - WorkoutDetailSheet

struct WorkoutDetailSheet: View {
    let workout: WorkoutRow
    let onMarkComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    @State private var isCompleting  = false
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.title2).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    Text(workout.title).font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Spacer()
                    Button(action: { shareWorkout() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.tmGold)
                    }
                }
                .padding(20)

                HStack(spacing: 20) {
                    metaItem(icon: "dumbbell.fill", value: "\(workout.exercises.count) exercises")
                    metaItem(icon: "clock.fill",    value: "\(workout.estimatedMins) min")
                    metaItem(icon: "chart.bar.fill", value: workout.difficulty.capitalized)
                    if let mg = workout.muscleGroup, !mg.isEmpty {
                        metaItem(icon: "figure.strengthtraining.traditional", value: mg)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 16)

                if !workout.description.isEmpty {
                    Text(workout.description).font(.subheadline).foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20).padding(.bottom, 12)
                }

                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(workout.exercises.enumerated()), id: \.offset) { i, ex in
                            ExerciseDetailRow(index: i + 1, exercise: ex)
                        }
                    }
                    .padding(20)
                }


            }
        }
    }

    private func metaItem(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            Text(value).font(.caption).foregroundColor(.white.opacity(0.7))
        }
    }

    private func shareWorkout() {
        let pdf = generateWorkoutPDF()
        let av = UIActivityViewController(activityItems: [pdf], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            var presented = root
            while let next = presented.presentedViewController { presented = next }
            presented.present(av, animated: true)
        }
    }

    private func generateWorkoutPDF() -> URL {
        let pageW: CGFloat = 612; let pageH: CGFloat = 792
        let margin: CGFloat = 48; var y: CGFloat = margin
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let titleAttr:   [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24, weight: .black), .foregroundColor: UIColor(red: 0.82, green: 0.69, blue: 0.27, alpha: 1)]
            let sectionAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: UIColor.darkGray]
            let bodyAttr:    [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.black]
            let boldAttr:    [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: UIColor.black]
            let tipsAttr:    [NSAttributedString.Key: Any] = [.font: UIFont.italicSystemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
            workout.title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr); y += 36
            var meta = "\(workout.difficulty.capitalized)  ·  \(workout.estimatedMins) min  ·  \(workout.exercises.count) exercises"
            if let mg = workout.muscleGroup, !mg.isEmpty { meta += "  ·  \(mg)" }
            meta.draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttr); y += 24
            UIColor.lightGray.setStroke()
            let line = UIBezierPath(); line.move(to: CGPoint(x: margin, y: y)); line.addLine(to: CGPoint(x: pageW - margin, y: y)); line.lineWidth = 0.5; line.stroke(); y += 16
            for (i, ex) in workout.exercises.enumerated() {
                if y > pageH - 100 { ctx.beginPage(); y = margin }
                "\(i + 1).  \(ex.name)".draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttr); y += 20
                var detail = "\(ex.sets) sets  ×  \(ex.reps) reps"
                if !ex.weight.isEmpty { detail += "  @  \(ex.weight)" }
                if ex.restSeconds > 0 { detail += "  ·  \(ex.restSeconds)s rest" }
                detail.draw(at: CGPoint(x: margin + 20, y: y), withAttributes: bodyAttr); y += 18
                if !ex.notes.isEmpty {
                    if y > pageH - 60 { ctx.beginPage(); y = margin }
                    let tipsNS = "Tip: \(ex.notes)" as NSString
                    let maxW = pageW - margin * 2 - 20
                    tipsNS.draw(in: CGRect(x: margin + 20, y: y, width: maxW, height: 200), withAttributes: tipsAttr)
                    y += tipsNS.boundingRect(with: CGSize(width: maxW, height: 200), options: .usesLineFragmentOrigin, attributes: tipsAttr, context: nil).height + 4
                }
                y += 14
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(workout.title.replacingOccurrences(of: " ", with: "_"))_Workout.pdf")
        try? data.write(to: url); return url
    }
}

// MARK: - ExerciseDetailRow

struct ExerciseDetailRow: View {
    let index: Int; let exercise: ExerciseItem

    var body: some View {
        HStack(spacing: 14) {
            Text("\(index)").font(.system(size: 13, weight: .black)).foregroundColor(.black)
                .frame(width: 28, height: 28).background(Circle().fill(Color.tmGold))
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 8) {
                    statChip("\(exercise.sets) sets", .tmGold)
                    statChip("\(exercise.reps) reps", .blue)
                    if !exercise.weight.isEmpty && exercise.weight != "0" { statChip(exercise.weight, .orange) }
                    if exercise.restSeconds > 0 { statChip("\(exercise.restSeconds)s rest", .purple) }
                }
                if !exercise.notes.isEmpty {
                    Text(exercise.notes).font(.caption2).foregroundColor(.white.opacity(0.4)).lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1)))
    }

    private func statChip(_ label: String, _ color: Color) -> some View {
        Text(label).font(.system(size: 10, weight: .bold)).foregroundColor(color)
            .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(color.opacity(0.12)))
    }
}


// MARK: - Day Workout Card

struct DayWorkoutCard: View {
    let workout: WorkoutRow
    let onTap:   () -> Void
    @State private var expanded = false

    var isRest: Bool { workout.isRestDay ?? false }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: {
                if isRest { return }
                withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() }
            }) {
                HStack(spacing: 14) {
                    // Day badge
                    VStack(spacing: 2) {
                        Text("DAY").font(.system(size: 8, weight: .bold)).foregroundColor(.black.opacity(0.6))
                        Text("\(workout.dayNumber ?? 0)").font(.system(size: 16, weight: .black)).foregroundColor(.black)
                    }
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(isRest ? Color.blue.opacity(0.7) : Color.tmGold))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if isRest {
                                Image(systemName: "moon.zzz.fill").font(.caption).foregroundColor(.blue.opacity(0.8))
                            }
                            Text(workout.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        }
                        if isRest {
                            Text("Rest & Recovery").font(.caption).foregroundColor(.blue.opacity(0.7))
                        } else {
                            HStack(spacing: 6) {
                                if let mg = workout.muscleGroup, !mg.isEmpty {
                                    Text(mg).foregroundColor(.tmGold)
                                    Text("·").foregroundColor(.white.opacity(0.3))
                                }
                                Text("\(workout.exercises.count) exercises")
                                Text("·").foregroundColor(.white.opacity(0.3))
                                Text("\(workout.estimatedMins) min")
                            }.font(.caption).foregroundColor(.white.opacity(0.45))
                        }
                    }

                    Spacer()

                    if !isRest {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 14).padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded exercise list
            if expanded && !isRest {
                Divider().background(Color.white.opacity(0.06))
                VStack(spacing: 0) {
                    ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { i, ex in
                        HStack(spacing: 12) {
                            Text("\(i + 1)").font(.system(size: 11, weight: .black)).foregroundColor(.tmGold)
                                .frame(width: 20, alignment: .center)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.name).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Text("\(ex.sets) sets · \(ex.reps) reps").font(.caption).foregroundColor(.white.opacity(0.45))
                                    if !ex.weight.isEmpty { Text("· \(ex.weight)").font(.caption).foregroundColor(.tmGold) }
                                }
                            }
                            Spacer()
                            if ex.restSeconds > 0 {
                                Text("\(ex.restSeconds)s").font(.caption2).foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        if i < workout.exercises.count - 1 {
                            Divider().background(Color.white.opacity(0.04)).padding(.leading, 46)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))

                // Tap to open full detail
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right.circle").font(.caption)
                        Text("View Full Workout Detail").font(.caption).fontWeight(.semibold)
                    }
                    .foregroundColor(.tmGold).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(Color.tmGold.opacity(0.06))
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14)
            .fill(isRest ? Color.blue.opacity(0.05) : Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isRest ? Color.blue.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}


// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}


// MARK: - Weekly Program Card

struct WeeklyProgramCard: View {
    let days:            [WorkoutRow]
    let isExpanded:      Bool
    let onTap:           () -> Void
    let onSelectWorkout: (WorkoutRow) -> Void

    private var programTitle: String {
        if let mg = days.first(where: { !($0.isRestDay ?? false) })?.muscleGroup {
            return "\(days.count)-Day Program"
        }
        return "\(days.count)-Day Program"
    }

    private var workoutDays: Int { days.filter { !($0.isRestDay ?? false) }.count }
    private var restDays:    Int { days.filter { $0.isRestDay ?? false }.count }

    private var dateLabel: String {
        guard let date = days.first?.createdAt else { return "" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header — tap to expand/collapse
            Button(action: onTap) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.tmGold.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "dumbbell.fill").font(.system(size: 18)).foregroundColor(.tmGold)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(programTitle).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                        HStack(spacing: 8) {
                            Text("\(workoutDays) workouts").font(.caption).foregroundColor(.tmGold)
                            if restDays > 0 {
                                Text("·").foregroundColor(.white.opacity(0.3))
                                Text("\(restDays) rest days").font(.caption).foregroundColor(.blue.opacity(0.8))
                            }
                            Text("·").foregroundColor(.white.opacity(0.3))
                            Text(dateLabel).font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.white.opacity(0.4))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded day list
            if isExpanded {
                Divider().background(Color.white.opacity(0.06))
                VStack(spacing: 0) {
                    ForEach(Array(days.enumerated()), id: \.element.id) { i, workout in
                        Button(action: { onSelectWorkout(workout) }) {
                            HStack(spacing: 12) {
                                // Day badge
                                Text("\(workout.dayNumber ?? i+1)")
                                    .font(.system(size: 11, weight: .black)).foregroundColor(.black)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(workout.isRestDay ?? false ? Color.blue : Color.tmGold))

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(workout.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                    if !(workout.isRestDay ?? false) {
                                        HStack(spacing: 6) {
                                            if let mg = workout.muscleGroup, !mg.isEmpty {
                                                Text(mg).font(.caption).foregroundColor(.tmGold)
                                                Text("·").foregroundColor(.white.opacity(0.3))
                                            }
                                            Text("\(workout.exercises.count) exercises").font(.caption).foregroundColor(.white.opacity(0.4))
                                            Text("·").foregroundColor(.white.opacity(0.3))
                                            Text("\(workout.estimatedMins) min").font(.caption).foregroundColor(.white.opacity(0.4))
                                        }
                                    } else {
                                        Text("Rest & Recovery").font(.caption).foregroundColor(.blue.opacity(0.7))
                                    }
                                }
                                Spacer()
                                if !(workout.isRestDay ?? false) {
                                    Image(systemName: "chevron.right").font(.caption2).foregroundColor(.white.opacity(0.3))
                                }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .disabled(workout.isRestDay ?? false)

                        if i < days.count - 1 {
                            Divider().background(Color.white.opacity(0.04)).padding(.leading, 52)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - SBWorkoutRow

struct SBWorkoutRow: View {
    let workout: WorkoutRow; let isTrainerView: Bool
    @ObservedObject private var store = SBWorkoutStore.shared
    @State private var isCompleting = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(difficultyColor.opacity(0.15)).frame(width: 38, height: 38)
                    Image(systemName: statusIcon).font(.system(size: 14)).foregroundColor(difficultyColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(workout.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                    HStack(spacing: 6) {
                        if let mg = workout.muscleGroup, !mg.isEmpty {
                            Text(mg).font(.caption).fontWeight(.bold).foregroundColor(.tmGold)
                            Text("·").foregroundColor(.white.opacity(0.3))
                        }
                        Text("\(workout.estimatedMins) min"); Text("·")
                        Text(workout.difficulty.capitalized); Text("·")
                        Text("\(workout.exercises.count) exercises")
                    }.font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text(workout.status.capitalized).font(.system(size: 9, weight: .bold))
                    .foregroundColor(workout.status == "completed" ? .black : .white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(
                        workout.status == "completed" ? Color.green :
                        workout.status == "assigned"  ? Color.tmGold : Color.orange))
            }.padding(12)


        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }

    private var difficultyColor: Color {
        workout.difficulty == "beginner" ? .green : workout.difficulty == "advanced" ? .red : .tmGold
    }
    private var statusIcon: String {
        workout.status == "completed" ? "checkmark.circle.fill" : workout.status == "skipped" ? "xmark.circle" : "dumbbell"
    }
    private func markComplete() {
        isCompleting = true
        Task { try? await store.markComplete(workout.id); await MainActor.run { isCompleting = false } }
    }
}




// MARK: - Meal Sort Helper

func sortedMeals(_ meals: [MealItem]) -> [MealItem] {
    let order = ["breakfast": 0, "pre-workout": 1, "lunch": 2, "snack": 3,
                 "post-workout": 4, "dinner": 5]
    return meals.sorted {
        (order[$0.mealType.lowercased()] ?? 6) < (order[$1.mealType.lowercased()] ?? 6)
    }
}

// MARK: - SBMealPlanClientCard

struct SBMealPlanClientCard: View {
    let plan: MealPlanRow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color.tmGold.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: "fork.knife").font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text("\(plan.meals.count) meals · \(plan.dailyCalories) kcal/day")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                }
                Spacer()
                if plan.isActive {
                    Text("ACTIVE").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(Color.green))
                }
            }
            .padding(14)
            Divider().background(Color.white.opacity(0.06))
            HStack(spacing: 0) {
                macroCell("\(plan.dailyCalories)", "kcal", .tmGold)
                Divider().background(Color.white.opacity(0.08)).frame(height: 28)
                macroCell(String(format: "%.0fg", plan.proteinG), "protein", .red)
                Divider().background(Color.white.opacity(0.08)).frame(height: 28)
                macroCell(String(format: "%.0fg", plan.carbsG), "carbs", .blue)
                Divider().background(Color.white.opacity(0.08)).frame(height: 28)
                macroCell(String(format: "%.0fg", plan.fatG), "fats", .orange)
            }
            .padding(.vertical, 8)
            if !plan.meals.isEmpty {
                Divider().background(Color.white.opacity(0.06))
                VStack(spacing: 0) {
                    let preview: [MealItem] = Array(sortedMeals(plan.meals).prefix(3))
                    ForEach(Array(preview.enumerated()), id: \.element.id) { i, meal in
                        HStack(spacing: 10) {
                            Text(meal.mealType).font(.caption).fontWeight(.semibold)
                                .foregroundColor(.tmGold).frame(width: 70, alignment: .leading)
                            Text(meal.name).font(.caption).foregroundColor(.white.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("\(meal.calories) cal").font(.caption).foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        if i < preview.count - 1 {
                            Divider().background(Color.white.opacity(0.04)).padding(.leading, 14)
                        }
                    }
                    if plan.meals.count > 3 {
                        Text("Tap to see all \(plan.meals.count) meals")
                            .font(.caption).foregroundColor(.tmGold.opacity(0.7))
                            .padding(.horizontal, 14).padding(.bottom, 8)
                    }
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(plan.isActive ? Color.green.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1)))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 13, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - MealPlanDetailSheet

struct MealPlanDetailSheet: View {
    let plan: MealPlanRow
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").fontWeight(.semibold)
                            Text("Back")
                        }.foregroundColor(.tmGold)
                    }
                    Spacer()
                    if plan.isActive {
                        Text("ACTIVE").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(Color.green))
                    }
                    Button(action: { shareMealPlan() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold)).foregroundColor(.tmGold)
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 16)

                // Plan title
                VStack(spacing: 4) {
                    Text(plan.title).font(.title2).fontWeight(.bold).foregroundColor(.white)
                    if !plan.description.isEmpty {
                        Text(plan.description).font(.caption).foregroundColor(.white.opacity(0.5))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20).padding(.bottom, 16)

                // Daily macro strip
                HStack(spacing: 0) {
                    macroCell("\(plan.dailyCalories)", "Calories", .tmGold)
                    macroCell(String(format: "%.0fg", plan.proteinG), "Protein", .red)
                    macroCell(String(format: "%.0fg", plan.carbsG),   "Carbs",   .blue)
                    macroCell(String(format: "%.0fg", plan.fatG),     "Fat",     .orange)
                }
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.05))

                Divider().background(Color.white.opacity(0.08))

                // Meal list
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedMeals(plan.meals).enumerated()), id: \.element.id) { i, meal in
                            MealDetailRow(meal: meal, index: i + 1)
                            if i < plan.meals.count - 1 {
                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(16)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 17, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.45))
        }.frame(maxWidth: .infinity)
    }

    private func shareMealPlan() {
        let pdf = generateMealPlanPDF()
        let av = UIActivityViewController(activityItems: [pdf], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            var presented = root
            while let next = presented.presentedViewController { presented = next }
            presented.present(av, animated: true)
        }
    }


    private func generateMealPlanPDF() -> URL {
        let pageW: CGFloat = 612; let pageH: CGFloat = 792
        let margin: CGFloat = 48
        var y: CGFloat = margin

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageW, height: pageH))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()

            // Title
            let titleAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 24, weight: .black), .foregroundColor: UIColor(red: 0.82, green: 0.69, blue: 0.27, alpha: 1)]
            plan.title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttr)
            y += 36

            if plan.isActive {
                let activeAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: UIColor.systemGreen]
                "ACTIVE PLAN".draw(at: CGPoint(x: margin, y: y), withAttributes: activeAttr)
                y += 20
            }

            // Divider
            UIColor.lightGray.setStroke()
            let line = UIBezierPath(); line.move(to: CGPoint(x: margin, y: y + 4)); line.addLine(to: CGPoint(x: pageW - margin, y: y + 4)); line.lineWidth = 0.5; line.stroke()
            y += 16

            // Daily targets
            let sectionAttr: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11, weight: .bold), .foregroundColor: UIColor.darkGray]
            let bodyAttr:    [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .regular), .foregroundColor: UIColor.black]
            let boldAttr:    [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: UIColor.black]

            "DAILY TARGETS".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionAttr)
            y += 18

            let macros = [
                ("Calories", "\(plan.dailyCalories) kcal"),
                ("Protein",  String(format: "%.0fg", plan.proteinG)),
                ("Carbs",    String(format: "%.0fg", plan.carbsG)),
                ("Fat",      String(format: "%.0fg", plan.fatG))
            ]
            let colW = (pageW - margin * 2) / 4
            for (i, (label, value)) in macros.enumerated() {
                let x = margin + CGFloat(i) * colW
                label.draw(at: CGPoint(x: x, y: y), withAttributes: sectionAttr)
                value.draw(at: CGPoint(x: x, y: y + 16), withAttributes: boldAttr)
            }
            y += 48

            // Meals
            let orderedMeals = sortedMeals(plan.meals)
            for (i, meal) in orderedMeals.enumerated() {
                // Check page space
                if y > pageH - 120 { ctx.beginPage(); y = margin }

                // Meal header
                let mealHeader = "\(i + 1).  \(meal.mealType.uppercased()) — \(meal.name)"
                mealHeader.draw(at: CGPoint(x: margin, y: y), withAttributes: boldAttr)
                y += 18

                // Macros
                let macroLine = "\(meal.calories) cal  ·  P: \(String(format: "%.0f", meal.protein))g  ·  C: \(String(format: "%.0f", meal.carbs))g  ·  F: \(String(format: "%.0f", meal.fat))g"
                macroLine.draw(at: CGPoint(x: margin + 16, y: y), withAttributes: bodyAttr)
                y += 18

                // Foods
                if !meal.notes.isEmpty {
                    let foods = meal.notes.components(separatedBy: ", ")
                    for food in foods {
                        if y > pageH - 60 { ctx.beginPage(); y = margin }
                        let formatted = "  •  \(formatFoodText(food))"
                        formatted.draw(at: CGPoint(x: margin + 16, y: y), withAttributes: bodyAttr)
                        y += 16
                    }
                }
                y += 12
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(plan.title.replacingOccurrences(of: " ", with: "_"))_MealPlan.pdf")
        try? data.write(to: url)
        return url
    }

    private func formatFoodText(_ raw: String) -> String {
        let parts = raw.components(separatedBy: " ")
        guard parts.count >= 3,
              let multiplierStr = parts.first, multiplierStr.hasSuffix("x"),
              let multiplier = Double(multiplierStr.dropLast()) else { return raw }
        let rest = parts.dropFirst().joined(separator: " ")
        let restParts = rest.components(separatedBy: " ")
        if let baseAmount = Double(restParts[0]), restParts.count >= 2 {
            let actual = baseAmount * multiplier
            let unitAndName = restParts.dropFirst().joined(separator: " ")
            let formatted = actual == floor(actual) ? String(Int(actual)) : String(format: "%.1f", actual)
            return "\(formatted) \(unitAndName)"
        }
        return rest
    }
}

// MARK: - MealDetailRow

struct MealDetailRow: View {
    let meal:  MealItem
    let index: Int
    @State private var expanded = false

    var body: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
            VStack(spacing: 0) {
                // Main row
                HStack(spacing: 14) {
                    // Meal number circle
                    Text("\(index)")
                        .font(.system(size: 12, weight: .black)).foregroundColor(.black)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.tmGold))

                    // Meal info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(meal.name)
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                        HStack(spacing: 6) {
                            Image(systemName: mealIcon(meal.mealType)).font(.system(size: 10)).foregroundColor(.tmGold)
                            Text(meal.mealType.capitalized).font(.caption).foregroundColor(.tmGold)
                        }
                    }

                    Spacer()

                    // Calories + chevron
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(meal.calories)").font(.system(size: 16, weight: .black)).foregroundColor(.white)
                        Text("cal").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                    }
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal, 16).padding(.vertical, 14)

                // Expanded detail
                if expanded {
                    VStack(alignment: .leading, spacing: 10) {
                        // Macros row
                        HStack(spacing: 0) {
                            macroChip(String(format: "%.0f", meal.protein), "Protein", .red)
                            macroChip(String(format: "%.0f", meal.carbs),   "Carbs",   .blue)
                            macroChip(String(format: "%.0f", meal.fat),     "Fat",     .orange)
                        }
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Food items listed line by line
                        if !meal.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(meal.notes.components(separatedBy: ", "), id: \.self) { item in
                                    HStack(spacing: 8) {
                                        Circle().fill(Color.tmGold).frame(width: 5, height: 5)
                                        Text(formatFoodItem(item.trimmingCharacters(in: .whitespaces)))
                                            .font(.caption).foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func macroChip(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(value)g").font(.system(size: 14, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
        }.frame(maxWidth: .infinity)
    }

    /// Converts "1.5x 1 cup Oatmeal (cooked)" → "1.5 cups Oatmeal (cooked)"
    /// Converts "0.5x 2 eggs Whole Eggs" → "1 egg Whole Eggs"
    private func formatFoodItem(_ raw: String) -> String {
        // Expected format: "{servings}x {unit} {name}"
        // e.g. "2x 4 oz Chicken Breast" or "0.5x 1 cup Oatmeal (cooked)"
        let parts = raw.components(separatedBy: " ")
        guard parts.count >= 3,
              let multiplierStr = parts.first,
              multiplierStr.hasSuffix("x"),
              let multiplier = Double(multiplierStr.dropLast()) else {
            return raw
        }

        // Remove the "{n}x" prefix
        let rest = parts.dropFirst().joined(separator: " ")

        // Try to parse a leading number from rest (the "base" unit amount)
        let restParts = rest.components(separatedBy: " ")
        if let baseAmount = Double(restParts[0]), restParts.count >= 2 {
            let actual = baseAmount * multiplier
            let unitAndName = restParts.dropFirst().joined(separator: " ")
            let formatted = actual == floor(actual)
                ? String(Int(actual))
                : String(format: "%.1f", actual)
            return "\(formatted) \(unitAndName)"
        }

        return rest
    }

    private func mealIcon(_ type: String) -> String {
        switch type.lowercased() {
        case "breakfast": return "sunrise.fill"
        case "lunch":     return "sun.max.fill"
        case "dinner":    return "moon.fill"
        case "snack":     return "leaf.fill"
        case "pre-workout": return "bolt.fill"
        case "post-workout": return "flame.fill"
        default:          return "fork.knife"
        }
    }
}


// MARK: - ClientNutritionSection

struct ClientNutritionSection: View {
    let clientId:   String
    let clientName: String
    let trainerId:  String
    @Binding var selectedPlan: MealPlanRow?

    @ObservedObject private var store = SBMealPlanStore.shared
    @State private var isLoading = false

    private var plans: [MealPlanRow] {
        store.mealPlans.filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition").font(.title2).fontWeight(.bold).foregroundColor(.white)

            if isLoading {
                HStack { Spacer(); ProgressView().tint(.tmGold); Spacer() }.padding(.vertical, 20)
            } else if plans.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife").font(.system(size: 40))
                        .foregroundColor(.tmGold.opacity(0.2))
                    Text("No meal plan assigned yet")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Your trainer will assign a meal plan here.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
            } else {
                ForEach(plans) { plan in
                    Button(action: { selectedPlan = plan }) {
                        SBMealPlanClientCard(plan: plan)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            guard let uuid = UUID(uuidString: clientId) else { return }
            isLoading = true
            Task {
                try? await store.fetchForClient(uuid)
                await MainActor.run { isLoading = false }
            }
        }
    }
}

// MARK: - TrainerClientMealPlansView

struct TrainerClientMealPlansView: View {
    let trainerId: String; let clientId: String; let clientName: String
    @ObservedObject private var store = SBMealPlanStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingBuilder = false
    private var plans: [MealPlanRow] { store.mealPlans.filter { $0.clientId.uuidString == clientId } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if plans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife").font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No meal plans yet").font(.title3).foregroundColor(.white.opacity(0.4))
                    Button(action: { showingBuilder = true }) {
                        HStack(spacing: 8) { Image(systemName: "plus.circle.fill"); Text("Create Meal Plan") }
                            .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
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
                }.listStyle(.plain).scrollContentBackground(.hidden)
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
                        Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 4) { Image(systemName: "plus"); Text("Create") }
                        .fontWeight(.semibold).foregroundColor(.tmGold)
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

// MARK: - SBMealPlanRow

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
                        .padding(.horizontal, 8).padding(.vertical, 3).background(Capsule().fill(Color.tmGold))
                }
            }
            HStack(spacing: 0) {
                macroCell(String(format: "%.0fg", plan.proteinG), "protein", .red)
                macroCell(String(format: "%.0fg", plan.carbsG),   "carbs",   .blue)
                macroCell(String(format: "%.0fg", plan.fatG),     "fat",     .yellow)
            }
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.03)))
        }.padding(.vertical, 6)
    }
    private func macroCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 13, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }.frame(maxWidth: .infinity)
    }
}

// MARK: - Stub Views

struct LogWeightView: View {
    let clientId: String; @Environment(\.dismiss) var dismiss
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
    let clientId: String; @Environment(\.dismiss) var dismiss
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
        ZStack { Color.black.ignoresSafeArea(); Text("Weight History").foregroundColor(.white) }
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
        ZStack { Color.black.ignoresSafeArea(); Text("My Meal Plans").foregroundColor(.white) }
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
        }.padding(.vertical, 4)
    }
}
