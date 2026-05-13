//
//  TrainerFileStore.swift
//  TrainerMatch
//
//  Shared file/document system — trainers upload, clients view
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Model

struct TrainerSharedFile: Identifiable, Codable {
    let id: String
    let trainerId: String
    let clientId: String        // empty string = shared with all clients
    let name: String
    let fileName: String        // stored in Documents directory
    let fileType: FileType
    let note: String?
    let uploadedAt: Date

    enum FileType: String, Codable, CaseIterable {
        case pdf          = "PDF"
        case workout      = "Workout Plan"
        case nutrition    = "Nutrition Plan"
        case image        = "Image"
        case document     = "Document"
        case other        = "Other"
    }

    init(trainerId: String, clientId: String, name: String,
         fileName: String, fileType: FileType, note: String? = nil) {
        self.id         = UUID().uuidString
        self.trainerId  = trainerId
        self.clientId   = clientId
        self.name       = name
        self.fileName   = fileName
        self.fileType   = fileType
        self.note       = note
        self.uploadedAt = Date()
    }

    var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    var typeIcon: String {
        switch fileType {
        case .pdf:       return "doc.richtext.fill"
        case .workout:   return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife"
        case .image:     return "photo.fill"
        case .document:  return "doc.text.fill"
        case .other:     return "paperclip"
        }
    }

    var typeColor: Color {
        switch fileType {
        case .pdf:       return .red
        case .workout:   return .orange
        case .nutrition: return .green
        case .image:     return .blue
        case .document:  return .purple
        case .other:     return .gray
        }
    }
}

// MARK: - Store

class TrainerFileStore: ObservableObject {
    static let shared = TrainerFileStore()
    @Published var allFiles: [TrainerSharedFile] = []

    private let fm = FileManager.default
    private var storeURL: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("trainerFiles.json")
    }

    private init() { load() }

    // Files a client can see from a specific trainer
    func files(forTrainer trainerId: String, clientId: String) -> [TrainerSharedFile] {
        allFiles
            .filter { $0.trainerId == trainerId &&
                     ($0.clientId == clientId || $0.clientId.isEmpty) }
            .sorted { $0.uploadedAt > $1.uploadedAt }
    }

    // Files a trainer has shared (all clients or specific)
    func files(forTrainer trainerId: String) -> [TrainerSharedFile] {
        allFiles.filter { $0.trainerId == trainerId }
            .sorted { $0.uploadedAt > $1.uploadedAt }
    }

    func addFile(_ file: TrainerSharedFile) {
        allFiles.insert(file, at: 0)
        save()
        NotificationManager.shared.notifyFile(
            to: file.clientId, role: .client,
            from: file.trainerId, senderName: "Your Trainer",
            fileName: file.name
        )
    }

    func deleteFile(_ file: TrainerSharedFile) {
        try? fm.removeItem(at: file.fileURL)
        allFiles.removeAll { $0.id == file.id }
        save()
    }

    func saveFileData(_ data: Data, fileName: String) throws -> URL {
        let url = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(allFiles) else { return }
        try? data.write(to: storeURL)
    }

    private func load() {
        guard fm.fileExists(atPath: storeURL.path),
              let data = try? Data(contentsOf: storeURL),
              let files = try? JSONDecoder().decode([TrainerSharedFile].self, from: data)
        else { return }
        allFiles = files
    }
}

// MARK: - Trainer: Upload File View

struct TrainerUploadFileView: View {
    let trainerId: String
    let clientId: String        // pass "" for all clients
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var fileStore = TrainerFileStore.shared

    @State private var fileName = ""
    @State private var selectedType: TrainerSharedFile.FileType = .document
    @State private var note = ""
    @State private var showingFilePicker = false
    @State private var pickedFileURL: URL?
    @State private var pickedFileName = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {

                    // Recipient
                    VStack(alignment: .leading, spacing: 6) {
                        label("SHARING WITH")
                        Text(clientName.isEmpty ? "All Clients" : clientName)
                            .font(.body).fontWeight(.semibold).foregroundColor(.white)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // File name
                    VStack(alignment: .leading, spacing: 6) {
                        label("FILE NAME")
                        TextField("e.g. Week 3 Workout Plan", text: $fileName)
                            .foregroundColor(.white)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }

                    // Type picker
                    VStack(alignment: .leading, spacing: 6) {
                        label("FILE TYPE")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(TrainerSharedFile.FileType.allCases, id: \.self) { type in
                                    Button(action: { selectedType = type }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: iconFor(type)).font(.caption)
                                            Text(type.rawValue).font(.caption).fontWeight(.semibold)
                                        }
                                        .foregroundColor(selectedType == type ? .black : .white.opacity(0.6))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(selectedType == type ? Color.tmGold : Color.white.opacity(0.08)))
                                    }
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }

                    // Note
                    VStack(alignment: .leading, spacing: 6) {
                        label("NOTE (OPTIONAL)")
                        TextField("Add a note for your client...", text: $note, axis: .vertical)
                            .foregroundColor(.white)
                            .lineLimit(3...5)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    }

                    // Pick file
                    Button(action: { showingFilePicker = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: pickedFileURL == nil ? "doc.badge.plus" : "checkmark.circle.fill")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(pickedFileURL == nil ? "Choose File" : "File Selected")
                                    .fontWeight(.semibold)
                                if !pickedFileName.isEmpty {
                                    Text(pickedFileName).font(.caption).lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .foregroundColor(pickedFileURL == nil ? .tmGold : .green)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(pickedFileURL == nil ? Color.tmGold.opacity(0.3) : Color.green.opacity(0.4), lineWidth: 1)))
                    }

                    // Upload button
                    Button(action: uploadFile) {
                        HStack(spacing: 10) {
                            if isSaving {
                                ProgressView().tint(.black)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("SHARE FILE")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27)
                            .fill(canUpload ? Color.tmGold : Color.tmGold.opacity(0.3)))
                    }
                    .disabled(!canUpload || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Share File")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .image, .plainText, .data],
            allowsMultipleSelection: false
        ) { result in
            if let url = try? result.get().first {
                pickedFileURL = url
                pickedFileName = url.lastPathComponent
                if fileName.isEmpty { fileName = url.deletingPathExtension().lastPathComponent }
            }
        }
    }

    private var canUpload: Bool { !fileName.isEmpty && pickedFileURL != nil }

    private func uploadFile() {
        guard let sourceURL = pickedFileURL else { return }
        isSaving = true
        let ext = sourceURL.pathExtension
        let storedName = "file_\(UUID().uuidString).\(ext)"
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard sourceURL.startAccessingSecurityScopedResource() else { return }
                let data = try Data(contentsOf: sourceURL)
                sourceURL.stopAccessingSecurityScopedResource()
                try fileStore.saveFileData(data, fileName: storedName)
                let newFile = TrainerSharedFile(
                    trainerId: trainerId,
                    clientId: clientId,
                    name: fileName,
                    fileName: storedName,
                    fileType: selectedType,
                    note: note.isEmpty ? nil : note
                )
                DispatchQueue.main.async {
                    fileStore.addFile(newFile)
                    isSaving = false
                    dismiss()
                }
            } catch {
                DispatchQueue.main.async { isSaving = false }
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold)).tracking(1.2)
            .foregroundColor(.tmGold)
    }

    private func iconFor(_ type: TrainerSharedFile.FileType) -> String {
        switch type {
        case .pdf:       return "doc.richtext.fill"
        case .workout:   return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife"
        case .image:     return "photo.fill"
        case .document:  return "doc.text.fill"
        case .other:     return "paperclip"
        }
    }
}
