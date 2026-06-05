//
//  VideoMessage.swift
//  TrainerMatch
//

import Foundation

struct VideoMessage: Identifiable, Codable {
    var id:            String
    var trainerId:     String
    var clientId:      String
    var title:         String
    var message:       String
    var videoFileName: String
    var duration:      Double
    var messageType:   MessageType
    var uploadStatus:  UploadStatus
    var supabaseURL:   String?
    var isViewed:      Bool
    var viewedDate:    Date?
    var dateCreated:   Date

    init(trainerId:     String,
         clientId:      String,
         title:         String,
         message:       String,
         videoFileName: String,
         duration:      Double,
         messageType:   MessageType) {
        self.id            = UUID().uuidString
        self.trainerId     = trainerId
        self.clientId      = clientId
        self.title         = title
        self.message       = message
        self.videoFileName = videoFileName
        self.duration      = duration
        self.messageType   = messageType
        self.uploadStatus  = .pending
        self.supabaseURL   = nil
        self.isViewed      = false
        self.viewedDate    = nil
        self.dateCreated   = Date()
    }

    // MARK: - Computed

    var localVideoURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(videoFileName)
    }

    var playbackURL: URL? {
        if let s = supabaseURL, !s.isEmpty { return URL(string: s) }
        let local = localVideoURL
        return FileManager.default.fileExists(atPath: local.path) ? local : nil
    }

    var isNew: Bool { !isViewed }

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return mins > 0 ? "\(mins)m \(secs)s" : "\(secs)s"
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: dateCreated)
    }

    var timeAgo: String {
        let s = Int(Date().timeIntervalSince(dateCreated))
        if s < 60    { return "just now" }
        if s < 3600  { return "\(s/60)m ago" }
        if s < 86400 { return "\(s/3600)h ago" }
        let d = s/86400
        if d < 7 { return "\(d)d ago" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: dateCreated)
    }

    // MARK: - MessageType
    enum MessageType: String, Codable, CaseIterable, Identifiable {
        var id: String { rawValue }
        case progressFeedback    = "progress_feedback"
        case workoutInstructions = "workout_instructions"
        case motivational        = "motivational"
        case checkIn             = "check_in"
        case formCorrection      = "form_correction"
        case general             = "general"

        var displayName: String {
            switch self {
            case .progressFeedback:    return "Progress Feedback"
            case .workoutInstructions: return "Workout Instructions"
            case .motivational:        return "Motivational"
            case .checkIn:             return "Check-In"
            case .formCorrection:      return "Form Correction"
            case .general:             return "General"
            }
        }

        var icon: String {
            switch self {
            case .progressFeedback:    return "chart.line.uptrend.xyaxis"
            case .workoutInstructions: return "dumbbell.fill"
            case .motivational:        return "flame.fill"
            case .checkIn:             return "checkmark.circle.fill"
            case .formCorrection:      return "figure.run"
            case .general:             return "video.fill"
            }
        }
    }

    // MARK: - UploadStatus
    enum UploadStatus: String, Codable {
        case pending   = "pending"
        case uploading = "uploading"
        case uploaded  = "uploaded"
        case failed    = "failed"
    }

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, title, message, duration
        case trainerId     = "trainer_id"
        case clientId      = "client_id"
        case videoFileName = "video_file_name"
        case messageType   = "message_type"
        case uploadStatus  = "upload_status"
        case supabaseURL   = "supabase_url"
        case isViewed      = "is_viewed"
        case viewedDate    = "viewed_date"
        case dateCreated   = "date_created"
    }
}
