//
//  AddProgressEntryWithPhotos.swift
//  TrainerMatch
//
//  Updated to use real camera + photo library via ProgressPhotoPicker
//

import SwiftUI
import PhotosUI

struct AddProgressEntryWithPhotosView: View {
    let client: Client
    @ObservedObject var trainerVM: TrainerViewModel
    @Environment(\.dismiss) var dismiss

    @State private var entryDate = Date()
    @State private var weight = ""
    @State private var bodyFat = ""
    @State private var chest = ""
    @State private var waist = ""
    @State private var hips = ""
    @State private var thighs = ""
    @State private var arms = ""
    @State private var notes = ""
    @State private var progressImages: [UIImage] = []

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: Entry Date
                        SectionCard(title: "ENTRY DETAILS", icon: "calendar") {
                            DatePicker("Date", selection: $entryDate, displayedComponents: .date)
                                .colorScheme(.dark)
                                .foregroundColor(.white)
                        }

                        // MARK: Progress Photos — NEW
                        SectionCard(title: "PROGRESS PHOTOS", icon: "camera.fill") {
                            ProgressPhotoPicker(images: $progressImages, maxCount: 4)
                            Text("Tip: Same pose & lighting each session makes for the best comparison")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.45))
                                .padding(.top, 4)
                        }

                        // MARK: Body Metrics
                        SectionCard(title: "BODY METRICS", icon: "scalemass.fill") {
                            MetricField(label: "Weight", unit: "lbs", text: $weight)
                            Divider().background(Color.white.opacity(0.1))
                            MetricField(label: "Body Fat", unit: "%", text: $bodyFat)
                        }

                        // MARK: Measurements
                        SectionCard(title: "MEASUREMENTS (optional)", icon: "ruler.fill") {
                            MetricField(label: "Chest", unit: "in", text: $chest)
                            Divider().background(Color.white.opacity(0.1))
                            MetricField(label: "Waist", unit: "in", text: $waist)
                            Divider().background(Color.white.opacity(0.1))
                            MetricField(label: "Hips", unit: "in", text: $hips)
                            Divider().background(Color.white.opacity(0.1))
                            MetricField(label: "Thighs", unit: "in", text: $thighs)
                            Divider().background(Color.white.opacity(0.1))
                            MetricField(label: "Arms", unit: "in", text: $arms)
                        }

                        // MARK: Notes
                        SectionCard(title: "NOTES", icon: "note.text") {
                            TextEditor(text: $notes)
                                .frame(height: 100)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(.white)
                                .overlay(
                                    Group {
                                        if notes.isEmpty {
                                            Text("How is the client feeling? Any observations...")
                                                .foregroundColor(.white.opacity(0.3))
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                                .allowsHitTesting(false)
                                        }
                                    }
                                )
                        }

                        // MARK: Save Button
                        Button(action: saveProgressEntry) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("SAVE PROGRESS ENTRY")
                                    .font(.system(size: 15, weight: .heavy))
                            }
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 27)
                                    .fill(Color.tmGoldGradient())
                            )
                            .shadow(color: .tmGold.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Add Progress Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.tmGold)
                }
            }
        }
    }

    private func saveProgressEntry() {
        let measurements = BodyMeasurements(
            chest: Double(chest),
            waist: Double(waist),
            hips: Double(hips),
            thighs: Double(thighs),
            arms: Double(arms)
        )
        let hasAnyMeasurement = measurements.chest != nil || measurements.waist != nil ||
                                measurements.hips != nil || measurements.thighs != nil ||
                                measurements.arms != nil

        let entryId = UUID().uuidString

        // Save actual images to disk keyed by entryId + index
        var photoKeys: [String]? = nil
        if !progressImages.isEmpty {
            photoKeys = progressImages.indices.map { idx in
                let key = ProfileImageManager.progressPhotoKey(for: entryId, index: idx)
                ProfileImageManager.shared.saveImage(progressImages[idx], forKey: key)
                return key
            }
        }

        let entry = ProgressEntry(
            id: entryId,
            clientId: client.id,
            date: entryDate,
            weight: Double(weight),
            bodyFat: Double(bodyFat),
            measurements: hasAnyMeasurement ? measurements : nil,
            photoURLs: photoKeys,  // storing local keys instead of URLs
            notes: notes.isEmpty ? nil : notes
        )

        trainerVM.addProgressEntry(entry)
        dismiss()
    }
}

// MARK: - Section Card

private struct SectionCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.black)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.tmGold)

            content
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Metric Field

private struct MetricField: View {
    let label: String
    let unit: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
                .frame(width: 70)
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.tmGold)
                .frame(width: 28, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AddProgressEntryWithPhotosView(
        client: Client.sampleClients[0],
        trainerVM: TrainerViewModel()
    )
}
