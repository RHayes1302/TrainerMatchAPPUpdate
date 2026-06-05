//
//  WorkoutBuilderView.swift
//  TrainerMatch
//
//  Trainer assigns workouts to clients with a full exercise library,
//  category filtering, search, and Supabase persistence.
//

import SwiftUI

// MARK: - Exercise Library

struct ExerciseLibraryItem: Identifiable {
    let id = UUID()
    let name:     String
    let category: ExerciseCategory
    let defaultSets: Int
    let defaultReps: String
    let defaultRest: Int
    let tips:     String

    enum ExerciseCategory: String, CaseIterable {
        case chest      = "Chest"
        case back       = "Back"
        case shoulders  = "Shoulders"
        case arms       = "Arms"
        case legs       = "Legs"
        case core       = "Core"
        case cardio     = "Cardio"
        case fullBody   = "Full Body"

        var icon: String {
            switch self {
            case .chest:     return "figure.strengthtraining.traditional"
            case .back:      return "figure.row"
            case .shoulders: return "figure.arms.open"
            case .arms:      return "dumbbell.fill"
            case .legs:      return "figure.run"
            case .core:      return "figure.core.training"
            case .cardio:    return "heart.fill"
            case .fullBody:  return "figure.mixed.cardio"
            }
        }

        var color: Color {
            switch self {
            case .chest:     return .red
            case .back:      return .blue
            case .shoulders: return .orange
            case .arms:      return .purple
            case .legs:      return .green
            case .core:      return .yellow
            case .cardio:    return .pink
            case .fullBody:  return .tmGold
            }
        }
    }
}

// MARK: - Exercise Library Data

struct ExerciseLibrary {
    static let all: [ExerciseLibraryItem] = [
        // CHEST
        ExerciseLibraryItem(name: "Barbell Bench Press",    category: .chest,     defaultSets: 4, defaultReps: "8-10",  defaultRest: 90,  tips: "Keep shoulder blades retracted, feet flat on floor."),
        ExerciseLibraryItem(name: "Dumbbell Bench Press",   category: .chest,     defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Full range of motion, controlled descent."),
        ExerciseLibraryItem(name: "Incline Bench Press",    category: .chest,     defaultSets: 3, defaultReps: "8-10",  defaultRest: 90,  tips: "Set bench to 30-45 degrees for upper chest focus."),
        ExerciseLibraryItem(name: "Cable Fly",              category: .chest,     defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Squeeze chest at peak contraction."),
        ExerciseLibraryItem(name: "Push-Up",                category: .chest,     defaultSets: 3, defaultReps: "15-20", defaultRest: 60,  tips: "Keep core tight, full range of motion."),
        ExerciseLibraryItem(name: "Dumbbell Fly",           category: .chest,     defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Slight bend in elbows throughout movement."),
        ExerciseLibraryItem(name: "Chest Dip",              category: .chest,     defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Lean forward slightly to target chest."),

        // BACK
        ExerciseLibraryItem(name: "Deadlift",               category: .back,      defaultSets: 4, defaultReps: "5-6",   defaultRest: 120, tips: "Neutral spine, drive through heels."),
        ExerciseLibraryItem(name: "Pull-Up",                category: .back,      defaultSets: 4, defaultReps: "6-10",  defaultRest: 90,  tips: "Full hang at bottom, chin over bar at top."),
        ExerciseLibraryItem(name: "Barbell Row",            category: .back,      defaultSets: 4, defaultReps: "8-10",  defaultRest: 90,  tips: "Hinge at hips, pull to lower chest."),
        ExerciseLibraryItem(name: "Lat Pulldown",           category: .back,      defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Pull bar to upper chest, lean slightly back."),
        ExerciseLibraryItem(name: "Seated Cable Row",       category: .back,      defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Keep chest up, squeeze shoulder blades."),
        ExerciseLibraryItem(name: "Single Arm Dumbbell Row",category: .back,      defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Brace on bench, row to hip."),
        ExerciseLibraryItem(name: "Face Pull",              category: .back,      defaultSets: 3, defaultReps: "15-20", defaultRest: 60,  tips: "Pull to face level, external rotate at end."),
        ExerciseLibraryItem(name: "Hyperextension",         category: .back,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Keep movement controlled, don't hyperextend."),

        // SHOULDERS
        ExerciseLibraryItem(name: "Overhead Press",         category: .shoulders, defaultSets: 4, defaultReps: "8-10",  defaultRest: 90,  tips: "Bar path straight up, lock out at top."),
        ExerciseLibraryItem(name: "Dumbbell Shoulder Press",category: .shoulders, defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Don't flare elbows excessively."),
        ExerciseLibraryItem(name: "Lateral Raise",          category: .shoulders, defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Lead with elbows, slight forward lean."),
        ExerciseLibraryItem(name: "Front Raise",            category: .shoulders, defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Control the descent, don't use momentum."),
        ExerciseLibraryItem(name: "Arnold Press",           category: .shoulders, defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Rotate palms as you press up."),
        ExerciseLibraryItem(name: "Upright Row",            category: .shoulders, defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Elbows lead, pull to chin level."),
        ExerciseLibraryItem(name: "Rear Delt Fly",          category: .shoulders, defaultSets: 3, defaultReps: "15-20", defaultRest: 60,  tips: "Slight bend in elbows, squeeze rear delts."),

        // ARMS
        ExerciseLibraryItem(name: "Barbell Curl",           category: .arms,      defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Keep elbows at sides, full range of motion."),
        ExerciseLibraryItem(name: "Dumbbell Curl",          category: .arms,      defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Supinate wrist at top of movement."),
        ExerciseLibraryItem(name: "Hammer Curl",            category: .arms,      defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Neutral grip targets brachialis."),
        ExerciseLibraryItem(name: "Tricep Pushdown",        category: .arms,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Keep elbows at sides, full extension."),
        ExerciseLibraryItem(name: "Skull Crusher",          category: .arms,      defaultSets: 3, defaultReps: "10-12", defaultRest: 75,  tips: "Lower bar to forehead, keep elbows in."),
        ExerciseLibraryItem(name: "Tricep Dip",             category: .arms,      defaultSets: 3, defaultReps: "10-15", defaultRest: 60,  tips: "Keep elbows close, upright torso."),
        ExerciseLibraryItem(name: "Concentration Curl",     category: .arms,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Elbow on inner thigh, full range."),
        ExerciseLibraryItem(name: "Overhead Tricep Extension", category: .arms,   defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Keep upper arms stationary."),

        // LEGS
        ExerciseLibraryItem(name: "Barbell Squat",          category: .legs,      defaultSets: 4, defaultReps: "6-8",   defaultRest: 120, tips: "Break parallel, knees track over toes."),
        ExerciseLibraryItem(name: "Romanian Deadlift",      category: .legs,      defaultSets: 3, defaultReps: "10-12", defaultRest: 90,  tips: "Hinge at hips, feel hamstring stretch."),
        ExerciseLibraryItem(name: "Leg Press",              category: .legs,      defaultSets: 4, defaultReps: "10-12", defaultRest: 90,  tips: "Don't lock knees at top, full range."),
        ExerciseLibraryItem(name: "Walking Lunge",          category: .legs,      defaultSets: 3, defaultReps: "12 each", defaultRest: 75, tips: "Step forward, knee doesn't pass toes."),
        ExerciseLibraryItem(name: "Leg Curl",               category: .legs,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Full contraction, controlled descent."),
        ExerciseLibraryItem(name: "Leg Extension",          category: .legs,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Full extension, squeeze quad at top."),
        ExerciseLibraryItem(name: "Calf Raise",             category: .legs,      defaultSets: 4, defaultReps: "15-20", defaultRest: 45,  tips: "Full stretch at bottom, hold at top."),
        ExerciseLibraryItem(name: "Bulgarian Split Squat",  category: .legs,      defaultSets: 3, defaultReps: "10 each", defaultRest: 75, tips: "Rear foot elevated, front foot forward."),
        ExerciseLibraryItem(name: "Goblet Squat",           category: .legs,      defaultSets: 3, defaultReps: "12-15", defaultRest: 60,  tips: "Hold dumbbell at chest, squat deep."),
        ExerciseLibraryItem(name: "Hip Thrust",             category: .legs,      defaultSets: 4, defaultReps: "12-15", defaultRest: 75,  tips: "Drive hips up, squeeze glutes at top."),

        // CORE
        ExerciseLibraryItem(name: "Plank",                  category: .core,      defaultSets: 3, defaultReps: "45 sec", defaultRest: 45, tips: "Neutral spine, don't let hips sag."),
        ExerciseLibraryItem(name: "Crunch",                 category: .core,      defaultSets: 3, defaultReps: "20-25", defaultRest: 45,  tips: "Lift shoulders, not full sit-up."),
        ExerciseLibraryItem(name: "Bicycle Crunch",         category: .core,      defaultSets: 3, defaultReps: "20 each", defaultRest: 45, tips: "Controlled rotation, don't pull neck."),
        ExerciseLibraryItem(name: "Russian Twist",          category: .core,      defaultSets: 3, defaultReps: "20 each", defaultRest: 45, tips: "Lean back slightly, rotate controlled."),
        ExerciseLibraryItem(name: "Leg Raise",              category: .core,      defaultSets: 3, defaultReps: "15-20", defaultRest: 45,  tips: "Lower back pressed to floor."),
        ExerciseLibraryItem(name: "Cable Crunch",           category: .core,      defaultSets: 3, defaultReps: "15-20", defaultRest: 45,  tips: "Crunch abs, not just pulling with arms."),
        ExerciseLibraryItem(name: "Ab Wheel Rollout",       category: .core,      defaultSets: 3, defaultReps: "10-12", defaultRest: 60,  tips: "Keep core tight throughout."),
        ExerciseLibraryItem(name: "Side Plank",             category: .core,      defaultSets: 3, defaultReps: "30 sec each", defaultRest: 45, tips: "Hips up, body in straight line."),

        // CARDIO
        ExerciseLibraryItem(name: "Treadmill Run",          category: .cardio,    defaultSets: 1, defaultReps: "20 min", defaultRest: 0,  tips: "Maintain conversational pace."),
        ExerciseLibraryItem(name: "Jump Rope",              category: .cardio,    defaultSets: 5, defaultReps: "2 min",  defaultRest: 60, tips: "Land softly on balls of feet."),
        ExerciseLibraryItem(name: "Burpee",                 category: .cardio,    defaultSets: 4, defaultReps: "10-15", defaultRest: 60,  tips: "Explosive jump at top."),
        ExerciseLibraryItem(name: "Box Jump",               category: .cardio,    defaultSets: 4, defaultReps: "8-10",  defaultRest: 60,  tips: "Land softly with bent knees."),
        ExerciseLibraryItem(name: "Mountain Climber",       category: .cardio,    defaultSets: 3, defaultReps: "30 sec", defaultRest: 45, tips: "Hips level, drive knees to chest."),
        ExerciseLibraryItem(name: "Rowing Machine",         category: .cardio,    defaultSets: 1, defaultReps: "15 min", defaultRest: 0,  tips: "Drive with legs first, then pull arms."),
        ExerciseLibraryItem(name: "Stationary Bike",        category: .cardio,    defaultSets: 1, defaultReps: "20 min", defaultRest: 0,  tips: "Maintain steady cadence."),
        ExerciseLibraryItem(name: "Battle Ropes",           category: .cardio,    defaultSets: 5, defaultReps: "30 sec", defaultRest: 30, tips: "Full arm movement, engage core."),

        // FULL BODY
        ExerciseLibraryItem(name: "Clean and Press",        category: .fullBody,  defaultSets: 4, defaultReps: "5-6",   defaultRest: 120, tips: "Explosive pull, press overhead."),
        ExerciseLibraryItem(name: "Kettlebell Swing",       category: .fullBody,  defaultSets: 4, defaultReps: "15-20", defaultRest: 60,  tips: "Hip hinge, not a squat."),
        ExerciseLibraryItem(name: "Thruster",               category: .fullBody,  defaultSets: 4, defaultReps: "10-12", defaultRest: 75,  tips: "Squat to press in one fluid motion."),
        ExerciseLibraryItem(name: "Turkish Get-Up",         category: .fullBody,  defaultSets: 3, defaultReps: "5 each", defaultRest: 90, tips: "Slow and controlled throughout."),
        ExerciseLibraryItem(name: "Man Maker",              category: .fullBody,  defaultSets: 3, defaultReps: "8-10",  defaultRest: 90,  tips: "Push-up, row, squat, press combo."),
        ExerciseLibraryItem(name: "Bear Crawl",             category: .fullBody,  defaultSets: 3, defaultReps: "20 yards", defaultRest: 60, tips: "Keep hips low, opposite hand/foot."),
    ]

    static func search(_ query: String) -> [ExerciseLibraryItem] {
        guard !query.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    static func byCategory(_ category: ExerciseLibraryItem.ExerciseCategory) -> [ExerciseLibraryItem] {
        all.filter { $0.category == category }
    }
}

// MARK: - Workout Builder View

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
    @State private var selectedExercises: [ExerciseItem] = []

    @State private var showingLibrary    = false
    @State private var isSaving          = false
    @State private var editingExercise:  ExerciseItem? = nil

    let difficulties = ["beginner", "intermediate", "advanced"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {

                    // Title
                    formBlock("WORKOUT TITLE") {
                        TextField("e.g. Upper Body Strength Day", text: $title)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                    }

                    // Description
                    formBlock("DESCRIPTION (OPTIONAL)") {
                        TextField("Focus areas, notes for client...", text: $description, axis: .vertical)
                            .foregroundColor(.white).lineLimit(2...4).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }

                    // Difficulty + Duration
                    HStack(spacing: 12) {
                        formBlock("DIFFICULTY") {
                            Menu {
                                ForEach(difficulties, id: \.self) { d in
                                    Button(d.capitalized) { difficulty = d }
                                }
                            } label: {
                                HStack {
                                    Circle().fill(difficultyColor).frame(width: 8, height: 8)
                                    Text(difficulty.capitalized).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                                }
                                .padding(12)
                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            }
                        }

                        formBlock("EST. MINS") {
                            HStack {
                                Button(action: { if estimatedMins > 5 { estimatedMins -= 5 } }) {
                                    Image(systemName: "minus.circle.fill").foregroundColor(.tmGold).font(.title3)
                                }
                                Text("\(estimatedMins)").font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white).frame(minWidth: 36)
                                Button(action: { estimatedMins += 5 }) {
                                    Image(systemName: "plus.circle.fill").foregroundColor(.tmGold).font(.title3)
                                }
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                    }

                    // Due Date
                    formBlock("DUE DATE") {
                        DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.compact).colorScheme(.dark).tint(.tmGold)
                            .labelsHidden().padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Exercise List
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("EXERCISES").font(.system(size: 10, weight: .bold))
                                    .tracking(1.2).foregroundColor(.tmGold)
                                if !selectedExercises.isEmpty {
                                    Text("\(selectedExercises.count) added • \(totalVolume)")
                                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                                }
                            }
                            Spacer()
                            Button(action: { showingLibrary = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill").font(.caption)
                                    Text("Add Exercise").font(.caption).fontWeight(.semibold)
                                }
                                .foregroundColor(.black).padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Capsule().fill(Color.tmGold))
                            }
                        }

                        if selectedExercises.isEmpty {
                            Button(action: { showingLibrary = true }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "dumbbell.fill")
                                        .font(.system(size: 32)).foregroundColor(.tmGold.opacity(0.4))
                                    Text("Tap to browse exercise library")
                                        .font(.subheadline).foregroundColor(.white.opacity(0.35))
                                    Text("60+ exercises across 8 categories")
                                        .font(.caption).foregroundColor(.white.opacity(0.25))
                                }
                                .frame(maxWidth: .infinity).padding(24)
                                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.tmGold.opacity(0.15),
                                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(Array(selectedExercises.enumerated()), id: \.element.id) { i, ex in
                                ExerciseRowCard(
                                    exercise: ex,
                                    index: i + 1,
                                    onEdit: { editingExercise = ex },
                                    onDelete: { selectedExercises.removeAll { $0.id == ex.id } },
                                    onMoveUp: {
                                        if i > 0 { selectedExercises.swapAt(i, i - 1) }
                                    },
                                    onMoveDown: {
                                        if i < selectedExercises.count - 1 {
                                            selectedExercises.swapAt(i, i + 1)
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Assign Button
                    Button(action: saveWorkout) {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("ASSIGN TO \(clientName.uppercased())")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(canSave ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(canSave ? Color.tmGold : Color.white.opacity(0.08))
                            .shadow(color: canSave ? Color.tmGold.opacity(0.4) : .clear, radius: 10, y: 4))
                    }
                    .disabled(!canSave || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Assign Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .sheet(isPresented: $showingLibrary) {
            ExerciseLibraryView { exercise in
                let item = ExerciseItem(
                    id: UUID(), name: exercise.name,
                    sets: exercise.defaultSets, reps: exercise.defaultReps,
                    weight: "", notes: exercise.tips,
                    restSeconds: exercise.defaultRest
                )
                selectedExercises.append(item)
            }
        }
        .sheet(item: $editingExercise) { ex in
            ExerciseEditSheet(exercise: ex) { updated in
                if let i = selectedExercises.firstIndex(where: { $0.id == updated.id }) {
                    selectedExercises[i] = updated
                }
            }
        }
    }

    private var canSave: Bool { !title.isEmpty && !selectedExercises.isEmpty }

    private var difficultyColor: Color {
        switch difficulty {
        case "beginner": return .green
        case "advanced": return .red
        default:         return .tmGold
        }
    }

    private var totalVolume: String {
        let sets = selectedExercises.reduce(0) { $0 + $1.sets }
        return "\(sets) total sets"
    }

    private func saveWorkout() {
        guard canSave,
              let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isSaving = true
        let row = WorkoutRow(
            id: UUID(), trainerId: tUUID, clientId: cUUID,
            title: title, description: description,
            exercises: selectedExercises,
            difficulty: difficulty, estimatedMins: estimatedMins,
            status: "assigned", assignedDate: Date(),
            dueDate: dueDate, completedAt: nil, createdAt: Date()
        )
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

    private func formBlock<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - Exercise Library Browser

struct ExerciseLibraryView: View {
    let onAdd: (ExerciseLibraryItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var searchText   = ""
    @State private var selectedCategory: ExerciseLibraryItem.ExerciseCategory? = nil
    @State private var addedIds: Set<UUID> = []

    private var filtered: [ExerciseLibraryItem] {
        var list = selectedCategory != nil
            ? ExerciseLibrary.byCategory(selectedCategory!)
            : ExerciseLibrary.all
        if !searchText.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return list
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
                        TextField("Search exercises...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                label: "All",
                                icon: "square.grid.2x2.fill",
                                color: .tmGold,
                                isSelected: selectedCategory == nil
                            ) { selectedCategory = nil }

                            ForEach(ExerciseLibraryItem.ExerciseCategory.allCases, id: \.self) { cat in
                                CategoryChip(
                                    label: cat.rawValue,
                                    icon: cat.icon,
                                    color: cat.color,
                                    isSelected: selectedCategory == cat
                                ) { selectedCategory = selectedCategory == cat ? nil : cat }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 8)

                    Divider().background(Color.white.opacity(0.08))

                    // Exercise list
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass").font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.2)).padding(.top, 60)
                            Text("No exercises found").font(.headline).foregroundColor(.white.opacity(0.4))
                            Text("Try a different search or category")
                                .font(.subheadline).foregroundColor(.white.opacity(0.3))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(filtered) { exercise in
                                ExerciseLibraryRow(
                                    exercise: exercise,
                                    isAdded: addedIds.contains(exercise.id)
                                ) {
                                    onAdd(exercise)
                                    addedIds.insert(exercise.id)
                                }
                                .listRowBackground(Color.white.opacity(0.03))
                                .listRowSeparatorTint(Color.white.opacity(0.06))
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(.tmGold)
                }
            }
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let label:      String
    let icon:       String
    let color:      Color
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11))
                Text(label).font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(isSelected ? .black : .white.opacity(0.6))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(isSelected ? color : Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Library Row

struct ExerciseLibraryRow: View {
    let exercise: ExerciseLibraryItem
    let isAdded:  Bool
    let onAdd:    () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(exercise.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: exercise.category.icon)
                    .font(.system(size: 16)).foregroundColor(exercise.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 8) {
                    Text(exercise.category.rawValue).font(.caption)
                        .foregroundColor(exercise.category.color)
                    Text("•").foregroundColor(.white.opacity(0.3))
                    Text("\(exercise.defaultSets) sets × \(exercise.defaultReps)")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                    Text("•").foregroundColor(.white.opacity(0.3))
                    Text("\(exercise.defaultRest)s rest")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(isAdded ? .green : .tmGold)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Exercise Row Card (in workout)

struct ExerciseRowCard: View {
    let exercise:   ExerciseItem
    let index:      Int
    let onEdit:     () -> Void
    let onDelete:   () -> Void
    let onMoveUp:   () -> Void
    let onMoveDown: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Index badge
            Text("\(index)")
                .font(.system(size: 12, weight: .black)).foregroundColor(.black)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.tmGold))

            // Exercise info
            VStack(alignment: .leading, spacing: 3) {
                Text(exercise.name)
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                HStack(spacing: 6) {
                    Label("\(exercise.sets) sets", systemImage: "repeat")
                    Text("×")
                    Text(exercise.reps)
                    if exercise.restSeconds > 0 {
                        Text("• \(exercise.restSeconds)s rest")
                    }
                }
                .font(.caption).foregroundColor(.white.opacity(0.45))
                if !exercise.weight.isEmpty {
                    Text("Weight: \(exercise.weight)")
                        .font(.caption2).foregroundColor(.tmGold)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 4) {
                Button(action: onMoveUp) {
                    Image(systemName: "chevron.up").font(.caption).foregroundColor(.white.opacity(0.4))
                        .padding(6)
                }
                Button(action: onMoveDown) {
                    Image(systemName: "chevron.down").font(.caption).foregroundColor(.white.opacity(0.4))
                        .padding(6)
                }
                Button(action: onEdit) {
                    Image(systemName: "pencil").font(.caption).foregroundColor(.tmGold)
                        .padding(6)
                }
                Button(action: onDelete) {
                    Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                        .padding(6)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
}

// MARK: - Exercise Edit Sheet

struct ExerciseEditSheet: View {
    let exercise: ExerciseItem
    let onSave:   (ExerciseItem) -> Void
    @Environment(\.dismiss) var dismiss

    @State private var name:    String
    @State private var sets:    String
    @State private var reps:    String
    @State private var weight:  String
    @State private var rest:    String
    @State private var notes:   String

    init(exercise: ExerciseItem, onSave: @escaping (ExerciseItem) -> Void) {
        self.exercise = exercise
        self.onSave   = onSave
        _name   = State(initialValue: exercise.name)
        _sets   = State(initialValue: "\(exercise.sets)")
        _reps   = State(initialValue: exercise.reps)
        _weight = State(initialValue: exercise.weight)
        _rest   = State(initialValue: "\(exercise.restSeconds)")
        _notes  = State(initialValue: exercise.notes)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        editField("EXERCISE NAME", text: $name)

                        HStack(spacing: 12) {
                            editField("SETS", text: $sets, keyboard: .numberPad)
                            editField("REPS", text: $reps)
                        }

                        HStack(spacing: 12) {
                            editField("WEIGHT", text: $weight, placeholder: "e.g. 135 lbs")
                            editField("REST (sec)", text: $rest, keyboard: .numberPad)
                        }

                        editField("TIPS / NOTES", text: $notes, multiline: true)

                        Button(action: save) {
                            Text("SAVE CHANGES").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                                .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func editField(_ label: String, text: Binding<String>,
                            placeholder: String = "",
                            keyboard: UIKeyboardType = .default,
                            multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            if multiline {
                TextField(placeholder.isEmpty ? label.lowercased() : placeholder,
                          text: text, axis: .vertical)
                    .lineLimit(2...4).foregroundColor(.white).padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1))
            } else {
                TextField(placeholder.isEmpty ? label.lowercased() : placeholder, text: text)
                    .keyboardType(keyboard).foregroundColor(.white).padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
        }
    }

    private func save() {
        let updated = ExerciseItem(
            id: exercise.id, name: name,
            sets: Int(sets) ?? exercise.sets,
            reps: reps, weight: weight,
            notes: notes,
            restSeconds: Int(rest) ?? exercise.restSeconds
        )
        onSave(updated)
        dismiss()
    }
}
