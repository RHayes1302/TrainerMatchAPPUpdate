//
//  ReviewStore.swift
//  TrainerMatch
//
//  Reviews, star ratings, category ratings, and trainer verification system.
//  Reviews can be left by: booked clients (via BookingStore) or rostered clients (via TrainerViewModel)
//

import SwiftUI
import PhotosUI

// MARK: ─────────────────────────────────────────────
// MARK: MODELS
// MARK: ─────────────────────────────────────────────

struct TrainerReview: Identifiable, Codable {
    let id:          String
    var trainerId:   String
    var clientId:    String
    var clientName:  String
    var overallRating:       Double  // 1-5
    var communicationRating: Double  // 1-5
    var punctualityRating:   Double  // 1-5
    var resultsRating:       Double  // 1-5
    var reviewText:  String
    var isVerifiedBooking: Bool  // came from a paid booking
    var createdAt:   Date
    var trainerResponse: String?  // trainer can respond
    var trainerRespondedAt: Date?

    var averageCategoryRating: Double {
        (communicationRating + punctualityRating + resultsRating) / 3.0
    }

    init(trainerId: String, clientId: String, clientName: String,
         overallRating: Double, communicationRating: Double,
         punctualityRating: Double, resultsRating: Double,
         reviewText: String, isVerifiedBooking: Bool) {
        self.id                  = UUID().uuidString
        self.trainerId           = trainerId
        self.clientId            = clientId
        self.clientName          = clientName
        self.overallRating       = overallRating
        self.communicationRating = communicationRating
        self.punctualityRating   = punctualityRating
        self.resultsRating       = resultsRating
        self.reviewText          = reviewText
        self.isVerifiedBooking   = isVerifiedBooking
        self.createdAt           = Date()
        self.trainerResponse     = nil
        self.trainerRespondedAt  = nil
    }
}

// MARK: - Verification

enum VerificationStatus: String, Codable {
    case none        = "none"
    case claimed     = "claimed"     // certification number on file — silver badge
    case verified    = "verified"    // photo reviewed and approved — gold badge
    case pending     = "pending"     // photo uploaded, awaiting review
}

struct TrainerVerification: Codable {
    var trainerId:           String
    var certificationBody:   String       // NASM, ISSA, ACE, etc.
    var certificationNumber: String
    var certificationExpiry: String?      // MM/YYYY
    var status:              VerificationStatus
    var certPhotoURL:        String?      // uploaded photo URL
    var submittedAt:         Date
    var reviewedAt:          Date?
    var reviewNotes:         String?      // admin notes
}

// MARK: ─────────────────────────────────────────────
// MARK: STORE
// MARK: ─────────────────────────────────────────────

class ReviewStore: ObservableObject {
    static let shared = ReviewStore()

    @Published var reviews:       [TrainerReview]        = []
    @Published var verifications: [String: TrainerVerification] = [:]

    private var reviewURL: URL { docURL("tmReviews.json")       }
    private var verifURL:  URL { docURL("tmVerifications.json") }

    private init() { loadLocal() }

    // MARK: - Review queries

    func reviews(forTrainer id: String) -> [TrainerReview] {
        reviews.filter { $0.trainerId == id }
               .sorted { $0.createdAt > $1.createdAt }
    }

    func averageRating(forTrainer id: String) -> Double {
        let r = reviews(forTrainer: id)
        guard !r.isEmpty else { return 0 }
        return r.map { $0.overallRating }.reduce(0, +) / Double(r.count)
    }

    func reviewCount(forTrainer id: String) -> Int {
        reviews(forTrainer: id).count
    }

    func hasReviewed(trainerId: String, clientId: String) -> Bool {
        reviews.contains { $0.trainerId == trainerId && $0.clientId == clientId }
    }

    func canReview(trainerId: String, clientId: String) -> Bool {
        // Must not have already reviewed
        guard !hasReviewed(trainerId: trainerId, clientId: clientId) else { return false }
        // Must have a completed booking OR be on trainer's roster
        let hasBooking = BookingStore.shared.bookings(forClient: clientId)
            .contains { $0.trainerId == trainerId && $0.status == .completed && $0.isPaid }
        return hasBooking
    }

    func ratingBreakdown(forTrainer id: String) -> [Int: Int] {
        var breakdown: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        for review in reviews(forTrainer: id) {
            let star = Int(review.overallRating.rounded())
            breakdown[star, default: 0] += 1
        }
        return breakdown
    }

    // MARK: - Submit review

    func submitReview(_ review: TrainerReview) {
        guard !hasReviewed(trainerId: review.trainerId, clientId: review.clientId) else { return }
        reviews.insert(review, at: 0)
        saveLocal()
        // Notify trainer
        NotificationManager.shared.send(
            recipientId: review.trainerId, recipientRole: .trainer,
            senderId: review.clientId, senderName: review.clientName,
            category: .message,
            title: "New \(Int(review.overallRating))★ review from \(review.clientName)",
            body: review.reviewText.isEmpty ? "No comment" : review.reviewText
        )
    }

    func respondToReview(reviewId: String, response: String) {
        if let i = reviews.firstIndex(where: { $0.id == reviewId }) {
            reviews[i].trainerResponse    = response
            reviews[i].trainerRespondedAt = Date()
            saveLocal()
        }
    }

    func deleteReview(reviewId: String) {
        reviews.removeAll { $0.id == reviewId }
        saveLocal()
    }

    // MARK: - Verification

    func verification(forTrainer id: String) -> TrainerVerification? {
        verifications[id]
    }

    func verificationStatus(forTrainer id: String) -> VerificationStatus {
        verifications[id]?.status ?? .none
    }

    func claimCertification(trainerId: String, body: String,
                             number: String, expiry: String?) {
        let v = TrainerVerification(
            trainerId:           trainerId,
            certificationBody:   body,
            certificationNumber: number,
            certificationExpiry: expiry,
            status:              .claimed,
            certPhotoURL:        nil,
            submittedAt:         Date()
        )
        verifications[trainerId] = v
        saveLocal()
    }

    func uploadCertificationPhoto(trainerId: String, photoURL: String) {
        if var v = verifications[trainerId] {
            v.certPhotoURL = photoURL
            v.status       = .pending
            v.submittedAt  = Date()
            verifications[trainerId] = v
        } else {
            var v = TrainerVerification(
                trainerId: trainerId, certificationBody: "",
                certificationNumber: "", certificationExpiry: nil,
                status: .pending, certPhotoURL: photoURL, submittedAt: Date()
            )
            verifications[trainerId] = v
        }
        saveLocal()
    }

    func approveVerification(trainerId: String) {
        if var v = verifications[trainerId] {
            v.status     = .verified
            v.reviewedAt = Date()
            verifications[trainerId] = v
            saveLocal()
        }
    }

    // MARK: - Persistence

    private func docURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    private func saveLocal() {
        try? JSONEncoder().encode(reviews).write(to: reviewURL)
        let verifArray = Array(verifications.values)
        try? JSONEncoder().encode(verifArray).write(to: verifURL)
    }

    private func loadLocal() {
        if let d = try? Data(contentsOf: reviewURL),
           let v = try? JSONDecoder().decode([TrainerReview].self, from: d) {
            reviews = v
        }
        if let d = try? Data(contentsOf: verifURL),
           let v = try? JSONDecoder().decode([TrainerVerification].self, from: d) {
            verifications = Dictionary(uniqueKeysWithValues: v.map { ($0.trainerId, $0) })
        }
    }
}
