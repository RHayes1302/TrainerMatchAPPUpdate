//
//  ProgressPhotoGalleryView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/10/26.
//

//
//  ProgressPhotoGalleryView.swift
//  TrainerMatch
//
//  Updated to display real photos saved to device storage
//

import SwiftUI

// MARK: - Gallery View

struct ProgressPhotoGalleryView: View {
    let client: Client
    let progressEntries: [ProgressEntry]
    @State private var selectedEntry: ProgressEntry?

    var entriesWithPhotos: [ProgressEntry] {
        progressEntries
            .filter { $0.photoURLs != nil && !$0.photoURLs!.isEmpty }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if entriesWithPhotos.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(entriesWithPhotos) { entry in
                            ProgressPhotoCard(entry: entry, client: client)
                                .onTapGesture { selectedEntry = entry }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Progress Photos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $selectedEntry) { entry in
            ProgressPhotoDetailView(entry: entry, client: client)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64))
                .foregroundColor(.tmGold.opacity(0.4))
            Text("No Progress Photos Yet")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text("Add progress entries with photos to track \(client.name)'s transformation")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Progress Photo Card

struct ProgressPhotoCard: View {
    let entry: ProgressEntry
    let client: Client

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(date: .long, time: .omitted))
                        .font(.headline)
                        .foregroundColor(.white)
                    if let weight = entry.weight {
                        Text(String(format: "%.1f lbs", weight))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
                if let bodyFat = entry.bodyFat {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Body Fat")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Text(String(format: "%.1f%%", bodyFat))
                            .font(.headline)
                            .foregroundColor(.tmGold)
                    }
                }
            }

            // Photos scroll row — real images from disk
            if let keys = entry.photoURLs, !keys.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(keys, id: \.self) { key in
                            StoredProgressPhoto(key: key, cornerRadius: 12, height: 160)
                                .frame(width: 130)
                        }
                    }
                }
            }

            // Notes
            if let notes = entry.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Progress Photo Detail View

struct ProgressPhotoDetailView: View {
    let entry: ProgressEntry
    let client: Client
    @Environment(\.dismiss) var dismiss
    @State private var selectedPhotoIndex: Int = 0

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // Full-size photo viewer
                        if let keys = entry.photoURLs, !keys.isEmpty {
                            TabView(selection: $selectedPhotoIndex) {
                                ForEach(keys.indices, id: \.self) { idx in
                                    StoredProgressPhoto(key: keys[idx], cornerRadius: 0, height: 400)
                                        .tag(idx)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .automatic))
                            .frame(height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)

                            // Photo counter
                            Text("Photo \(selectedPhotoIndex + 1) of \(keys.count)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        // Stats grid
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 14
                        ) {
                            if let weight = entry.weight {
                                DetailStatCard(title: "Weight", value: String(format: "%.1f lbs", weight))
                            }
                            if let bodyFat = entry.bodyFat {
                                DetailStatCard(title: "Body Fat", value: String(format: "%.1f%%", bodyFat))
                            }
                            if let m = entry.measurements {
                                if let v = m.chest   { DetailStatCard(title: "Chest",  value: String(format: "%.1f in", v)) }
                                if let v = m.waist   { DetailStatCard(title: "Waist",  value: String(format: "%.1f in", v)) }
                                if let v = m.hips    { DetailStatCard(title: "Hips",   value: String(format: "%.1f in", v)) }
                                if let v = m.thighs  { DetailStatCard(title: "Thighs", value: String(format: "%.1f in", v)) }
                                if let v = m.arms    { DetailStatCard(title: "Arms",   value: String(format: "%.1f in", v)) }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Notes
                        if let notes = entry.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                    Text("NOTES")
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.tmGold)

                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.85))
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.06))
                            )
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle(entry.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.tmGold)
                }
            }
        }
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.55))
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.tmGold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
        )
    }
}

#Preview {
    NavigationView {
        ProgressPhotoGalleryView(
            client: Client.sampleClients[0],
            progressEntries: ProgressEntry.sampleEntries
        )
    }
}
