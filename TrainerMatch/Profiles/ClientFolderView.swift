//
//  ClientFolderView.swift
//  TrainerMatch
//
//  Per-client folder — replaces EnhancedClientDetailView as the navigation destination.
//  Tabs: Overview · Progress · Health · Workouts · Nutrition · Check-Ins · Files
//

import SwiftUI
import QuickLook

struct ClientFolderView: View {
    @ObservedObject var trainerViewModel: TrainerViewModel
    let client: Client

    @ObservedObject private var authManager  = AuthManager.shared
    @ObservedObject private var parqStore    = PARQStore.shared
    @ObservedObject private var checkStore   = SBCheckInStore.shared
    @ObservedObject private var workoutStore = WorkoutStore.shared
    @ObservedObject private var mealStore    = MealPlanStore.shared
    @ObservedObject private var weightStore  = WeightTrackingStore.shared
    @ObservedObject private var fileStore    = TrainerFileStore.shared
    @ObservedObject private var sbConn       = SBConnectionStore.shared

    @State private var selectedTab: FolderTab = .overview
    @State private var showingChat = false   // ✅ NEW

    private var trainerId: String {
        SupabaseAuthManager.shared.currentTrainer?.id.uuidString
            ?? authManager.currentTrainerProfile?.id ?? ""
    }

    // ✅ Resolve the Supabase UUID for this client
    private var clientUUID: UUID { UUID(uuidString: client.id) ?? UUID() }
    private var trainerUUID: UUID { UUID(uuidString: trainerId) ?? UUID() }
    private var trainerName: String {
        SupabaseAuthManager.shared.currentTrainer?.fullName
            ?? authManager.currentTrainerProfile?.fullName ?? "Trainer"
    }

    enum FolderTab: String, CaseIterable {
        case overview   = "Overview"
        case progress   = "Progress"
        case health     = "Health"
        case workouts   = "Workouts"
        case nutrition  = "Nutrition"
        case checkIns   = "Check-Ins"
        case files      = "Files"

        var icon: String {
            switch self {
            case .overview:   return "person.fill"
            case .progress:   return "chart.line.uptrend.xyaxis"
            case .health:     return "heart.text.square.fill"
            case .workouts:   return "dumbbell.fill"
            case .nutrition:  return "fork.knife"
            case .checkIns:   return "camera.fill"
            case .files:      return "folder.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                folderHeader
                tabBar
                Divider().background(Color.white.opacity(0.08))
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) { tabContent }.padding(20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .loadClientData(clientId: client.id, trainerId: trainerId)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: requestPARQ) {
                        Label("Request PAR-Q", systemImage: "heart.text.square")
                    }
                    // ✅ FIXED: now opens the chat
                    Button(action: { showingChat = true }) {
                        Label("Send Message", systemImage: "message")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.tmGold)
                }
            }
        }
        // ✅ Chat sheet
        .sheet(isPresented: $showingChat) {
            NavigationView {
                SupabaseChatView(
                    trainerId:       trainerUUID,
                    clientId:        clientUUID,
                    currentUserId:   trainerUUID,
                    currentUserName: trainerName,
                    otherPersonName: client.name
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    // MARK: – Header

    private var folderHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 60, height: 60)
                    Text(initials(client.name))
                        .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 10) {
                        parqBadge
                        if mealStore.activePlan(forClient: client.id) != nil {
                            statusBadge("Meal Plan", color: .tmGold)
                        }
                        if weightStore.activeGoal(forClient: client.id) != nil {
                            statusBadge("Goal Set", color: .blue)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 2) {
                    Image(systemName: "folder.fill").font(.system(size: 28))
                        .foregroundColor(.tmGold.opacity(0.4))
                    Text("CLIENT FILE").font(.system(size: 7, weight: .black))
                        .tracking(0.5).foregroundColor(.tmGold.opacity(0.4))
                }
            }

            // ✅ VISIBLE MESSAGE BUTTON — always shown in header
            Button(action: { showingChat = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 14))
                    Text("MESSAGE \(client.name.components(separatedBy: " ").first?.uppercased() ?? "CLIENT")")
                        .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 16).padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 22).fill(Color.tmGold)
                    .shadow(color: Color.tmGold.opacity(0.4), radius: 8, y: 3))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black)
    }

    private var parqBadge: some View {
        let latest = parqStore.latestForm(forClient: client.id)
        if let form = latest, form.isSubmitted {
            return AnyView(
                HStack(spacing: 4) {
                    Image(systemName: form.riskLevel.icon).font(.system(size: 9))
                    Text("PAR-Q \(form.riskLevel.label)").font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(form.riskLevel.color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(form.riskLevel.color.opacity(0.12)))
            )
        } else if let _ = parqStore.pendingForm(forClient: client.id, trainerId: trainerId) {
            return AnyView(
                Text("PAR-Q Pending").font(.system(size: 9, weight: .bold))
                    .foregroundColor(.tmGold)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Color.tmGold.opacity(0.12)))
            )
        } else {
            return AnyView(
                Text("No PAR-Q").font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
            )
        }
    }

    private func statusBadge(_ label: String, color: Color) -> some View {
        Text(label).font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
    }

    // MARK: – Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(FolderTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14))
                                .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.35))
                            Text(tab.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.35))
                        }
                        .frame(minWidth: 70).padding(.vertical, 10)
                        .overlay(
                            Rectangle()
                                .fill(selectedTab == tab ? Color.tmGold : Color.clear)
                                .frame(height: 2),
                            alignment: .bottom
                        )
                    }
                    .buttonStyle(.plain)
                    .overlay(badgeFor(tab), alignment: .topTrailing)
                }
            }
            .padding(.horizontal, 10)
        }
        .background(Color.black)
    }

    private func badgeFor(_ tab: FolderTab) -> some View {
        let count: Int = {
            switch tab {
            case .health:
                let f = parqStore.latestForm(forClient: client.id)
                return (f?.status == .completed) ? 1 : 0
            case .checkIns:
                return checkStore.checkIns
                    .filter { $0.clientId.uuidString == client.id && ($0.notes ?? "").isEmpty }.count
            default: return 0
            }
        }()
        return Group {
            if count > 0 {
                Circle().fill(Color.red).frame(width: 8, height: 8).offset(x: -6, y: 4)
            }
        }
    }

    // MARK: – Tab content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:   overviewTab
        case .progress:   progressTab
        case .health:     healthTab
        case .workouts:   workoutsTab
        case .nutrition:  nutritionTab
        case .checkIns:   checkInsTab
        case .files:      filesTab
        }
    }

    private var overviewTab: some View {
        VStack(spacing: 16) {
            quickStatsRow
            TrainerClientWeightSummary(clientId: client.id, clientName: client.name)
            RecentMessagesSection(
                messages: VideoMessageViewModel.shared.getRecentMessages(for: client.id, limit: 3),
                viewModel: VideoMessageViewModel.shared,
                onViewAll: {}
            )
        }
    }

    private var quickStatsRow: some View {
        let checkIns = checkStore.checkIns(forClient: client.id).count
        let workouts = workoutStore.workouts(forClient: client.id).count
        let plans    = mealStore.plans(forClient: client.id).count
        let latestW  = weightStore.latestWeight(forClient: client.id)

        return HStack(spacing: 10) {
            quickStat("\(checkIns)", "Check-Ins",  .purple)
            quickStat("\(workouts)", "Workouts",   .tmGold)
            quickStat("\(plans)",    "Meal Plans", .green)
            if let w = latestW {
                quickStat(String(format: "%.0f", w.weight), "lbs", .blue)
            }
        }
    }

    private func quickStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .black)).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.5)
                .foregroundColor(.white.opacity(0.35))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)))
    }

    private var progressTab: some View {
        TrainerClientProgressDashboard(clientId: client.id, clientName: client.name)
    }

    private var healthTab: some View {
        VStack(spacing: 16) {
            TrainerPARQSummaryCard(
                trainerId: trainerId, clientId: client.id, clientName: client.name)
            TrainerClientWeightSummary(clientId: client.id, clientName: client.name)
        }
    }

    private var workoutsTab: some View {
        TrainerClientWorkoutSummary(
            trainerId: trainerId, clientId: client.id, clientName: client.name)
    }

    private var nutritionTab: some View {
        TrainerClientMealPlanSummary(
            trainerId: trainerId, clientId: client.id, clientName: client.name)
    }

    private var checkInsTab: some View {
        TrainerAllCheckInsForClientView(clientId: client.id, clientName: client.name)
    }

    private var filesTab: some View {
        TrainerSharedFilesSection(
            trainerId: trainerId, clientId: client.id,
            clientName: client.name, onShareFile: {})
    }

    // MARK: Helpers

    private func initials(_ name: String) -> String {
        name.split(separator: " ").prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined().uppercased()
    }

    private func requestPARQ() {
        parqStore.requestForm(
            trainerId: trainerId, clientId: client.id, clientName: client.name)
    }
}
