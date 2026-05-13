//
//  ProfileImageManager.swift
//  TrainerMatch
//
//  Created by Ramone Hayes on 2/26/26.
//

//
//  ProfileImageManager.swift
//  TrainerMatch
//
//  Handles profile picture and progress photo storage locally on device
//

import SwiftUI
import PhotosUI

// MARK: - Image Storage Manager

class ProfileImageManager: ObservableObject {
    static let shared = ProfileImageManager()

    private let fileManager = FileManager.default

    // MARK: - Save Image

    func saveImage(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let url = fileURL(for: key)
        try? data.write(to: url)
    }

    // MARK: - Load Image

    func loadImage(forKey key: String) -> UIImage? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Delete Image

    func deleteImage(forKey key: String) {
        let url = fileURL(for: key)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Keys

    static func profileImageKey(for userId: String) -> String {
        "profile_\(userId)"
    }

    static func progressPhotoKey(for entryId: String, index: Int) -> String {
        "progress_\(entryId)_\(index)"
    }

    // MARK: - Private

    private func fileURL(for key: String) -> URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(key).jpg")
    }
}

// MARK: - Profile Image Picker View

struct ProfileImagePickerView: View {
    let userId: String
    var size: CGFloat = 120
    var isEditable: Bool = true
    var placeholder: String = "person.fill"

    @StateObject private var imageManager = ProfileImageManager.shared
    @State private var profileImage: UIImage?
    @State private var showingOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var selectedItem: PhotosPickerItem?

    private var imageKey: String {
        ProfileImageManager.profileImageKey(for: userId)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Profile circle
            Group {
                if let image = profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.tmGold, Color.tmGoldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Image(systemName: placeholder)
                                .font(.system(size: size * 0.38))
                                .foregroundColor(.black)
                        )
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.black, lineWidth: 4))

            // Edit badge
            if isEditable {
                Button(action: { showingOptions = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.tmGold)
                            .frame(width: size * 0.28, height: size * 0.28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: size * 0.12))
                            .foregroundColor(.black)
                    }
                }
                .offset(x: 4, y: 4)
            }
        }
        .onAppear {
            profileImage = imageManager.loadImage(forKey: imageKey)
        }
        .confirmationDialog("Profile Photo", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Take Photo") { showingCamera = true }
            Button("Choose from Library") { showingPhotoPicker = true }
            if profileImage != nil {
                Button("Remove Photo", role: .destructive) {
                    imageManager.deleteImage(forKey: imageKey)
                    profileImage = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    let resized = resizeImage(image, maxDimension: 800)
                    imageManager.saveImage(resized, forKey: imageKey)
                    await MainActor.run { profileImage = resized }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker { image in
                let resized = resizeImage(image, maxDimension: 800)
                imageManager.saveImage(resized, forKey: imageKey)
                profileImage = resized
                showingCamera = false
            }
        }
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        if ratio >= 1 { return image }
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

// MARK: - Progress Photo Picker (for entries)

struct ProgressPhotoPicker: View {
    @Binding var images: [UIImage]
    var maxCount: Int = 4

    @State private var showingOptions = false
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var selectedItems: [PhotosPickerItem] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Add photo button
            Button(action: { showingOptions = true }) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.tmGold.opacity(0.15))
                            .frame(width: 56, height: 56)
                        Image(systemName: "camera.fill")
                            .font(.title3)
                            .foregroundColor(.tmGold)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Progress Photos")
                            .font(.headline)
                            .foregroundColor(.tmGold)
                        Text(images.isEmpty
                             ? "Camera or photo library • Up to \(maxCount)"
                             : "\(images.count)/\(maxCount) photos added")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    if images.count < maxCount {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.tmGold)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.tmGold.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .disabled(images.count >= maxCount)

            // Selected photos grid
            if !images.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(images.indices, id: \.self) { idx in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: images[idx])
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button(action: { images.remove(at: idx) }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding(8)
                        }
                    }
                }
            }
        }
        .confirmationDialog("Add Photo", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Take Photo") { showingCamera = true }
            Button("Choose from Library") { showingPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(
            isPresented: $showingPhotoPicker,
            selection: $selectedItems,
            maxSelectionCount: maxCount - images.count,
            matching: .images
        )
        .onChange(of: selectedItems) { newItems in
            Task {
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            if images.count < maxCount {
                                images.append(image)
                            }
                        }
                    }
                }
                await MainActor.run { selectedItems = [] }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker { image in
                if images.count < maxCount {
                    images.append(image)
                }
                showingCamera = false
            }
        }
    }
}

// MARK: - Camera Image Picker (UIKit wrapper)

struct CameraImagePicker: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            if let image { onCapture(image) }
        }
    }
}

// MARK: - Inline Photo Display (for gallery)

struct StoredProgressPhoto: View {
    let key: String
    var cornerRadius: CGFloat = 12
    var height: CGFloat = 160

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: height)
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .onAppear {
            image = ProfileImageManager.shared.loadImage(forKey: key)
        }
    }
}
