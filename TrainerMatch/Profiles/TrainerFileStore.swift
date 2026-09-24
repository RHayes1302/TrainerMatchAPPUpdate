//
//  TrainerFileStore.swift
//  TrainerMatch
//
//  Shared file system — trainers upload to Supabase Storage, clients download and view
//

import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import Supabase

// MARK: - Model

struct TrainerSharedFile: Identifiable, Codable {
    let id:         String
    let trainerId:  String
    let clientId:   String
    var name:       String?     // display name
    let fileName:   String      // actual stored file name
    let fileType:   String      // stored as plain string
    var note:       String?
    var uploadedAt: Date?
    var supabaseUrl: String?    // file_url column

    // Computed file type enum for UI
    var displayName: String { name ?? fileName }
    var fileTypeEnum: FileTypeEnum {
        FileTypeEnum(rawValue: fileType) ?? .other
    }

    enum FileTypeEnum: String, CaseIterable {
        case pdf       = "PDF"
        case workout   = "Workout Plan"
        case nutrition = "Nutrition Plan"
        case image     = "Image"
        case document  = "Document"
        case other     = "Other"
    }

    init(trainerId: String, clientId: String, name: String,
         fileName: String, fileType: String, note: String? = nil, supabaseUrl: String? = nil) {
        self.id          = UUID().uuidString
        self.trainerId   = trainerId
        self.clientId    = clientId
        self.name        = name
        self.fileName    = fileName
        self.fileType    = fileType
        self.note        = note
        self.uploadedAt  = Date()
        self.supabaseUrl = supabaseUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, note, name
        case trainerId   = "trainer_id"
        case clientId    = "client_id"
        case fileName    = "file_name"
        case fileType    = "file_type"
        case uploadedAt  = "created_at"
        case supabaseUrl = "file_url"
    }

    var typeIcon: String {
        switch fileTypeEnum {
        case .pdf:       return "doc.richtext.fill"
        case .workout:   return "figure.strengthtraining.traditional"
        case .nutrition: return "fork.knife"
        case .image:     return "photo.fill"
        case .document:  return "doc.text.fill"
        case .other:     return "paperclip"
        }
    }

    var typeColor: Color {
        switch fileTypeEnum {
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
    // Cache per trainer-client pair to avoid overwrites
    private var fileCache: [String: [TrainerSharedFile]] = [:]

    private init() {}
    
    private func cacheKey(trainerId: String, clientId: String) -> String {
        "\(trainerId.uppercased())_\(clientId.uppercased())"
    }

    // MARK: Fetch

    func fetchFiles(trainerId: String, clientId: String) async {
        let key = cacheKey(trainerId: trainerId, clientId: clientId)
        do {
            let rows: [TrainerSharedFile] = try await supabase
                .from("shared_files")
                .select()
                .eq("trainer_id", value: trainerId)
                .order("created_at", ascending: false)
                .execute()
                .value
            let filtered = rows.filter { $0.clientId.uppercased() == clientId.uppercased() }
            print("📁 fetchFiles: \(filtered.count) files for \(key)")
            await MainActor.run {
                fileCache[key] = filtered
                allFiles = filtered
            }
        } catch {
            print("❌ fetchFiles error: \(error)")
        }
    }

    func fetchFilesForClient(trainerId: String, clientId: String) async {
        // Try fetching by given clientId first, then try row id lookup via auth_id
        do {
            var rows: [TrainerSharedFile] = try await supabase
                .from("shared_files")
                .select()
                .eq("trainer_id", value: trainerId)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Filter by clientId case-insensitively, also try auth_id lookup
            var matched = rows.filter { $0.clientId.uppercased() == clientId.uppercased() }

            if matched.isEmpty {
                // Look up row id via auth_id
                struct ClientRow: Decodable {
                    let id: UUID
                    enum CodingKeys: String, CodingKey { case id }
                }
                if let clientRows = try? await supabase
                    .from("clients").select("id")
                    .eq("auth_id", value: clientId)
                    .execute()
                    .value as [ClientRow],
                   let rowId = clientRows.first?.id {
                    matched = rows.filter { $0.clientId.uppercased() == rowId.uuidString.uppercased() }
                }
            }

            print("📁 fetchFilesForClient: \(matched.count) files")
            await MainActor.run { allFiles = matched }
        } catch {
            print("❌ fetchFilesForClient error: \(error)")
        }
    }

    // MARK: Upload

    func uploadFile(data: Data, fileName: String, file: TrainerSharedFile) async throws {
        let path = "\(file.trainerId)/\(fileName)"

        // Upload to Supabase Storage
        try await supabase.storage
            .from("shared_files")
            .upload(path, data: data)

        // Get public URL
        let publicURL = try supabase.storage
            .from("shared_files")
            .getPublicURL(path: path)

        // Save metadata to shared_files table
        // Build insert payload matching actual table columns
        struct FileInsert: Encodable {
            let id, trainer_id, client_id, name, file_name, file_type, file_url: String
            let note: String?
        }
        let insert = FileInsert(
            id: file.id,
            trainer_id: file.trainerId,
            client_id: file.clientId,
            name: file.name ?? file.fileName,
            file_name: file.fileName,
            file_type: file.fileType,
            file_url: publicURL.absoluteString,
            note: file.note
        )

        try await supabase
            .from("shared_files")
            .insert(insert)
            .execute()

        var saved = file
        saved.supabaseUrl = publicURL.absoluteString

        await MainActor.run { allFiles.insert(saved, at: 0) }
    }

    // MARK: Delete

    func deleteFile(_ file: TrainerSharedFile) async {
        let path = "\(file.trainerId)/\(file.fileName)"
        try? await supabase.storage.from("shared_files").remove(paths: [path])
        try? await supabase.from("shared_files").delete().eq("id", value: file.id).execute()
        await MainActor.run { allFiles.removeAll { $0.id == file.id } }
    }

    // MARK: Helpers

    func files(forTrainer trainerId: String, clientId: String) -> [TrainerSharedFile] {
        let key = cacheKey(trainerId: trainerId, clientId: clientId)
        return (fileCache[key] ?? allFiles.filter {
            $0.trainerId.uppercased() == trainerId.uppercased() &&
            $0.clientId.uppercased() == clientId.uppercased()
        })
        .sorted { ($0.uploadedAt ?? .distantPast) > ($1.uploadedAt ?? .distantPast) }
    }

    private func contentType(for fileName: String) -> String {
        switch fileName.split(separator: ".").last?.lowercased() {
        case "pdf":              return "application/pdf"
        case "jpg", "jpeg":     return "image/jpeg"
        case "png":             return "image/png"
        case "doc", "docx":     return "application/msword"
        default:                return "application/octet-stream"
        }
    }
}

// MARK: - Trainer Upload File View

struct TrainerUploadFileView: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var fileStore = TrainerFileStore.shared

    @State private var fileName         = ""
    @State private var note             = ""
    @State private var selectedType     = "PDF"
    @State private var showingFilePicker = false
    @State private var pickedFileURL:   URL?
    @State private var pickedFileName   = ""
    @State private var pickedFileData:  Data?
    @State private var isSaving         = false
    @State private var errorMessage:    String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {

                    // File picker button
                    Button(action: { showingFilePicker = true }) {
                        VStack(spacing: 12) {
                            if let name = pickedFileURL?.lastPathComponent {
                                Image(systemName: "doc.fill").font(.system(size: 36)).foregroundColor(.tmGold)
                                Text(name).font(.subheadline).fontWeight(.semibold).foregroundColor(.white).multilineTextAlignment(.center)
                                Text("Tap to change file").font(.caption).foregroundColor(.white.opacity(0.4))
                            } else {
                                Image(systemName: "arrow.up.doc.fill").font(.system(size: 36)).foregroundColor(.tmGold.opacity(0.6))
                                Text("Tap to select a file").font(.subheadline).fontWeight(.semibold).foregroundColor(.white.opacity(0.6))
                                Text("PDF, images, documents supported").font(.caption).foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .frame(maxWidth: .infinity).padding(30)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(
                                pickedFileURL != nil ? Color.tmGold.opacity(0.5) : Color.tmGold.opacity(0.2),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))))
                    }.buttonStyle(.plain)

                    // File name
                    formField("FILE NAME") {
                        TextField("e.g. Week 1 Workout Plan", text: $fileName)
                            .foregroundColor(.white).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
                    }

                    // File type
                    formField("FILE TYPE") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TrainerSharedFile.FileTypeEnum.allCases, id: \.self) { type in
                                    Button(action: { selectedType = type.rawValue }) {
                                        Text(type.rawValue).font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(selectedType == type.rawValue ? .black : .white.opacity(0.6))
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(Capsule().fill(selectedType == type.rawValue ? Color.tmGold : Color.white.opacity(0.08)))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Note
                    formField("NOTE (OPTIONAL)") {
                        TextField("Add a note for \(clientName)...", text: $note, axis: .vertical)
                            .foregroundColor(.white).lineLimit(2...4).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    if let err = errorMessage {
                        Text("⚠️ \(err)").font(.caption).foregroundColor(.red)
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                    }

                    // Upload button
                    Button(action: uploadFile) {
                        HStack(spacing: 8) {
                            if isSaving { ProgressView().tint(.black) }
                            else { Image(systemName: "arrow.up.circle.fill"); Text("SEND TO \(clientName.uppercased())").font(.system(size: 14, weight: .heavy)).tracking(0.5) }
                        }
                        .foregroundColor(canUpload ? .black : .white.opacity(0.4))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(RoundedRectangle(cornerRadius: 27).fill(canUpload ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                    .disabled(!canUpload || isSaving)
                }
                .padding(20)
            }
        }
        .navigationTitle("Share File with \(clientName)").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar).toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() }.foregroundColor(.tmGold) } }
        .fileImporter(isPresented: $showingFilePicker,
                      allowedContentTypes: [.pdf, .image, .plainText, .data, .item],
                      allowsMultipleSelection: false) { result in
            if let url = try? result.get().first {
                pickedFileURL = url
                pickedFileName = url.lastPathComponent
                if fileName.isEmpty { fileName = url.deletingPathExtension().lastPathComponent }
                // Read data immediately while we have access
                if url.startAccessingSecurityScopedResource() {
                    pickedFileData = try? Data(contentsOf: url)
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }

    private var canUpload: Bool { !fileName.isEmpty && pickedFileData != nil }

    private func uploadFile() {
        guard let data = pickedFileData else { return }
        isSaving = true
        errorMessage = nil
        let ext = pickedFileURL?.pathExtension ?? "bin"
        let storedName = "file_\(UUID().uuidString).\(ext)"
        let newFile = TrainerSharedFile(
            trainerId: trainerId, clientId: clientId,
            name: fileName, fileName: storedName,
            fileType: selectedType, note: note.isEmpty ? nil : note
        )
        Task {
            do {
                try await fileStore.uploadFile(data: data, fileName: storedName, file: newFile)
                await MainActor.run { isSaving = false; dismiss() }
            } catch {
                await MainActor.run { isSaving = false; errorMessage = error.localizedDescription }
            }
        }
    }

    private func formField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
            content()
        }
    }
}

// MARK: - Client Files View

struct ClientSharedFilesView: View {
    let trainerId: String
    let clientId:  String
    @ObservedObject private var store = TrainerFileStore.shared
    @State private var isLoading      = false
    @State private var previewURL:    URL?
    @State private var downloadedURLs: [String: URL] = [:]

    private var files: [TrainerSharedFile] {
        store.files(forTrainer: trainerId, clientId: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Files").font(.title2).fontWeight(.bold).foregroundColor(.white)

            if isLoading {
                HStack { Spacer(); ProgressView().tint(.tmGold); Spacer() }.padding(.vertical, 20)
            } else if files.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "folder").font(.system(size: 40)).foregroundColor(.tmGold.opacity(0.2))
                    Text("No files shared yet").font(.subheadline).foregroundColor(.white.opacity(0.4))
                    Text("Your trainer will share files here.").font(.caption).foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
            } else {
                VStack(spacing: 10) {
                    ForEach(files) { file in
                        ClientFileRow(file: file, downloadedURL: downloadedURLs[file.id]) {
                            openFile(file)
                        }
                    }
                }
            }
        }
        .onAppear {
            isLoading = true
            Task {
                await store.fetchFilesForClient(trainerId: trainerId, clientId: clientId)
                await MainActor.run { isLoading = false }
            }
        }
        .sheet(isPresented: Binding(
            get: { previewURL != nil },
            set: { if !$0 { previewURL = nil } }
        )) {
            if let url = previewURL { QuickLookPreview(url: url) }
        }
    }

    private func openFile(_ file: TrainerSharedFile) {
        guard let urlString = file.supabaseUrl, let url = URL(string: urlString) else { return }
        let ext = (file.fileName as NSString).pathExtension
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.id).appendingPathExtension(ext)
        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
            try? FileManager.default.removeItem(at: localURL)
            do {
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.downloadedURLs[file.id] = localURL
                    self.previewURL = localURL
                }
            } catch { print("❌ Move error: \(error)") }
        }.resume()
    }
}

// MARK: - Client File Row

struct ClientFileRow: View {
    let file:          TrainerSharedFile
    let downloadedURL: URL?
    let onOpen:        () -> Void
    @State private var isDownloading = false

    var body: some View {
        Button(action: {
            isDownloading = true
            onOpen()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isDownloading = false }
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(file.typeColor.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: file.typeIcon).font(.system(size: 18)).foregroundColor(file.typeColor)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.displayName).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    HStack(spacing: 6) {
                        Text(file.fileType).font(.caption).foregroundColor(file.typeColor)
                        if let note = file.note, !note.isEmpty {
                            Text("·").foregroundColor(.white.opacity(0.3))
                            Text(note).font(.caption).foregroundColor(.white.opacity(0.45)).lineLimit(1)
                        }
                    }
                    Text(file.uploadedAt ?? Date(), style: .date).font(.caption2).foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                if isDownloading {
                    ProgressView().tint(.tmGold).scaleEffect(0.8)
                } else {
                    Image(systemName: downloadedURL != nil ? "eye.fill" : "arrow.down.circle")
                        .font(.system(size: 18)).foregroundColor(.tmGold)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - QuickLook Preview

struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> QLPreviewController {
        let vc = QLPreviewController()
        vc.dataSource = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: QLPreviewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(url: url) }
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem { url as QLPreviewItem }
    }
}

// MARK: - Document Viewer (opens with system app)

func openFileWithSystem(_ url: URL) {
    let controller = UIDocumentInteractionController(url: url)
    controller.presentPreview(animated: true)
    // Keep reference alive
    objc_setAssociatedObject(UIApplication.shared, "docController", controller, .OBJC_ASSOCIATION_RETAIN)
}

// MARK: - Trainer Files Section (updated to use Supabase)

class TrainerFilePreviewState: ObservableObject {
    @Published var previewURL: URL?
    @Published var showPreview = false
}

struct TrainerFilesSection: View {
    let trainerId:  String
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = TrainerFileStore.shared
    @StateObject private var previewState = TrainerFilePreviewState()
    @State private var showingUpload  = false
    @State private var showingAll     = false
    @State private var isDownloading  = false

    private var files: [TrainerSharedFile] {
        store.files(forTrainer: trainerId, clientId: clientId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill").font(.caption).foregroundColor(.tmGold)
                    Text("SHARED FILES").font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                }
                Spacer()
                HStack(spacing: 10) {
                    if !files.isEmpty {
                        Button("View All") { showingAll = true }.font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                    }
                    Button(action: { showingUpload = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill").font(.caption)
                            Text("Share").font(.caption).fontWeight(.semibold)
                        }.foregroundColor(.tmGold)
                    }
                }
            }

            if files.isEmpty {
                Button(action: { showingUpload = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "folder").foregroundColor(.tmGold.opacity(0.4))
                        Text("Share files with \(clientName)").font(.caption).foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity).padding(14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.03)))
                }.buttonStyle(.plain)
            } else {
                VStack(spacing: 8) {
                    ForEach(files.prefix(3)) { file in
                        HStack(spacing: 12) {
                            Button(action: { openFile(file) }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(file.typeColor.opacity(0.15)).frame(width: 36, height: 36)
                                        Image(systemName: file.typeIcon).font(.system(size: 14)).foregroundColor(file.typeColor)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(file.displayName).font(.system(size: 13, weight: .semibold)).foregroundColor(.white).lineLimit(1)
                                        Text(file.fileType).font(.caption2).foregroundColor(file.typeColor)
                                    }
                                    Spacer()
                                    Image(systemName: "eye.fill").font(.caption2).foregroundColor(.tmGold.opacity(0.6))
                                }
                            }.buttonStyle(.plain)
                            Button(action: { deleteFile(file) }) {
                                Image(systemName: "trash").font(.caption2).foregroundColor(.red.opacity(0.6))
                            }
                        }
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                    }
                }
            }
        }
        .onAppear { Task { await store.fetchFiles(trainerId: trainerId, clientId: clientId) } }
        .sheet(isPresented: $previewState.showPreview) {
            if let url = previewState.previewURL { QuickLookPreview(url: url) }
        }
        .sheet(isPresented: $showingUpload) {
            NavigationView {
                TrainerUploadFileView(trainerId: trainerId, clientId: clientId, clientName: clientName)
            }.tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func openFile(_ file: TrainerSharedFile) {
        guard let urlString = file.supabaseUrl, let remoteURL = URL(string: urlString) else { return }
        let ext = (file.fileName as NSString).pathExtension
        let localURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(file.id).appendingPathExtension(ext)
        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else { return }
            try? FileManager.default.removeItem(at: localURL)
            guard (try? FileManager.default.moveItem(at: tempURL, to: localURL)) != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.previewState.previewURL = localURL
                self.previewState.showPreview = true
            }
        }.resume()
    }

    private func deleteFile(_ file: TrainerSharedFile) {
        Task { await store.deleteFile(file) }
    }
}
