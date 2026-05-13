//
//  TrainerBannerImageView.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/26/26.
//

//
//  TrainerBannerImageView.swift
//  TrainerMatch
//
//  Facebook-style cover photo banner for trainer profiles.
//  Tapping opens a camera / photo library picker.
//  Falls back to the gold gradient if no photo is set.
//

import SwiftUI
import PhotosUI

struct TrainerBannerImageView: View {
    let userId: String

    @State private var bannerImage: UIImage?
    @State private var showingOptions  = false
    @State private var showingPicker   = false
    @State private var showingCamera   = false
    @State private var selectedItem: PhotosPickerItem?

    private var bannerKey: String { "banner_\(userId)" }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {

            // ── Banner area ──────────────────────────────────────────
            Group {
                if let img = bannerImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    // Gold gradient fallback (original look)
                    LinearGradient(
                        colors: [Color.tmGold, Color.tmGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28))
                                .foregroundColor(.black.opacity(0.35))
                            Text("TAP TO ADD COVER PHOTO")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black.opacity(0.35))
                                .tracking(1.5)
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture { showingOptions = true }

            // ── Edit badge (bottom-right corner) ────────────────────
            Button(action: { showingOptions = true }) {
                HStack(spacing: 5) {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                    Text(bannerImage == nil ? "Add Cover" : "Edit Cover")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.tmGold)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.trailing, 12)
            .padding(.bottom, 10)
        }
        .onAppear {
            bannerImage = ProfileImageManager.shared.loadImage(forKey: bannerKey)
        }
        // ── Action sheet ─────────────────────────────────────────────
        .confirmationDialog("Cover Photo", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Take Photo")           { showingCamera = true  }
            Button("Choose from Library")  { showingPicker = true  }
            if bannerImage != nil {
                Button("Remove Photo", role: .destructive) {
                    ProfileImageManager.shared.deleteImage(forKey: bannerKey)
                    bannerImage = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        // ── Photo library picker ─────────────────────────────────────
        .photosPicker(isPresented: $showingPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let raw  = UIImage(data: data) {
                    let resized = resizeBanner(raw)
                    ProfileImageManager.shared.saveImage(resized, forKey: bannerKey)
                    await MainActor.run { bannerImage = resized }
                }
            }
        }
        // ── Camera ────────────────────────────────────────────────────
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker { captured in
                let resized = resizeBanner(captured)
                ProfileImageManager.shared.saveImage(resized, forKey: bannerKey)
                bannerImage = resized
                showingCamera = false
            }
        }
    }

    // Banner photos are wide-crop — resize to 1200 × 450 max
    private func resizeBanner(_ image: UIImage) -> UIImage {
        let targetWidth: CGFloat  = 1200
        let targetHeight: CGFloat = 450
        let scale = min(targetWidth / image.size.width, targetHeight / image.size.height)
        if scale >= 1 { return image }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// Convenience key stored in ProfileImageManager
extension ProfileImageManager {
    static func bannerImageKey(for userId: String) -> String {
        "banner_\(userId)"
    }
}
