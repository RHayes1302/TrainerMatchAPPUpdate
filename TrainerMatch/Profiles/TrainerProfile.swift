//
//  TrainerProfile.swift
//  TrainerMatch
//

import SwiftUI
import PhotosUI

struct TrainerProfileMySpaceView: View {
    let trainer: TrainerProfile
    @State private var selectedTab: ProfileTab = .about
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var profileImage: UIImage?
    @State private var bannerImage: UIImage?
    @State private var profilePickerItem: PhotosPickerItem?
    @State private var bannerPickerItem: PhotosPickerItem?
    @State private var showingLogoutAlert = false
    @State private var showingMenu = false
    @State private var showingTrainerSearch = false
    @State private var showingGyms = false
    @State private var showingNearbyTrainers = false
    @State private var isUploadingProfile = false
    @State private var isUploadingBanner = false

    enum ProfileTab {
        case about, proof, clients, schedule
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                tabBar
                tabContent
            }
            .background(Color.black)
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .tint(.tmGold)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { showingMenu = true }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                        .foregroundColor(.tmGold)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 14) {
                    NavigationLink(destination: SupabaseTrainerEditProfileView()) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.tmGold)
                    }
                    Button(action: { showingLogoutAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red.opacity(0.85))
                    }
                }
            }
        }
        .onAppear { loadPhotos() }
        .onChange(of: profilePickerItem) { _, item in
            Task { await saveProfilePhoto(item) }
        }
        .onChange(of: bannerPickerItem) { _, item in
            Task { await saveBannerPhoto(item) }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                Task { await SupabaseAuthManager.shared.signOut() }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showingMenu) {
            TrainerMenuSheet(
                showingMenu: $showingMenu,
                showingTrainerSearch: $showingTrainerSearch,
                showingGyms: $showingGyms,
                showingNearbyTrainers: $showingNearbyTrainers
            )
        }
        .sheet(isPresented: $showingTrainerSearch) {
            NavigationView { TrainerSearchView() }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingGyms) {
            NavigationView { GymsNearYouView() }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingNearbyTrainers) {
            NavigationView { NearbyTrainersView() }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    // MARK: - Photo helpers

    private func loadPhotos() {
        if let urlStr = SupabaseAuthManager.shared.currentTrainer?.profileImageUrl,
           let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { profileImage = img }
                }
            }
        } else {
            let userId = SupabaseAuthManager.shared.currentTrainer?.id.uuidString
                ?? authManager.currentTrainerProfile?.id ?? ""
            profileImage = ProfileImageManager.shared.loadImage(
                forKey: ProfileImageManager.profileImageKey(for: userId))
        }

        if let urlStr = SupabaseAuthManager.shared.currentTrainer?.bannerImageUrl,
           let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { bannerImage = img }
                }
            }
        } else {
            let userId = SupabaseAuthManager.shared.currentTrainer?.id.uuidString
                ?? authManager.currentTrainerProfile?.id ?? ""
            bannerImage = ProfileImageManager.shared.loadImage(
                forKey: "banner_\(userId).jpg")
        }
    }

    private func saveProfilePhoto(_ item: PhotosPickerItem?) async {
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
        await MainActor.run { profileImage = resized; isUploadingProfile = true }
        if let jpegData = resized.jpegData(compressionQuality: 0.8) {
            do { _ = try await SupabaseAuthManager.shared.uploadProfilePhoto(imageData: jpegData) }
            catch {
                print("❌ Profile photo upload failed: \(error)")
                let userId = SupabaseAuthManager.shared.currentTrainer?.id.uuidString ?? ""
                ProfileImageManager.shared.saveImage(
                    resized, forKey: ProfileImageManager.profileImageKey(for: userId))
            }
        }
        await MainActor.run { isUploadingProfile = false }
    }

    private func saveBannerPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        let maxDim: CGFloat = 1200
        let scale = min(maxDim / uiImage.size.width, maxDim / uiImage.size.height, 1)
        let newSize = CGSize(width: uiImage.size.width * scale,
                             height: uiImage.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: newSize).image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }
        await MainActor.run { bannerImage = resized; isUploadingBanner = true }
        if let jpegData = resized.jpegData(compressionQuality: 0.8) {
            do { _ = try await SupabaseAuthManager.shared.uploadBannerPhoto(imageData: jpegData) }
            catch {
                print("❌ Banner photo upload failed: \(error)")
                let userId = SupabaseAuthManager.shared.currentTrainer?.id.uuidString ?? ""
                ProfileImageManager.shared.saveImage(resized, forKey: "banner_\(userId).jpg")
            }
        }
        await MainActor.run { isUploadingBanner = false }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            headerBanner
            nameAndStatus
        }
    }

    private var headerBanner: some View {
        VStack(spacing: 0) {
            PhotosPicker(selection: $bannerPickerItem, matching: .images) {
                ZStack {
                    if let img = bannerImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(height: 200).clipped()
                    } else {
                        LinearGradient(
                            colors: [Color.tmGold, Color.tmGoldDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 200)
                    }
                    if isUploadingBanner {
                        Color.black.opacity(0.4).frame(height: 200)
                        ProgressView().tint(.tmGold).scaleEffect(1.5)
                    } else {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Label(bannerImage == nil ? "Add Cover Photo" : "Change Cover",
                                      systemImage: bannerImage == nil
                                      ? "photo.badge.plus.fill" : "pencil.circle.fill")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(bannerImage == nil
                                                     ? .black.opacity(0.5) : .white)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Capsule().fill(Color.black.opacity(0.25)))
                                    .padding(10)
                            }
                        }
                    }
                }
                .frame(height: 200)
            }

            HStack {
                PhotosPicker(selection: $profilePickerItem, matching: .images) {
                    ZStack {
                        Circle().fill(Color.black).frame(width: 108, height: 108)
                        if let img = profileImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 104, height: 104).clipShape(Circle())
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                                     startPoint: .topLeading,
                                                     endPoint: .bottomTrailing))
                                .frame(width: 104, height: 104)
                                .overlay(Text(trainer.businessName?.prefix(1) ?? "T")
                                    .font(.system(size: 42, weight: .bold))
                                    .foregroundColor(.black))
                        }
                        if isUploadingProfile {
                            Circle().fill(Color.black.opacity(0.5)).frame(width: 104, height: 104)
                            ProgressView().tint(.tmGold)
                        } else {
                            Circle().fill(Color.tmGold).frame(width: 30, height: 30)
                                .overlay(Image(systemName: "camera.fill")
                                    .font(.system(size: 12)).foregroundColor(.black))
                                .offset(x: 36, y: 36)
                        }
                    }
                    .overlay(Circle().stroke(Color.black, lineWidth: 4).frame(width: 108))
                }
                .offset(y: -24).padding(.leading, 20)
                Spacer()
            }
            .frame(height: 50).background(Color.black)
        }
    }

    private var nameAndStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trainer.businessName ?? "Personal Trainer")
                        .font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                    statusBadge
                }
                Spacer()
                quickStats
            }
            .padding(.horizontal, 20).padding(.top, 12)
            locationAndService
        }
        .padding(.bottom, 20).background(Color.black)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(trainer.isVerified ? Color.green : Color.orange)
                .frame(width: 10, height: 10)
            Text(trainer.isVerified ? "Verified Trainer" : "Active")
                .font(.caption).foregroundColor(.white.opacity(0.8))
        }
    }

    private var quickStats: some View {
        VStack(spacing: 8) {
            if let rating = trainer.rating {
                StatBubble(icon: "star.fill",
                           value: String(format: "%.1f", rating), label: "Rating")
            }
            StatBubble(icon: "calendar",
                       value: "\(trainer.yearsOfExperience)", label: "Years")
        }
    }

    private var locationAndService: some View {
        HStack(spacing: 16) {
            if let location = trainer.location {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.tmGold)
                    Text("\(location.city), \(location.state)")
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
            if let serviceType = trainer.serviceTypes.first {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill").foregroundColor(.tmGold)
                    Text(serviceType == .both ? "In-Person & Online" : serviceType.rawValue)
                        .font(.caption).foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ProfileTabButton(icon: "person.circle.fill", title: "PROFILE",
                isSelected: selectedTab == .about, action: { selectedTab = .about })
            ProfileTabButton(icon: "trophy.fill", title: "PROOF",
                isSelected: selectedTab == .proof, action: { selectedTab = .proof })
            ProfileTabButton(icon: "person.2.fill", title: "CLIENTS",
                isSelected: selectedTab == .clients, action: { selectedTab = .clients })
            ProfileTabButton(icon: "calendar", title: "SCHEDULE",
                isSelected: selectedTab == .schedule, action: { selectedTab = .schedule })
        }
        .background(Color.white.opacity(0.05))
    }

    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:
            AboutMeSection(trainer: trainer)
        case .proof:
            ProofOfWorkSection(trainerId: trainer.userId)
        case .clients:
            VStack(spacing: 0) {
                GymAdBannerView().padding(.horizontal, 20).padding(.top, 8)
                TrainerClientsDashboardLink()
                TrainerReviewsLink(trainerId: trainer.userId)
                TrainerVerificationLink(trainerId: trainer.userId)
                TrainerBookingsLink(trainerId: trainer.userId)
                TrainerAllWorkoutsLink(trainerId: trainer.userId)
                TrainerAllMealPlansLink(trainerId: trainer.userId)
                TrainerAllCheckInsLink(trainerId: trainer.userId)
            }
        case .schedule:
            ScheduleSection(trainer: trainer)
        }
    }
}

// MARK: - Trainer Menu Sheet

struct TrainerMenuSheet: View {
    @Binding var showingMenu: Bool
    @Binding var showingTrainerSearch: Bool
    @Binding var showingGyms: Bool
    @Binding var showingNearbyTrainers: Bool
    @State private var showingLogoutAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20)
                            .padding(.top, 40)
                        Text("TrainerMatch")
                            .font(.system(size: 32, weight: .bold)).italic()
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Circle().fill(Color.green).frame(width: 8, height: 8)
                            Text(SupabaseAuthManager.shared.currentTrainer?.fullName ?? "Trainer")
                                .font(.subheadline).foregroundColor(.white.opacity(0.7))
                            Text("·").foregroundColor(.white.opacity(0.3))
                            Text("Trainer").font(.caption).foregroundColor(.tmGold)
                        }
                        .padding(.horizontal, 20).padding(.vertical, 8)
                        .background(Capsule().fill(Color.white.opacity(0.05)))
                    }
                    .padding(.bottom, 40)

                    menuSection("EXPLORE") {
                        menuButton(icon: "person.2.circle.fill", title: "Trainers Nearby") {
                            showingMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingNearbyTrainers = true
                            }
                        }
                        menuButton(icon: "magnifyingglass", title: "Search All Trainers") {
                            showingMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingTrainerSearch = true
                            }
                        }
                        menuButton(icon: "building.2.fill", title: "Gyms Near You") {
                            showingMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                showingGyms = true
                            }
                        }
                    }
                    .padding(.bottom, 32)

                    menuSection("ACCOUNT") {
                        Button(action: { showingLogoutAlert = true }) {
                            HStack(spacing: 16) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.title3).foregroundColor(.red).frame(width: 30)
                                Text("Log Out")
                                    .font(.body).fontWeight(.semibold).foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 16).padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.08))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)))
                        }
                        .padding(.horizontal, 20).padding(.bottom, 8)
                    }
                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showingMenu = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.tmGold).padding(20)
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                showingMenu = false
                Task { await SupabaseAuthManager.shared.signOut() }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private func menuSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.tmGold).padding(.bottom, 12)
            content()
        }
    }

    private func menuButton(icon: String, title: String,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title3).foregroundColor(.tmGold).frame(width: 30)
                Text(title).font(.body).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 16).padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }
}

// MARK: - Stat Bubble
struct StatBubble: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption2).foregroundColor(.tmGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.caption).fontWeight(.bold).foregroundColor(.white)
                Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
    }
}

// MARK: - Profile Tab Button
struct ProfileTabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(isSelected ? .tmGold : .white.opacity(0.5))
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isSelected ? Color.tmGold.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - About Me Section
struct AboutMeSection: View {
    let trainer: TrainerProfile

    var body: some View {
        VStack(spacing: 20) {
            professionalInfo
            if let bio = trainer.bio, !bio.isEmpty { bioCard }
            if !trainer.specialties.isEmpty { specialtiesCard }
            if !trainer.serviceTypes.isEmpty { servicesCard }
            if !trainer.certifications.isEmpty { certificationsCard }
        }
        .padding(20)
    }

    // ✅ Monthly rate added here
    private var professionalInfo: some View {
        InfoCard(title: "PROFESSIONAL INFO", icon: "briefcase.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if let location = trainer.location {
                    InfoRow(label: "Location",
                            value: "\(location.city), \(location.state)")
                }
                InfoRow(label: "Experience",
                        value: "\(trainer.yearsOfExperience) years")
                if let rate = trainer.hourlyRate {
                    InfoRow(label: "In-Person Rate", value: "$\(Int(rate))/hour")
                }
                if let rate = trainer.monthlyRate {
                    InfoRow(label: "Virtual Rate", value: "$\(Int(rate))/month")
                }
            }
        }
    }

    private var bioCard: some View {
        InfoCard(title: "ABOUT ME", icon: "text.quote") {
            Text(trainer.bio ?? "")
                .font(.body).foregroundColor(.white.opacity(0.9)).lineSpacing(4)
        }
    }

    private var specialtiesCard: some View {
        InfoCard(title: "SPECIALTIES", icon: "star.circle.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(trainer.specialties, id: \.self) { specialty in
                    Text("• \(specialty.rawValue)").foregroundColor(.white)
                }
            }
        }
    }

    private var servicesCard: some View {
        InfoCard(title: "SERVICES", icon: "checkmark.circle.fill") {
            VStack(spacing: 10) {
                ForEach(trainer.serviceTypes, id: \.self) { service in
                    HStack {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.tmGold)
                        Text(service == .both ? "In-Person & Online" : service.rawValue)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
            }
        }
    }

    private var certificationsCard: some View {
        InfoCard(title: "CERTIFICATIONS", icon: "checkmark.seal.fill") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(trainer.certifications, id: \.self) { cert in
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill").font(.caption2).foregroundColor(.tmGold)
                        Text(cert).font(.body).foregroundColor(.white)
                    }
                }
            }
        }
    }
}

// MARK: - Schedule Section
struct ScheduleSection: View {
    let trainer: TrainerProfile
    var body: some View { TrainerScheduleView(trainerId: trainer.id) }
}

// MARK: - Supporting Views
struct InfoCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.black).font(.caption)
                Text(title).font(.system(size: 12, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 12).padding(.vertical, 6).background(Color.tmGold)
            content.padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":").font(.body).fontWeight(.semibold).foregroundColor(.tmGold)
            Text(value).font(.body).foregroundColor(.white)
            Spacer()
        }
    }
}

struct ContactRow: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.body).foregroundColor(.tmGold).frame(width: 24)
            Text(value).font(.body).foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        TrainerProfileMySpaceView(trainer: TrainerProfile.sampleProfile)
            .environmentObject(AuthManager.shared)
    }
}

// MARK: - Trainer Clients Dashboard Link

struct TrainerClientsDashboardLink: View {
    @ObservedObject private var authManager = AuthManager.shared
    @ObservedObject private var store = TrainerConnectionStore.shared

    private var clientCount: Int {
        guard let id = authManager.currentTrainerProfile?.id else { return 0 }
        return store.activeClients(forTrainer: id).count
    }

    var body: some View {
        NavigationLink(destination:
            TrainerDashboardView().navigationBarBackButtonHidden(false)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Clients")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(clientCount == 0
                         ? "No clients yet"
                         : "\(clientCount) connected client\(clientCount == 1 ? "" : "s")")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trainer All Check-Ins Link

struct TrainerAllCheckInsLink: View {
    let trainerId: String
    @ObservedObject private var store = SBCheckInStore.shared
    @State private var showingCheckIns = false

    private var pendingCount: Int {
        store.checkIns.filter {
            $0.trainerId.uuidString == trainerId && ($0.notes ?? "").isEmpty
        }.count
    }

    var body: some View {
        Button(action: { showingCheckIns = true }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Check-Ins")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(pendingCount > 0
                         ? "\(pendingCount) awaiting review" : "All check-ins reviewed")
                        .font(.caption)
                        .foregroundColor(pendingCount > 0 ? .orange : .white.opacity(0.4))
                }
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 12, weight: .black)).foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.tmGold))
                }
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingCheckIns) {
            NavigationView { TrainerCheckInsView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Trainer All Workouts Link

struct TrainerAllWorkoutsLink: View {
    let trainerId: String
    @ObservedObject private var store = WorkoutStore.shared
    @State private var showingWorkouts = false

    private var pendingCount: Int { store.pendingCount(forTrainer: trainerId) }
    private var allClientWorkouts: [TMWorkout] { store.workouts(forTrainer: trainerId) }

    var body: some View {
        Button(action: { showingWorkouts = true }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Assigned Workouts")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(pendingCount > 0
                         ? "\(pendingCount) awaiting completion"
                         : "\(allClientWorkouts.count) total assigned")
                        .font(.caption)
                        .foregroundColor(pendingCount > 0 ? .orange : .white.opacity(0.4))
                }
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.system(size: 12, weight: .black)).foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(Color.tmGold))
                }
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingWorkouts) {
            NavigationView { TrainerAllClientsWorkoutsView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct TrainerAllClientsWorkoutsView: View {
    let trainerId: String
    @ObservedObject private var store = WorkoutStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var filter: TMWorkout.WorkoutStatus? = nil

    private var allWorkouts: [TMWorkout] { store.workouts(forTrainer: trainerId) }
    private var filtered: [TMWorkout] {
        guard let f = filter else { return allWorkouts }
        return allWorkouts.filter { $0.status == f }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", selected: filter == nil) { filter = nil }
                        filterChip("Assigned",  selected: filter == .assigned)  { filter = .assigned }
                        filterChip("Completed", selected: filter == .completed) { filter = .completed }
                        filterChip("Skipped",   selected: filter == .skipped)   { filter = .skipped }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .background(Color.white.opacity(0.03))
                if filtered.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "dumbbell").font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                        Text("No workouts found")
                            .font(.title3).foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filtered) { w in
                            WorkoutCardRow(workout: w, showClient: true)
                                .listRowBackground(Color.white.opacity(0.03))
                                .listRowSeparatorTint(Color.white.opacity(0.06))
                        }
                        .onDelete { idx in idx.forEach { store.delete(filtered[$0]) } }
                    }
                    .listStyle(.plain).scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("All Workouts").navigationBarTitleDisplayMode(.inline)
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
        }
    }

    private func filterChip(_ label: String, selected: Bool,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Trainer All Meal Plans Link

struct TrainerAllMealPlansLink: View {
    let trainerId: String
    @ObservedObject private var store = MealPlanStore.shared
    @State private var showingPlans = false

    private var allPlans: [MealPlan] { store.plans(forTrainer: trainerId) }
    private var activeCount: Int { allPlans.filter { $0.isActive }.count }

    var body: some View {
        Button(action: { showingPlans = true }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "fork.knife")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Meal Plans")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(activeCount > 0
                         ? "\(activeCount) active plan\(activeCount == 1 ? "" : "s")"
                         : "\(allPlans.count) plan\(allPlans.count == 1 ? "" : "s") assigned")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPlans) {
            NavigationView { TrainerAllClientsPlansView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct TrainerAllClientsPlansView: View {
    let trainerId: String
    @ObservedObject private var store = MealPlanStore.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            let plans = store.plans(forTrainer: trainerId)
            if plans.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "fork.knife").font(.system(size: 44))
                        .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No meal plans assigned yet")
                        .font(.title3).foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(plans) { p in
                        MealPlanCardRow(plan: p, showClient: true)
                            .listRowBackground(Color.white.opacity(0.03))
                            .listRowSeparatorTint(Color.white.opacity(0.06))
                    }
                    .onDelete { idx in idx.forEach { store.delete(plans[$0]) } }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("All Meal Plans").navigationBarTitleDisplayMode(.inline)
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
        }
    }
}

// MARK: - Trainer Bookings Link

struct TrainerBookingsLink: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared

    private var pendingCount: Int {
        store.bookings(forTrainer: trainerId).filter { $0.status == .pending }.count
    }

    var body: some View {
        NavigationLink(destination: TrainerBookingHubView(trainerId: trainerId)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bookings & Payments")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(pendingCount > 0
                         ? "\(pendingCount) pending booking\(pendingCount == 1 ? "" : "s")"
                         : "Manage services, packages & memberships")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount)").font(.system(size: 12, weight: .black))
                        .foregroundColor(.black).padding(6)
                        .background(Circle().fill(Color.tmGold))
                }
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trainer Reviews Link

struct TrainerReviewsLink: View {
    let trainerId: String
    @ObservedObject private var store = ReviewStore.shared

    var body: some View {
        NavigationLink(destination:
            TrainerReviewsListView(trainerId: trainerId, isTrainerView: true)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "star.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reviews & Ratings")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    let avg   = store.averageRating(forTrainer: trainerId)
                    let count = store.reviewCount(forTrainer: trainerId)
                    if count > 0 {
                        HStack(spacing: 4) {
                            starRow(rating: avg, size: 11)
                            Text(String(format: "%.1f · %d review%@",
                                        avg, count, count == 1 ? "" : "s"))
                                .font(.caption).foregroundColor(.tmGold)
                        }
                    } else {
                        Text("No reviews yet")
                            .font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Trainer Verification Link

struct TrainerVerificationLink: View {
    let trainerId: String
    @ObservedObject private var store = ReviewStore.shared

    var body: some View {
        NavigationLink(destination: TrainerVerificationView(trainerId: trainerId)) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.12)).frame(width: 48, height: 48)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verification")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    VerificationBadge(
                        status: store.verificationStatus(forTrainer: trainerId),
                        compact: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.tmGold.opacity(0.5))
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 8)
        }
        .buttonStyle(.plain)
    }
}
