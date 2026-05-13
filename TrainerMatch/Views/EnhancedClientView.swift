//
//  EnhancedClientView.swift
//  TrainerMatch
//

import SwiftUI
import AVKit
import QuickLook

struct EnhancedClientDetailView: View {
    @ObservedObject var trainerViewModel: TrainerViewModel
    @StateObject var videoMessageViewModel = VideoMessageViewModel.shared
    @ObservedObject private var authManager = AuthManager.shared
    let client: Client

    @State private var showingVideoCamera  = false
    @State private var showingAllMessages  = false
    @State private var showingShareFile    = false

    var stats: ClientStats { trainerViewModel.getClientStats(for: client) }

    var recentMessages: [VideoMessage] {
        videoMessageViewModel.getRecentMessages(for: client.id, limit: 3)
    }
    var unviewedMessageCount: Int {
        videoMessageViewModel.getUnviewedCount(for: client.id)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    ClientHeaderSection(client: client, stats: stats)
                    QuickActionsSection(
                        onSendVideo:    { showingVideoCamera = true },
                        onViewMessages: { showingAllMessages = true },
                        onShareFile:    { showingShareFile   = true },
                        unviewedCount:  unviewedMessageCount
                    )
                    if !recentMessages.isEmpty {
                        RecentMessagesSection(
                            messages:   recentMessages,
                            viewModel:  videoMessageViewModel,
                            onViewAll:  { showingAllMessages = true }
                        )
                    }
                    TrainerSharedFilesSection(
                        trainerId:   authManager.currentTrainerProfile?.id ?? "",
                        clientId:    client.id,
                        clientName:  client.name,
                        onShareFile: { showingShareFile = true }
                    )
                    ClientStatsSection(stats: stats)
                    TrainerClientWorkoutSummary(
                        trainerId:  authManager.currentTrainerProfile?.id ?? "",
                        clientId:   client.id,
                        clientName: client.name
                    )
                    TrainerClientMealPlanSummary(
                        trainerId:  authManager.currentTrainerProfile?.id ?? "",
                        clientId:   client.id,
                        clientName: client.name
                    )
                    TrainerClientCheckInSummary(
                        trainerId:  authManager.currentTrainerProfile?.id ?? "",
                        clientId:   client.id,
                        clientName: client.name
                    )
                    TrainerClientWeightSummary(clientId: client.id, clientName: client.name)
                        .padding(.horizontal, 4)
                    ActivitySection(client: client)
                    ProgressSection(entries: trainerViewModel.getProgressEntries(for: client))
                }
                .padding()
            }
        }
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingVideoCamera = true }) {
                        Label("Send Video Message", systemImage: "video.fill")
                    }
                    Button(action: { showingAllMessages = true }) {
                        Label("View All Messages", systemImage: "message.fill")
                    }
                    Divider()
                    Button(action: {}) {
                        Label("Edit Client", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").foregroundColor(.tmGold)
                }
            }
        }
        .sheet(isPresented: $showingVideoCamera) {
            VideoMessageCameraView(
                viewModel:  videoMessageViewModel,
                clientName: client.name,
                clientId:   client.id
            )
        }
        .sheet(isPresented: $showingAllMessages) {
            NavigationView {
                ClientVideoMessagesView(
                    viewModel:  videoMessageViewModel,
                    clientId:   client.id,
                    clientName: client.name
                )
            }
        }
        .sheet(isPresented: $showingShareFile) {
            NavigationView {
                TrainerUploadFileView(
                    trainerId:  authManager.currentTrainerProfile?.id
                                ?? videoMessageViewModel.currentTrainerId,
                    clientId:   client.id,
                    clientName: client.name
                )
            }
            .tint(.tmGold)
        }
    }
}

// MARK: - Client Header

struct ClientHeaderSection: View {
    let client: Client
    let stats:  ClientStats
    @State private var profileImage: UIImage?

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 100, height: 100)
                if let img = profileImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 96, height: 96).clipShape(Circle())
                } else {
                    Text(client.name.prefix(1))
                        .font(.system(size: 40, weight: .bold)).foregroundColor(.black)
                }
            }
            .onAppear {
                profileImage = ProfileImageManager.shared.loadImage(
                    forKey: ProfileImageManager.profileImageKey(for: client.id))
            }
            VStack(spacing: 4) {
                Text(client.name).font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(client.email).font(.subheadline).foregroundColor(.white.opacity(0.7))
                HStack(spacing: 16) {
                    Label("\(stats.daysActive) days", systemImage: "calendar")
                    if let foundVia = client.foundVia {
                        Label(foundVia, systemImage: "link")
                    }
                }
                .font(.caption).foregroundColor(.tmGold)
            }
        }
        .padding().frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05)).cornerRadius(16)
    }
}

// MARK: - Quick Actions

struct QuickActionsSection: View {
    let onSendVideo:    () -> Void
    let onViewMessages: () -> Void
    var onShareFile:    (() -> Void)? = nil
    let unviewedCount:  Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Quick Actions").font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Button(action: onSendVideo) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.tmGoldGradient()).frame(width: 60, height: 60)
                            Image(systemName: "video.fill").font(.title2).foregroundColor(.black)
                        }
                        Text("Send Video").font(.caption).fontWeight(.semibold).foregroundColor(.white)
                    }
                }
                Button(action: onViewMessages) {
                    VStack(spacing: 8) {
                        ZStack(alignment: .topTrailing) {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 60, height: 60)
                            Image(systemName: "message.fill").font(.title2).foregroundColor(.tmGold)
                            if unviewedCount > 0 {
                                Text("\(unviewedCount)")
                                    .font(.caption2).fontWeight(.bold).foregroundColor(.black)
                                    .padding(4).background(Color.red).clipShape(Circle())
                                    .offset(x: 8, y: -8)
                            }
                        }
                        Text("Messages").font(.caption).fontWeight(.semibold).foregroundColor(.white)
                    }
                }
                if let onShareFile = onShareFile {
                    Button(action: onShareFile) {
                        VStack(spacing: 8) {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 60, height: 60)
                                .overlay(Image(systemName: "folder.badge.plus")
                                    .font(.title2).foregroundColor(.tmGold))
                            Text("Share File").font(.caption).fontWeight(.semibold).foregroundColor(.white)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(16)
    }
}

// MARK: - Recent Messages

struct RecentMessagesSection: View {
    let messages:  [VideoMessage]
    @ObservedObject var viewModel: VideoMessageViewModel
    let onViewAll: () -> Void
    @State private var selectedMessage: VideoMessage?
    @State private var showingPlayer = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Video Messages").font(.headline).foregroundColor(.white)
                Spacer()
                Button(action: onViewAll) {
                    Text("View All").font(.subheadline).foregroundColor(.tmGold)
                }
            }
            ForEach(messages) { message in
                MessagePreviewCard(message: message) {
                    selectedMessage = message
                    showingPlayer   = true
                    if !message.isViewed { viewModel.markAsViewed(message) }
                }
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(16)
        .sheet(isPresented: $showingPlayer) {
            if let msg = selectedMessage {
                VideoMessagePlayerView(message: msg, onClose: { showingPlayer = false })
            }
        }
    }
}

struct MessagePreviewCard: View {
    let message: VideoMessage
    let onTap:   () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05))
                        .frame(width: 60, height: 60)
                    Image(systemName: "play.circle.fill").font(.title2).foregroundColor(.tmGold)
                    if message.isNew {
                        VStack { HStack { Spacer()
                            Circle().fill(Color.red).frame(width: 10, height: 10)
                        }; Spacer() }
                    }
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.title).font(.subheadline).fontWeight(.semibold)
                        .foregroundColor(.white).lineLimit(1)
                    HStack {
                        Text(message.messageType.rawValue).font(.caption).foregroundColor(.tmGold)
                        Text("•").foregroundColor(.white.opacity(0.5))
                        Text(message.timeAgo).font(.caption).foregroundColor(.white.opacity(0.5))
                    }
                }
                Spacer()
                Text(message.formattedDuration).font(.caption).foregroundColor(.white.opacity(0.6))
            }
            .padding(12).background(Color.white.opacity(0.05)).cornerRadius(12)
        }
    }
}

// MARK: - Client Stats

struct ClientStatsSection: View {
    let stats: ClientStats

    var body: some View {
        VStack(spacing: 12) {
            Text("Statistics").font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ClientStatCard(title: "Total Workouts",  value: "\(stats.totalWorkouts)",
                               icon: "figure.strengthtraining.traditional")
                ClientStatCard(title: "Completion Rate",
                               value: String(format: "%.0f%%", stats.completionRate),
                               icon: "chart.line.uptrend.xyaxis")
                ClientStatCard(title: "Active Workouts", value: "\(stats.activeWorkouts)",
                               icon: "flame.fill")
                if let wc = stats.weightChange {
                    ClientStatCard(title: "Weight Change",
                                   value: String(format: "%.1f kg", wc),
                                   icon: "scalemass.fill", isPositive: wc < 0)
                }
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(16)
    }
}

struct ClientStatCard: View {
    let title:  String
    let value:  String
    let icon:   String
    var isPositive: Bool = true

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(.tmGold)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.white.opacity(0.05)).cornerRadius(12)
    }
}

// MARK: - Activity

struct ActivitySection: View {
    let client: Client

    var body: some View {
        VStack(spacing: 12) {
            Text("Activity Tracking").font(.headline).foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                ActivityCard(title: "Steps Today", value: "\(client.dailySteps)",
                             icon: "figure.walk", color: .green)
                ActivityCard(title: "Distance",
                             value: String(format: "%.1f km", client.dailyDistance),
                             icon: "map", color: .blue)
            }
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(statusColor(for: client.activityStatus)).font(.caption)
                Text(client.activityStatus).font(.subheadline).foregroundColor(.white.opacity(0.8))
                Spacer()
                if let lastSync = client.lastSyncDate {
                    Text("Synced \(timeAgo(lastSync))").font(.caption).foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(16)
    }

    private func statusColor(for status: String) -> Color {
        switch status {
        case "Very Active": return .green
        case "Active":      return .yellow
        case "Lightly Active": return .orange
        default: return .red
        }
    }
    private func timeAgo(_ date: Date) -> String {
        let m = Int(Date().timeIntervalSince(date) / 60)
        return m < 60 ? "\(m)m ago" : "\(m/60)h ago"
    }
}

struct ActivityCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title3).foregroundColor(color)
            Text(value).font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text(title).font(.caption).foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.white.opacity(0.05)).cornerRadius(12)
    }
}

// MARK: - Progress

struct ProgressSection: View {
    let entries: [ProgressEntry]
    var body: some View {
        if !entries.isEmpty {
            VStack(spacing: 12) {
                Text("Recent Progress").font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ForEach(entries.prefix(3)) { entry in ProgressEntryRow(entry: entry) }
            }
            .padding().background(Color.white.opacity(0.05)).cornerRadius(16)
        }
    }
}

struct ProgressEntryRow: View {
    let entry: ProgressEntry
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date, style: .date).font(.subheadline).foregroundColor(.white)
                if let weight = entry.weight {
                    Text(String(format: "%.1f kg", weight)).font(.caption).foregroundColor(.tmGold)
                }
            }
            Spacer()
            if let notes = entry.notes {
                Text(notes).font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(2)
            }
        }
        .padding().background(Color.white.opacity(0.05)).cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        EnhancedClientDetailView(
            trainerViewModel: TrainerViewModel(),
            client: Client.sampleClients[0]
        )
    }
}

// MARK: - Shared Files Section

struct TrainerSharedFilesSection: View {
    let trainerId:   String
    let clientId:    String
    let clientName:  String
    let onShareFile: () -> Void
    @ObservedObject private var fileStore = TrainerFileStore.shared
    @State private var showingAll = false

    private var files: [TrainerSharedFile] {
        Array(fileStore.files(forTrainer: trainerId, clientId: clientId).prefix(3))
    }
    private var totalCount: Int {
        fileStore.files(forTrainer: trainerId, clientId: clientId).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill").foregroundColor(.tmGold).font(.caption)
                    Text("SHARED FILES").font(.system(size: 11, weight: .bold))
                        .tracking(1.2).foregroundColor(.tmGold)
                    if totalCount > 0 {
                        Text("\(totalCount)").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.tmGold))
                    }
                }
                Spacer()
                HStack(spacing: 12) {
                    if totalCount > 3 {
                        Button("See All") { showingAll = true }
                            .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }
                    Button(action: onShareFile) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus"); Text("Share")
                        }
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(Color.tmGold))
                    }
                }
            }
            if files.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "doc.badge.plus").font(.title3).foregroundColor(.white.opacity(0.2))
                    Text("No files shared yet. Tap Share to send documents to \(clientName).")
                        .font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1)))
            } else {
                ForEach(files) { file in TrainerFileRow(file: file, showDelete: true) }
            }
        }
        .sheet(isPresented: $showingAll) {
            NavigationView {
                TrainerAllFilesView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - File Row

struct TrainerFileRow: View {
    let file:       TrainerSharedFile
    var showDelete: Bool = false
    @ObservedObject private var fileStore = TrainerFileStore.shared
    @State private var showingDeleteAlert = false
    @State private var previewURL: URL?

    var body: some View {
        Button(action: openFile) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(file.typeColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: file.typeIcon).font(.system(size: 16)).foregroundColor(file.typeColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(file.name).font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white).lineLimit(1)
                    HStack(spacing: 6) {
                        Text(file.fileType.rawValue).font(.caption).foregroundColor(file.typeColor)
                        Text("·").foregroundColor(.white.opacity(0.2))
                        Text(file.uploadedAt, style: .date).font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                    if let note = file.note {
                        Text(note).font(.caption2).foregroundColor(.white.opacity(0.35)).lineLimit(1)
                    }
                }
                Spacer()
                if showDelete {
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
                            .padding(8).background(Circle().fill(Color.red.opacity(0.08)))
                    }
                } else {
                    Image(systemName: "eye.fill").font(.caption).foregroundColor(.tmGold.opacity(0.6))
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1)))
        }
        .buttonStyle(.plain)
        .alert("Delete File?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { fileStore.deleteFile(file) }
        } message: { Text("Remove \"\(file.name)\"?") }
        .quickLookPreview($previewURL)
    }

    private func openFile() {
        let url = file.fileURL
        if FileManager.default.fileExists(atPath: url.path) { previewURL = url }
    }
}

// MARK: - All Files View

struct TrainerAllFilesView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var fileStore = TrainerFileStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var showingUpload = false

    private var files: [TrainerSharedFile] {
        fileStore.files(forTrainer: trainerId, clientId: clientId)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if files.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder").font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.15)).padding(.top, 60)
                    Text("No files shared with \(clientName) yet.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                    Button(action: { showingUpload = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill"); Text("Share First File")
                        }
                        .foregroundColor(.black).padding(.horizontal, 24).padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(files) { file in
                        TrainerFileRow(file: file, showDelete: true)
                            .listRowBackground(Color.white.opacity(0.03))
                            .listRowSeparatorTint(Color.white.opacity(0.06))
                    }
                }
                .listStyle(.plain).scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Files — \(clientName)").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingUpload = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus"); Text("Share")
                    }.fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .sheet(isPresented: $showingUpload) {
            NavigationView {
                TrainerUploadFileView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold)
        }
    }
}

// MARK: - Trainer Check-In Summary

struct TrainerClientCheckInSummary: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBCheckInStore.shared
    @State private var showingAll = false

    private var clientCheckIns: [CheckInRow] {
        store.checkIns.filter { $0.trainerId.uuidString == trainerId && $0.clientId.uuidString == clientId }
    }
    private var pending: [CheckInRow] { clientCheckIns.filter { ($0.notes ?? "").isEmpty } }
    private var latest:  CheckInRow?  { clientCheckIns.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill").foregroundColor(.tmGold).font(.caption)
                    Text("CHECK-INS").font(.system(size: 11, weight: .bold))
                        .tracking(1.2).foregroundColor(.tmGold)
                    if !pending.isEmpty {
                        Text("\(pending.count)").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.tmGold))
                    }
                }
                Spacer()
                Button("View All") { showingAll = true }
                    .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
            }

            if clientCheckIns.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder").font(.title3).foregroundColor(.white.opacity(0.2))
                    Text("\(clientName) hasn't submitted any check-ins yet.")
                        .font(.caption).foregroundColor(.white.opacity(0.35))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.06), lineWidth: 1)))
            } else if let ci = latest {
                Button(action: { showingAll = true }) {
                    HStack(spacing: 14) {
                        HStack(spacing: 4) {
                            ForEach([ci.frontURL, ci.rearURL].compactMap { $0 }.prefix(2), id: \.self) { url in
                                AsyncCheckInThumbSB(url: url)
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest: \(ci.formattedDate)")
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                            Text(ci.formattedWeight).font(.caption).foregroundColor(.tmGold)
                            Text(ci.isReviewed ? "✓ Reviewed" : "⏳ Needs review")
                                .font(.caption2).fontWeight(.semibold)
                                .foregroundColor(ci.isReviewed ? .green : .orange)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold.opacity(0.5))
                    }
                    .padding(12).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { store.loadForTrainer(trainerId) }
        .sheet(isPresented: $showingAll) {
            NavigationView {
                TrainerSingleClientCheckInsView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct AsyncCheckInThumbSB: View {
    let url: URL
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Color.white.opacity(0.06)
            }
        }
        .frame(width: 48, height: 56).clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            if let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { image = UIImage(data: data) }
            }
        }
    }
}

// MARK: - Single Client Check-Ins View

struct TrainerSingleClientCheckInsView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBCheckInStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: TrainerCheckInsView.FilterMode = .pending

    private var items: [CheckInRow] {
        let all = store.checkIns.filter {
            $0.trainerId.uuidString == trainerId && $0.clientId.uuidString == clientId
        }
        switch selectedFilter {
        case .pending:  return all.filter { ($0.notes ?? "").isEmpty }
        case .reviewed: return all.filter { !($0.notes ?? "").isEmpty }
        case .all:      return all
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(TrainerCheckInsView.FilterMode.allCases, id: \.self) { mode in
                        Button(action: { selectedFilter = mode }) {
                            Text(mode.rawValue).font(.system(size: 13, weight: .bold))
                                .foregroundColor(selectedFilter == mode ? .black : .white.opacity(0.4))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(selectedFilter == mode ? Color.tmGold : Color.clear)
                        }
                    }
                }
                .background(Color.white.opacity(0.05))

                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.viewfinder").font(.system(size: 44))
                            .foregroundColor(.white.opacity(0.15)).padding(.top, 50)
                        Text("No \(selectedFilter.rawValue.lowercased()) check-ins from \(clientName)")
                            .font(.subheadline).foregroundColor(.white.opacity(0.4)).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(items) { ci in SBTrainerCheckInCard(checkIn: ci) }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("\(clientName)'s Check-Ins").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold); Text("Back")
                    }.foregroundColor(.tmGold)
                }
            }
        }
        .onAppear { store.loadForTrainer(trainerId) }
    }
}

// MARK: - Trainer Workout Summary

struct TrainerClientWorkoutSummary: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = SBWorkoutStore.shared
    @State private var showingWorkouts = false
    @State private var showingBuilder  = false

    private var allWorkouts: [WorkoutRow] {
        store.workouts.filter { $0.clientId.uuidString == clientId }
    }
    private var pending: [WorkoutRow] { allWorkouts.filter { $0.status == "assigned" } }
    private var latest:   WorkoutRow? { allWorkouts.first }
    private var completionRate: Int {
        guard !allWorkouts.isEmpty else { return 0 }
        let done = allWorkouts.filter { $0.status == "completed" }.count
        return Int(Double(done) / Double(allWorkouts.count) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill").foregroundColor(.tmGold).font(.caption)
                    Text("WORKOUTS").font(.system(size: 11, weight: .bold))
                        .tracking(1.2).foregroundColor(.tmGold)
                    if !pending.isEmpty {
                        Text("\(pending.count)").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.tmGold))
                    }
                }
                Spacer()
                HStack(spacing: 10) {
                    Button(action: { showingBuilder = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Assign").font(.caption).fontWeight(.semibold)
                        }.foregroundColor(.tmGold)
                    }
                    Button("View All") { showingWorkouts = true }
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }

            if allWorkouts.isEmpty {
                Button(action: { showingBuilder = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell").font(.title3).foregroundColor(.tmGold.opacity(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No workouts assigned").font(.subheadline).fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.5))
                            Text("Tap to build and assign the first workout")
                                .font(.caption).foregroundColor(.white.opacity(0.3))
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold.opacity(0.4))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
                }
                .buttonStyle(.plain)
            } else {
                HStack(spacing: 0) {
                    wkStat("\(allWorkouts.count)", "Total")
                    Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                    wkStat("\(pending.count)", "Pending")
                    Divider().background(Color.white.opacity(0.08)).frame(height: 30)
                    wkStat("\(completionRate)%", "Done")
                }
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))

                if let w = latest {
                    Button(action: { showingWorkouts = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(wDiffColor(w.difficulty).opacity(0.15)).frame(width: 38, height: 38)
                                Image(systemName: wStatusIcon(w.status))
                                    .font(.system(size: 14)).foregroundColor(wDiffColor(w.difficulty))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(w.title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                                HStack(spacing: 6) {
                                    Text("\(w.exercises.count) exercises"); Text("·")
                                    Text("\(w.estimatedMins) min")
                                }
                                .font(.caption).foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Text(w.status.capitalized).font(.system(size: 9, weight: .bold))
                                .foregroundColor(w.status == "completed" ? .black : .white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(
                                    w.status == "completed" ? Color.green :
                                    w.status == "assigned"  ? Color.tmGold : Color.orange))
                        }
                        .padding(12).background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear { store.loadForClient(clientId) }
        .sheet(isPresented: $showingWorkouts) {
            NavigationView {
                TrainerClientWorkoutsView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(isPresented: $showingBuilder) {
            NavigationView {
                WorkoutBuilderView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func wkStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .black)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
    private func wDiffColor(_ d: String) -> Color {
        switch d { case "beginner": return .green; case "advanced": return .red; default: return .tmGold }
    }
    private func wStatusIcon(_ s: String) -> String {
        switch s { case "completed": return "checkmark.circle.fill"; case "skipped": return "xmark.circle"; default: return "dumbbell" }
    }
}
