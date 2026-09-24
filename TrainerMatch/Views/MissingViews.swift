//
//  MissingViews.swift
//  TrainerMatch
//
//  Clean replacements for views that were in deleted store files.
//  Uses only types that actually exist in LegacyModels + SupabaseDataStores.
//

import SwiftUI
import PhotosUI

// MARK: - TrainerClientWeightSummary

struct TrainerClientWeightSummary: View {
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBWeightStore.shared

    private var latest: SBWeightEntryRow? { store.latestWeight(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "scalemass.fill").foregroundColor(.tmGold).font(.caption)
                Text("WEIGHT TRACKING")
                    .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            }

            if let entry = latest {
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("Current").font(.caption).foregroundColor(.white.opacity(0.4))
                        HStack(alignment: .lastTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", entry.weight))
                                .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                            Text(entry.unit).font(.caption).foregroundColor(.tmGold.opacity(0.6))
                        }
                        if let date = entry.loggedAt {
                            Text(date, style: .date).font(.caption2).foregroundColor(.white.opacity(0.3))
                        }
                    }
                    Spacer()
                    if !entry.note.isEmpty {
                        Text(entry.note).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(2)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
            } else {
                Text("No weight logged yet.")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }
}

// MARK: - ClientWeightView

struct ClientWeightView: View {
    let clientId: String
    @ObservedObject private var store = SBWeightStore.shared
    @State private var showingLog     = false
    @State private var weightText     = ""
    @State private var unit           = "lbs"
    @State private var note           = ""
    @State private var isSaving       = false

    private var entries: [SBWeightEntryRow] { store.entries(forClient: clientId) }
    private var latest:  SBWeightEntryRow?  { entries.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Weight Tracking").font(.title2).fontWeight(.bold).foregroundColor(.white)
                Spacer()
                Button(action: { showingLog = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Weight")
                    }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.tmGold))
                }
            }

            if let e = latest {
                HStack(spacing: 0) {
                    weightStat("Current", value: String(format: "%.1f", e.weight), unit: e.unit, color: .tmGold)
                    Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                    weightStat("Entries", value: "\(entries.count)", unit: "total", color: .white)
                }
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "scalemass").font(.system(size: 36)).foregroundColor(.tmGold.opacity(0.3))
                    Text("No weight logged yet").foregroundColor(.white.opacity(0.4))
                    Text("Tap Log Weight to add your first entry")
                        .font(.caption).foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity).padding(30)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
            }

            if !entries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RECENT").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                    ForEach(entries.prefix(5)) { e in
                        HStack {
                            if let d = e.loggedAt {
                                Text(d, style: .date).font(.subheadline).foregroundColor(.white)
                            }
                            Spacer()
                            Text(String(format: "%.1f %@", e.weight, e.unit))
                                .font(.system(size: 15, weight: .bold)).foregroundColor(.tmGold)
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingLog) { logWeightSheet }
    }

    private var logWeightSheet: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 24) {
                    TextField("0.0", text: $weightText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 52, weight: .black))
                        .foregroundColor(.tmGold).multilineTextAlignment(.center)

                    HStack(spacing: 0) {
                        ForEach(["lbs", "kg"], id: \.self) { u in
                            Button(action: { unit = u }) {
                                Text(u).font(.system(size: 13, weight: .bold))
                                    .foregroundColor(unit == u ? .black : .white.opacity(0.5))
                                    .padding(.horizontal, 24).padding(.vertical, 8)
                                    .background(unit == u ? Color.tmGold : Color.clear)
                            }
                        }
                    }
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.08)))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    TextField("Note (optional)", text: $note)
                        .foregroundColor(.white).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                    Button(action: saveWeight) {
                        Text(isSaving ? "Saving..." : "SAVE")
                            .font(.system(size: 15, weight: .heavy))
                            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                    }
                    .disabled(Double(weightText) == nil || isSaving)
                }
                .padding(24)
            }
            .navigationTitle("Log Weight").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingLog = false }.foregroundColor(.tmGold)
                }
            }
        }
    }

    private func saveWeight() {
        guard let w = Double(weightText) else { return }
        // Handle both auth_id and row_id
        guard let uid = UUID(uuidString: clientId) else { return }
        isSaving = true
        let entry = SBWeightEntryRow(
            id: UUID(), clientId: uid, trainerId: nil,
            weight: w, unit: unit, note: note, loggedAt: Date()
        )
        Task {
            do {
                try await SBWeightStore.shared.log(entry)
                await MainActor.run {
                    isSaving   = false
                    showingLog = false
                    weightText = ""
                    note       = ""
                }
            } catch {
                print("❌ Weight save error: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }

    private func weightStat(_ label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(0.5).foregroundColor(.white.opacity(0.4))
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value).font(.system(size: 22, weight: .black)).foregroundColor(color)
                if !unit.isEmpty {
                    Text(unit).font(.system(size: 11)).foregroundColor(color.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - TrainerClientMealPlanSummary

struct TrainerClientMealPlanSummary: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var planStore = SBMealPlanStore.shared
    @ObservedObject private var logStore  = NutritionLogRequestStore.shared
    @State private var showingPlans       = false
    @State private var showingBuilder     = false
    @State private var showingLogViewer   = false
    @State private var showingTemplates   = false
    @State private var isSendingRequest   = false
    @State private var requestSent        = false
    @State private var logEntries: [MealLogEntry] = []
    @State private var selectedPlan: MealPlanRow? = nil

    private var plans: [MealPlanRow] {
        planStore.mealPlans.filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() }
    }
    private var active: MealPlanRow? { plans.first(where: { $0.isActive }) ?? plans.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "fork.knife").foregroundColor(.tmGold).font(.caption)
                    Text("NUTRITION")
                        .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: sendLogRequest) {
                        HStack(spacing: 4) {
                            if isSendingRequest {
                                ProgressView().scaleEffect(0.7).tint(.tmGold)
                            } else {
                                Image(systemName: requestSent ? "checkmark.circle.fill" : "doc.text.magnifyingglass").font(.caption)
                                Text(requestSent ? "Requested" : "Request Log").font(.caption).fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(requestSent ? .green : .tmGold)
                    }
                    .disabled(isSendingRequest || requestSent)

                    Button(action: { showingBuilder = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Assign").font(.caption).fontWeight(.semibold)
                        }.foregroundColor(.tmGold)
                    }
                    Button(action: { showingTemplates = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.down").font(.caption)
                            Text("Templates").font(.caption).fontWeight(.semibold)
                        }.foregroundColor(.tmGold)
                    }
                    if !plans.isEmpty {
                        Button("View All") { showingPlans = true }
                            .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }
                }
            }

            if !logEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("RECENT MEAL LOG").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        Spacer()
                        Button("See All") { showingLogViewer = true }.font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }
                    ForEach(logEntries.prefix(3)) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.mealName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                Text(entry.mealType).font(.caption).foregroundColor(.tmGold)
                            }
                            Spacer()
                            Text("\(entry.calories) cal").font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                        }
                        .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            }

            if plans.isEmpty {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife").font(.title3).foregroundColor(.tmGold.opacity(0.4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No meal plan assigned").font(.subheadline).fontWeight(.semibold).foregroundColor(.white.opacity(0.5))
                            Text("Tap to build and assign a nutrition plan").font(.caption).foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold.opacity(0.4))
                    }
                    .padding(14)
                    // placeholder to match structure
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
                }
                .buttonStyle(.plain)
            } else {
                // Show all plans as tappable cards
                VStack(spacing: 10) {
                    ForEach(plans) { plan in
                        Button(action: { selectedPlan = plan }) {
                            SBMealPlanClientCard(plan: plan)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
        .onAppear {
            guard let uuid = UUID(uuidString: clientId) else { return }
            Task {
                try? await planStore.fetchForClient(uuid)
                logEntries = await logStore.fetchLogEntries(forClient: clientId)
            }
        }
        .sheet(isPresented: $showingPlans) {
            NavigationView { TrainerClientMealPlansView(trainerId: trainerId, clientId: clientId, clientName: clientName) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationView { MealPlanBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingLogViewer) {
            NavigationView { TrainerMealLogViewer(clientName: clientName, entries: logEntries) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $selectedPlan) { plan in MealPlanDetailSheet(plan: plan) }
        .sheet(isPresented: $showingTemplates) {
            NavigationView {
                TrainerTemplateLibraryView(
                    trainerId: trainerId, clientId: clientId,
                    clientName: clientName, mode: .meal)
            }.tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func sendLogRequest() {
        isSendingRequest = true
        Task {
            let oneSignalId = await NutritionLogRequestStore.fetchClientOneSignalId(clientId: clientId)
            let trainerName = await NutritionLogRequestStore.fetchTrainerName(trainerId: trainerId)
            do {
                try await logStore.requestLog(clientId: clientId, clientOneSignalId: oneSignalId, trainerName: trainerName)
            } catch { print("❌ Nutrition log request failed: \(error)") }
            await MainActor.run { isSendingRequest = false; requestSent = true }
        }
    }
}

// MARK: - Trainer Meal Log Viewer

struct TrainerMealLogViewer: View {
    let clientName: String
    let entries:    [MealLogEntry]
    @Environment(\.dismiss) var dismiss

    private var grouped: [(String, [MealLogEntry])] {
        let fmt = DateFormatter(); fmt.dateStyle = .medium
        let dict = Dictionary(grouping: entries) { fmt.string(from: $0.loggedAt ?? Date()) }
        return dict.sorted { $0.key > $1.key }
    }
    private var totalCalories: Int    { entries.reduce(0) { $0 + $1.calories } }
    private var totalProtein:  Double { entries.reduce(0.0) { $0 + $1.proteinG } }
    private var dayCount:      Int    { max(1, grouped.count) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if entries.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "fork.knife").font(.system(size: 48)).foregroundColor(.white.opacity(0.1)).padding(.top, 60)
                            Text("\(clientName) hasn't logged any meals yet.").font(.subheadline).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                        }.frame(maxWidth: .infinity)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3-DAY SUMMARY").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            HStack(spacing: 0) {
                                summaryCell("\(totalCalories / dayCount)", "avg cal/day", .tmGold)
                                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                                summaryCell(String(format: "%.0fg", totalProtein / Double(dayCount)), "avg protein", .red)
                                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                                summaryCell("\(entries.count)", "total meals", .white)
                            }
                            .padding(.vertical, 12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                        }
                        ForEach(grouped, id: \.0) { day, dayEntries in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(day).font(.system(size: 12, weight: .bold)).foregroundColor(.tmGold)
                                ForEach(dayEntries) { entry in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(entry.mealName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                                Text(entry.mealType).font(.caption).foregroundColor(.tmGold)
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(entry.calories) cal").font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                                                Text(String(format: "P:%.0fg  C:%.0fg  F:%.0fg", entry.proteinG, entry.carbsG, entry.fatG))
                                                    .font(.caption2).foregroundColor(.white.opacity(0.35))
                                            }
                                        }
                                        if !entry.rawText.isEmpty {
                                            Text("\u{201C}\(entry.rawText)\u{201D}").font(.caption2).foregroundColor(.white.opacity(0.3)).italic()
                                        }
                                    }
                                    .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                                }
                                HStack { Spacer(); Text("Day total: \(dayEntries.reduce(0) { $0 + $1.calories }) cal").font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold.opacity(0.7)) }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("\(clientName)'s Meal Log").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(action: { dismiss() }) { HStack(spacing: 4) { Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back") }.foregroundColor(.tmGold) } } }
    }

    private func summaryCell(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35))
        }.frame(maxWidth: .infinity)
    }
}



// MARK: - TrainerClientWorkoutSummary

struct TrainerClientWorkoutSummary: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBWorkoutStore.shared
    @State private var showingBuilder     = false
    @State private var showingTemplates   = false
    @State private var selectedWorkout: WorkoutRow? = nil
    @State private var expandedProgram: String? = nil

    private var workouts: [WorkoutRow] {
        store.workouts
            .filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() }
            .sorted(by: { ($0.dayNumber ?? 0) < ($1.dayNumber ?? 0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill").font(.caption).foregroundColor(.tmGold)
                    Text("WORKOUTS")
                        .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill").font(.caption)
                        Text("Assign Program").font(.caption).fontWeight(.semibold)
                    }.foregroundColor(.tmGold)
                }
                Button(action: { showingTemplates = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down").font(.caption)
                        Text("Templates").font(.caption).fontWeight(.semibold)
                    }.foregroundColor(.tmGold)
                }
            }

            if workouts.isEmpty {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell.fill").font(.title3).foregroundColor(.tmGold.opacity(0.4))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No workouts assigned").font(.subheadline).fontWeight(.semibold).foregroundColor(.white.opacity(0.5))
                            Text("Tap to build a weekly program").font(.caption).foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold.opacity(0.4))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
                }.buttonStyle(.plain)
            } else {
                VStack(spacing: 10) {
                    let cal = Calendar.current
                    let grouped = Dictionary(grouping: workouts) { w -> String in
                        guard let date = w.createdAt else { return "unknown" }
                        let c = cal.dateComponents([.year,.month,.day,.hour,.minute], from: date)
                        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)-\(c.hour ?? 0)-\(c.minute ?? 0)"
                    }
                    let programs = grouped
                        .map { key, days in (key, days.sorted(by: { ($0.dayNumber ?? 0) < ($1.dayNumber ?? 0) })) }
                        .sorted { $0.1.first?.createdAt ?? .distantPast > $1.1.first?.createdAt ?? .distantPast }
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
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                WorkoutBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout, onMarkComplete: {})
        }
    }
}


// MARK: - RecentMessagesSection

struct RecentMessagesSection: View {
    let messages:  [VideoMessage]
    let viewModel: VideoMessageViewModel
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill").font(.caption).foregroundColor(.tmGold)
                    Text("RECENT MESSAGES")
                        .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                if !messages.isEmpty {
                    Button("View All", action: onViewAll)
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }

            if messages.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "video").foregroundColor(.white.opacity(0.2))
                    Text("No video messages yet").font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
            } else {
                VStack(spacing: 8) {
                    ForEach(messages.prefix(3)) { msg in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).fill(Color.tmGold.opacity(0.15)).frame(width: 40, height: 40)
                                Image(systemName: "play.fill").font(.system(size: 14)).foregroundColor(.tmGold)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(msg.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                Text(msg.message).font(.caption).foregroundColor(.white.opacity(0.45)).lineLimit(1)
                            }
                            Spacer()
                            if !msg.isViewed {
                                Circle().fill(Color.tmGold).frame(width: 8, height: 8)
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            }
        }
    }
}

// MARK: - TrainerAllCheckInsForClientView

struct TrainerAllCheckInsForClientView: View {
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBCheckInStore.shared

    private var checkIns: [CheckInRow] { store.checkIns(forClient: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "camera.fill").font(.caption).foregroundColor(.tmGold)
                Text("CHECK-INS").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                Spacer()
                Text("\(checkIns.count) total").font(.caption).foregroundColor(.white.opacity(0.4))
            }
            if checkIns.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "camera").foregroundColor(.white.opacity(0.2))
                    Text("No check-ins submitted yet").font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(12).background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
            } else {
                ForEach(checkIns.prefix(5)) { ci in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))
                            .frame(width: 48, height: 48)
                            .overlay(Image(systemName: "camera").foregroundColor(.white.opacity(0.3)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(ci.formattedDate).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text(ci.formattedWeight).font(.caption).foregroundColor(.tmGold)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
                    }
                    .padding(10).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
    }
}

// MARK: - ClientCheckInHistoryView

struct ClientCheckInHistoryView: View {
    let clientId: String
    @ObservedObject private var store = SBCheckInStore.shared
    @Environment(\.dismiss) var dismiss

    private var items: [CheckInRow] {
        store.checkIns.filter {
            $0.clientId.uuidString.uppercased() == clientId.uppercased()
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if items.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "camera.viewfinder").font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No check-ins yet").font(.title3).foregroundColor(.white.opacity(0.4))
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(items) { ci in
                            SBCheckInHistoryRow(checkIn: ci)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("My Check-Ins").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button(action: { dismiss() }) { HStack(spacing: 4) { Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back") }.foregroundColor(.tmGold) } } }
        .onAppear {
            guard let uuid = UUID(uuidString: clientId) else { return }
            Task { try? await store.fetchForClient(uuid) }
        }
    }
}

// MARK: - SBCheckInHistoryRow

struct SBCheckInHistoryRow: View {
    let checkIn: CheckInRow
    var body: some View {
        HStack(spacing: 12) {
            // Photo thumbnail
            if let url = checkIn.photoUrls.first.flatMap({ URL(string: $0) }) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                        .frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.15))
                        .frame(width: 50, height: 50)
                        .overlay(Image(systemName: "camera.fill").foregroundColor(.purple))
                }
            } else {
                RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.15))
                    .frame(width: 50, height: 50)
                    .overlay(Image(systemName: "camera.fill").foregroundColor(.purple))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text((checkIn.checkedInAt ?? Date()).formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                let count = checkIn.photoUrls.count
                Text("\(count) photo\(count == 1 ? "" : "s")")
                    .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - ClientSubmitCheckInView

struct ClientSubmitCheckInView: View {
    let clientId:   String
    let clientName: String
    let trainerId:  String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = SBCheckInStore.shared

    @State private var frontItem:  PhotosPickerItem?
    @State private var rearItem:   PhotosPickerItem?
    @State private var rightItem:  PhotosPickerItem?
    @State private var leftItem:   PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var rearImage:  UIImage?
    @State private var rightImage: UIImage?
    @State private var leftImage:  UIImage?
    @State private var weightText  = ""
    @State private var unit        = "lbs"
    @State private var notes       = ""
    @State private var isSaving    = false
    @State private var showSuccess = false

    private var canSubmit: Bool { Double(weightText) != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        photoCell("Front", item: $frontItem, image: $frontImage)
                        photoCell("Rear",  item: $rearItem,  image: $rearImage)
                        photoCell("Right", item: $rightItem, image: $rightImage)
                        photoCell("Left",  item: $leftItem,  image: $leftImage)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("MORNING WEIGHT").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        HStack {
                            TextField("0.0", text: $weightText).keyboardType(.decimalPad)
                                .font(.system(size: 32, weight: .black)).foregroundColor(.tmGold)
                            Spacer()
                            HStack(spacing: 0) {
                                ForEach(["lbs", "kg"], id: \.self) { u in
                                    Button(action: { unit = u }) {
                                        Text(u).font(.system(size: 12, weight: .bold))
                                            .foregroundColor(unit == u ? .black : .white.opacity(0.5))
                                            .padding(.horizontal, 14).padding(.vertical, 7)
                                            .background(unit == u ? Color.tmGold : Color.clear)
                                    }
                                }
                            }
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.08)))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                        .padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE (OPTIONAL)").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        TextField("How are you feeling?", text: $notes, axis: .vertical)
                            .foregroundColor(.white).lineLimit(3...5).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }
                    Button(action: submit) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) }
                            else { Image(systemName: "paperplane.fill"); Text("SUBMIT CHECK-IN").font(.system(size: 15, weight: .heavy)).tracking(0.5) }
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27).fill(canSubmit ? Color.tmGold : Color.tmGold.opacity(0.3)))
                    }
                    .disabled(!canSubmit || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Weekly Check-In").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.tmGold) } }
        .alert("Check-In Submitted! ✅", isPresented: $showSuccess) { Button("Done") { dismiss() } }
        message: { Text("Your trainer will review your progress soon.") }
    }

    private func photoCell(_ label: String, item: Binding<PhotosPickerItem?>, image: Binding<UIImage?>) -> some View {
        PhotosPicker(selection: item, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(image.wrappedValue != nil ? Color.tmGold.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
                    .frame(height: 140)
                if let img = image.wrappedValue {
                    Image(uiImage: img).resizable().scaledToFill().frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill").font(.title2).foregroundColor(.white.opacity(0.3))
                        Text(label).font(.system(size: 13, weight: .bold)).foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
        .onChange(of: item.wrappedValue) { _, newItem in
            Task { if let data = try? await newItem?.loadTransferable(type: Data.self) { image.wrappedValue = UIImage(data: data) } }
        }
    }

    private func submit() {
        guard let w = Double(weightText), let clientUUID = UUID(uuidString: clientId), let trainerUUID = UUID(uuidString: trainerId) else { return }
        isSaving = true
        var photoData: [Data] = []
        for img in [frontImage, rearImage, rightImage, leftImage].compactMap({ $0 }) {
            if let d = img.jpegData(compressionQuality: 0.7) { photoData.append(d) }
        }
        let row = CheckInRow(id: UUID(), trainerId: trainerUUID, clientId: clientUUID, weight: w, notes: notes, photoUrls: [], energyLevel: nil, sleepHours: nil, waterOz: nil, checkedInAt: Date(), createdAt: Date())
        Task {
            try? await SBCheckInStore.shared.submit(row, photos: photoData)
            await MainActor.run { isSaving = false; showSuccess = true }
        }
    }
}
