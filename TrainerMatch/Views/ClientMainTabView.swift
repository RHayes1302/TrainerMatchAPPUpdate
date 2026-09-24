//
//  ClientMainTabView.swift
//  TrainerMatch
//
//  Bottom navigation for the client side
//

import SwiftUI

struct ClientMainTabView: View {
    let client: ClientRow
    @EnvironmentObject var auth: SupabaseAuthManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab: ClientTab = .home

    enum ClientTab: Int, CaseIterable {
        case home, training, nutrition, progress, find

        var title: String {
            switch self {
            case .home:      return "Home"
            case .training:  return "Training"
            case .nutrition: return "Nutrition"
            case .progress:  return "Progress"
            case .find:      return "Find"
            }
        }

        var icon: String {
            switch self {
            case .home:      return "house"
            case .training:  return "dumbbell"
            case .nutrition: return "fork.knife"
            case .progress:  return "chart.line.uptrend.xyaxis"
            case .find:      return "magnifyingglass"
            }
        }

        var filledIcon: String {
            switch self {
            case .home:      return "house.fill"
            case .training:  return "dumbbell.fill"
            case .nutrition: return "fork.knife"
            case .progress:  return "chart.line.uptrend.xyaxis"
            case .find:      return "magnifyingglass"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch selectedTab {
                case .home:      ClientHomeTab(client: client, selectedTab: $selectedTab)
                case .training:  ClientTrainingTab(client: client)
                case .nutrition: ClientNutritionTab(client: client)
                case .progress:  ClientProgressTab(client: client)
                case .find:      ClientFindTab()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom nav bar
            ClientBottomNavBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Bottom Nav Bar

struct ClientBottomNavBar: View {
    @Binding var selectedTab: ClientMainTabView.ClientTab
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        VStack(spacing: 0) {
            Divider().background(Color.white.opacity(0.1))
            HStack(spacing: 0) {
                ForEach(ClientMainTabView.ClientTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 4) {
                            Image(systemName: selectedTab == tab ? tab.filledIcon : tab.icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == tab ? gold : .white.opacity(0.4))
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .bold : .regular))
                                .foregroundColor(selectedTab == tab ? gold : .white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.black.opacity(0.95))
            .padding(.bottom, 20) // safe area
        }
        .background(Color.black.opacity(0.95))
    }
}

// MARK: - Home Tab

struct ClientHomeTab: View {
    let client: ClientRow
    @Binding var selectedTab: ClientMainTabView.ClientTab
    @EnvironmentObject var auth: SupabaseAuthManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingProfile = false
    @State private var connectedTrainers: [TrainerClientConnection] = []
    @ObservedObject private var sbStore = SBConnectionStore.shared

    private var clientId: String { client.id.uuidString }
    private var connections: [TrainerClientConnection] {
        sbStore.rows
            .filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() &&
                     ($0.status == "active" || $0.status == "accepted") }
            .map { $0.asConnection }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Profile header
                    ClientHomeHeader(client: client, onProfileTap: { showingProfile = true })

                    if connections.isEmpty {
                        noTrainerPrompt
                    } else {
                        if let connection = connections.first {
                            ClientHomeSummaryView(
                                clientName: client.fullName,
                                trainerId: connection.trainerId,
                                selectedTab: $selectedTab
                            )
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingProfile) {
            NavigationView {
                ClientProfileMySpaceView(client: client.toClientProfile())
                    .environmentObject(auth)
                    .environmentObject(authManager)
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
        .onAppear {
            SBConnectionStore.shared.loadForClient(clientId)
        }
    }

    private var noTrainerPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64)).foregroundColor(.tmGold.opacity(0.6))
            Text("Find Your Trainer").font(.title2).fontWeight(.bold).foregroundColor(.white)
            Text("Connect with a certified trainer to unlock your personalized workout and nutrition plans.")
                .font(.subheadline).foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center).padding(.horizontal)
            Button(action: { selectedTab = .find }) {
                Text("FIND A TRAINER")
                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
            }
            .padding(.horizontal, 40)
        }
        .padding(30)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.04)))
        .padding(.horizontal, 20)
    }
}

// MARK: - Home Summary (replaces the old HealthKit ring dashboard)

struct ClientHomeSummaryView: View {
    let clientName: String
    let trainerId: String
    @Binding var selectedTab: ClientMainTabView.ClientTab
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Connected status card
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(gold.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(gold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're connected")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                        Text("Your trainer can see your progress and plans.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))

                // Quick links into the other tabs
                quickLinkRow(
                    icon: "dumbbell.fill",
                    title: "Today's Training",
                    subtitle: "View your workout program",
                    tab: .training
                )
                quickLinkRow(
                    icon: "fork.knife",
                    title: "Nutrition Plan",
                    subtitle: "View your meal plan",
                    tab: .nutrition
                )
                quickLinkRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Progress",
                    subtitle: "Log a check-in or view your history",
                    tab: .progress
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }

    private func quickLinkRow(icon: String, title: String, subtitle: String, tab: ClientMainTabView.ClientTab) -> some View {
        Button(action: { selectedTab = tab }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(gold.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: icon).foregroundColor(gold)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Header with Profile Image

struct ClientHomeHeader: View {
    let client: ClientRow
    let onProfileTap: () -> Void
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,").font(.subheadline).foregroundColor(.white.opacity(0.5))
                Text(client.fullName.components(separatedBy: " ").first ?? client.fullName)
                    .font(.title).fontWeight(.bold).foregroundColor(.white)
            }
            Spacer()
            Button(action: onProfileTap) {
                ZStack {
                    Circle().fill(gold.opacity(0.2)).frame(width: 48, height: 48)
                    if let urlStr = client.profileImageUrl, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            initialsView
                        }
                        .frame(width: 48, height: 48).clipShape(Circle())
                    } else {
                        initialsView
                    }
                }
                .overlay(Circle().stroke(gold, lineWidth: 2))
            }
        }
        .padding(.horizontal, 20).padding(.top, 60).padding(.bottom, 8)
    }

    private var initialsView: some View {
        Text(initials).font(.system(size: 16, weight: .black)).foregroundColor(gold)
    }

    private var initials: String {
        client.fullName.split(separator: " ").prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined().uppercased()
    }
}

// MARK: - Training Tab

struct ClientTrainingTab: View {
    let client: ClientRow
    @ObservedObject private var sbStore = SBConnectionStore.shared
    @ObservedObject private var workoutStore = SBWorkoutStore.shared
    @State private var selectedWorkout: WorkoutRow? = nil

    private var clientId: String { client.id.uuidString }
    private var connection: TrainerClientConnection? {
        sbStore.rows
            .filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() &&
                     ($0.status == "active" || $0.status == "accepted") }
            .map { $0.asConnection }.first
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let conn = connection {
                            ClientWorkoutsSection(
                                clientId: clientId,
                                clientName: client.fullName,
                                trainerId: conn.trainerId,
                                selectedWorkout: $selectedWorkout
                            )
                            .padding(.horizontal, 20)
                        } else {
                            noConnectionView(icon: "dumbbell.fill", message: "Connect with a trainer to receive your workout program.")
                        }
                    }
                    .padding(.top, 20).padding(.bottom, 80)
                }
            }
            .navigationTitle("Training").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(item: $selectedWorkout) { workout in
            WorkoutDetailSheet(workout: workout, onMarkComplete: {})
        }
        .onAppear { SBConnectionStore.shared.loadForClient(clientId) }
    }
}

// MARK: - Nutrition Tab

struct ClientNutritionTab: View {
    let client: ClientRow
    @ObservedObject private var sbStore = SBConnectionStore.shared

    private var clientId: String { client.id.uuidString }
    private var connection: TrainerClientConnection? {
        sbStore.rows
            .filter { $0.clientId.uuidString.uppercased() == clientId.uppercased() &&
                     ($0.status == "active" || $0.status == "accepted") }
            .map { $0.asConnection }.first
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let conn = connection {
                            ClientNutritionSection(
                                clientId: clientId,
                                clientName: client.fullName,
                                trainerId: conn.trainerId,
                                selectedPlan: .constant(nil)
                            )
                            .padding(.horizontal, 20)
                        } else {
                            noConnectionView(icon: "fork.knife", message: "Connect with a trainer to receive your meal plan.")
                        }
                    }
                    .padding(.top, 20).padding(.bottom, 80)
                }
            }
            .navigationTitle("Nutrition").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { SBConnectionStore.shared.loadForClient(clientId) }
    }
}

// MARK: - Progress Tab

struct ClientProgressTab: View {
    let client: ClientRow
    @ObservedObject private var sbStore = SBConnectionStore.shared
    @State private var showingSubmitCheckIn = false
    @State private var isLoading = true

    private var clientId: String { client.id.uuidString }
    private var authId: String { client.authId?.uuidString ?? clientId }

    private var connection: TrainerClientConnection? {
        // Try by row id first, then auth_id
        sbStore.rows
            .filter {
                ($0.clientId.uuidString.uppercased() == clientId.uppercased() ||
                 $0.clientId.uuidString.uppercased() == authId.uppercased()) &&
                ($0.status == "active" || $0.status == "accepted")
            }
            .map { $0.asConnection }.first
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Submit check-in button - always show
                        Button(action: { showingSubmitCheckIn = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "camera.fill").font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Submit Weekly Check-In")
                                        .font(.system(size: 15, weight: .bold))
                                    Text("Send progress photos to your trainer")
                                        .font(.caption).opacity(0.7)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }
                            .foregroundColor(.black).padding(16)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.tmGold))
                        }
                        .buttonStyle(.plain).padding(.horizontal, 20)

                        // Weight tracking
                        TrainerClientWeightSummary(clientId: authId, clientName: client.fullName)
                            .padding(.horizontal, 20)

                        // Check-in history
                        ClientCheckInHistoryView(clientId: authId)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20).padding(.bottom, 100)
                }
            }
            .navigationTitle("Progress").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear { SBConnectionStore.shared.loadForClient(authId) }
        .sheet(isPresented: $showingSubmitCheckIn) {
            NavigationView {
                ClientSubmitCheckInView(
                    clientId:   authId,
                    clientName: client.fullName,
                    trainerId:  connection?.trainerId ?? ""
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Find Tab

struct ClientFindTab: View {
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        NearbyTrainersView()
                    }
                    .padding(.bottom, 80)
                }
            }
            .navigationTitle("Find a Trainer").navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Helper

func noConnectionView(icon: String, message: String) -> some View {
    VStack(spacing: 16) {
        Image(systemName: icon).font(.system(size: 48))
            .foregroundColor(.tmGold.opacity(0.3))
        Text(message).font(.subheadline).foregroundColor(.white.opacity(0.4))
            .multilineTextAlignment(.center)
            .padding(.leading, 40).padding(.trailing, 40)
    }
    .frame(maxWidth: .infinity).padding(.top, 60).padding(.bottom, 60)
}
