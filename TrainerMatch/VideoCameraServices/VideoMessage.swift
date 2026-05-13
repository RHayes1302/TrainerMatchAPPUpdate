//
//  VideoMessage.swift
//  TrainerMatch
//
//  Video messaging system — trainers record and send video feedback to clients.
//  Videos are uploaded to Supabase Storage so clients can stream them on any device.
//

import Foundation

struct VideoMessage: Identifiable, Codable {
    let id:           String
    var trainerId:    String
    var clientId:     String
    var title:        String
    var message:      String
    var videoFileName: String       // local filename (trainer device only)
    var supabaseURL:  String?       // remote URL — clients stream from this
    var duration:     TimeInterval
    var dateCreated:  Date
    var isViewed:     Bool
    var viewedDate:   Date?
    var messageType:  MessageType
    var uploadStatus: UploadStatus

    enum MessageType: String, Codable, CaseIterable {
        case progressFeedback   = "Progress Feedback"
        case workoutInstructions = "Workout Instructions"
        case motivational       = "Motivational Message"
        case checkIn            = "Check-In"
        case formCorrection     = "Form Correction"
        case general            = "General Message"
    }

    enum UploadStatus: String, Codable {
        case local      // recorded but not yet uploaded
        case uploading  // in progress
        case uploaded   // available to client via supabaseURL
        case failed     // upload failed — retry available
    }

    init(trainerId:    String,
         clientId:    String,
         title:       String,
         message:     String,
         videoFileName: String,
         duration:    TimeInterval,
         messageType: MessageType = .general) {
        self.id            = UUID().uuidString
        self.trainerId     = trainerId
        self.clientId      = clientId
        self.title         = title
        self.message       = message
        self.videoFileName = videoFileName
        self.supabaseURL   = nil
        self.duration      = duration
        self.dateCreated   = Date()
        self.isViewed      = false
        self.messageType   = messageType
        self.uploadStatus  = .local
    }

    // MARK: - Computed

    /// Local file URL on the trainer's device
    var localVideoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(videoFileName)
    }

    /// URL to use for playback — prefers Supabase (accessible everywhere),
    /// falls back to local file (trainer device only)
    var playbackURL: URL? {
        if let remote = supabaseURL, let url = URL(string: remote) {
            return url
        }
        let local = localVideoURL
        return FileManager.default.fileExists(atPath: local.path) ? local : nil
    }

    /// Whether this video can be played on the client's device
    var isAvailableToClient: Bool { supabaseURL != nil }

    var isNew: Bool { !isViewed }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: dateCreated)
    }

    var formattedDuration: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }

    var timeAgo: String {
        let c = Calendar.current.dateComponents(
            [.minute, .hour, .day, .weekOfYear], from: dateCreated, to: Date())
        if let w = c.weekOfYear, w > 0 { return "\(w)w ago" }
        if let d = c.day,       d > 0  { return "\(d)d ago" }
        if let h = c.hour,      h > 0  { return "\(h)h ago" }
        if let m = c.minute,    m > 0  { return "\(m)m ago" }
        return "Just now"
    }

    // MARK: - Sample data

    static let sampleMessages: [VideoMessage] = []
}
