//
//  SupabaseManager.swift
//  TrainerMatch
//

import Foundation
import Supabase
import Auth

// MARK: - Client

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://axmxhxdqfxedltjclssz.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4bXhoeGRxZnhlZGx0amNsc3N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MTYzMjQsImV4cCI6MjA5MjM5MjMyNH0.pUP1qRfN_ugKfBPjERiPiV7C9lEpsmwe8wGHXPh7HVg"
)

// MARK: - Storage helper

enum StorageBucket: String {
    case profilePhotos  = "profile-photos"
    case bannerPhotos   = "banner-photos"
    case checkInPhotos  = "check-in-photos"
    case certPhotos     = "cert-photos"
    case sharedFiles    = "shared-files"
    case gymAds         = "gym-ads"
    case trainerResults = "trainer-results"   // ✅ NEW
}

struct SupabaseStorage {

    static func uploadImage(
        data: Data,
        bucket: StorageBucket,
        path: String,
        contentType: String = "image/jpeg"
    ) async throws -> String {
        let _ = try await supabase.storage
            .from(bucket.rawValue)
            .upload(path, data: data, options: .init(contentType: contentType, upsert: true))

        let url = try supabase.storage
            .from(bucket.rawValue)
            .getPublicURL(path: path)
        return url.absoluteString
    }

    static func deleteFile(bucket: StorageBucket, path: String) async throws {
        let _ = try await supabase.storage
            .from(bucket.rawValue)
            .remove(paths: [path])
    }

    static func downloadImage(bucket: StorageBucket, path: String) async throws -> Data {
        try await supabase.storage
            .from(bucket.rawValue)
            .download(path: path)
    }
}

// MARK: - Image deletion

extension SupabaseStorage {

    static func deleteProfilePhoto(userId: String) async {
        try? await deleteFile(bucket: .profilePhotos, path: "\(userId)/profile.jpg")
    }

    static func deleteBannerPhoto(userId: String) async {
        try? await deleteFile(bucket: .bannerPhotos, path: "\(userId)/banner.jpg")
    }

    static func deleteCheckInPhotos(clientId: String, checkInId: String, count: Int) async {
        for i in 0..<count {
            try? await deleteFile(
                bucket: .checkInPhotos,
                path: "\(clientId)/checkin_\(checkInId)_\(i).jpg"
            )
        }
    }

    static func deleteByURL(_ urlString: String, bucket: StorageBucket) async {
        guard let url = URL(string: urlString) else { return }
        let components = url.pathComponents
        guard let bucketIndex = components.firstIndex(of: bucket.rawValue) else { return }
        let path = components.dropFirst(bucketIndex + 1).joined(separator: "/")
        try? await deleteFile(bucket: bucket, path: path)
    }

    static func deleteGymAdImage(adId: String) async {
        try? await deleteFile(bucket: .gymAds, path: "\(adId)/logo.jpg")
    }

    static func deleteCertPhoto(trainerId: String) async {
        try? await deleteFile(bucket: .certPhotos, path: "\(trainerId)/cert.jpg")
    }

    // ✅ NEW
    static func deleteTrainerResultPhotos(trainerId: String, resultId: String) async {
        try? await deleteFile(bucket: .trainerResults, path: "\(trainerId)/\(resultId)_before.jpg")
        try? await deleteFile(bucket: .trainerResults, path: "\(trainerId)/\(resultId)_after.jpg")
    }
}

// MARK: - Error handling

enum TMError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case uploadFailed(String)
    case networkError(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:       return "You must be signed in to continue."
        case .profileNotFound:        return "Profile not found."
        case .uploadFailed(let msg):  return "Upload failed: \(msg)"
        case .networkError(let msg):  return "Network error: \(msg)"
        case .unknown(let msg):       return msg
        }
    }
}
