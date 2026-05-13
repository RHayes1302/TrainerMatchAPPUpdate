//
//  TrainerResultsGallery.swift
//  TrainerMatch
//
//  Fully migrated to Supabase.
//  - SBTrainerResultRow  → trainer_results table
//  - SBTrainerResultsStore → fetch / save / delete
//  - ProofOfWorkSection  → trainer-side manage (replaces local version)
//  - TrainerResultsGalleryView → public read-only (used in public profile)
//

import SwiftUI
import PhotosUI

// MARK: - Row Model

struct SBTrainerResultRow: Codable, Identifiable {
    var id:            UUID
    var trainerId:     UUID
    var goalAchieved:  String
    var duration:      String
    var clientLabel:   String
    var beforeUrl:     String
    var afterUrl:      String
    var createdAt:     Date?

    enum CodingKeys: String, CodingKey {
        case id
        case trainerId    = "trainer_id"
        case goalAchieved = "goal_achieved"
        case duration
        case clientLabel  = "client_label"
        case beforeUrl    = "before_url"
        case afterUrl     = "after_url"
        case createdAt    = "created_at"
    }
}

// MARK: - Store

@MainActor
class SBTrainerResultsStore: ObservableObject {
    static let shared = SBTrainerResultsStore()
    @Published var results: [SBTrainerResultRow] = []
    private init() {}

    func fetch(trainerId: UUID) async {
        results = (try? await supabase
            .from("trainer_results")
            .select()
            .eq("trainer_id", value: trainerId)
            .order("created_at", ascending: false)
            .execute()
            .value) ?? []
    }

    func save(
        trainerId: UUID,
        goalAchieved: String,
        duration: String,
        clientLabel: String,
        beforeData: Data,
        afterData: Data?
    ) async throws {
        let resultId = UUID()

        // Upload before photo (required)
        let beforePath = "\(trainerId)/\(resultId)_before.jpg"
        let beforeUrl = try await SupabaseStorage.uploadImage(
            data: beforeData, bucket: .trainerResults, path: beforePath)

        // Upload after photo (optional)
        var afterUrl = ""
        if let afterData {
            let afterPath = "\(trainerId)/\(resultId)_after.jpg"
            afterUrl = try await SupabaseStorage.uploadImage(
                data: afterData, bucket: .trainerResults, path: afterPath)
        }

        let row = SBTrainerResultRow(
            id: resultId,
            trainerId: trainerId,
            goalAchieved: goalAchieved,
            duration: duration,
            clientLabel: clientLabel,
            beforeUrl: beforeUrl,
            afterUrl: afterUrl,
            createdAt: Date()
        )
        try await supabase.from("trainer_results").insert(row).execute()
        results.insert(row, at: 0)
    }

    func delete(_ result: SBTrainerResultRow) async {
        await SupabaseStorage.deleteTrainerResultPhotos(
            trainerId: result.trainerId.uuidString,
            resultId: result.id.uuidString)
        try? await supabase.from("trainer_results")
            .delete()
            .eq("id", value: result.id)
            .execute()
        results.removeAll { $0.id == result.id }
    }
}

// MARK: - ProofOfWorkSection (trainer-side, replaces local version)

struct ProofOfWorkSection: View {
    let trainerId: String
    @StateObject private var store = SBTrainerResultsStore.shared
    @State private var showingAddSheet = false
    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 0) {

            // Explainer banner
            HStack(spacing: 14) {
                Image(systemName: "megaphone.fill")
                    .font(.title2).foregroundColor(.tmGold)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Proof of Work")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text("These photos appear on your PUBLIC profile so potential clients can see real results before contacting you.")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.tmGold.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.tmGold.opacity(0.35), lineWidth: 1)))
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 20)

            // Upload button
            Button(action: { showingAddSheet = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ADD CLIENT RESULT")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        Text("Upload a before & after photo")
                            .font(.caption).opacity(0.75)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).opacity(0.6)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14)
                    .fill(Color.tmGold)
                    .shadow(color: .tmGold.opacity(0.4), radius: 10, x: 0, y: 5))
            }
            .padding(.horizontal, 20).padding(.bottom, 24)

            if isLoading {
                ProgressView().tint(.tmGold).padding(.top, 40)
            } else if store.results.isEmpty {
                emptyState
            } else {
                manageGallery
            }
        }
        .task {
            if let tid = UUID(uuidString: trainerId) {
                await store.fetch(trainerId: tid)
            }
            isLoading = false
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSBResultSheet(trainerId: trainerId, store: store)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().fill(Color.tmGold.opacity(0.08)).frame(width: 100, height: 100)
                Image(systemName: "camera.on.rectangle.fill")
                    .font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.5))
            }
            Text("No proof photos yet")
                .font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text("Upload before & after photos of clients you've helped.\n\nThese show up on your public profile as proof of your work — the best way to convert new clients.")
                .font(.subheadline).foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center).padding(.horizontal, 30)
        }
        .padding(.vertical, 40)
    }

    private var manageGallery: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR RESULTS (\(store.results.count))")
                    .font(.system(size: 12, weight: .bold)).foregroundColor(.tmGold).tracking(1.2)
                Spacer()
                Text("Tap card to delete")
                    .font(.caption2).foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 20)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                spacing: 14
            ) {
                ForEach(store.results) { result in
                    SBManageProofCard(result: result) {
                        Task { await store.delete(result) }
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 40)
        }
    }
}

// MARK: - Manage Card (trainer view — has delete)

struct SBManageProofCard: View {
    let result:   SBTrainerResultRow
    let onDelete: () -> Void
    @State private var beforeImage: UIImage?
    @State private var afterImage:  UIImage?
    @State private var showingDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    remotePhotoHalf(url: result.beforeUrl, label: "BEFORE",
                                    image: $beforeImage,
                                    width: geo.size.width / 2,
                                    height: geo.size.height, isAfter: false)
                    if !result.afterUrl.isEmpty {
                        remotePhotoHalf(url: result.afterUrl, label: "AFTER",
                                        image: $afterImage,
                                        width: geo.size.width / 2,
                                        height: geo.size.height, isAfter: true)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.04))
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                            .overlay(Text("No After").font(.caption2)
                                .foregroundColor(.white.opacity(0.2)))
                    }
                }
            }
            .frame(height: 120)

            VStack(alignment: .leading, spacing: 3) {
                if !result.goalAchieved.isEmpty {
                    Text(result.goalAchieved)
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold).lineLimit(1)
                }
                if !result.duration.isEmpty {
                    Text(result.duration).font(.caption2).foregroundColor(.white.opacity(0.5))
                }
                Button(action: { showingDeleteAlert = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash").font(.caption2)
                        Text("Remove").font(.caption2)
                    }
                    .foregroundColor(.red.opacity(0.7)).padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).padding(.vertical, 8)
            .background(Color.white.opacity(0.05))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
        .alert("Remove this result?", isPresented: $showingDeleteAlert) {
            Button("Remove", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the photos from your public profile.")
        }
    }

    private func remotePhotoHalf(
        url: String, label: String,
        image: Binding<UIImage?>,
        width: CGFloat, height: CGFloat, isAfter: Bool
    ) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let img = image.wrappedValue {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: width, height: height).clipped()
            } else {
                Rectangle().fill(Color.white.opacity(0.05))
                    .frame(width: width, height: height)
                    .overlay(ProgressView().tint(.tmGold))
            }
            Text(label)
                .font(.system(size: 7, weight: .black)).tracking(1)
                .foregroundColor(isAfter ? .black : .white)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Capsule().fill(isAfter ? Color.tmGold : Color.black.opacity(0.6)))
                .padding(5)
        }
        .frame(width: width, height: height)
        .task {
            guard image.wrappedValue == nil, let photoUrl = URL(string: url),
                  let data = try? await URLSession.shared.data(from: photoUrl).0 else { return }
            await MainActor.run { image.wrappedValue = UIImage(data: data) }
        }
    }
}

// MARK: - Add Result Sheet

struct AddSBResultSheet: View {
    let trainerId: String
    let store: SBTrainerResultsStore
    @Environment(\.dismiss) var dismiss

    @State private var goalAchieved  = ""
    @State private var duration      = ""
    @State private var clientLabel   = ""
    @State private var beforeItem:   PhotosPickerItem?
    @State private var afterItem:    PhotosPickerItem?
    @State private var beforeImage:  UIImage?
    @State private var afterImage:   UIImage?
    @State private var isSaving      = false
    @State private var errorMessage  = ""
    @State private var showingError  = false

    private var canSave: Bool { beforeImage != nil && !goalAchieved.isEmpty }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {

                        // Photo pickers
                        HStack(spacing: 12) {
                            photoUploadButton(
                                image: beforeImage, label: "BEFORE",
                                item: $beforeItem, isAfter: false)
                            photoUploadButton(
                                image: afterImage, label: "AFTER",
                                item: $afterItem, isAfter: true)
                        }
                        .frame(height: 200)
                        .padding(.horizontal, 20)

                        // Fields
                        VStack(spacing: 14) {
                            resultField("Result / Achievement *",
                                        placeholder: "e.g. Lost 28 lbs",
                                        text: $goalAchieved)
                            resultField("Time Frame",
                                        placeholder: "e.g. 12 weeks",
                                        text: $duration)
                            resultField("Client Label (optional)",
                                        placeholder: "e.g. Sarah – 3 months",
                                        text: $clientLabel)
                        }
                        .padding(.horizontal, 20)

                        // Consent
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill").foregroundColor(.tmGold)
                            Text("Only post photos with your client's consent.")
                                .font(.caption).foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)

                        // Save button
                        Button(action: saveResult) {
                            HStack(spacing: 8) {
                                if isSaving {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("SAVE RESULT")
                                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                }
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26)
                                .fill(canSave ? Color.tmGold : Color.gray.opacity(0.4)))
                        }
                        .disabled(!canSave || isSaving)
                        .padding(.horizontal, 20).padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Client Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
                }
            }
            .alert("Upload Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
            .onChange(of: beforeItem) { _, item in
                Task { beforeImage = await loadPickerImage(item) }
            }
            .onChange(of: afterItem) { _, item in
                Task { afterImage = await loadPickerImage(item) }
            }
        }
    }

    private func photoUploadButton(
        image: UIImage?, label: String,
        item: Binding<PhotosPickerItem?>, isAfter: Bool
    ) -> some View {
        PhotosPicker(selection: item, matching: .images) {
            ZStack(alignment: .bottomLeading) {
                if let img = image {
                    Image(uiImage: img).resizable().scaledToFill().clipped()
                } else {
                    RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.07))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2).foregroundColor(.tmGold)
                                Text("Add \(label)")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.6))
                            })
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.tmGold.opacity(0.3),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6])))
                }
                Text(label)
                    .font(.system(size: 10, weight: .black)).tracking(1.5)
                    .foregroundColor(isAfter ? .black : .white)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Capsule().fill(isAfter ? Color.tmGold : Color.black.opacity(0.5)))
                    .padding(8)
            }
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func resultField(_ label: String, placeholder: String,
                              text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.5))
            TextField(placeholder, text: text)
                .foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1))
        }
    }

    private func loadPickerImage(_ item: PhotosPickerItem?) async -> UIImage? {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self) else { return nil }
        return resized(UIImage(data: data), maxDim: 900)
    }

    private func resized(_ image: UIImage?, maxDim: CGFloat) -> UIImage? {
        guard let image else { return nil }
        let scale = maxDim / max(image.size.width, image.size.height)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func saveResult() {
        guard let tid = UUID(uuidString: trainerId),
              let beforeData = beforeImage?.jpegData(compressionQuality: 0.8) else { return }
        let afterData = afterImage?.jpegData(compressionQuality: 0.8)
        isSaving = true
        Task {
            do {
                try await store.save(
                    trainerId: tid,
                    goalAchieved: goalAchieved,
                    duration: duration,
                    clientLabel: clientLabel,
                    beforeData: beforeData,
                    afterData: afterData)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Public Gallery (used in SupabaseTrainerPublicProfileView & TrainerPublicProfileView)

struct TrainerResultsGalleryView: View {
    let trainerId: String
    @StateObject private var store = SBTrainerResultsStore.shared
    @State private var selectedResult: SBTrainerResultRow?
    @State private var loaded = false

    var body: some View {
        Group {
            if !loaded {
                EmptyView()
            } else if store.results.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.20))
                        Text("Client Results")
                            .font(.title3).fontWeight(.bold)
                            .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.20))
                        Spacer()
                        Text("\(store.results.count) transformation\(store.results.count == 1 ? "" : "s")")
                            .font(.caption).foregroundColor(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(store.results) { result in
                                SBPublicResultCard(result: result)
                                    .onTapGesture { selectedResult = result }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task {
            if let tid = UUID(uuidString: trainerId) {
                await store.fetch(trainerId: tid)
            }
            loaded = true
        }
        .sheet(item: $selectedResult) { result in
            SBResultLightbox(result: result)
        }
    }
}

// MARK: - Public Result Card

struct SBPublicResultCard: View {
    let result: SBTrainerResultRow
    @State private var beforeImage: UIImage?
    @State private var afterImage:  UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                remoteSlot(url: result.beforeUrl, label: "BEFORE",
                           image: $beforeImage, isAfter: false)
                if !result.afterUrl.isEmpty {
                    remoteSlot(url: result.afterUrl, label: "AFTER",
                               image: $afterImage, isAfter: true)
                }
            }
            .frame(width: result.afterUrl.isEmpty ? 120 : 240, height: 155)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.85, green: 0.70, blue: 0.20).opacity(0.4), lineWidth: 1))

            if !result.goalAchieved.isEmpty {
                Text(result.goalAchieved)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.85, green: 0.70, blue: 0.20)).lineLimit(1)
            }
            if !result.duration.isEmpty {
                Text(result.duration).font(.caption2).foregroundColor(.secondary)
            }
            Text("Tap to enlarge").font(.caption2).foregroundColor(.secondary.opacity(0.6))
        }
        .frame(width: result.afterUrl.isEmpty ? 120 : 240)
    }

    private func remoteSlot(url: String, label: String,
                             image: Binding<UIImage?>, isAfter: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let img = image.wrappedValue {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity).clipped()
            } else {
                Rectangle().fill(Color.white.opacity(0.06))
                    .overlay(ProgressView().tint(.tmGold))
            }
            Text(label)
                .font(.system(size: 9, weight: .black)).foregroundColor(isAfter ? .black : .white)
                .tracking(1.5).padding(.horizontal, 7).padding(.vertical, 3)
                .background(Capsule().fill(isAfter ? Color.tmGold : Color.black.opacity(0.55)))
                .padding(6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            guard image.wrappedValue == nil, let photoUrl = URL(string: url),
                  let data = try? await URLSession.shared.data(from: photoUrl).0 else { return }
            await MainActor.run { image.wrappedValue = UIImage(data: data) }
        }
    }
}

// MARK: - Lightbox

struct SBResultLightbox: View {
    let result: SBTrainerResultRow
    @Environment(\.dismiss) var dismiss
    @State private var beforeImage: UIImage?
    @State private var afterImage:  UIImage?
    @State private var showAfter = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    if !result.clientLabel.isEmpty {
                        Text(result.clientLabel)
                            .font(.caption).foregroundColor(.white.opacity(0.45))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

                if afterImage != nil {
                    HStack(spacing: 0) {
                        lightboxBtn("BEFORE", active: !showAfter) { showAfter = false }
                        lightboxBtn("AFTER",  active: showAfter)  { showAfter = true }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, 40).padding(.bottom, 20)
                }

                Spacer()

                Group {
                    if showAfter, let img = afterImage {
                        Image(uiImage: img).resizable().scaledToFit()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal:   .move(edge: .leading).combined(with: .opacity)))
                    } else if let img = beforeImage {
                        Image(uiImage: img).resizable().scaledToFit()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal:   .move(edge: .trailing).combined(with: .opacity)))
                    } else {
                        ProgressView().tint(.tmGold)
                    }
                }
                .animation(.spring(response: 0.4), value: showAfter)
                .padding(.horizontal, 16)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()

                VStack(spacing: 6) {
                    if !result.goalAchieved.isEmpty {
                        Text(result.goalAchieved)
                            .font(.system(size: 28, weight: .black)).foregroundColor(.tmGold)
                    }
                    if !result.duration.isEmpty {
                        Text(result.duration)
                            .font(.subheadline).foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .task {
            if let url = URL(string: result.beforeUrl),
               let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { beforeImage = UIImage(data: data) }
            }
            if !result.afterUrl.isEmpty,
               let url = URL(string: result.afterUrl),
               let data = try? await URLSession.shared.data(from: url).0 {
                await MainActor.run { afterImage = UIImage(data: data) }
            }
        }
    }

    private func lightboxBtn(_ label: String, active: Bool,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 13, weight: .bold)).tracking(1)
                .foregroundColor(active ? .black : .white.opacity(0.6))
                .frame(maxWidth: .infinity).padding(.vertical, 11)
                .background(active ? Color.tmGold : Color.white.opacity(0.08))
        }
    }
}

// MARK: - PublicResultsTab (used in SupabaseTrainerPublicProfileView)

struct PublicResultsTab: View {
    let trainerId: String
    @StateObject private var store = SBTrainerResultsStore.shared
    @State private var selectedResult: SBTrainerResultRow?
    @State private var loaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !loaded {
                ProgressView().tint(.tmGold).frame(maxWidth: .infinity).padding(.top, 40)
            } else if store.results.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "camera.on.rectangle")
                        .font(.system(size: 44)).foregroundColor(.white.opacity(0.2))
                    Text("No results posted yet")
                        .font(.headline).foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 60)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CLIENT TRANSFORMATIONS")
                                .font(.system(size: 11, weight: .black))
                                .tracking(1.5).foregroundColor(.tmGold)
                            Text("Real results from real clients")
                                .font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("\(store.results.count)")
                            .font(.system(size: 28, weight: .black)).foregroundColor(.tmGold)
                    }
                    .padding(.horizontal, 20)

                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 10),
                                  GridItem(.flexible(), spacing: 10)],
                        spacing: 12
                    ) {
                        ForEach(store.results) { result in
                            SBPublicProofTile(result: result)
                                .onTapGesture { selectedResult = result }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .task {
            if let tid = UUID(uuidString: trainerId) {
                await store.fetch(trainerId: tid)
            }
            loaded = true
        }
        .sheet(item: $selectedResult) { result in
            SBResultLightbox(result: result)
        }
    }
}

// MARK: - Public Proof Tile (grid tile in PublicResultsTab)

struct SBPublicProofTile: View {
    let result: SBTrainerResultRow
    @State private var beforeImage: UIImage?
    @State private var afterImage:  UIImage?

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    tileHalf(url: result.beforeUrl, label: "BEFORE",
                             image: $beforeImage,
                             w: geo.size.width / 2, h: geo.size.height, isAfter: false)
                    if !result.afterUrl.isEmpty {
                        tileHalf(url: result.afterUrl, label: "AFTER",
                                 image: $afterImage,
                                 w: geo.size.width / 2, h: geo.size.height, isAfter: true)
                    } else {
                        Rectangle().fill(Color.white.opacity(0.04))
                            .frame(width: geo.size.width / 2, height: geo.size.height)
                    }
                }
            }
            .frame(height: 145)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                if !result.goalAchieved.isEmpty {
                    Text(result.goalAchieved)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.tmGold).lineLimit(1)
                }
                if !result.duration.isEmpty {
                    Text(result.duration)
                        .font(.caption2).foregroundColor(.white.opacity(0.45))
                }
                Text("Tap to enlarge")
                    .font(.system(size: 9)).foregroundColor(.white.opacity(0.25)).padding(.top, 1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 9).padding(.vertical, 8)
            .background(Color.white.opacity(0.06))
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
    }

    private func tileHalf(url: String, label: String,
                           image: Binding<UIImage?>,
                           w: CGFloat, h: CGFloat, isAfter: Bool) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let img = image.wrappedValue {
                Image(uiImage: img).resizable().scaledToFill()
                    .frame(width: w, height: h).clipped()
            } else {
                Rectangle().fill(Color.white.opacity(0.04))
                    .frame(width: w, height: h)
                    .overlay(ProgressView().tint(.tmGold).scaleEffect(0.6))
            }
            Text(label)
                .font(.system(size: 7, weight: .black)).tracking(1)
                .foregroundColor(isAfter ? .black : .white)
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Capsule().fill(isAfter ? Color.tmGold : Color.black.opacity(0.6)))
                .padding(5)
        }
        .frame(width: w, height: h)
        .task {
            guard image.wrappedValue == nil, let photoUrl = URL(string: url),
                  let data = try? await URLSession.shared.data(from: photoUrl).0 else { return }
            await MainActor.run { image.wrappedValue = UIImage(data: data) }
        }
    }
}
