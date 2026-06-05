//
//  ClientCheckInView.swift
//  TrainerMatch
//

import SwiftUI
import PhotosUI

struct ClientCheckInView: View {
    let clientId:  UUID
    let trainerId: UUID
    let clientName: String

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = SBCheckInStore.shared

    @State private var weightStr    = ""
    @State private var energyLevel  = 3
    @State private var sleepHours   = 7.0
    @State private var waterOz      = 64
    @State private var notes        = ""
    @State private var selectedItems:  [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @State private var isSubmitting  = false
    @State private var showSuccess   = false
    @State private var errorMessage: String? = nil

    private var weight: Double? { Double(weightStr) }
    private var canSubmit: Bool { !weightStr.isEmpty && weight != nil }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    header
                    weightSection
                    wellnessSection
                    photosSection
                    notesSection
                    submitButton
                    if let err = errorMessage {
                        Text("⚠️ \(err)").font(.caption).foregroundColor(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 20)
                    }
                }
                .padding(.horizontal, 20).padding(.bottom, 60)
            }
        }
        .navigationTitle("Weekly Check-In")
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
        .alert("Check-In Submitted! 💪", isPresented: $showSuccess) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your trainer has been notified and will review your check-in soon.")
        }
        .onChange(of: selectedItems) { _, items in
            Task { await loadSelectedImages(items) }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 70, height: 70)
                Image(systemName: "figure.run.circle.fill").font(.system(size: 36)).foregroundColor(.tmGold)
            }
            .padding(.top, 24)
            Text("Weekly Check-In").font(.system(size: 26, weight: .black)).foregroundColor(.white)
            Text("Log your progress for the week").font(.subheadline).foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Weight

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("CURRENT WEIGHT", icon: "scalemass.fill")
            HStack {
                TextField("0.0", text: $weightStr).keyboardType(.decimalPad)
                    .font(.system(size: 32, weight: .black)).foregroundColor(.white)
                    .multilineTextAlignment(.center)
                Text("lbs").font(.system(size: 16, weight: .bold)).foregroundColor(.tmGold)
            }
            .padding(.horizontal, 20).padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(weightStr.isEmpty ? Color.tmGold.opacity(0.3) : Color.tmGold,
                                lineWidth: 1.5))
            )
            if weightStr.isEmpty {
                Text("* Weight is required").font(.caption).foregroundColor(.red.opacity(0.7))
            }
        }
    }

    // MARK: - Wellness

    private var wellnessSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionLabel("WELLNESS STATS", icon: "heart.fill")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Energy Level").font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(energyLabel).font(.system(size: 13, weight: .bold)).foregroundColor(energyColor)
                }
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { level in
                        Button(action: { energyLevel = level }) {
                            VStack(spacing: 4) {
                                Image(systemName: level <= energyLevel ? "bolt.fill" : "bolt")
                                    .font(.system(size: 20))
                                    .foregroundColor(level <= energyLevel ? energyColor : .white.opacity(0.2))
                                Text("\(level)").font(.system(size: 10, weight: .bold))
                                    .foregroundColor(level <= energyLevel ? energyColor : .white.opacity(0.2))
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(level <= energyLevel ? energyColor.opacity(0.12) : Color.white.opacity(0.04)))
                        }
                    }
                }
            }
            .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Sleep Hours").font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(String(format: "%.1f hrs", sleepHours)).font(.system(size: 14, weight: .black)).foregroundColor(.purple)
                }
                Slider(value: $sleepHours, in: 3...12, step: 0.5).tint(.purple)
                HStack {
                    Text("3h").font(.caption2).foregroundColor(.white.opacity(0.3))
                    Spacer()
                    Text("12h").font(.caption2).foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Daily Water Intake").font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(waterOz) oz").font(.system(size: 14, weight: .black)).foregroundColor(.cyan)
                }
                Slider(value: Binding(get: { Double(waterOz) }, set: { waterOz = Int($0) }),
                       in: 16...200, step: 8).tint(.cyan)
                HStack {
                    Text("16oz").font(.caption2).foregroundColor(.white.opacity(0.3))
                    Spacer()
                    Text("200oz").font(.caption2).foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
        }
    }

    // MARK: - Photos

    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("PROGRESS PHOTOS", icon: "camera.fill")
            Text("Add up to 3 progress photos (optional)").font(.caption).foregroundColor(.white.opacity(0.4))
            if selectedImages.isEmpty {
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 3, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.6))
                        Text("Tap to add photos").font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity).frame(height: 120)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.tmGold.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                }
            } else {
                HStack(spacing: 10) {
                    ForEach(selectedImages.indices, id: \.self) { i in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: selectedImages[i]).resizable().scaledToFill()
                                .frame(width: 100, height: 120).clipShape(RoundedRectangle(cornerRadius: 12))
                            Button(action: { removePhoto(at: i) }) {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 20)).foregroundColor(.white)
                                    .background(Color.black.opacity(0.5).clipShape(Circle()))
                            }.offset(x: 6, y: -6)
                        }
                    }
                    if selectedImages.count < 3 {
                        PhotosPicker(selection: $selectedItems, maxSelectionCount: 3, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus").font(.system(size: 24)).foregroundColor(.tmGold.opacity(0.6))
                                Text("Add").font(.caption).foregroundColor(.white.opacity(0.4))
                            }
                            .frame(width: 100, height: 120)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tmGold.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("NOTES FOR TRAINER", icon: "text.bubble.fill")
            TextField("How did your week go? Any concerns or wins to share?",
                      text: $notes, axis: .vertical)
                .lineLimit(4...8).foregroundColor(.white).padding(14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
        }
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button(action: submitCheckIn) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView().tint(.black).scaleEffect(0.9)
                    Text("Submitting...").font(.system(size: 16, weight: .heavy)).foregroundColor(.black)
                } else {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18))
                    Text("SUBMIT CHECK-IN").font(.system(size: 16, weight: .heavy)).tracking(0.5)
                }
            }
            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 28)
                .fill(canSubmit ? Color.tmGold : Color.white.opacity(0.1))
                .shadow(color: canSubmit ? Color.tmGold.opacity(0.4) : .clear, radius: 12, y: 4))
        }
        .disabled(!canSubmit || isSubmitting).padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
            Text(text).font(.system(size: 11, weight: .black)).tracking(1.2).foregroundColor(.tmGold)
        }
    }

    private var energyLabel: String {
        switch energyLevel {
        case 1: return "Very Low"; case 2: return "Low"; case 3: return "Moderate"
        case 4: return "High";     case 5: return "Excellent"; default: return ""
        }
    }

    private var energyColor: Color {
        switch energyLevel {
        case 1, 2: return .red.opacity(0.8); case 3: return .orange
        case 4:    return .tmGold;            case 5: return .green; default: return .white
        }
    }

    private func removePhoto(at index: Int) {
        selectedImages.remove(at: index)
        if index < selectedItems.count { selectedItems.remove(at: index) }
    }

    private func loadSelectedImages(_ items: [PhotosPickerItem]) async {
        var images: [UIImage] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) { images.append(img) }
        }
        await MainActor.run { selectedImages = images }
    }

    // MARK: - Submit

    private func submitCheckIn() {
        guard canSubmit else { return }
        isSubmitting = true; errorMessage = nil

        // ✅ No trainerFeedback in initializer — it lives in LegacyModels extension
        let checkIn = CheckInRow(
            id:          UUID(),
            trainerId:   trainerId,
            clientId:    clientId,
            weight:      weight,
            notes:       notes,
            photoUrls:   [],
            energyLevel: energyLevel,
            sleepHours:  sleepHours,
            waterOz:     waterOz,
            checkedInAt: Date(),
            createdAt:   Date()
        )

        let photoData = selectedImages.compactMap { $0.jpegData(compressionQuality: 0.8) }

        Task {
            do {
                try await store.submit(checkIn, photos: photoData)
                print("✅ Check-in submitted successfully")
                PushNotificationManager.shared.sendNewClientNotification(
                    toTrainerId: trainerId.uuidString,
                    clientName:  clientName
                )
                await MainActor.run { isSubmitting = false; showSuccess = true }
            } catch {
                print("❌ Check-in failed: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Check-In History Row

struct CheckInHistoryRow: View {
    let checkIn: CheckInRow

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
                            statBadge("scalemass.fill", String(format: "%.1f lbs", w), .tmGold)
                        }
                        if let e = checkIn.energyLevel {
                            statBadge("bolt.fill", "\(e)/5", energyColor(e))
                        }
                        if let s = checkIn.sleepHours {
                            statBadge("moon.fill", String(format: "%.1fh", s), .purple)
                        }
                    }
                    if !checkIn.notes.isEmpty {
                        Text(checkIn.notes).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if !(checkIn.trainerFeedback ?? "").isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green).font(.system(size: 18))
                    } else {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange.opacity(0.6)).font(.system(size: 18))
                    }
                    if !checkIn.photoUrls.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "photo.fill").font(.caption2).foregroundColor(.white.opacity(0.3))
                            Text("\(checkIn.photoUrls.count)").font(.caption2).foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
            }

            if let feedback = checkIn.trainerFeedback, !feedback.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.caption).foregroundColor(.tmGold)
                        Text("TRAINER FEEDBACK")
                            .font(.system(size: 10, weight: .black)).tracking(1.2).foregroundColor(.tmGold)
                    }
                    Text(feedback)
                        .font(.subheadline).foregroundColor(.white.opacity(0.85))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.tmGold.opacity(0.08))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.tmGold.opacity(0.25), lineWidth: 1))
                        )
                }
            } else {
                Text("⏳ Awaiting trainer review")
                    .font(.caption).foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(!(checkIn.trainerFeedback ?? "").isEmpty
                            ? Color.tmGold.opacity(0.2) : Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private func statBadge(_ icon: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)).foregroundColor(color)
            Text(value).font(.system(size: 11, weight: .bold)).foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(Capsule().fill(color.opacity(0.1)))
    }

    private func energyColor(_ level: Int) -> Color {
        switch level {
        case 1, 2: return .red.opacity(0.8); case 3: return .orange
        case 4:    return .tmGold;            case 5: return .green; default: return .white
        }
    }
}

// MARK: - Client Check-In Section

struct ClientCheckInSection: View {
    let clientId:   UUID
    let trainerId:  UUID
    let clientName: String

    @ObservedObject private var store = SBCheckInStore.shared
    @State private var showingSubmit = false

    private var checkIns: [CheckInRow] {
        store.checkIns(forClient: clientId.uuidString)
    }

    private var feedbackCount: Int {
        checkIns.filter { !($0.trainerFeedback ?? "").isEmpty }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { showingSubmit = true }) {
                HStack(spacing: 10) {
                    Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    Text("SUBMIT THIS WEEK'S CHECK-IN")
                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold)
                    .shadow(color: Color.tmGold.opacity(0.4), radius: 10, y: 4))
            }
            .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, 16)

            if checkIns.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "figure.run.circle")
                        .font(.system(size: 44)).foregroundColor(.white.opacity(0.1)).padding(.top, 40)
                    Text("No check-ins yet").font(.headline).foregroundColor(.white.opacity(0.35))
                    Text("Submit your first check-in above\nto start tracking your progress.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.25)).multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.bottom, 60)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CHECK-IN HISTORY")
                            .font(.system(size: 10, weight: .black)).tracking(1.5).foregroundColor(.tmGold)
                        Spacer()
                        if feedbackCount > 0 {
                            Text("\(feedbackCount) with feedback")
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.tmGold)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 4)
                    ForEach(checkIns) { checkIn in
                        CheckInHistoryRow(checkIn: checkIn).padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear { store.loadForClient(clientId.uuidString) }
        .sheet(isPresented: $showingSubmit) {
            NavigationView {
                ClientCheckInView(clientId: clientId, trainerId: trainerId, clientName: clientName)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
