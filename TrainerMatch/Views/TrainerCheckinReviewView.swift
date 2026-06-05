//
//  TrainerCheckInReviewView.swift
//  TrainerMatch
//
//  Task 5 — Trainer Check-In Review
//

import SwiftUI
import Supabase

// MARK: - Image Cache

private class CIImageCache {
    static let shared = CIImageCache()
    private var cache = NSCache<NSString, UIImage>()
    private init() { cache.countLimit = 200; cache.totalCostLimit = 50 * 1024 * 1024 }
    func get(_ key: String) -> UIImage? { cache.object(forKey: key as NSString) }
    func set(_ image: UIImage, for key: String) { cache.setObject(image, forKey: key as NSString) }
}

// MARK: - Wrapper to make URL Identifiable

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

// MARK: - Main Review View

struct TrainerCheckInReviewView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String

    @State private var checkIns: [CheckInRow] = []
    @State private var filter: FilterMode = .pending
    @State private var selectedCheckIn: CheckInRow? = nil
    @State private var isLoading = true

    enum FilterMode: String, CaseIterable {
        case pending  = "Needs Review"
        case reviewed = "Reviewed"
        case all      = "All"
    }

    private var items: [CheckInRow] {
        switch filter {
        case .pending:  return checkIns.filter { ($0.trainerFeedback ?? "").isEmpty }
        case .reviewed: return checkIns.filter { !($0.trainerFeedback ?? "").isEmpty }
        case .all:      return checkIns
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(action: { filter = mode }) {
                        VStack(spacing: 2) {
                            Text(mode.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(filter == mode ? .black : .white.opacity(0.4))
                            if mode == .pending {
                                let count = checkIns.filter { ($0.trainerFeedback ?? "").isEmpty }.count
                                if count > 0 {
                                    Text("\(count)")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(filter == mode ? .black : .orange)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(filter == mode ? Color.tmGold : Color.clear)
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 16)

            if isLoading {
                ProgressView().tint(.tmGold).padding(.top, 40)
            } else if items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: filter == .pending
                          ? "checkmark.circle.fill" : "camera.viewfinder")
                        .font(.system(size: 44))
                        .foregroundColor(filter == .pending
                                         ? .green.opacity(0.4) : .white.opacity(0.1))
                        .padding(.top, 40)
                    Text(filter == .pending
                         ? "All caught up! No pending check-ins."
                         : "No \(filter.rawValue.lowercased()) check-ins from \(clientName).")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 14) {
                    ForEach(items) { checkIn in
                        CITrainerCard(checkIn: checkIn)
                            .onTapGesture { selectedCheckIn = checkIn }
                    }
                }
            }
        }
        .task { await loadCheckIns() }
        .sheet(item: $selectedCheckIn) { checkIn in
            NavigationView {
                TrainerCheckInDetailView(
                    checkIn:    checkIn,
                    clientName: clientName,
                    onReviewed: { await loadCheckIns() }
                )
            }
            .tint(.tmGold)
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func loadCheckIns() async {
        isLoading = true
        do {
            let rows: [CheckInRow] = try await supabase
                .from("check_ins")
                .select()
                .eq("trainer_id", value: trainerId)
                .eq("client_id",  value: clientId)
                .order("checked_in_at", ascending: false)
                .execute()
                .value
            await MainActor.run {
                checkIns  = rows
                isLoading = false
            }
        } catch {
            print("❌ Failed to load check-ins: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Check-In Card

struct CITrainerCard: View {
    let checkIn: CheckInRow

    private var isReviewed: Bool { !( checkIn.trainerFeedback ?? "").isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(checkIn.checkedInAt?.formatted(.dateTime.month(.abbreviated)) ?? "—")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.tmGold)
                    Text(checkIn.checkedInAt?.formatted(.dateTime.day()) ?? "—")
                        .font(.system(size: 22, weight: .black)).foregroundColor(.white)
                }
                .frame(width: 44).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.tmGold.opacity(0.1)))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        if let w = checkIn.weight {
                            ciMiniStat("scalemass.fill", String(format: "%.1f lbs", w), .tmGold)
                        }
                        if let e = checkIn.energyLevel {
                            ciMiniStat("bolt.fill", "\(e)/5", ciEnergyColor(e))
                        }
                        if let s = checkIn.sleepHours {
                            ciMiniStat("moon.fill", String(format: "%.1fh", s), .purple)
                        }
                    }
                    if let w = checkIn.waterOz {
                        ciMiniStat("drop.fill", "\(w) oz", .cyan)
                    }
                }

                Spacer()

                Text(isReviewed ? "✓ Reviewed" : "⏳ Needs Review")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isReviewed ? .black : .orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(isReviewed ? Color.green : Color.orange.opacity(0.2)))
            }

            // Photo strip
            if !checkIn.photoUrls.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(checkIn.photoUrls.prefix(3), id: \.self) { urlStr in
                            CIThumbView(urlStr: urlStr)
                        }
                    }
                }
            }

            if !checkIn.notes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble.fill").font(.caption2).foregroundColor(.tmGold)
                    Text(checkIn.notes).font(.caption).foregroundColor(.white.opacity(0.6)).lineLimit(2)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
            }

            if !isReviewed {
                HStack {
                    Spacer()
                    Text("Tap to review →")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold.opacity(0.7))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(isReviewed ? Color.green.opacity(0.2) : Color.tmGold.opacity(0.25),
                            lineWidth: 1))
        )
    }

    private func ciMiniStat(_ icon: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.1)))
    }

    private func ciEnergyColor(_ level: Int) -> Color {
        switch level {
        case 1, 2: return .red.opacity(0.8)
        case 3:    return .orange
        case 4:    return .tmGold
        case 5:    return .green
        default:   return .white
        }
    }
}

// MARK: - Detail View

struct TrainerCheckInDetailView: View {
    let checkIn:    CheckInRow
    let clientName: String
    let onReviewed: () async -> Void

    @Environment(\.dismiss) var dismiss
    @State private var reviewNote  = ""
    @State private var isSaving    = false
    @State private var showSuccess = false
    @State private var selectedPhoto: IdentifiableURL? = nil

    private var isReviewed: Bool { !(checkIn.trainerFeedback ?? "").isEmpty }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    ciClientHeader
                    ciStatsGrid
                    if !checkIn.photoUrls.isEmpty { ciPhotosSection }
                    if isReviewed { ciExistingNote }
                    else          { ciReviewSection }
                }
                .padding(20).padding(.bottom, 40)
            }
        }
        .navigationTitle("\(clientName)'s Check-In")
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
        }
        .navigationBarBackButtonHidden(true)
        .alert("Review Sent! ✅", isPresented: $showSuccess) {
            Button("Done") {
                Task { await onReviewed() }
                dismiss()
            }
        } message: {
            Text("\(clientName) will be notified that you reviewed their check-in.")
        }
        .sheet(item: $selectedPhoto) { item in
            FullscreenPhotoView(url: item.url, label: "\(clientName)'s check-in photo")
        }
    }

    private var ciClientHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 52, height: 52)
                Text(clientName.prefix(1).uppercased())
                    .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(clientName).font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                Text(checkIn.checkedInAt?.formatted(
                    .dateTime.weekday(.wide).month(.wide).day().year()
                ) ?? "Unknown date")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Text(isReviewed ? "✓ Reviewed" : "Needs Review")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isReviewed ? .black : .orange)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(isReviewed ? Color.green : Color.orange.opacity(0.2)))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }

    private var ciStatsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            ciSectionLabel("STATS", icon: "chart.bar.fill")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let w = checkIn.weight {
                    ciStatCard("Weight", String(format: "%.1f lbs", w), "scalemass.fill", .tmGold)
                }
                if let e = checkIn.energyLevel {
                    ciStatCard("Energy", "\(e) / 5", "bolt.fill", ciEnergyColor(e))
                }
                if let s = checkIn.sleepHours {
                    ciStatCard("Sleep", String(format: "%.1f hrs", s), "moon.fill", .purple)
                }
                if let w = checkIn.waterOz {
                    ciStatCard("Water", "\(w) oz", "drop.fill", .cyan)
                }
            }
            if !checkIn.notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CLIENT'S NOTE")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                    Text(checkIn.notes)
                        .font(.body).foregroundColor(.white.opacity(0.8)).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                }
            }
        }
    }

    private var ciPhotosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ciSectionLabel("PROGRESS PHOTOS", icon: "photo.fill")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8),
                               count: min(checkIn.photoUrls.count, 3)),
                spacing: 8
            ) {
                ForEach(checkIn.photoUrls, id: \.self) { urlStr in
                    if let url = URL(string: urlStr) {
                        Button(action: { selectedPhoto = IdentifiableURL(url: url) }) {
                            CIPhotoLarge(urlStr: urlStr)
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var ciExistingNote: some View {
        VStack(alignment: .leading, spacing: 12) {
            ciSectionLabel("YOUR REVIEW", icon: "bubble.left.and.bubble.right.fill")
            Text(checkIn.trainerFeedback ?? "")
                .font(.body).foregroundColor(.white.opacity(0.85)).padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1))
                )
        }
    }

    private var ciReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ciSectionLabel("LEAVE A REVIEW", icon: "bubble.left.fill")
            TextField("Great work this week! I noticed...", text: $reviewNote, axis: .vertical)
                .lineLimit(4...8).foregroundColor(.white).padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                )
            Button(action: submitReview) {
                HStack(spacing: 10) {
                    if isSaving {
                        ProgressView().tint(.black).scaleEffect(0.9)
                        Text("Saving...").font(.system(size: 15, weight: .heavy)).foregroundColor(.black)
                    } else {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                        Text("MARK AS REVIEWED").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 27)
                        .fill(reviewNote.isEmpty ? Color.white.opacity(0.1) : Color.tmGold)
                        .shadow(color: reviewNote.isEmpty ? .clear : Color.tmGold.opacity(0.4),
                                radius: 10, y: 4)
                )
            }
            .disabled(reviewNote.isEmpty || isSaving)
        }
    }

    private func ciSectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            Text(text).font(.system(size: 11, weight: .black)).tracking(1.2).foregroundColor(.tmGold)
        }
    }

    private func ciStatCard(_ label: String, _ value: String,
                              _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            Text(value).font(.system(size: 17, weight: .black)).foregroundColor(.white)
            Text(label).font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 12).fill(color.opacity(0.08)))
    }

    private func ciEnergyColor(_ level: Int) -> Color {
        switch level {
        case 1, 2: return .red.opacity(0.8)
        case 3:    return .orange
        case 4:    return .tmGold
        case 5:    return .green
        default:   return .white
        }
    }

    private func submitReview() {
        guard !reviewNote.isEmpty else { return }
        isSaving = true
        Task {
            do {
                struct Update: Encodable {
                    let trainerFeedback: String
                    enum CodingKeys: String, CodingKey {
                        case trainerFeedback = "trainer_feedback"
                    }
                }
                try await supabase.from("check_ins")
                    .update(Update(trainerFeedback: reviewNote))
                    .eq("id", value: checkIn.id)
                    .execute()

                PushNotificationManager.shared.sendTrainerAcceptedNotification(
                    toClientId:  checkIn.clientId.uuidString,
                    trainerName: "Your Trainer"
                )

                await MainActor.run { isSaving = false; showSuccess = true }
            } catch {
                print("❌ Review save failed: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}

// MARK: - Cached Thumbnail

struct CIThumbView: View {
    let urlStr: String
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
            } else if failed {
                Color.white.opacity(0.06)
                    .overlay(Image(systemName: "photo.slash").foregroundColor(.white.opacity(0.3)))
            } else {
                Color.white.opacity(0.06)
                    .overlay(ProgressView().tint(.tmGold).scaleEffect(0.7))
            }
        }
        .frame(width: 72, height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .task(id: urlStr) { await load() }
    }

    private func load() async {
        // Check cache first
        if let cached = CIImageCache.shared.get(urlStr) {
            await MainActor.run { image = cached }
            return
        }

        // Try loading the URL
        guard let url = URL(string: urlStr) else {
            await MainActor.run { failed = true }
            return
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 15
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ Photo load failed — status: \((response as? HTTPURLResponse)?.statusCode ?? 0) url: \(urlStr)")
                await MainActor.run { failed = true }
                return
            }

            guard let full = UIImage(data: data) else {
                await MainActor.run { failed = true }
                return
            }

            // Downsample for thumbnail
            let thumb = await Task.detached(priority: .utility) {
                let size = CGSize(width: 144, height: 168)
                return UIGraphicsImageRenderer(size: size).image { _ in
                    full.draw(in: CGRect(origin: .zero, size: size))
                }
            }.value

            CIImageCache.shared.set(thumb, for: urlStr)
            await MainActor.run { image = thumb }

        } catch {
            print("❌ Photo load error: \(error.localizedDescription) url: \(urlStr)")
            await MainActor.run { failed = true }
        }
    }
}

// MARK: - Cached Large Photo

struct CIPhotoLarge: View {
    let urlStr: String
    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img).resizable().scaledToFill()
            } else if failed {
                Color.white.opacity(0.06)
                    .overlay(Image(systemName: "photo.slash").foregroundColor(.white.opacity(0.3)))
            } else {
                Color.white.opacity(0.06)
                    .overlay(ProgressView().tint(.tmGold))
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .task(id: urlStr) { await load() }
    }

    private func load() async {
        if let cached = CIImageCache.shared.get(urlStr + "_large") {
            await MainActor.run { image = cached }
            return
        }

        guard let url = URL(string: urlStr) else {
            await MainActor.run { failed = true }
            return
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 20
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("❌ Large photo failed — status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                await MainActor.run { failed = true }
                return
            }

            guard let img = UIImage(data: data) else {
                await MainActor.run { failed = true }
                return
            }

            CIImageCache.shared.set(img, for: urlStr + "_large")
            await MainActor.run { image = img }

        } catch {
            print("❌ Large photo error: \(error.localizedDescription)")
            await MainActor.run { failed = true }
        }
    }
}
