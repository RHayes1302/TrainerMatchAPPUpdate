//
//  TrainedDashBoardView.swift
//  TrainerMatch
//
//  Fully Supabase-backed trainer client dashboard.
//  Fetches real ClientRow data and bridges to ClientFolderView.
//

import SwiftUI

// MARK: - ClientRow → Client bridge

extension ClientRow {
    /// Converts a Supabase ClientRow into the local Client model
    func toLocalClient(trainerId: String = "") -> Client {
        Client(
            id:          id.uuidString,
            name:        fullName,
            email:       email,
            dateJoined:  createdAt ?? Date(),
            trainerId:   trainerId,
            fitnessGoals: fitnessGoals.compactMap { FitnessGoal(rawValue: $0) }
        )
    }
}

// MARK: - Main Dashboard

struct TrainerDashboardView: View {

    @ObservedObject private var sbStore  = SBConnectionStore.shared
    @ObservedObject private var auth     = SupabaseAuthManager.shared
    @StateObject   private var trainerVM = TrainerViewModel()

    @State private var clients:      [ClientRow] = []
    @State private var isLoading     = true
    @State private var searchText    = ""
    @State private var sortOption:   ClientSortOption = .recentlyAdded

    private var trainerId: String {
        auth.currentTrainer?.id.uuidString ?? ""
    }

    private var filtered: [ClientRow] {
        let base = searchText.isEmpty ? clients :
            clients.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText) ||
                $0.city.localizedCaseInsensitiveContains(searchText)
            }
        return base.sorted {
            switch sortOption {
            case .nameAscending:  return $0.fullName < $1.fullName
            case .nameDescending: return $0.fullName > $1.fullName
            case .recentlyAdded:  return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            case .mostActive:     return $0.fullName < $1.fullName // fallback
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                dashboardHeader

                // ── Stats ──
                TrainerStatsHeaderView(clientCount: clients.count)
                    .padding(.horizontal, 16).padding(.top, 12)

                // ── Search + Sort ──
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray).font(.system(size: 15))
                        TextField("Search clients...", text: $searchText)
                            .font(.system(size: 15))
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)

                    HStack {
                        Text("Sort by:").font(.subheadline).foregroundColor(.gray)
                        Picker("Sort", selection: $sortOption) {
                            ForEach(ClientSortOption.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.menu).tint(.tmGold)
                        Spacer()
                        Text("\(filtered.count) client\(filtered.count == 1 ? "" : "s")")
                            .font(.caption).foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 12)

                // ── Client List ──
                if isLoading {
                    Spacer()
                    VStack(spacing: 14) {
                        ProgressView().tint(.tmGold).scaleEffect(1.3)
                        Text("Loading clients...").font(.subheadline).foregroundColor(.gray)
                    }
                    Spacer()
                } else if filtered.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { clientRow in
                                NavigationLink(destination:
                                    ClientFolderView(
                                        trainerViewModel: trainerVM,
                                        client: clientRow.toLocalClient(trainerId: trainerId)
                                    )
                                ) {
                                    SBClientCard(clientRow: clientRow, trainerId: trainerId)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("My Clients")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await loadClients() } }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.tmGold)
                }
            }
        }
        .task { await loadClients() }
    }

    // MARK: - Header

    private var dashboardHeader: some View {
        HStack(spacing: 12) {
            TrainerMatchLogo(size: .small)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nearby Trainers")
                    .font(.system(size: 16, weight: .heavy)).italic()
                    .foregroundColor(.white)
                Text("Find Your Perfect Trainer")
                    .font(.caption2).foregroundColor(.tmGold)
            }
            Spacer()
            if let trainer = auth.currentTrainer {
                Text("Hi, \(trainer.firstName)")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color.black)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.sequence.fill")
                .font(.system(size: 52)).foregroundColor(.tmGold.opacity(0.25))
            Text(searchText.isEmpty ? "No Clients Yet" : "No Results")
                .font(.title3.bold()).foregroundColor(.primary)
            Text(searchText.isEmpty
                 ? "When clients select you and you accept, they'll appear here."
                 : "Try a different search term.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Load

    private func loadClients() async {
        isLoading = true
        // Load Supabase connection rows
        sbStore.loadForTrainer(trainerId)
        // Fetch full client profiles
        if let rows = try? await auth.fetchTrainerClients() {
            await MainActor.run {
                clients  = rows
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Supabase Client Card

struct SBClientCard: View {
    let clientRow: ClientRow
    let trainerId: String

    @ObservedObject private var parqStore    = PARQStore.shared
    @ObservedObject private var checkStore   = SBCheckInStore.shared
    @ObservedObject private var workoutStore = WorkoutStore.shared

    @State private var profileImage: UIImage?

    private var clientId: String { clientRow.id.uuidString }
    private var initials: String {
        [clientRow.firstName.prefix(1), clientRow.lastName.prefix(1)]
            .map(String.init).joined().uppercased()
    }

    private var parqStatus: (label: String, color: Color) {
        if let f = parqStore.latestForm(forClient: clientId), f.isSubmitted {
            return ("PAR-Q \(f.riskLevel.label)", f.riskLevel.color)
        }
        if parqStore.pendingForm(forClient: clientId, trainerId: trainerId) != nil {
            return ("PAR-Q Pending", .tmGold)
        }
        return ("No PAR-Q", .gray)
    }

    private var checkInCount: Int {
        checkStore.checkIns.filter { $0.clientId.uuidString == clientId }.count
    }
    private var workoutCount: Int { workoutStore.workouts(forClient: clientId).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row — avatar + name + badge
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.tmGold, .tmGoldDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 52, height: 52).clipShape(Circle())
                    } else {
                        Text(initials)
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.black)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(clientRow.fullName)
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.primary)
                    Text("\(clientRow.city), \(clientRow.state) · \(clientRow.fitnessLevel)")
                        .font(.caption).foregroundColor(.secondary)

                    // PAR-Q badge
                    Text(parqStatus.label)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(parqStatus.color)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Capsule().fill(parqStatus.color.opacity(0.12)))
                }

                Spacer()

                Image(systemName: "folder.fill")
                    .font(.system(size: 22)).foregroundColor(.tmGold.opacity(0.4))
            }
            .padding(16)

            Divider().padding(.horizontal, 16)

            // Stats row
            HStack(spacing: 0) {
                cardStat(icon: "camera.fill",    value: "\(checkInCount)", label: "Check-Ins",  color: .purple)
                Divider().frame(height: 36)
                cardStat(icon: "dumbbell.fill",  value: "\(workoutCount)", label: "Workouts",   color: .tmGold)
                Divider().frame(height: 36)
                cardStat(icon: "heart.text.square.fill",
                         value: parqStatus.label == "No PAR-Q" ? "None" : "On File",
                         label: "Health Form", color: parqStatus.color)
            }
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        .onAppear { loadPhoto() }
    }

    private func cardStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2).foregroundColor(color)
                Text(value).font(.system(size: 13, weight: .bold)).foregroundColor(.primary)
            }
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func loadPhoto() {
        guard let urlStr = clientRow.profileImageUrl,
              let url = URL(string: urlStr) else { return }
        Task {
            if let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                await MainActor.run { profileImage = img }
            }
        }
    }
}

// MARK: - Trainer Stats Header
struct TrainerStatsHeaderView: View {
    let clientCount: Int

    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Clients").font(.subheadline).foregroundColor(.gray)
                Text("\(clientCount)")
                    .font(.system(size: 32, weight: .bold)).foregroundColor(.tmGold)
            }
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.3))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

// MARK: - Client Card View (kept for any legacy usage)
struct ClientCardView: View {
    let client: Client
    let stats: ClientStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.tmGold, .tmGoldDark],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                    .overlay(Text(client.name.prefix(1))
                        .font(.title2).fontWeight(.bold).foregroundColor(.white))
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name).font(.headline).foregroundColor(.primary)
                    Text(client.email).font(.caption).foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray).font(.caption)
            }
            Divider()
            HStack(spacing: 16) {
                StatBadge(icon: "figure.walk",          value: "\(client.dailySteps)",        label: "steps",  color: .green)
                StatBadge(icon: "flame.fill",            value: "\(stats.activeWorkouts)",     label: "active", color: .orange)
                StatBadge(icon: "checkmark.circle.fill", value: "\(Int(stats.completionRate))%", label: "done", color: .blue)
            }
            HStack {
                Circle().fill(activityColor).frame(width: 8, height: 8)
                Text(client.activityStatus).font(.caption).foregroundColor(.gray)
                Spacer()
                if let lastSync = client.lastSyncDate {
                    Text("Updated \(timeAgo(from: lastSync))").font(.caption2).foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var activityColor: Color {
        switch client.activityStatus {
        case "Very Active":       return .green
        case "Active":            return .blue
        case "Moderately Active": return .yellow
        case "Lightly Active":    return .orange
        default:                  return .red
        }
    }

    private func timeAgo(from date: Date) -> String {
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        if hours < 1  { return "just now" }
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(value).font(.caption).fontWeight(.semibold)
            }
            .foregroundColor(color)
            Text(label).font(.caption2).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview { TrainerDashboardView() }
