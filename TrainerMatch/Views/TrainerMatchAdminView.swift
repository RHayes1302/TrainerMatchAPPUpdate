//
//  TrainerMatchAdminView.swift
//  TrainerMatch
//
//  Admin dashboard — accessed by 5-tapping the TrainerMatch logo.
//  PIN protected. All settings linked to Supabase app_settings table.
//
//  Tabs:
//  1. Trainers    — view all, deactivate/delete + cascade cleanup
//  2. Clients     — view all, deactivate/delete + cascade cleanup
//  3. Gym Ads     — approve / reject / delete
//  4. Check-Ins   — view all platform check-ins, delete
//  5. Results     — view all proof-of-work results, delete
//  6. Settings    — maintenance mode, trainer approval, app review mode (all Supabase)
//

import SwiftUI

// MARK: - App Settings Model

struct AppSettings: Codable {
    var id:                      String
    var maintenanceMode:         Bool
    var requireTrainerApproval:  Bool
    var appReviewMode:           Bool
    var updatedAt:               Date?

    enum CodingKeys: String, CodingKey {
        case id
        case maintenanceMode        = "maintenance_mode"
        case requireTrainerApproval = "require_trainer_approval"
        case appReviewMode          = "app_review_mode"
        case updatedAt              = "updated_at"
    }

    static let `default` = AppSettings(
        id: "global",
        maintenanceMode: false,
        requireTrainerApproval: false,
        appReviewMode: true,
        updatedAt: nil
    )
}

// MARK: - App Settings Store

@MainActor
class AppSettingsStore: ObservableObject {
    static let shared = AppSettingsStore()
    @Published var settings: AppSettings = .default
    @Published var isLoading = false
    private init() {}

    func fetch() async {
        do {
            let result: AppSettings = try await supabase
                .from("app_settings")
                .select()
                .eq("id", value: "global")
                .single()
                .execute()
                .value
            settings = result
        } catch {
            print("❌ AppSettings fetch error: \(error)")
        }
    }

    func update(_ keyPath: WritableKeyPath<AppSettings, Bool>, value: Bool) async {
        settings[keyPath: keyPath] = value
        do {
            struct UpdatePayload: Encodable {
                var maintenanceMode:        Bool
                var requireTrainerApproval: Bool
                var appReviewMode:          Bool
                enum CodingKeys: String, CodingKey {
                    case maintenanceMode        = "maintenance_mode"
                    case requireTrainerApproval = "require_trainer_approval"
                    case appReviewMode          = "app_review_mode"
                }
            }
            let payload = UpdatePayload(
                maintenanceMode:        settings.maintenanceMode,
                requireTrainerApproval: settings.requireTrainerApproval,
                appReviewMode:          settings.appReviewMode
            )
            try await supabase
                .from("app_settings")
                .update(payload)
                .eq("id", value: "global")
                .execute()
            print("✅ AppSettings updated")
        } catch {
            settings[keyPath: keyPath] = !value
            print("❌ AppSettings update error: \(error)")
        }
    }
}

// MARK: - Admin PIN Lock

struct TMAdminLockView: View {
    @Environment(\.dismiss) var dismiss
    @State private var enteredPIN   = ""
    @State private var showingAdmin = false
    @State private var shake        = false
    @State private var showError    = false

    private let correctPIN = "012230"

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 30) {
                    Spacer()

                    // ✅ TrainerMatch logo instead of shield
                    TrainerMatchLogo(size: .large)

                    Text("ADMIN ACCESS")
                        .font(.title2.bold()).foregroundColor(.tmGold)
                    Text("Enter your admin PIN")
                        .font(.subheadline).foregroundColor(.gray)

                    // PIN dots
                    HStack(spacing: 20) {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .fill(i < enteredPIN.count ? Color.tmGold : Color.white.opacity(0.2))
                                .frame(width: 16, height: 16)
                        }
                    }
                    .offset(x: shake ? -10 : 0)
                    .animation(shake ? .easeInOut(duration: 0.1).repeatCount(5) : .default, value: shake)

                    if showError {
                        Text("Incorrect PIN")
                            .font(.caption.bold()).foregroundColor(.red)
                    }

                    // Number pad
                    VStack(spacing: 15) {
                        ForEach([[1,2,3],[4,5,6],[7,8,9]], id: \.self) { row in
                            HStack(spacing: 25) {
                                ForEach(row, id: \.self) { num in
                                    pinButton(label: "\(num)") { addDigit("\(num)") }
                                }
                            }
                        }
                        HStack(spacing: 25) {
                            pinButton(label: "⌫", color: .red.opacity(0.7)) {
                                if !enteredPIN.isEmpty { enteredPIN.removeLast(); showError = false }
                            }
                            pinButton(label: "0") { addDigit("0") }
                            pinButton(label: "✓", color: .green.opacity(0.7)) { checkPIN() }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
                }
            }
            .navigationDestination(isPresented: $showingAdmin) {
                TMAdminDashboardView()
            }
        }
    }

    private func addDigit(_ digit: String) {
        guard enteredPIN.count < 6 else { return }
        enteredPIN += digit
        showError = false
        if enteredPIN.count == 6 { checkPIN() }
    }

    private func checkPIN() {
        if enteredPIN == correctPIN {
            showingAdmin = true
            enteredPIN = ""
        } else {
            shake = true; showError = true; enteredPIN = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { shake = false }
        }
    }

    private func pinButton(label: String, color: Color = Color.white.opacity(0.15),
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.title2.bold()).foregroundColor(.white)
                .frame(width: 75, height: 75).background(color).clipShape(Circle())
        }
    }
}

// MARK: - Admin Dashboard

struct TMAdminDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var settingsStore = AppSettingsStore.shared

    @State private var allTrainers:  [TrainerRow]         = []
    @State private var allClients:   [ClientRow]          = []
    @State private var allGymAds:    [GymAdRow]           = []
    @State private var allCheckIns:  [CheckInRow]         = []
    @State private var allResults:   [SBTrainerResultRow] = []
    @State private var isLoading     = false
    @State private var selectedTab   = 0

    var pendingAds: [GymAdRow] { allGymAds.filter { $0.status == "pending" } }
    var activeAds:  [GymAdRow] { allGymAds.filter { $0.status == "active"  } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {

                // ✅ Header with TrainerMatch logo instead of shield
                HStack {
                    TrainerMatchLogo(size: .medium)
                    Text("ADMIN").font(.title2.bold()).foregroundColor(.tmGold)
                    Spacer()
                    Button(action: { Task { await loadAll() } }) {
                        Image(systemName: "arrow.clockwise").foregroundColor(.tmGold)
                    }
                }
                .padding()

                // Stats bar
                HStack(spacing: 0) {
                    adminStat(count: allTrainers.count,  label: "TRAINERS",  color: .tmGold)
                    adminStat(count: allClients.count,   label: "CLIENTS",   color: .blue)
                    adminStat(count: pendingAds.count,   label: "PENDING",   color: .orange)
                    adminStat(count: allCheckIns.count,  label: "CHECK-INS", color: .green)
                    adminStat(count: allResults.count,   label: "RESULTS",   color: .purple)
                }
                .background(Color.white.opacity(0.05))

                // Tab bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach([
                            (0, "Trainers"),
                            (1, "Clients"),
                            (2, "Gym Ads\(pendingAds.count > 0 ? " (\(pendingAds.count))" : "")"),
                            (3, "Check-Ins"),
                            (4, "Results"),
                            (5, "⚙️ Settings")
                        ], id: \.0) { tag, label in
                            Button(action: { selectedTab = tag }) {
                                Text(label)
                                    .font(.caption.bold())
                                    .foregroundColor(selectedTab == tag ? .black : .white.opacity(0.5))
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(selectedTab == tag ? Color.tmGold : Color.white.opacity(0.07))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 8)
                }
                .background(Color.white.opacity(0.04))

                // Content
                if isLoading {
                    Spacer()
                    ProgressView().tint(.tmGold)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            switch selectedTab {
                            case 0: trainersTab
                            case 1: clientsTab
                            case 2: gymAdsTab
                            case 3: checkInsTab
                            case 4: resultsTab
                            case 5: settingsTab
                            default: EmptyView()
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .principal) {
                Text("Nearby Trainers ADMIN").font(.caption.bold()).foregroundColor(.tmGold)
            }
        }
        .task { await loadAll() }
    }

    // MARK: - Tabs

    @ViewBuilder private var trainersTab: some View {
        if allTrainers.isEmpty {
            adminEmpty(message: "No trainers yet", icon: "person.fill")
        } else {
            ForEach(allTrainers) { trainer in
                TMAdminTrainerCard(trainer: trainer,
                    onDelete:       { Task { await deleteTrainer(trainer) } },
                    onToggleActive: { Task { await toggleTrainerActive(trainer) } }
                )
            }
        }
    }

    @ViewBuilder private var clientsTab: some View {
        if allClients.isEmpty {
            adminEmpty(message: "No clients yet", icon: "person.2.fill")
        } else {
            ForEach(allClients) { client in
                TMAdminClientCard(client: client,
                    onDelete:       { Task { await deleteClient(client) } },
                    onToggleActive: { Task { await toggleClientActive(client) } }
                )
            }
        }
    }

    @ViewBuilder private var gymAdsTab: some View {
        if allGymAds.isEmpty {
            adminEmpty(message: "No gym ads", icon: "megaphone.fill")
        } else {
            ForEach(allGymAds) { ad in
                TMAdminGymAdCard(ad: ad,
                    onApprove: { Task { await updateAdStatus(ad, status: "active")   } },
                    onReject:  { Task { await updateAdStatus(ad, status: "rejected") } },
                    onDelete:  { Task { await deleteGymAd(ad) } }
                )
            }
        }
    }

    @ViewBuilder private var checkInsTab: some View {
        if allCheckIns.isEmpty {
            adminEmpty(message: "No check-ins yet", icon: "camera.fill")
        } else {
            ForEach(allCheckIns) { ci in
                TMAdminCheckInCard(checkIn: ci, onDelete: { Task { await deleteCheckIn(ci) } })
            }
        }
    }

    @ViewBuilder private var resultsTab: some View {
        if allResults.isEmpty {
            adminEmpty(message: "No proof-of-work results yet", icon: "trophy.fill")
        } else {
            ForEach(allResults) { result in
                TMAdminResultCard(result: result, onDelete: { Task { await deleteResult(result) } })
            }
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        VStack(spacing: 16) {

            settingCard(
                title: "App Review Mode",
                subtitle: "ON: reviewers can access all features without restrictions. Turn OFF after App Store approval.",
                icon: "app.badge.checkmark.fill",
                iconColor: .blue,
                isOn: Binding(
                    get: { settingsStore.settings.appReviewMode },
                    set: { val in Task { await settingsStore.update(\.appReviewMode, value: val) } }
                ),
                statusOn:  "REVIEW MODE ON — Full access for App Store reviewers",
                statusOff: "NORMAL MODE — Standard restrictions apply"
            )

            settingCard(
                title: "Maintenance Mode",
                subtitle: "ON: shows a maintenance screen to all users at login. Use during major updates.",
                icon: "wrench.and.screwdriver.fill",
                iconColor: .orange,
                isOn: Binding(
                    get: { settingsStore.settings.maintenanceMode },
                    set: { val in Task { await settingsStore.update(\.maintenanceMode, value: val) } }
                ),
                statusOn:  "MAINTENANCE ON — Users will see the maintenance screen",
                statusOff: "MAINTENANCE OFF — App is fully operational"
            )

            settingCard(
                title: "Require Trainer Approval",
                subtitle: "ON: new trainer accounts must be approved by admin before going live to clients.",
                icon: "checkmark.seal.fill",
                iconColor: .tmGold,
                isOn: Binding(
                    get: { settingsStore.settings.requireTrainerApproval },
                    set: { val in Task { await settingsStore.update(\.requireTrainerApproval, value: val) } }
                ),
                statusOn:  "APPROVAL REQUIRED — New trainers need manual review",
                statusOff: "OPEN — New trainers go live immediately"
            )

            VStack(alignment: .leading, spacing: 12) {
                Text("PLATFORM SUMMARY")
                    .font(.caption.bold()).foregroundColor(.tmGold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.tmGold.opacity(0.15)).cornerRadius(6)

                Group {
                    statRow("Total Trainers",       "\(allTrainers.count)")
                    statRow("Active Trainers",       "\(allTrainers.filter { $0.isActive }.count)")
                    statRow("Inactive Trainers",     "\(allTrainers.filter { !$0.isActive }.count)")
                    statRow("Total Clients",         "\(allClients.count)")
                    statRow("Active Clients",        "\(allClients.filter { $0.isActive }.count)")
                    statRow("Total Check-Ins",       "\(allCheckIns.count)")
                    statRow("Gym Ads — Active",      "\(activeAds.count)")
                    statRow("Gym Ads — Pending",     "\(pendingAds.count)")
                    statRow("Proof-of-Work Results", "\(allResults.count)")
                }
            }
            .padding()
            .background(Color.white.opacity(0.04))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))

            Spacer()
        }
    }

    // MARK: - Load

    private func loadAll() async {
        isLoading = true
        await settingsStore.fetch()
        do {
            allTrainers = try await supabase
                .from("trainers").select()
                .order("created_at", ascending: false).execute().value
            allClients = try await supabase
                .from("clients").select()
                .order("created_at", ascending: false).execute().value
            allGymAds = try await supabase
                .from("gym_ads").select()
                .order("created_at", ascending: false).execute().value
            allCheckIns = try await supabase
                .from("check_ins").select()
                .order("checked_in_at", ascending: false).execute().value
            allResults = try await supabase
                .from("trainer_results").select()
                .order("created_at", ascending: false).execute().value
        } catch {
            print("❌ Admin load error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Trainer Actions

    private func deleteTrainer(_ trainer: TrainerRow) async {
        await SupabaseStorage.deleteProfilePhoto(userId: trainer.id.uuidString)
        await SupabaseStorage.deleteBannerPhoto(userId: trainer.id.uuidString)
        let results: [SBTrainerResultRow] = (try? await supabase
            .from("trainer_results").select()
            .eq("trainer_id", value: trainer.id).execute().value) ?? []
        for r in results {
            await SupabaseStorage.deleteTrainerResultPhotos(
                trainerId: trainer.id.uuidString, resultId: r.id.uuidString)
        }
        for table in ["trainer_clients","workouts","meal_plans","check_ins",
                       "messages","weight_entries","trainer_results"] {
            try? await supabase.from(table).delete()
                .eq("trainer_id", value: trainer.id).execute()
        }
        try? await supabase.from("trainers").delete()
            .eq("id", value: trainer.id).execute()
        allTrainers.removeAll { $0.id == trainer.id }
    }

    private func toggleTrainerActive(_ trainer: TrainerRow) async {
        struct U: Encodable {
            let isActive: Bool
            enum CodingKeys: String, CodingKey { case isActive = "is_active" }
        }
        try? await supabase.from("trainers")
            .update(U(isActive: !trainer.isActive))
            .eq("id", value: trainer.id).execute()
        if let i = allTrainers.firstIndex(where: { $0.id == trainer.id }) {
            allTrainers[i].isActive = !allTrainers[i].isActive
        }
    }

    // MARK: - Client Actions

    private func deleteClient(_ client: ClientRow) async {
        await SupabaseStorage.deleteProfilePhoto(userId: client.id.uuidString)
        let checkIns: [CheckInRow] = (try? await supabase
            .from("check_ins").select()
            .eq("client_id", value: client.id).execute().value) ?? []
        for ci in checkIns {
            await SupabaseStorage.deleteCheckInPhotos(
                clientId: client.id.uuidString,
                checkInId: ci.id.uuidString,
                count: ci.photoUrls.count)
        }
        for table in ["trainer_clients","check_ins","weight_entries","messages"] {
            try? await supabase.from(table).delete()
                .eq("client_id", value: client.id).execute()
        }
        try? await supabase.from("clients").delete()
            .eq("id", value: client.id).execute()
        allClients.removeAll { $0.id == client.id }
    }

    private func toggleClientActive(_ client: ClientRow) async {
        struct U: Encodable {
            let isActive: Bool
            enum CodingKeys: String, CodingKey { case isActive = "is_active" }
        }
        try? await supabase.from("clients")
            .update(U(isActive: !client.isActive))
            .eq("id", value: client.id).execute()
        if let i = allClients.firstIndex(where: { $0.id == client.id }) {
            allClients[i].isActive = !allClients[i].isActive
        }
    }

    // MARK: - Gym Ad Actions

    private func updateAdStatus(_ ad: GymAdRow, status: String) async {
        struct U: Encodable { let status: String }
        try? await supabase.from("gym_ads")
            .update(U(status: status))
            .eq("id", value: ad.id).execute()
        if let i = allGymAds.firstIndex(where: { $0.id == ad.id }) {
            allGymAds[i].status = status
        }
    }

    private func deleteGymAd(_ ad: GymAdRow) async {
        await SupabaseStorage.deleteGymAdImage(adId: ad.id.uuidString)
        try? await supabase.from("gym_ads").delete()
            .eq("id", value: ad.id).execute()
        allGymAds.removeAll { $0.id == ad.id }
    }

    // MARK: - Check-In Actions

    private func deleteCheckIn(_ checkIn: CheckInRow) async {
        await SupabaseStorage.deleteCheckInPhotos(
            clientId: checkIn.clientId.uuidString,
            checkInId: checkIn.id.uuidString,
            count: checkIn.photoUrls.count)
        try? await supabase.from("check_ins").delete()
            .eq("id", value: checkIn.id).execute()
        allCheckIns.removeAll { $0.id == checkIn.id }
    }

    // MARK: - Result Actions

    private func deleteResult(_ result: SBTrainerResultRow) async {
        await SupabaseStorage.deleteTrainerResultPhotos(
            trainerId: result.trainerId.uuidString,
            resultId: result.id.uuidString)
        try? await supabase.from("trainer_results").delete()
            .eq("id", value: result.id).execute()
        allResults.removeAll { $0.id == result.id }
    }

    // MARK: - UI Helpers

    private func adminStat(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title2.bold()).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
    }

    private func adminEmpty(message: String, icon: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.3))
            Text(message).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 60)
    }

    private func settingCard(title: String, subtitle: String,
                              icon: String, iconColor: Color,
                              isOn: Binding<Bool>,
                              statusOn: String, statusOff: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon).font(.title3).foregroundColor(iconColor).frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.subheadline.bold()).foregroundColor(.white)
                    Text(subtitle).font(.caption).foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Toggle("", isOn: isOn).tint(.tmGold)
            }
            HStack(spacing: 6) {
                Circle().fill(isOn.wrappedValue ? Color.green : Color.red).frame(width: 8, height: 8)
                Text(isOn.wrappedValue ? statusOn : statusOff)
                    .font(.caption.bold())
                    .foregroundColor(isOn.wrappedValue ? .green : .red)
            }
            Text("Saved to Supabase — applies to all users instantly")
                .font(.system(size: 10)).foregroundColor(.white.opacity(0.25))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(isOn.wrappedValue ? iconColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.gray)
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Trainer Card

struct TMAdminTrainerCard: View {
    let trainer:        TrainerRow
    let onDelete:       () -> Void
    let onToggleActive: () -> Void
    @State private var showingDeleteAlert = false
    @State private var profileImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(trainer.isActive ? Color.tmGold.opacity(0.2) : Color.red.opacity(0.15))
                        .frame(width: 52, height: 52)
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 48, height: 48).clipShape(Circle())
                    } else {
                        Text(trainer.firstName.prefix(1))
                            .font(.title3.bold()).foregroundColor(.tmGold)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(trainer.fullName).font(.subheadline.bold()).foregroundColor(.white)
                        Text(trainer.isActive ? "ACTIVE" : "INACTIVE")
                            .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(trainer.isActive ? Color.green : Color.red)
                            .cornerRadius(4)
                    }
                    if let biz = trainer.businessName {
                        Text(biz).font(.caption).foregroundColor(.tmGold)
                    }
                    Text(trainer.email).font(.caption).foregroundColor(.gray)
                    Text("\(trainer.city), \(trainer.state)  ·  \(trainer.yearsOfExperience) yrs exp")
                        .font(.caption2).foregroundColor(.gray)
                    if let rate = trainer.hourlyRate {
                        Text("$\(Int(rate))/hr").font(.caption2).foregroundColor(.tmGold)
                    }
                }
                Spacer()
            }

            if !trainer.specialties.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(trainer.specialties.prefix(4), id: \.self) { s in
                            Text(s).font(.system(size: 9, weight: .semibold)).foregroundColor(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.tmGold).cornerRadius(4)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: onToggleActive) {
                    Text(trainer.isActive ? "DEACTIVATE" : "REACTIVATE")
                        .font(.caption.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(trainer.isActive ? Color.orange.opacity(0.8) : Color.green.opacity(0.8))
                        .cornerRadius(8)
                }
                Button(action: { showingDeleteAlert = true }) {
                    Text("DELETE").font(.caption.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.red.opacity(0.7)).cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(trainer.isActive ? Color.tmGold.opacity(0.2) : Color.red.opacity(0.3), lineWidth: 1))
        .alert("Delete Trainer?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Permanently delete \(trainer.fullName), all their clients connections, workouts, meal plans, check-ins, and storage photos?")
        }
        .task {
            if let urlStr = trainer.profileImageUrl, let url = URL(string: urlStr),
               let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { profileImage = UIImage(data: data) }
            }
        }
    }
}

// MARK: - Client Card

struct TMAdminClientCard: View {
    let client:         ClientRow
    let onDelete:       () -> Void
    let onToggleActive: () -> Void
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(client.isActive ? Color.blue.opacity(0.2) : Color.red.opacity(0.15))
                        .frame(width: 52, height: 52)
                    Text(client.firstName.prefix(1))
                        .font(.title3.bold()).foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(client.fullName).font(.subheadline.bold()).foregroundColor(.white)
                        Text(client.isActive ? "ACTIVE" : "INACTIVE")
                            .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(client.isActive ? Color.green : Color.red)
                            .cornerRadius(4)
                    }
                    Text(client.email).font(.caption).foregroundColor(.gray)
                    Text("\(client.city), \(client.state)").font(.caption2).foregroundColor(.gray)
                    Text("Level: \(client.fitnessLevel)").font(.caption2).foregroundColor(.blue)
                    if let w = client.targetWeight {
                        Text("Target: \(Int(w)) lbs").font(.caption2).foregroundColor(.gray)
                    }
                }
                Spacer()
            }

            if !client.fitnessGoals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(client.fitnessGoals.prefix(3), id: \.self) { g in
                            Text(g).font(.system(size: 9, weight: .semibold)).foregroundColor(.white)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.4)).cornerRadius(4)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: onToggleActive) {
                    Text(client.isActive ? "DEACTIVATE" : "REACTIVATE")
                        .font(.caption.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(client.isActive ? Color.orange.opacity(0.8) : Color.green.opacity(0.8))
                        .cornerRadius(8)
                }
                Button(action: { showingDeleteAlert = true }) {
                    Text("DELETE").font(.caption.bold()).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(Color.red.opacity(0.7)).cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(client.isActive ? Color.blue.opacity(0.2) : Color.red.opacity(0.3), lineWidth: 1))
        .alert("Delete Client?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Permanently delete \(client.fullName), all their check-ins, weight entries, messages, and storage photos?")
        }
    }
}

// MARK: - Gym Ad Card

struct TMAdminGymAdCard: View {
    let ad:        GymAdRow
    let onApprove: () -> Void
    let onReject:  () -> Void
    let onDelete:  () -> Void
    @State private var showingDeleteAlert = false

    var statusColor: Color {
        switch ad.status {
        case "active":   return .green
        case "pending":  return .orange
        case "rejected": return .red
        default:         return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ad.businessName).font(.headline.bold()).foregroundColor(.white)
                    Text(ad.tagline).font(.caption).foregroundColor(.gray)
                    Text(ad.category.uppercased())
                        .font(.system(size: 9, weight: .bold)).foregroundColor(.tmGold)
                }
                Spacer()
                VStack(spacing: 4) {
                    Text(ad.status.uppercased())
                        .font(.caption2.bold()).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(statusColor).cornerRadius(6)
                    Text(ad.plan.uppercased())
                        .font(.caption2.bold()).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.tmGold).cornerRadius(6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let phone = ad.phone {
                    Label(phone, systemImage: "phone.fill").font(.caption).foregroundColor(.gray)
                }
                if let email = ad.advertiserEmail {
                    Label(email, systemImage: "envelope.fill").font(.caption).foregroundColor(.gray)
                }
                if let city = ad.city, let state = ad.state {
                    Label("\(city), \(state)", systemImage: "mappin.circle.fill")
                        .font(.caption).foregroundColor(.gray)
                }
            }

            HStack(spacing: 8) {
                if ad.status == "pending" {
                    Button(action: onApprove) {
                        Text("APPROVE").font(.caption.bold()).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(Color.green).cornerRadius(8)
                    }
                    Button(action: onReject) {
                        Text("REJECT").font(.caption.bold()).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(Color.red.opacity(0.7)).cornerRadius(8)
                    }
                } else if ad.status == "active" {
                    Button(action: onReject) {
                        Text("DEACTIVATE").font(.caption.bold()).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(Color.orange.opacity(0.8)).cornerRadius(8)
                    }
                } else {
                    Button(action: onApprove) {
                        Text("REACTIVATE").font(.caption.bold()).foregroundColor(.black)
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .background(Color.green).cornerRadius(8)
                    }
                }
            }

            Button(action: { showingDeleteAlert = true }) {
                Text("DELETE PERMANENTLY")
                    .font(.caption.bold()).foregroundColor(.red)
                    .frame(maxWidth: .infinity).padding(.vertical, 8)
                    .background(Color.red.opacity(0.1)).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.4), lineWidth: 1))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(statusColor.opacity(0.3), lineWidth: 1))
        .alert("Delete Gym Ad?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Permanently delete the ad for \(ad.businessName) and its logo from storage?")
        }
    }
}

// MARK: - Check-In Card

struct TMAdminCheckInCard: View {
    let checkIn: CheckInRow
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Check-In").font(.subheadline.bold()).foregroundColor(.white)
                    Text("Client:  \(checkIn.clientId.uuidString.prefix(8))…")
                        .font(.caption).foregroundColor(.gray)
                    Text("Trainer: \(checkIn.trainerId.uuidString.prefix(8))…")
                        .font(.caption).foregroundColor(.gray)
                    if let weight = checkIn.weight {
                        Text("Weight: \(String(format: "%.1f", weight)) lbs")
                            .font(.caption).foregroundColor(.tmGold)
                    }
                    if let date = checkIn.checkedInAt {
                        Text(date, style: .date).font(.caption2).foregroundColor(.gray)
                    }
                    Label("\(checkIn.photoUrls.count) photo(s)", systemImage: "photo.fill")
                        .font(.caption2).foregroundColor(.blue)
                }
                Spacer()
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash").foregroundColor(.red)
                        .padding(8).background(Color.red.opacity(0.1)).cornerRadius(8)
                }
            }
            if !checkIn.notes.isEmpty {
                Text(checkIn.notes).font(.caption).foregroundColor(.white.opacity(0.6)).lineLimit(2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.2), lineWidth: 1))
        .alert("Delete Check-In?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This will permanently delete the check-in and all \(checkIn.photoUrls.count) photo(s) from storage.")
        }
    }
}

// MARK: - Result Card

struct TMAdminResultCard: View {
    let result:   SBTrainerResultRow
    let onDelete: () -> Void
    @State private var beforeImage: UIImage?
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06))
                    .frame(width: 64, height: 64)
                if let img = beforeImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo.fill").foregroundColor(.white.opacity(0.3))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(result.goalAchieved.isEmpty ? "No goal set" : result.goalAchieved)
                    .font(.subheadline.bold()).foregroundColor(.white)
                if !result.duration.isEmpty {
                    Text(result.duration).font(.caption).foregroundColor(.tmGold)
                }
                if !result.clientLabel.isEmpty {
                    Text(result.clientLabel).font(.caption2).foregroundColor(.gray)
                }
                Text("Trainer: \(result.trainerId.uuidString.prefix(8))…")
                    .font(.caption2).foregroundColor(.gray)
                if let date = result.createdAt {
                    Text(date, style: .date).font(.caption2).foregroundColor(.gray)
                }
            }
            Spacer()
            Button(action: { showingDeleteAlert = true }) {
                Image(systemName: "trash").foregroundColor(.red)
                    .padding(8).background(Color.red.opacity(0.1)).cornerRadius(8)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purple.opacity(0.25), lineWidth: 1))
        .alert("Delete Result?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("Permanently delete this proof-of-work result and both photos from storage?")
        }
        .task {
            if !result.beforeUrl.isEmpty, let url = URL(string: result.beforeUrl),
               let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { beforeImage = UIImage(data: data) }
            }
        }
    }
}
