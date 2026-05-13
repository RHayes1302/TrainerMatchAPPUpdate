//
//  ClientProfile.swift
//  TrainerMatch
//
//  Client profile photos now upload to Supabase Storage.
//

import SwiftUI
import PhotosUI
import QuickLook

struct ClientProfileMySpaceView: View {
    let client: ClientProfile
    @State private var selectedTab: ClientProfileTab = .about
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var profileImage: UIImage?
    @State private var imageSelection: PhotosPickerItem?
    @State private var showingEditProfile = false
    @State private var isUploadingPhoto = false

    enum ClientProfileTab: String {
        case about = "About"
        case goals = "Goals"
        case health = "Health"
        case progress = "Progress"
        case trainers = "Trainers"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    tabNavigation
                    tabContent
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadProfilePhoto()
        }
        .onChange(of: imageSelection) { _, newItem in
            Task { await handlePhotoPick(newItem) }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { authManager.logout(); dismiss() }) {
                    HStack(spacing: 5) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Logout").fontWeight(.semibold)
                    }
                    .foregroundColor(.red.opacity(0.85))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                TMBellButton(
                    recipientId: authManager.currentClientProfile?.id ?? "",
                    role: .client
                )
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingEditProfile = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil.circle.fill")
                        Text("Edit").fontWeight(.semibold)
                    }
                    .foregroundColor(.tmGold)
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            if let saved = authManager.currentClientProfile {
                NavigationView {
                    ClientEditProfileView(profile: saved)
                        .environmentObject(authManager)
                }
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Photo Load/Upload

    private func loadProfilePhoto() {
        // Try Supabase URL first (authoritative source)
        if let urlStr = SupabaseAuthManager.shared.currentClient?.profileImageUrl,
           let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { profileImage = img }
                }
            }
            return
        }
        // Fall back to local cache
        if let userId = authManager.currentClientProfile?.id {
            profileImage = ProfileImageManager.shared.loadImage(
                forKey: ProfileImageManager.profileImageKey(for: userId))
        }
    }

    private func handlePhotoPick(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        let maxDim: CGFloat = 500
        let scale = min(maxDim / uiImage.size.width, maxDim / uiImage.size.height, 1)
        let newSize = CGSize(width: uiImage.size.width * scale,
                             height: uiImage.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: newSize).image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }

        await MainActor.run {
            profileImage = resized
            isUploadingPhoto = true
        }

        if let jpegData = resized.jpegData(compressionQuality: 0.8) {
            do {
                _ = try await SupabaseAuthManager.shared.uploadProfilePhoto(imageData: jpegData)
            } catch {
                print("❌ Client photo upload failed: \(error)")
                // Fall back to local save
                if let userId = authManager.currentClientProfile?.id {
                    ProfileImageManager.shared.saveImage(
                        resized,
                        forKey: ProfileImageManager.profileImageKey(for: userId))
                }
            }
        }

        await MainActor.run { isUploadingPhoto = false }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.tmGold, Color.tmGoldDark],
                    startPoint: .topLeading, endPoint: .bottomTrailing)
                .frame(height: 200)

                HStack {
                    PhotosPicker(selection: $imageSelection, matching: .images) {
                        ZStack {
                            Circle().fill(Color.black).frame(width: 124, height: 124)
                            if let img = profileImage {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 120, height: 120).clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [Color.tmGold, Color.tmGoldDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 120, height: 120)
                                    .overlay(Text(client.name.prefix(1).uppercased())
                                        .font(.system(size: 48, weight: .bold))
                                        .foregroundColor(.black))
                            }
                            if isUploadingPhoto {
                                Circle().fill(Color.black.opacity(0.5)).frame(width: 120, height: 120)
                                ProgressView().tint(.tmGold)
                            } else {
                                Circle().fill(Color.tmGold).frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "camera.fill")
                                        .font(.system(size: 13)).foregroundColor(.black))
                                    .offset(x: 40, y: 40)
                            }
                        }
                        .overlay(Circle().stroke(Color.black, lineWidth: 4).frame(width: 124))
                    }
                    .offset(y: 40).padding(.leading, 20)
                    Spacer()
                }
            }
            .frame(height: 240)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                        HStack(spacing: 6) {
                            Circle().fill(Color.green).frame(width: 10, height: 10)
                            Text("Active Member").font(.caption).foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 50)

                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(.tmGold)
                        Text("\(client.city), \(client.state)")
                            .font(.caption).foregroundColor(.white.opacity(0.8))
                    }
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill").foregroundColor(.tmGold)
                        Text(client.fitnessLevel)
                            .font(.caption).foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20).background(Color.black)
        }
    }

    // MARK: - Tab Navigation

    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach([ClientProfileTab.about, .goals, .health, .progress, .trainers], id: \.self) { tab in
                Button(action: { withAnimation { selectedTab = tab } }) {
                    VStack(spacing: 6) {
                        Image(systemName: iconFor(tab)).font(.caption)
                        Text(tab.rawValue.uppercased()).font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.5))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.tmGold.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.05))
    }

    @ViewBuilder
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .about:    aboutContent
            case .goals:    goalsContent
            case .health:   healthContent
            case .progress: progressContent
            case .trainers: trainersContent
            }
        }
        .padding(20)
    }

    // MARK: - Tab Content

    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About").font(.title2).fontWeight(.bold).foregroundColor(.white)
            ClientInfoRow(label: "Age", value: "\(client.age)")
            ClientInfoRow(label: "Member Since", value: formattedDate(client.memberSince))
            ClientInfoRow(label: "Fitness Level", value: client.fitnessLevel)
            ClientInfoRow(label: "Preferred Training", value: client.preferredServiceType.rawValue)
            if let trainer = client.currentTrainer {
                ClientInfoRow(label: "Current Trainer", value: trainer)
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            NavigationLink(destination: ContentView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2).foregroundColor(.tmGold)
                            Text("Health Tracker").font(.headline).foregroundColor(.white)
                        }
                        Text("Track your nutrition, water, sleep, and workouts")
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.tmGold)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold, lineWidth: 1)))
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            Text("Account").font(.headline).foregroundColor(.tmGold)
            Button(action: { authManager.logout(); dismiss() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title3).foregroundColor(.red)
                    Text("Logout").font(.headline).foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.5), lineWidth: 1)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var goalsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !client.goals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("FITNESS GOALS")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                    ForEach(Array(client.goals.enumerated()), id: \.offset) { _, goal in
                        HStack(spacing: 10) {
                            Image(systemName: "target").foregroundColor(.tmGold)
                            Text(String(describing: goal)).foregroundColor(.white)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                    }
                }
            }
            Divider().background(Color.white.opacity(0.1))
            ClientWeightView(clientId: authManager.currentClientProfile?.id ?? "")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var healthContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Information").font(.title2).fontWeight(.bold).foregroundColor(.white)
            ClientHealthInfoSection(title: "Medical Conditions", content: client.medicalConditions)
            ClientHealthInfoSection(title: "Injuries",           content: client.injuries)
            ClientHealthInfoSection(title: "Allergies",          content: client.allergies)
            ClientHealthInfoSection(title: "Medications",        content: client.medications)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Progress").font(.title2).fontWeight(.bold).foregroundColor(.white)
            NavigationLink(destination: ContentView()) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "chart.xyaxis.line").font(.title2).foregroundColor(.tmGold)
                            Text("Open Health Tracker").font(.headline).foregroundColor(.white)
                        }
                        Text("View detailed daily tracking").font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill").font(.title2).foregroundColor(.tmGold)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold, lineWidth: 2)))
            }
            .padding(.bottom, 10)
            HStack(spacing: 20) {
                ClientProgressCard(icon: "flame.fill",
                                   value: "\(client.currentStreak)",
                                   label: "Day Streak", color: .orange)
                ClientProgressCard(icon: "checkmark.circle.fill",
                                   value: "\(client.workoutsCompleted)",
                                   label: "Total Workouts", color: .green)
            }
            ClientProgressCard(icon: "calendar.badge.clock",
                               value: "\(client.workoutsThisWeek)",
                               label: "This Week", color: .tmGold)
            ClientProgressCard(icon: "photo.fill",
                               value: "\(client.progressPhotoCount)",
                               label: "Progress Photos", color: .blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var trainersContent: some View {
        ClientTrainersView(clientId: authManager.currentClientProfile?.id ?? "")
    }

    private func iconFor(_ tab: ClientProfileTab) -> String {
        switch tab {
        case .about:    return "person.circle.fill"
        case .goals:    return "target"
        case .health:   return "heart.text.square.fill"
        case .progress: return "chart.xyaxis.line"
        case .trainers: return "person.2.fill"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
}

// MARK: - Supporting Views

struct ClientInfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value).foregroundColor(.white).fontWeight(.semibold)
        }
        .padding(.vertical, 8)
    }
}

struct ClientHealthInfoSection: View {
    let title: String
    let content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).foregroundColor(.tmGold)
            Text(content.isEmpty ? "None reported" : content)
                .foregroundColor(.white.opacity(0.8)).padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        }
    }
}

struct ClientProgressCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.system(size: 32, weight: .bold)).foregroundColor(.white)
            Text(label).font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - Client Profile Model

struct ClientProfile {
    let name: String
    let age: Int
    let city: String
    let state: String
    let memberSince: Date
    let currentTrainer: String?
    let preferredServiceType: ServiceType
    let fitnessLevel: String
    let goals: [FitnessGoal]
    let startingWeight: Int
    let currentWeight: Int
    let targetWeight: Int
    let medicalConditions: String
    let injuries: String
    let allergies: String
    let medications: String
    let currentStreak: Int
    let workoutsCompleted: Int
    let workoutsThisWeek: Int
    let progressPhotoCount: Int
    let measurements: ClientMeasurements

    struct ClientMeasurements {
        let chest: Double
        let waist: Double
        let hips: Double
        let arms: Double
    }

    static let sample = ClientProfile(
        name: "Nick Thomas", age: 32,
        city: "Las Vegas", state: "NV",
        memberSince: Date().addingTimeInterval(-90 * 24 * 60 * 60),
        currentTrainer: "Mario Kutz",
        preferredServiceType: .inPerson,
        fitnessLevel: "Intermediate",
        goals: [.weightLoss, .muscleGain, .generalFitness],
        startingWeight: 220, currentWeight: 195, targetWeight: 180,
        medicalConditions: "Mild asthma (well-controlled with inhaler)",
        injuries: "Previous right knee injury (ACL repair 2 years ago).",
        allergies: "Pollen, dust",
        medications: "Albuterol inhaler (as needed)",
        currentStreak: 12, workoutsCompleted: 45, workoutsThisWeek: 3,
        progressPhotoCount: 8,
        measurements: ClientMeasurements(chest: 42.5, waist: 34.0, hips: 38.5, arms: 15.5)
    )
}

#Preview {
    NavigationView {
        ClientProfileMySpaceView(client: ClientProfile.sample)
    }
}

// MARK: - Client Trainers Tab

struct ClientTrainersView: View {
    let clientId: String
    @ObservedObject private var store = TrainerConnectionStore.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var showingSearch = false
    @State private var showingReleaseAlert = false
    @State private var connectionToRelease: TrainerClientConnection?

    private var myTrainers: [TrainerClientConnection] {
        store.myTrainers(forClient: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Trainers").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text(myTrainers.isEmpty
                         ? "No connected trainers yet"
                         : "\(myTrainers.count) active connection\(myTrainers.count == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Button(action: { showingSearch = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("Find Trainer").fontWeight(.semibold)
                    }
                    .font(.system(size: 13)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                }
            }

            if myTrainers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.3)).padding(.top, 30)
                    Text("No Trainer Yet").font(.title3).fontWeight(.bold).foregroundColor(.white)
                    Text("Find a trainer that matches your goals and send them a request.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.45)).multilineTextAlignment(.center)
                    Button(action: { showingSearch = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                            Text("SEARCH TRAINERS").font(.system(size: 14, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            } else {
                ForEach(myTrainers) { conn in
                    ConnectedTrainerCard(
                        connection: conn,
                        clientId: clientId,
                        clientName: authManager.currentClientProfile?.fullName ?? "",
                        onRelease: {
                            connectionToRelease = conn
                            showingReleaseAlert = true
                        }
                    )
                }
                Button(action: { showingSearch = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                        Text("Find Another Trainer").fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption)
                    }
                    .foregroundColor(.tmGold).padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.tmGold.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            SBConnectionStore.shared.loadForClient(clientId)
        }
        .sheet(isPresented: $showingSearch) {
            NavigationView { TrainerSearchView() }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .alert("Release Trainer?", isPresented: $showingReleaseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Release Trainer", role: .destructive) {
                if let conn = connectionToRelease {
                    store.releaseConnection(id: conn.id)
                    TrainerConnectionStore.shared.notifyTrainerOfRelease(
                        trainerId: conn.trainerId,
                        trainerName: conn.trainerName,
                        clientName: conn.clientName)
                }
            }
        } message: {
            if let conn = connectionToRelease {
                Text("You are about to remove \(conn.trainerName) as your trainer.")
            }
        }
    }
}

// MARK: - Connected Trainer Card

struct ConnectedTrainerCard: View {
    let connection: TrainerClientConnection
    let clientId:   String
    let clientName: String
    let onRelease:  () -> Void
    @State private var profileImage: UIImage?
    @State private var showingHub = false
    @ObservedObject private var store = TrainerConnectionStore.shared

    private var unreadCount: Int {
        store.messages(forConnection: connection.id)
            .filter { $0.senderId != clientId && !$0.isRead }.count
    }

    private var videoCount: Int { VideoMessageViewModel.shared.getMessages(for: clientId).count }

    var body: some View {
        Button(action: { showingHub = true }) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 60, height: 60)
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 56, height: 56).clipShape(Circle())
                    } else {
                        Text(connection.trainerName.prefix(1))
                            .font(.title2).fontWeight(.bold).foregroundColor(.black)
                    }
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(connection.trainerName)
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.white)
                    Text("Connected \(timeAgo(connection.connectedAt))")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    HStack(spacing: 10) {
                        miniStat(icon: "bubble.left.fill", value: "\(unreadCount)",
                                 label: "new msgs", highlight: unreadCount > 0)
                        miniStat(icon: "video.fill", value: "\(videoCount)",
                                 label: "videos", highlight: false)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.tmGold)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(unreadCount > 0 ? Color.tmGold.opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: 1)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onAppear {
            // Trainer photos load from Supabase URL via ProfileImageManager local cache
            // Try URL first, fall back to local
            if let urlStr = getTrainerImageUrl(connection.trainerId) {
                Task {
                    if let url = URL(string: urlStr),
                       let data = try? await URLSession.shared.data(from: url).0,
                       let img = UIImage(data: data) {
                        await MainActor.run { profileImage = img }
                    }
                }
            } else {
                profileImage = ProfileImageManager.shared.loadImage(
                    forKey: ProfileImageManager.profileImageKey(for: connection.trainerId))
            }
        }
        .sheet(isPresented: $showingHub) {
            NavigationView {
                TrainerHubView(connection: connection, clientId: clientId,
                               clientName: clientName, onRelease: onRelease)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func getTrainerImageUrl(_ trainerId: String) -> String? {
        // Check if the connected trainer's Supabase row has a profile image URL
        // This is fetched from SBConnectionStore which has trainer info
        return nil // Trainer photo URL lookup happens via the TrainerRow in other views
    }

    private func miniStat(icon: String, value: String, label: String, highlight: Bool) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 9))
                .foregroundColor(highlight ? .tmGold : .white.opacity(0.3))
            Text("\(value) \(label)").font(.system(size: 10))
                .foregroundColor(highlight ? .tmGold : .white.opacity(0.35))
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "yesterday" }
        return "\(days) days ago"
    }
}

// MARK: - Trainer Hub

struct TrainerHubView: View {
    let connection: TrainerClientConnection
    let clientId:   String
    let clientName: String
    let onRelease:  () -> Void
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = TrainerConnectionStore.shared
    @StateObject private var videoVM = VideoMessageViewModel.shared
    @State private var selectedSection: HubSection = .messages
    @State private var showingReleaseAlert = false

    enum HubSection: String, CaseIterable {
        case messages  = "Messages"
        case workouts  = "Workouts"
        case nutrition = "Nutrition"
        case progress  = "Progress"
        case checkIn   = "Check-In"
        case health    = "Health"
        case gyms      = "Gyms"
        case schedule  = "Schedule"
        case videos    = "Videos"
        case files     = "Files"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                trainerHeader
                sectionPicker
                sectionContent
            }
        }
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
                Button(action: { showingReleaseAlert = true }) {
                    Text("Release Trainer").fontWeight(.semibold).foregroundColor(.red.opacity(0.8))
                }
            }
        }
        .alert("Release Trainer?", isPresented: $showingReleaseAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Release Trainer", role: .destructive) {
                TrainerConnectionStore.shared.notifyTrainerOfRelease(
                    trainerId: connection.trainerId,
                    trainerName: connection.trainerName,
                    clientName: connection.clientName)
                onRelease(); dismiss()
            }
        } message: {
            Text("You are about to remove \(connection.trainerName) as your trainer.")
        }
    }

    private var trainerHeader: some View {
        HStack(spacing: 14) {
            TrainerHubPhoto(trainerId: connection.trainerId, name: connection.trainerName, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.trainerName)
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Your Trainer").font(.caption).foregroundColor(.tmGold)
            }
            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 16)
        .background(Color.white.opacity(0.04))
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(HubSection.allCases, id: \.self) { section in
                    Button(action: { selectedSection = section }) {
                        VStack(spacing: 6) {
                            Image(systemName: iconFor(section)).font(.system(size: 16))
                            Text(section.rawValue).font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(selectedSection == section ? .tmGold : .white.opacity(0.4))
                        .frame(width: 80).padding(.vertical, 12)
                        .background(selectedSection == section ? Color.tmGold.opacity(0.08) : Color.clear)
                        .overlay(alignment: .bottom) {
                            if selectedSection == section {
                                Rectangle().fill(Color.tmGold).frame(height: 2)
                            }
                        }
                    }
                }
            }
        }
        .background(Color.white.opacity(0.04))
    }

    @ViewBuilder
    private var sectionContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                switch selectedSection {
                case .messages:
                    HubMessagesSection(connection: connection,
                                       clientId: clientId, clientName: clientName)
                case .videos:
                    HubVideosSection(viewModel: videoVM, clientId: clientId)
                case .workouts:
                    ClientWorkoutsSection(clientId: clientId, clientName: clientName,
                                          trainerId: connection.trainerId)
                case .nutrition:
                    ClientNutritionSection(clientId: clientId, clientName: clientName,
                                           trainerId: connection.trainerId)
                case .progress:
                    ClientProgressSection(clientId: clientId, trainerId: connection.trainerId)
                case .checkIn:
                    HubCheckInSection(clientId: clientId, clientName: clientName,
                                      trainerId: connection.trainerId)
                case .health:
                    ClientPARQHubSection(clientId: clientId, trainerId: connection.trainerId)
                case .gyms:
                    VStack(spacing: 0) {
                        GymAdBannerView().padding(.horizontal).padding(.top, 8)
                        NavigationLink(destination: GymsNearYouView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "building.2.fill").foregroundColor(.tmGold)
                                Text("See All Gyms Near You")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                            .padding(.horizontal).padding(.top, 10)
                        }
                        .buttonStyle(.plain)
                    }
                case .schedule:
                    HubScheduleSection(trainerId: connection.trainerId,
                                       clientId: clientId, clientName: clientName)
                case .files:
                    HubFilesSection(trainerId: connection.trainerId, clientId: clientId)
                }
            }
            .padding(20)
        }
    }

    private func iconFor(_ section: HubSection) -> String {
        switch section {
        case .messages:  return "bubble.left.and.bubble.right.fill"
        case .workouts:  return "dumbbell.fill"
        case .nutrition: return "fork.knife"
        case .progress:  return "chart.line.uptrend.xyaxis"
        case .checkIn:   return "camera.fill"
        case .health:    return "heart.text.square.fill"
        case .gyms:      return "building.2.fill"
        case .schedule:  return "calendar"
        case .videos:    return "video.fill"
        case .files:     return "folder.fill"
        }
    }
}

// MARK: - Hub Photo Helper

struct TrainerHubPhoto: View {
    let trainerId: String
    let name:      String
    let size:      CGFloat
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: size - 4, height: size - 4).clipShape(Circle())
            } else {
                Text(name.prefix(1))
                    .font(.system(size: size * 0.4, weight: .bold)).foregroundColor(.black)
            }
        }
        .task {
            // Try Supabase URL for trainer photo
            if let trainers = try? await SupabaseAuthManager.shared.fetchAllTrainers(),
               let trainerRow = trainers.first(where: { $0.id.uuidString == trainerId }),
               let urlStr = trainerRow.profileImageUrl,
               let url = URL(string: urlStr),
               let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                await MainActor.run { image = img }
            } else {
                // Fall back to local
                image = ProfileImageManager.shared.loadImage(
                    forKey: ProfileImageManager.profileImageKey(for: trainerId))
            }
        }
    }
}

// MARK: - Hub Messages Section

struct HubMessagesSection: View {
    let connection:  TrainerClientConnection
    let clientId:    String
    let clientName:  String
    @ObservedObject private var store = SBMessageStore.shared
    @State private var showingChat = false

    private var recentMessages: [MessageRow] {
        Array(store.messages.suffix(3).reversed())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("RECENT MESSAGES", icon: "bubble.left.fill")

            if recentMessages.isEmpty {
                emptyState(icon: "bubble.left",
                           message: "No messages yet. Send your trainer a message!")
            } else {
                ForEach(recentMessages) { msg in
                    SBHubMessageRow(message: msg, clientId: clientId)
                }
            }

            Button(action: { showingChat = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("OPEN FULL CHAT")
                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption)
                }
                .foregroundColor(.black).padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.tmGold))
            }
            .padding(.top, 4)
        }
        .task {
            try? await store.fetchMessages(
                trainerId: UUID(uuidString: connection.trainerId) ?? UUID(),
                clientId:  UUID(uuidString: connection.clientId)  ?? UUID()
            )
        }
        .sheet(isPresented: $showingChat) {
            NavigationView {
                SupabaseChatView(
                    trainerId:       UUID(uuidString: connection.trainerId) ?? UUID(),
                    clientId:        UUID(uuidString: connection.clientId)  ?? UUID(),
                    currentUserId:   UUID(uuidString: clientId)             ?? UUID(),
                    currentUserName: clientName,
                    otherPersonName: connection.trainerName
                )
            }
            .tint(.tmGold)
        }
    }
}

// MARK: - Supabase Hub Message Row

struct SBHubMessageRow: View {
    let message:  MessageRow
    let clientId: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: message.senderId.uuidString == clientId
                  ? "person.fill" : "figure.strengthtraining.traditional")
                .font(.caption)
                .foregroundColor(message.senderId.uuidString == clientId
                                 ? .white.opacity(0.5) : .tmGold)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(message.senderRole == "client" ? "You" : "Trainer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(message.senderId.uuidString == clientId
                                     ? .white.opacity(0.5) : .tmGold)
                Text(message.content)
                    .font(.subheadline).foregroundColor(.white).lineLimit(2)
            }
            Spacer()
            Text(timeAgo(message.sentAt ?? Date()))
                .font(.caption2).foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
    }

    private func timeAgo(_ date: Date) -> String {
        let mins = Int(Date().timeIntervalSince(date) / 60)
        if mins < 60 { return "\(mins)m" }
        if mins < 1440 { return "\(mins/60)h" }
        return "\(mins/1440)d"
    }
}

// MARK: - Videos Section

struct HubVideosSection: View {
    @ObservedObject var viewModel: VideoMessageViewModel
    let clientId: String
    @State private var selectedMessage: VideoMessage?
    @State private var showingPlayer = false

    private var videos: [VideoMessage] { viewModel.getMessages(for: clientId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("VIDEO MESSAGES FROM TRAINER", icon: "video.fill")
            if videos.isEmpty {
                emptyState(icon: "video.slash",
                           message: "Your trainer hasn't sent any video messages yet.")
            } else {
                ForEach(videos) { video in
                    Button(action: {
                        selectedMessage = video; showingPlayer = true
                        if !video.isViewed { viewModel.markAsViewed(video) }
                    }) { HubVideoRow(video: video) }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showingPlayer) {
            if let msg = selectedMessage {
                VideoMessagePlayerView(message: msg, onClose: { showingPlayer = false })
            }
        }
    }
}

struct HubVideoRow: View {
    let video: VideoMessage
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07))
                    .frame(width: 64, height: 52)
                Image(systemName: "play.circle.fill").font(.title2).foregroundColor(.tmGold)
                if video.isNew {
                    VStack { HStack { Spacer()
                        Circle().fill(Color.red).frame(width: 8, height: 8).padding(4)
                    }; Spacer() }
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                HStack(spacing: 6) {
                    Text(video.messageType.rawValue).font(.caption).foregroundColor(.tmGold)
                    Text("·").foregroundColor(.white.opacity(0.3))
                    Text(video.formattedDuration).font(.caption).foregroundColor(.white.opacity(0.5))
                    Text("·").foregroundColor(.white.opacity(0.3))
                    Text(video.timeAgo).font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }
            Spacer()
            if video.isNew {
                Text("NEW").font(.system(size: 8, weight: .heavy)).foregroundColor(.black)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(Color.tmGold))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(video.isNew ? Color.tmGold.opacity(0.4) : Color.white.opacity(0.07), lineWidth: 1)))
    }
}

// MARK: - Files Section

struct HubFilesSection: View {
    let trainerId: String
    let clientId:  String
    @ObservedObject private var fileStore = TrainerFileStore.shared

    private var files: [TrainerSharedFile] {
        fileStore.files(forTrainer: trainerId, clientId: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("FILES & DOCUMENTS", icon: "folder.fill")
            if files.isEmpty {
                emptyState(icon: "doc.badge.plus",
                           message: "Your trainer hasn't shared any files yet.")
            } else {
                ForEach(files) { file in HubFileRow(file: file) }
            }
        }
    }
}

struct HubFileRow: View {
    let file: TrainerSharedFile
    @State private var previewURL: URL?

    var body: some View {
        Button(action: openFile) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(file.typeColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: file.typeIcon).font(.title3).foregroundColor(file.typeColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.name)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(file.fileType.rawValue).font(.caption).foregroundColor(file.typeColor)
                        Text("·").foregroundColor(.white.opacity(0.3))
                        Text(file.uploadedAt, style: .date)
                            .font(.caption).foregroundColor(.white.opacity(0.45))
                    }
                    if let note = file.note {
                        Text(note).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                    }
                }
                Spacer()
                Image(systemName: FileManager.default.fileExists(atPath: file.fileURL.path)
                      ? "eye.fill" : "icloud.slash")
                    .font(.system(size: 16)).foregroundColor(.tmGold)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .quickLookPreview($previewURL)
    }

    private func openFile() {
        let url = file.fileURL
        if FileManager.default.fileExists(atPath: url.path) { previewURL = url }
    }
}

// MARK: - Shared Section Helpers

private func sectionHeader(_ title: String, icon: String) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
        Text(title).font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

private func emptyState(icon: String, message: String) -> some View {
    VStack(spacing: 12) {
        Image(systemName: icon).font(.system(size: 36))
            .foregroundColor(.white.opacity(0.15)).padding(.top, 20)
        Text(message).font(.subheadline).foregroundColor(.white.opacity(0.4))
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 10)
}

// MARK: - Hub Schedule Section

struct HubScheduleSection: View {
    let trainerId: String
    let clientId:  String
    let clientName: String
    @ObservedObject private var scheduleStore = TrainerScheduleStore.shared
    @ObservedObject private var requestStore  = AppointmentRequestStore.shared
    @State private var showingRequest = false
    @State private var selectedMonth  = Date()

    private var myEvents: [TrainerEvent] {
        let cal = Calendar.current
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: selectedMonth)),
              let end   = cal.date(byAdding: .month, value: 1, to: start) else { return [] }
        return scheduleStore.events(forTrainer: trainerId, from: start, to: end)
            .filter { $0.clientId == clientId || $0.clientId == nil || ($0.clientId ?? "").isEmpty }
    }

    private var pendingRequests: [AppointmentRequest] {
        requestStore.requests(forClient: clientId, trainerId: trainerId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Your sessions with this trainer")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Button(action: { showingRequest = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("Request")
                    }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.tmGold))
                }
            }

            HStack {
                Button(action: { shiftMonth(-1) }) {
                    Image(systemName: "chevron.left").foregroundColor(.tmGold)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
                Spacer()
                Text(monthTitle(selectedMonth))
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                Spacer()
                Button(action: { shiftMonth(1) }) {
                    Image(systemName: "chevron.right").foregroundColor(.tmGold)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
            }

            if myEvents.isEmpty && pendingRequests.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.25))
                    Text("No sessions this month")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Tap Request to ask your trainer for a session.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                if !pendingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("YOUR REQUESTS", icon: "clock.badge.questionmark.fill")
                        ForEach(pendingRequests) { req in
                            ClientRequestRow(request: req, clientId: clientId)
                        }
                    }
                }
                if !myEvents.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("SCHEDULED SESSIONS", icon: "calendar.badge.checkmark")
                        ForEach(myEvents) { event in
                            ClientEventRow(event: event, clientId: clientId)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingRequest) {
            NavigationView {
                ClientRequestSessionView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func shiftMonth(_ val: Int) {
        selectedMonth = Calendar.current.date(byAdding: .month, value: val, to: selectedMonth) ?? selectedMonth
    }
    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f.string(from: d)
    }
}

// MARK: - Client Event Row

struct ClientEventRow: View {
    let event:    TrainerEvent
    let clientId: String

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3).fill(event.color.color).frame(width: 4, height: 52)
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(event.color.color.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: event.typeIcon).font(.system(size: 15)).foregroundColor(event.color.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(event.formattedDate).font(.caption).foregroundColor(.white.opacity(0.5))
                Text(event.formattedTime).font(.caption).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Text("Confirmed").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 7).padding(.vertical, 3).background(Capsule().fill(Color.green))
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(event.color.color.opacity(0.2), lineWidth: 1)))
    }
}

// MARK: - Client Request Row

struct ClientRequestRow: View {
    let request:  AppointmentRequest
    let clientId: String
    @ObservedObject private var requestStore = AppointmentRequestStore.shared
    @State private var showingCancel = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(statusColor.opacity(0.12)).frame(width: 42, height: 42)
                Image(systemName: statusIcon).font(.system(size: 15)).foregroundColor(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(request.title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                Text(request.formattedDate).font(.caption).foregroundColor(.white.opacity(0.5))
                Text(request.formattedTime).font(.caption).foregroundColor(.white.opacity(0.4))
                if let note = request.note {
                    Text(note).font(.caption2).foregroundColor(.white.opacity(0.35)).lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                statusBadge
                if request.status == .pending {
                    Button(action: { showingCancel = true }) {
                        Text("Cancel").font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Capsule().fill(Color.red.opacity(0.1)))
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(statusColor.opacity(0.2), lineWidth: 1)))
        .alert("Cancel Request?", isPresented: $showingCancel) {
            Button("Keep It", role: .cancel) {}
            Button("Cancel Request", role: .destructive) { requestStore.cancelRequest(request) }
        } message: { Text("Cancel your request for \"\(request.title)\"?") }
    }

    private var statusColor: Color {
        switch request.status {
        case .pending:   return .tmGold
        case .accepted:  return .green
        case .declined:  return .red
        case .cancelled: return .gray
        }
    }
    private var statusIcon: String {
        switch request.status {
        case .pending:   return "clock.fill"
        case .accepted:  return "checkmark.circle.fill"
        case .declined:  return "xmark.circle.fill"
        case .cancelled: return "minus.circle.fill"
        }
    }
    private var statusBadge: some View {
        Text(request.status.rawValue).font(.system(size: 9, weight: .bold))
            .foregroundColor(request.status == .pending ? .black : .white)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(statusColor))
    }
}

// MARK: - Client Request Session View

struct ClientRequestSessionView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var requestStore = AppointmentRequestStore.shared
    @State private var title        = ""
    @State private var sessionType: TrainerEvent.EventType = .session
    @State private var preferredDate = Date().addingTimeInterval(86400)
    @State private var duration: Double = 60
    @State private var note         = ""
    @State private var isSaving     = false

    private var endDate: Date { preferredDate.addingTimeInterval(duration * 60) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    formBlock("SESSION TITLE") {
                        TextField("e.g. Leg Day Session", text: $title)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    formBlock("SESSION TYPE") {
                        Menu {
                            ForEach([TrainerEvent.EventType.session, .progressCheck,
                                     .consultation, .other], id: \.self) { t in
                                Button(t.rawValue) { sessionType = t }
                            }
                        } label: {
                            HStack {
                                Text(sessionType.rawValue).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.down").font(.caption).foregroundColor(.gray)
                            }
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                        }
                    }
                    formBlock("PREFERRED DATE & TIME") {
                        DatePicker("", selection: $preferredDate, in: Date()...)
                            .datePickerStyle(.compact).colorScheme(.dark).tint(.tmGold).labelsHidden()
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }
                    formBlock("DURATION — \(Int(duration)) min") {
                        Slider(value: $duration, in: 30...120, step: 15).tint(.tmGold).padding(.horizontal, 4)
                        HStack {
                            Text("30 min").font(.caption2).foregroundColor(.white.opacity(0.3))
                            Spacer()
                            Text("120 min").font(.caption2).foregroundColor(.white.opacity(0.3))
                        }
                    }
                    formBlock("NOTE TO TRAINER (OPTIONAL)") {
                        TextField("What do you want to work on?", text: $note, axis: .vertical)
                            .foregroundColor(.white).lineLimit(3...5).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }
                    if !title.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("REQUEST SUMMARY")
                                .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                            HStack(spacing: 6) {
                                Image(systemName: "calendar").foregroundColor(.tmGold)
                                Text(formattedSummary).font(.subheadline).foregroundColor(.white)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
                    }
                    Button(action: sendRequest) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) } else {
                                Image(systemName: "paperplane.fill")
                                Text("SEND REQUEST").font(.system(size: 15, weight: .heavy)).tracking(0.5)
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
        .navigationTitle("Request Session").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }

    private var formattedSummary: String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d 'at' h:mm a"
        return "\(f.string(from: preferredDate)) · \(Int(duration)) min"
    }

    private func sendRequest() {
        isSaving = true
        let req = AppointmentRequest(
            trainerId: trainerId, clientId: clientId, clientName: clientName,
            title: title, sessionType: sessionType,
            preferredDate: preferredDate, endDate: endDate,
            note: note.isEmpty ? nil : note)
        requestStore.addRequest(req)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isSaving = false; dismiss() }
    }

    private func formBlock<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - TrainerEvent date helper

extension TrainerEvent {
    var formattedDate: String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d yyyy"; return f.string(from: startDate)
    }
}

// MARK: - Hub Check-In Section

struct HubCheckInSection: View {
    let clientId:   String
    let clientName: String
    let trainerId:  String
    @ObservedObject private var store = CheckInStore.shared
    @State private var showingSubmit  = false
    @State private var showingHistory = false

    private var recent: [ClientCheckIn] { Array(store.checkIns(forClient: clientId).prefix(3)) }
    private var pendingCount: Int { recent.filter { !$0.isReviewed }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Check-Ins").font(.title2).fontWeight(.bold).foregroundColor(.white)
                    Text("Weekly progress photos + weight")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Button(action: { showingSubmit = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "camera.fill")
                        Text("New")
                    }
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.black)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.tmGold))
                }
            }

            HStack(spacing: 0) {
                statCell("\(store.checkIns(forClient: clientId).count)", "Total")
                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                statCell("\(pendingCount)", "Pending Review")
                Divider().background(Color.white.opacity(0.08)).frame(height: 36)
                statCell("\(store.checkIns(forClient: clientId).filter { $0.isReviewed }.count)", "Reviewed")
            }
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

            if recent.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 36)).foregroundColor(.tmGold.opacity(0.2))
                    Text("No check-ins yet").font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Tap New to submit your first weekly check-in.")
                        .font(.caption).foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("RECENT").font(.system(size: 10, weight: .bold))
                            .tracking(1.2).foregroundColor(.tmGold)
                        Spacer()
                        if store.checkIns(forClient: clientId).count > 3 {
                            Button("See All") { showingHistory = true }
                                .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                        }
                    }
                    ForEach(recent) { ci in ClientCheckInCard(checkIn: ci) }
                }
            }
        }
        .sheet(isPresented: $showingSubmit) {
            NavigationView {
                ClientSubmitCheckInView(clientId: clientId, clientName: clientName, trainerId: trainerId)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingHistory) {
            NavigationView { ClientCheckInHistoryView(clientId: clientId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 20, weight: .black)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
