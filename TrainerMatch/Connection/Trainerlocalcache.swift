//
//  TrainerLocalCache.swift
//  TrainerMatch
//
//  Local storage for trainer plan templates and client history
//  Templates are reusable across clients
//  History is cached locally when plans are replaced in Supabase
//

import SwiftUI
import Foundation

// MARK: - Saved Meal Plan Template

struct MealPlanTemplate: Identifiable, Codable {
    let id:            String
    let trainerId:     String
    let title:         String
    let description:   String
    let meals:         [MealItem]
    let dailyCalories: Int
    let proteinG:      Double
    let carbsG:        Double
    let fatG:          Double
    let savedAt:       Date

    init(from plan: MealPlanRow) {
        self.id            = UUID().uuidString
        self.trainerId     = plan.trainerId.uuidString
        self.title         = plan.title
        self.description   = plan.description
        self.meals         = plan.meals
        self.dailyCalories = plan.dailyCalories
        self.proteinG      = plan.proteinG
        self.carbsG        = plan.carbsG
        self.fatG          = plan.fatG
        self.savedAt       = Date()
    }
}

// MARK: - Saved Workout Template

struct WorkoutProgramTemplate: Identifiable, Codable {
    let id:        String
    let trainerId: String
    let title:     String
    let days:      [WorkoutDayTemplate]
    let savedAt:   Date

    init(trainerId: String, title: String, days: [WorkoutRow]) {
        self.id        = UUID().uuidString
        self.trainerId = trainerId
        self.title     = title
        self.days      = days.map { WorkoutDayTemplate(from: $0) }
        self.savedAt   = Date()
    }
}

struct WorkoutDayTemplate: Codable {
    let dayNumber:    Int?
    let title:        String
    let muscleGroup:  String?
    let difficulty:   String
    let estimatedMins: Int
    let exercises:    [ExerciseItem]
    let isRestDay:    Bool

    init(from row: WorkoutRow) {
        self.dayNumber     = row.dayNumber
        self.title         = row.title
        self.muscleGroup   = row.muscleGroup
        self.difficulty    = row.difficulty
        self.estimatedMins = row.estimatedMins
        self.exercises     = row.exercises
        self.isRestDay     = row.isRestDay ?? false
    }
}

// MARK: - Trainer Local Cache

class TrainerLocalCache: ObservableObject {
    static let shared = TrainerLocalCache()

    @Published var mealPlanTemplates:     [MealPlanTemplate]         = []
    @Published var workoutProgramTemplates: [WorkoutProgramTemplate] = []

    private let mealTemplatesKey    = "trainer_meal_templates"
    private let workoutTemplatesKey = "trainer_workout_templates"

    private init() {
        loadTemplates()
    }

    // MARK: - Template Management

    func saveMealPlanAsTemplate(_ plan: MealPlanRow) {
        let template = MealPlanTemplate(from: plan)
        mealPlanTemplates.insert(template, at: 0)
        persistMealTemplates()
    }

    func saveWorkoutProgramAsTemplate(trainerId: String, title: String, days: [WorkoutRow]) {
        let template = WorkoutProgramTemplate(trainerId: trainerId, title: title, days: days)
        workoutProgramTemplates.insert(template, at: 0)
        persistWorkoutTemplates()
    }

    func deleteMealTemplate(_ template: MealPlanTemplate) {
        mealPlanTemplates.removeAll { $0.id == template.id }
        persistMealTemplates()
    }

    func deleteWorkoutTemplate(_ template: WorkoutProgramTemplate) {
        workoutProgramTemplates.removeAll { $0.id == template.id }
        persistWorkoutTemplates()
    }

    // MARK: - History (auto-saved when plans replaced)

    func saveMealPlanHistory(_ plans: [MealPlanRow], clientId: String, trainerId: String) {
        // Save to UserDefaults as history
        let key = "meal_history_\(trainerId)_\(clientId)"
        if let data = try? JSONEncoder().encode(plans) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func saveWorkoutProgram(_ workouts: [WorkoutRow], clientId: String, trainerId: String) {
        let key = "workout_history_\(trainerId)_\(clientId)"
        if let data = try? JSONEncoder().encode(workouts) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func getMealPlanHistory(clientId: String, trainerId: String) -> [MealPlanRow] {
        let key = "meal_history_\(trainerId)_\(clientId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let plans = try? JSONDecoder().decode([MealPlanRow].self, from: data)
        else { return [] }
        return plans
    }

    func getWorkoutHistory(clientId: String, trainerId: String) -> [WorkoutRow] {
        let key = "workout_history_\(trainerId)_\(clientId)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let workouts = try? JSONDecoder().decode([WorkoutRow].self, from: data)
        else { return [] }
        return workouts
    }

    // MARK: - Convert Template to Plan for New Client

    func mealPlanRow(from template: MealPlanTemplate, trainerId: UUID, clientId: UUID) -> MealPlanRow {
        MealPlanRow(
            id:            UUID(),
            trainerId:     trainerId,
            clientId:      clientId,
            title:         template.title,
            description:   template.description,
            meals:         template.meals,
            dailyCalories: template.dailyCalories,
            proteinG:      template.proteinG,
            carbsG:        template.carbsG,
            fatG:          template.fatG,
            weekStart:     nil,
            isActive:      true,
            createdAt:     Date()
        )
    }

    func workoutRows(from template: WorkoutProgramTemplate, trainerId: UUID, clientId: UUID) -> [WorkoutRow] {
        let now = Date()
        return template.days.map { day in
            WorkoutRow(
                id:            UUID(),
                trainerId:     trainerId,
                clientId:      clientId,
                title:         day.title,
                description:   "",
                exercises:     day.exercises,
                difficulty:    day.difficulty,
                estimatedMins: day.estimatedMins,
                status:        "assigned",
                muscleGroup:   day.muscleGroup,
                dayNumber:     day.dayNumber,
                isRestDay:     day.isRestDay,
                assignedDate:  now,
                dueDate:       now.addingTimeInterval(7 * 86400),
                completedAt:   nil,
                createdAt:     now  // same timestamp = groups as one program
            )
        }
    }

    // MARK: - Persistence

    private func loadTemplates() {
        if let data = UserDefaults.standard.data(forKey: mealTemplatesKey),
           let templates = try? JSONDecoder().decode([MealPlanTemplate].self, from: data) {
            mealPlanTemplates = templates
        }
        if let data = UserDefaults.standard.data(forKey: workoutTemplatesKey),
           let templates = try? JSONDecoder().decode([WorkoutProgramTemplate].self, from: data) {
            workoutProgramTemplates = templates
        }
    }

    private func persistMealTemplates() {
        if let data = try? JSONEncoder().encode(mealPlanTemplates) {
            UserDefaults.standard.set(data, forKey: mealTemplatesKey)
        }
    }

    private func persistWorkoutTemplates() {
        if let data = try? JSONEncoder().encode(workoutProgramTemplates) {
            UserDefaults.standard.set(data, forKey: workoutTemplatesKey)
        }
    }
}

// MARK: - Trainer Template Library View

struct TrainerTemplateLibraryView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    let mode:       TemplateMode
    @ObservedObject private var cache = TrainerLocalCache.shared
    @ObservedObject private var mealStore    = SBMealPlanStore.shared
    @ObservedObject private var workoutStore = SBWorkoutStore.shared
    @Environment(\.dismiss) var dismiss

    enum TemplateMode { case meal, workout }

    @State private var isAssigning = false
    @State private var assignError: String? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if templates.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: mode == .meal ? "fork.knife" : "dumbbell.fill")
                        .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.3))
                    Text("No saved templates yet").font(.title3).foregroundColor(.white.opacity(0.5))
                    Text("Save a \(mode == .meal ? "meal plan" : "workout program") as a template\nto reuse it across clients")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .padding(40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(templates, id: \.id) { template in
                            TemplateCard(
                                title:    template.title,
                                subtitle: template.subtitle,
                                onAssign: { assignTemplate(template) },
                                onDelete: { deleteTemplate(template) },
                                isAssigning: isAssigning
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Saved Templates").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Error", isPresented: Binding(get: { assignError != nil }, set: { if !$0 { assignError = nil } })) {
            Button("OK") { assignError = nil }
        } message: {
            Text(assignError ?? "")
        }
    }

    // Unified template list
    private var templates: [AnyTemplate] {
        switch mode {
        case .meal:
            return cache.mealPlanTemplates
                .filter { $0.trainerId == trainerId }
                .map { AnyTemplate(id: $0.id, title: $0.title,
                                   subtitle: "\($0.meals.count) meals · \($0.dailyCalories) kcal/day",
                                   underlying: .meal($0)) }
        case .workout:
            return cache.workoutProgramTemplates
                .filter { $0.trainerId == trainerId }
                .map { AnyTemplate(id: $0.id, title: $0.title,
                                   subtitle: "\($0.days.count)-day program",
                                   underlying: .workout($0)) }
        }
    }

    private func assignTemplate(_ template: AnyTemplate) {
        guard let tUUID = UUID(uuidString: trainerId),
              let cUUID = UUID(uuidString: clientId) else { return }
        isAssigning = true
        Task {
            do {
                switch template.underlying {
                case .meal(let t):
                    let plan = cache.mealPlanRow(from: t, trainerId: tUUID, clientId: cUUID)
                    try await mealStore.create(plan)
                case .workout(let t):
                    let rows = cache.workoutRows(from: t, trainerId: tUUID, clientId: cUUID)
                    try await workoutStore.replaceProgram(rows)
                }
                await MainActor.run { isAssigning = false; dismiss() }
            } catch {
                await MainActor.run { isAssigning = false; assignError = error.localizedDescription }
            }
        }
    }

    private func deleteTemplate(_ template: AnyTemplate) {
        switch template.underlying {
        case .meal(let t):    cache.deleteMealTemplate(t)
        case .workout(let t): cache.deleteWorkoutTemplate(t)
        }
    }
}

// MARK: - Supporting Types

struct AnyTemplate: Identifiable {
    let id:         String
    let title:      String
    let subtitle:   String
    let underlying: UnderlyingTemplate

    enum UnderlyingTemplate {
        case meal(MealPlanTemplate)
        case workout(WorkoutProgramTemplate)
    }
}

struct TemplateCard: View {
    let title:       String
    let subtitle:    String
    let onAssign:    () -> Void
    let onDelete:    () -> Void
    let isAssigning: Bool

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Button(action: onAssign) {
                if isAssigning {
                    ProgressView().tint(.black).scaleEffect(0.8)
                } else {
                    Text("Assign").font(.caption).fontWeight(.bold).foregroundColor(.black)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Capsule().fill(Color.tmGold))
            .disabled(isAssigning)

            Button(action: onDelete) {
                Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1)))
    }
}
