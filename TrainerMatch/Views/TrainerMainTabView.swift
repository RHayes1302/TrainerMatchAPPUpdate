//
//  TrainerMainTabView.swift
//  TrainerMatch
//
//  Bottom navigation for the trainer side
//

import SwiftUI
import Supabase

struct TrainerMainTabView: View {
    let trainer: TrainerRow
    @EnvironmentObject var auth: SupabaseAuthManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: TrainerTab = .clients
    @State private var navigateToPending = false

    enum TrainerTab: Int, CaseIterable {
        case clients, schedule, messages, promote, profile

        var title: String {
            switch self {
            case .clients:  return "Clients"
            case .schedule: return "Schedule"
            case .messages: return "Messages"
            case .promote:  return "Promote"
            case .profile:  return "Profile"
            }
        }

        var icon: String {
            switch self {
            case .clients:  return "person.2"
            case .schedule: return "calendar"
            case .messages: return "message"
            case .promote:  return "star"
            case .profile:  return "person.circle"
            }
        }

        var filledIcon: String {
            switch self {
            case .clients:  return "person.2.fill"
            case .schedule: return "calendar.badge.clock"
            case .messages: return "message.fill"
            case .promote:  return "star.fill"
            case .profile:  return "person.circle.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .clients:
                    NavigationView { TrainerDashboardView() }
                    .navigationViewStyle(StackNavigationViewStyle()).tint(.tmGold)
                case .schedule: TrainerScheduleTab(trainer: trainer)
                case .messages: TrainerMessagesTab(trainer: trainer)
                case .promote:  TrainerPromoteTab(trainer: trainer)
                case .profile:
                    NavigationView {
                        TrainerProfileTabView(trainer: trainer)
                            .environmentObject(auth)
                            .environmentObject(authManager)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .tint(.tmGold)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            TrainerBottomNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
        .task {
            await GymAdManager.shared.fetchActiveAds()
            PushNotificationManager.shared.loginUser(
                userId: trainer.authId?.uuidString ?? trainer.id.uuidString
            )
            SBConnectionStore.shared.loadForTrainer(trainer.id.uuidString)
        }
        .onReceive(NotificationCenter.default.publisher(for: .tmPushNotificationTapped)) { note in
            let action = note.userInfo?["action"] as? String ?? ""
            if action == "pending_requests" { selectedTab = .clients }
        }
    }
}

// MARK: - Trainer Bottom Nav Bar

struct TrainerBottomNavBar: View {
    @Binding var selectedTab: TrainerMainTabView.TrainerTab
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 0) {
                ForEach(TrainerMainTabView.TrainerTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? tab.filledIcon : tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? gold : .white.opacity(0.4))
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundColor(selectedTab == tab ? gold : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.black.opacity(0.95))
            .padding(.bottom, 20)
        }
        .background(Color.black.opacity(0.95))
    }
}


// MARK: - Trainer Client Nav Tab (opens ClientFolderView on tap)

struct TrainerClientNavTab: View {
    let trainer: TrainerRow
    @ObservedObject private var store   = TrainerConnectionStore.shared
    @ObservedObject private var sbStore = SBConnectionStore.shared
    @State private var searchText = ""

    private var trainerId:     String { trainer.id.uuidString }
    private var trainerName:   String { trainer.businessName ?? trainer.fullName }
    private var currentUserId: String { trainer.authId?.uuidString ?? trainer.id.uuidString }

    private var pending: [TrainerRequest] { store.pendingRequests(forTrainer: trainerId) }
    private var activeClients: [TrainerClientConnection] {
        let all = store.activeClients(forTrainer: trainerId)
        if searchText.isEmpty { return all }
        return all.filter { $0.clientName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats strip
                        HStack(spacing: 0) {
                            statPill("\(store.activeClients(forTrainer: trainerId).count)", label: "Active Clients", icon: "person.2.fill")
                            Divider().background(Color.white.opacity(0.1)).frame(height: 40)
                            statPill("\(pending.count)", label: "Pending", icon: "clock.fill")
                        }
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1)))

                        // Search
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
                            TextField("Search clients...", text: $searchText).foregroundColor(.white)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))

                        // Pending requests
                        if !pending.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("PENDING REQUESTS", icon: "clock.fill", count: pending.count)
                                ForEach(pending) { req in
                                    PendingRequestCard(request: req, trainerName: trainerName)
                                }
                            }
                        }

                        // Active clients with NavigationLink to ClientFolderView
                        if !activeClients.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                sectionLabel("MY CLIENTS", icon: "person.2.fill", count: activeClients.count)
                                ForEach(activeClients) { conn in
                                    NavigationLink(destination:
                                        ClientFolderView(
                                            trainerViewModel: TrainerViewModel(),
                                            client: Client(
                                                id: conn.clientId,
                                                name: conn.clientName,
                                                email: "",
                                                dateJoined: Date(),
                                                trainerId: trainerId
                                            )
                                        )
                                    ) {
                                        TrainerClientFolderCard(connection: conn)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if activeClients.isEmpty && pending.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.3))
                                Text("No clients yet").font(.title3).foregroundColor(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 60)
                        }
                    }
                    .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 80)
                }
            }
            .navigationTitle("My Clients").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { SBConnectionStore.shared.loadForTrainer(trainerId) }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tint(.tmGold)
    }

    private func statPill(_ value: String, label: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.system(size: 20, weight: .black)).foregroundColor(.white)
                Text(label).font(.caption2).foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity).padding(.horizontal, 16)
    }

    private func sectionLabel(_ title: String, icon: String, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            Text(title).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            Spacer()
            Text("\(count)").font(.caption).foregroundColor(.white.opacity(0.4))
        }
    }
}


// MARK: - Trainer Client Folder Card

struct TrainerClientFolderCard: View {
    let connection: TrainerClientConnection
    @ObservedObject private var parqStore = PARQStore.shared
    @ObservedObject private var sbStore   = SBConnectionStore.shared
    @State private var profileImageUrl: String? = nil

    private var initials: String {
        connection.clientName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined().uppercased()
    }

    private var parqStatus: String? {
        guard let form = parqStore.latestForm(forClient: connection.clientId) else { return nil }
        return form.status == .completed ? "PAR-Q On File" : nil
    }

    var body: some View {
        HStack(spacing: 14) {
            // Profile photo
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                if let urlStr = profileImageUrl, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                            .frame(width: 52, height: 52).clipShape(Circle())
                    } placeholder: {
                        Text(initials).font(.title3).fontWeight(.bold).foregroundColor(.black)
                    }
                } else {
                    Text(initials).font(.title3).fontWeight(.bold).foregroundColor(.black)
                }
            }

            // Client info
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.clientName)
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                if let parq = parqStatus {
                    Text(parq).font(.caption).foregroundColor(.green)
                } else {
                    Text("No PAR-Q").font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // Folder icon
            Image(systemName: "folder.fill")
                .font(.title3).foregroundColor(.tmGold.opacity(0.7))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)))
        .onAppear { fetchPhoto() }
    }

    private func fetchPhoto() {
        Task {
            struct PhotoRow: Decodable {
                let profileImageUrl: String?
                enum CodingKeys: String, CodingKey { case profileImageUrl = "profile_image_url" }
            }
            // Try by id first, then by auth_id
            var rows: [PhotoRow] = (try? await supabase
                .from("clients").select("profile_image_url")
                .eq("id", value: connection.clientId)
                .execute().value) ?? []
            if rows.isEmpty {
                rows = (try? await supabase
                    .from("clients").select("profile_image_url")
                    .eq("auth_id", value: connection.clientId)
                    .execute().value) ?? []
            }
            if let url = rows.first?.profileImageUrl {
                await MainActor.run { profileImageUrl = url }
            }
        }
    }
}


// MARK: - Trainer Profile Tab

struct TrainerProfileTabView: View {
    let trainer: TrainerRow
    @EnvironmentObject var auth: SupabaseAuthManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSubscription = false
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    // Subscription status
                    Button(action: { showingSubscription = true }) {
                        SubscriptionStatusBadge()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20).padding(.top, 20)

                    // Full trainer profile
                    TrainerProfileMySpaceView(trainer: trainer.toLocalTrainerProfile())
                        .environmentObject(auth)
                        .environmentObject(authManager)
                }
            }
        }
        .navigationTitle("Profile").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingSubscription) {
            NavigationView {
                TrainerSubscriptionView(trainerId: trainer.id.uuidString)
            }
            .tint(gold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Schedule Tab

struct TrainerScheduleTab: View {
    let trainer: TrainerRow

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 60)).foregroundColor(.tmGold.opacity(0.4))
                    Text("Schedule").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Upcoming sessions and video calls will appear here.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            }
            .navigationTitle("Schedule").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Messages Tab

struct TrainerMessagesTab: View {
    let trainer: TrainerRow
    @ObservedObject private var sbStore = SBConnectionStore.shared

    private var clients: [TrainerClientConnection] {
        sbStore.rows
            .filter { $0.trainerId.uuidString.uppercased() == trainer.id.uuidString.uppercased() &&
                     ($0.status == "active" || $0.status == "accepted") }
            .map { $0.asConnection }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                if clients.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 60)).foregroundColor(.tmGold.opacity(0.3))
                        Text("No messages yet").font(.title3).foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(clients, id: \.id) { connection in
                                NavigationLink(destination:
                                    SupabaseChatView(
                                        trainerId:       UUID(uuidString: trainer.id.uuidString) ?? UUID(),
                                        clientId:        UUID(uuidString: connection.clientId) ?? UUID(),
                                        currentUserId:   UUID(uuidString: trainer.id.uuidString) ?? UUID(),
                                        currentUserName: trainer.fullName,
                                        otherPersonName: connection.clientName
                                    )
                                ) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 46, height: 46)
                                            Text(connection.clientName.prefix(2).uppercased())
                                                .font(.system(size: 14, weight: .black)).foregroundColor(.tmGold)
                                        }
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(connection.clientName)
                                                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                            Text("Tap to message").font(.caption).foregroundColor(.white.opacity(0.4))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
                                    }
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20).padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Messages").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tint(.tmGold)
    }
}

// MARK: - Promote Tab

struct TrainerPromoteTab: View {
    let trainer: TrainerRow

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Gym Ads section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("GYM ADS").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            NavigationLink(destination:
                                ZStack {
                                    Color.black.ignoresSafeArea()
                                    Text("Gym Ads Coming Soon").foregroundColor(.white)
                                }
                            ) {
                                promoteCard(icon: "building.2.fill", title: "Manage Gym Ads",
                                           subtitle: "Advertise at local gyms to reach new clients")
                            }.buttonStyle(.plain)
                        }

                        // Success Stories
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONTENT").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            NavigationLink(destination: SuccessStoriesView()) {
                                promoteCard(icon: "star.fill", title: "Success Stories",
                                           subtitle: "Share client transformations to attract new clients")
                            }.buttonStyle(.plain)
                        }

                        // Profile stats placeholder
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PROFILE STATS").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            VStack(spacing: 12) {
                                HStack {
                                    statBox(value: "—", label: "Profile Views")
                                    statBox(value: "—", label: "Requests")
                                    statBox(value: "—", label: "Connections")
                                }
                            }
                        }
                    }
                    .padding(20).padding(.bottom, 80)
                }
            }
            .navigationTitle("Promote").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .tint(.tmGold)
    }

    private func promoteCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.tmGold.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.system(size: 18)).foregroundColor(.tmGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.45))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)))
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}
