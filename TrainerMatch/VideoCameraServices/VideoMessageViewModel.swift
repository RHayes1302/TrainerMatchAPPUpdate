//
//  VideoMessageViewModel.swift
//  TrainerMatch
//
//  Trainers record video → uploaded to Supabase Storage → clients stream from URL.
//  All message metadata stored in Supabase `video_messages` table.
//

import Foundation
import AVFoundation
import SwiftUI
import Supabase

@MainActor
class VideoMessageViewModel: ObservableObject {
    static let shared = VideoMessageViewModel()

    @Published var videoMessages:     [VideoMessage] = []
    @Published var cameraService     = CameraService()
    @Published var selectedMessage:   VideoMessage?
    @Published var showingCameraSheet = false
    @Published var showingDetailSheet = false
    @Published var temporaryVideoURL: URL?
    @Published var isUploading        = false
    @Published var uploadProgress:    Double = 0
    @Published var uploadError:       String? = nil

    var currentClientId: String?
    var currentTrainerId: String {
        SupabaseAuthManager.shared.currentTrainer?.id.uuidString ?? "unknown"
    }

    private let fileManager = FileManager.default

    private init() {
        loadLocalMessages()
        cameraService.setupCamera()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.cameraService.startSession()
        }
    }

    // MARK: - Recording

    func startRecording() {
        cameraService.startRecording { [weak self] url in
            DispatchQueue.main.async { self?.temporaryVideoURL = url }
        }
    }

    func stopRecording()  { cameraService.stopRecording() }

    func cancelRecording() {
        if let url = temporaryVideoURL {
            try? fileManager.removeItem(at: url)
            temporaryVideoURL = nil
        }
    }

    // MARK: - Send

    func sendMessage(to clientId: String,
                     title: String,
                     message: String,
                     messageType: VideoMessage.MessageType) {
        guard let tempURL = temporaryVideoURL else { return }

        let fileName = "video_msg_\(UUID().uuidString).mov"
        let destURL  = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        do {
            try fileManager.moveItem(at: tempURL, to: destURL)
            temporaryVideoURL = nil

            let duration = AVAsset(url: destURL).duration.seconds
            var newMessage = VideoMessage(
                trainerId: currentTrainerId, clientId: clientId,
                title: title.isEmpty ? "Video Message" : title,
                message: message, videoFileName: fileName,
                duration: duration, messageType: messageType
            )

            videoMessages.insert(newMessage, at: 0)
            saveLocalMessages()

            // Upload in background
            Task { await uploadToSupabase(&newMessage, localURL: destURL) }

        } catch {
            print("VideoMessageViewModel sendMessage error: \(error)")
        }
    }

    // MARK: - Supabase Upload

    private func uploadToSupabase(_ message: inout VideoMessage, localURL: URL) async {
        guard let index = videoMessages.firstIndex(where: { $0.id == message.id }) else { return }

        isUploading = true
        uploadProgress = 0
        uploadError = nil
        videoMessages[index].uploadStatus = .uploading

        do {
            let videoData   = try Data(contentsOf: localURL)
            let storagePath = "\(message.trainerId)/\(message.clientId)/\(message.id).mov"

            let _ = try await supabase.storage
                .from("video-messages")
                .upload(storagePath, data: videoData,
                        options: .init(contentType: "video/quicktime", upsert: false))

            let publicURL = try supabase.storage
                .from("video-messages")
                .getPublicURL(path: storagePath)

            videoMessages[index].supabaseURL  = publicURL.absoluteString
            videoMessages[index].uploadStatus = .uploaded
            message.supabaseURL              = publicURL.absoluteString
            message.uploadStatus             = .uploaded

            try await saveMessageToDB(videoMessages[index])

            NotificationManager.shared.notifyVideo(
                to: message.clientId, role: .client,
                from: message.trainerId, senderName: "Your Trainer"
            )

            saveLocalMessages()
            uploadProgress = 1.0

        } catch {
            videoMessages[index].uploadStatus = .failed
            uploadError = "Upload failed — tap to retry."
            saveLocalMessages()
        }

        isUploading = false
    }

    // MARK: - Retry

    func retryUpload(for message: VideoMessage) {
        guard message.uploadStatus == .failed else { return }
        let localURL = message.localVideoURL
        guard fileManager.fileExists(atPath: localURL.path) else { return }
        var mutableMsg = message
        Task { await uploadToSupabase(&mutableMsg, localURL: localURL) }
    }

    // MARK: - Supabase DB row

    private func saveMessageToDB(_ msg: VideoMessage) async throws {
        struct Row: Encodable {
            var id, trainerId, clientId, title, message, videoFileName, messageType, uploadStatus: String
            var supabaseUrl: String?
            var duration: Double
            var dateCreated: Date
            var isViewed: Bool
            enum CodingKeys: String, CodingKey {
                case id, title, message, duration
                case trainerId     = "trainer_id"
                case clientId      = "client_id"
                case supabaseUrl   = "supabase_url"
                case videoFileName = "video_file_name"
                case messageType   = "message_type"
                case uploadStatus  = "upload_status"
                case dateCreated   = "date_created"
                case isViewed      = "is_viewed"
            }
        }
        let row = Row(id: msg.id, trainerId: msg.trainerId, clientId: msg.clientId,
                      title: msg.title, message: msg.message, videoFileName: msg.videoFileName,
                      messageType: msg.messageType.rawValue, uploadStatus: msg.uploadStatus.rawValue,
                      supabaseUrl: msg.supabaseURL, duration: msg.duration,
                      dateCreated: msg.dateCreated, isViewed: msg.isViewed)
        try await supabase.from("video_messages").upsert(row).execute()
    }

    // MARK: - Fetch for client (streams from Supabase URL)

    func fetchMessagesForClient(_ clientId: String) async {
        struct Row: Decodable {
            var id, trainerId, clientId, title, message, videoFileName, messageType, uploadStatus: String
            var supabaseUrl: String?
            var duration: Double
            var dateCreated: Date
            var isViewed: Bool
            var viewedDate: Date?
            enum CodingKeys: String, CodingKey {
                case id, title, message, duration
                case trainerId     = "trainer_id"
                case clientId      = "client_id"
                case supabaseUrl   = "supabase_url"
                case videoFileName = "video_file_name"
                case messageType   = "message_type"
                case uploadStatus  = "upload_status"
                case dateCreated   = "date_created"
                case isViewed      = "is_viewed"
                case viewedDate    = "viewed_date"
            }
        }
        do {
            let rows: [Row] = try await supabase
                .from("video_messages")
                .select()
                .eq("client_id", value: clientId)
                .eq("upload_status", value: "uploaded")
                .order("date_created", ascending: false)
                .execute()
                .value

            let fetched = rows.map { row -> VideoMessage in
                var msg = VideoMessage(
                    trainerId: row.trainerId, clientId: row.clientId,
                    title: row.title, message: row.message,
                    videoFileName: row.videoFileName, duration: row.duration,
                    messageType: VideoMessage.MessageType(rawValue: row.messageType) ?? .general
                )
                msg.supabaseURL  = row.supabaseUrl
                msg.uploadStatus = .uploaded
                msg.isViewed     = row.isViewed
                msg.viewedDate   = row.viewedDate
                return msg
            }

            let existingIds = Set(videoMessages.map { $0.id })
            let newOnes = fetched.filter { !existingIds.contains($0.id) }
            videoMessages.insert(contentsOf: newOnes, at: 0)
            videoMessages.sort { $0.dateCreated > $1.dateCreated }

        } catch {
            print("VideoMessageViewModel fetchForClient error: \(error)")
        }
    }

    // MARK: - Mark viewed

    func markAsViewed(_ message: VideoMessage) {
        guard let i = videoMessages.firstIndex(where: { $0.id == message.id }) else { return }
        videoMessages[i].isViewed   = true
        videoMessages[i].viewedDate = Date()
        saveLocalMessages()
        Task {
            struct Update: Encodable {
                var isViewed: Bool; var viewedDate: Date
                enum CodingKeys: String, CodingKey {
                    case isViewed = "is_viewed"; case viewedDate = "viewed_date"
                }
            }
            try? await supabase.from("video_messages")
                .update(Update(isViewed: true, viewedDate: Date()))
                .eq("id", value: message.id)
                .execute()
        }
    }

    // MARK: - Delete

    func deleteMessage(_ message: VideoMessage) {
        let local = message.localVideoURL
        if fileManager.fileExists(atPath: local.path) { try? fileManager.removeItem(at: local) }
        if message.supabaseURL != nil {
            let path = "\(message.trainerId)/\(message.clientId)/\(message.id).mov"
            Task {
                try? await supabase.storage.from("video-messages").remove(paths: [path])
                try? await supabase.from("video_messages").delete().eq("id", value: message.id).execute()
            }
        }
        videoMessages.removeAll { $0.id == message.id }
        saveLocalMessages()
    }

    func updateMessage(_ message: VideoMessage, title: String, messageText: String) {
        guard let i = videoMessages.firstIndex(where: { $0.id == message.id }) else { return }
        videoMessages[i].title   = title
        videoMessages[i].message = messageText
        saveLocalMessages()
    }

    // MARK: - Query helpers

    func getMessages(for clientId: String) -> [VideoMessage] {
        videoMessages.filter { $0.clientId == clientId }.sorted { $0.dateCreated > $1.dateCreated }
    }
    func getUnviewedCount(for clientId: String) -> Int {
        videoMessages.filter { $0.clientId == clientId && !$0.isViewed }.count
    }
    func getRecentMessages(for clientId: String, limit: Int = 5) -> [VideoMessage] {
        Array(getMessages(for: clientId).prefix(limit))
    }
    func getAllUnviewedMessages() -> [VideoMessage] {
        videoMessages.filter { !$0.isViewed }.sorted { $0.dateCreated > $1.dateCreated }
    }

    // MARK: - Local cache

    private var messagesFileURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("videoMessages.json")
    }
    private func saveLocalMessages() {
        guard let data = try? JSONEncoder().encode(videoMessages) else { return }
        try? data.write(to: messagesFileURL)
    }
    func loadLocalMessages() {
        guard fileManager.fileExists(atPath: messagesFileURL.path),
              let data = try? Data(contentsOf: messagesFileURL),
              let msgs  = try? JSONDecoder().decode([VideoMessage].self, from: data)
        else { return }
        videoMessages = msgs
    }
}
