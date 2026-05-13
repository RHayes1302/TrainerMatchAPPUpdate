//
//  ReviewViews.swift
//  TrainerMatch
//
//  All review-related views:
//  - TrainerRatingSummary (shown on public profile)
//  - WriteReviewView (client submits a review)
//  - ReviewCard (single review display)
//  - TrainerReviewsListView (all reviews for a trainer)
//  - TrainerRespondView (trainer responds to a review)
//  - VerificationBadge (silver/gold badge)
//  - TrainerVerificationView (trainer claims/uploads cert)
//

import SwiftUI
import PhotosUI

// MARK: ─────────────────────────────────────────────
// MARK: VERIFICATION BADGE
// MARK: ─────────────────────────────────────────────

struct VerificationBadge: View {
    let status: VerificationStatus
    var compact: Bool = false

    var body: some View {
        switch status {
        case .verified:
            badge("checkmark.seal.fill", compact ? "Verified" : "Verified Trainer",
                  fg: .black, bg: Color.tmGold)
        case .claimed, .pending:
            badge("doc.badge.checkmark", compact ? "Cert on File" : "Certification on File",
                  fg: .white, bg: Color.white.opacity(0.15))
        case .none:
            EmptyView()
        }
    }

    private func badge(_ icon: String, _ label: String,
                       fg: Color, bg: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: compact ? 9 : 11, weight: .bold))
            Text(label).font(.system(size: compact ? 9 : 11, weight: .bold))
        }
        .foregroundColor(fg)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 3 : 5)
        .background(Capsule().fill(bg))
        .overlay(Capsule().stroke(status == .verified ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 1))
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: RATING SUMMARY (shown on public profile)
// MARK: ─────────────────────────────────────────────

struct TrainerRatingSummary: View {
    let trainerId: String
    @ObservedObject private var store = ReviewStore.shared

    private var avg: Double   { store.averageRating(forTrainer: trainerId) }
    private var count: Int    { store.reviewCount(forTrainer: trainerId) }
    private var breakdown: [Int: Int] { store.ratingBreakdown(forTrainer: trainerId) }

    var body: some View {
        if count == 0 {
            HStack(spacing: 6) {
                Image(systemName: "star").foregroundColor(.white.opacity(0.3))
                Text("No reviews yet").font(.caption).foregroundColor(.white.opacity(0.35))
            }
        } else {
            VStack(spacing: 12) {
                // Big rating number
                HStack(alignment: .bottom, spacing: 12) {
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f", avg))
                            .font(.system(size: 48, weight: .black)).foregroundColor(.tmGold)
                        starRow(rating: avg, size: 18)
                        Text("\(count) review\(count == 1 ? "" : "s")")
                            .font(.caption).foregroundColor(.white.opacity(0.4))
                    }
                    Spacer()
                    // Breakdown bars
                    VStack(spacing: 4) {
                        ForEach([5, 4, 3, 2, 1], id: \.self) { star in
                            ratingBar(star: star)
                        }
                    }
                }

                Divider().background(Color.white.opacity(0.08))

                // Category averages
                let reviews = store.reviews(forTrainer: trainerId)
                if !reviews.isEmpty {
                    let comm  = reviews.map { $0.communicationRating }.reduce(0,+) / Double(reviews.count)
                    let punct = reviews.map { $0.punctualityRating   }.reduce(0,+) / Double(reviews.count)
                    let res   = reviews.map { $0.resultsRating       }.reduce(0,+) / Double(reviews.count)
                    HStack(spacing: 0) {
                        categoryAvg("💬", "Communication", comm)
                        categoryAvg("⏰", "Punctuality", punct)
                        categoryAvg("💪", "Results", res)
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
        }
    }

    private func ratingBar(star: Int) -> some View {
        let total  = max(count, 1)
        let filled = breakdown[star] ?? 0
        let ratio  = Double(filled) / Double(total)
        return HStack(spacing: 6) {
            Text("\(star)").font(.system(size: 10)).foregroundColor(.white.opacity(0.4))
                .frame(width: 8)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1)).frame(height: 5)
                    Capsule().fill(Color.tmGold).frame(width: geo.size.width * ratio, height: 5)
                }
            }
            .frame(height: 5)
            Text("\(filled)").font(.system(size: 10)).foregroundColor(.white.opacity(0.3))
                .frame(width: 16)
        }
        .frame(height: 14)
    }

    private func categoryAvg(_ icon: String, _ label: String, _ value: Double) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 18))
            Text(String(format: "%.1f", value))
                .font(.system(size: 14, weight: .bold)).foregroundColor(.tmGold)
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: WRITE REVIEW VIEW
// MARK: ─────────────────────────────────────────────

struct WriteReviewView: View {
    let trainer:    SavedTrainerProfile
    let clientId:   String
    let clientName: String
    let isVerifiedBooking: Bool

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = ReviewStore.shared

    @State private var overallRating:       Double = 0
    @State private var communicationRating: Double = 0
    @State private var punctualityRating:   Double = 0
    @State private var resultsRating:       Double = 0
    @State private var reviewText = ""
    @State private var submitted  = false

    private var canSubmit: Bool {
        overallRating > 0 && communicationRating > 0 &&
        punctualityRating > 0 && resultsRating > 0
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(Color.tmGold.opacity(0.15))
                                .frame(width: 64, height: 64)
                                .overlay(Circle().stroke(Color.tmGold, lineWidth: 1.5))
                            Text(trainer.firstName.prefix(1))
                                .font(.system(size: 24, weight: .black)).foregroundColor(.tmGold)
                        }
                        Text(trainer.businessName ?? trainer.fullName)
                            .font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                        if isVerifiedBooking {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text("Verified booking").font(.caption).foregroundColor(.green)
                            }
                        }
                    }
                    .padding(.top, 20)

                    // Overall rating
                    VStack(spacing: 10) {
                        sectionLabel("OVERALL RATING")
                        interactiveStars(rating: $overallRating, size: 40)
                        if overallRating > 0 {
                            Text(ratingLabel(overallRating))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.tmGold)
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))

                    // Category ratings
                    VStack(spacing: 14) {
                        sectionLabel("RATE SPECIFIC AREAS")
                        categoryRating("💬", "Communication",
                                       subtitle: "Responsiveness and clarity",
                                       rating: $communicationRating)
                        categoryRating("⏰", "Punctuality",
                                       subtitle: "On time for sessions",
                                       rating: $punctualityRating)
                        categoryRating("💪", "Results",
                                       subtitle: "Progress and effectiveness",
                                       rating: $resultsRating)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))

                    // Written review
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("WRITTEN REVIEW (OPTIONAL)")
                        TextField("Share your experience with this trainer...",
                                  text: $reviewText, axis: .vertical)
                            .foregroundColor(.white).lineLimit(4...8).padding(14)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.06)))
                    }

                    // Submit
                    Button(action: submit) {
                        Text("SUBMIT REVIEW")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            .foregroundColor(canSubmit ? .black : .white.opacity(0.3))
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(RoundedRectangle(cornerRadius: 27)
                                .fill(canSubmit ? Color.tmGold : Color.white.opacity(0.08)))
                            .shadow(color: canSubmit ? Color.tmGold.opacity(0.4) : .clear,
                                    radius: 12)
                    }
                    .disabled(!canSubmit)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Write a Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Review Submitted!", isPresented: $submitted) {
            Button("Done") { dismiss() }
        } message: {
            Text("Thank you for your feedback. It helps other clients find great trainers.")
        }
    }

    private func submit() {
        let review = TrainerReview(
            trainerId: trainer.id, clientId: clientId, clientName: clientName,
            overallRating: overallRating, communicationRating: communicationRating,
            punctualityRating: punctualityRating, resultsRating: resultsRating,
            reviewText: reviewText, isVerifiedBooking: isVerifiedBooking
        )
        store.submitReview(review)
        submitted = true
    }

    private func ratingLabel(_ rating: Double) -> String {
        switch Int(rating) {
        case 5: return "Excellent"
        case 4: return "Great"
        case 3: return "Good"
        case 2: return "Fair"
        default: return "Poor"
        }
    }

    private func categoryRating(_ icon: String, _ title: String,
                                  subtitle: String, rating: Binding<Double>) -> some View {
        HStack(spacing: 14) {
            Text(icon).font(.system(size: 24)).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(subtitle).font(.caption2).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            interactiveStars(rating: rating, size: 22)
        }
    }

    private func interactiveStars(rating: Binding<Double>, size: CGFloat) -> some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: Double(star) <= rating.wrappedValue
                      ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(Double(star) <= rating.wrappedValue
                                     ? .tmGold : .white.opacity(0.2))
                    .onTapGesture { rating.wrappedValue = Double(star) }
            }
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text).font(.system(size: 10, weight: .black)).tracking(1.5)
            .foregroundColor(.tmGold).frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: REVIEW CARD
// MARK: ─────────────────────────────────────────────

struct ReviewCard: View {
    let review: TrainerReview
    var isTrainerView: Bool = false
    @State private var showingRespond = false
    @ObservedObject private var store = ReviewStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 40, height: 40)
                    Text(review.clientName.prefix(1))
                        .font(.system(size: 16, weight: .bold)).foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(review.clientName)
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                        if review.isVerifiedBooking {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10)).foregroundColor(.green)
                        }
                    }
                    Text(review.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2).foregroundColor(.white.opacity(0.35))
                }
                Spacer()
                starRow(rating: review.overallRating, size: 13)
            }

            // Review text
            if !review.reviewText.isEmpty {
                Text(review.reviewText)
                    .font(.subheadline).foregroundColor(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Category mini-ratings
            HStack(spacing: 14) {
                miniRating("💬", review.communicationRating)
                miniRating("⏰", review.punctualityRating)
                miniRating("💪", review.resultsRating)
            }

            // Trainer response
            if let response = review.trainerResponse {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TRAINER RESPONSE").font(.system(size: 9, weight: .black))
                        .tracking(1.2).foregroundColor(.tmGold)
                    Text(response).font(.caption).foregroundColor(.white.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.tmGold.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
            } else if isTrainerView {
                Button(action: { showingRespond = true }) {
                    Label("Respond to this review", systemImage: "bubble.left.fill")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)))
        .sheet(isPresented: $showingRespond) {
            NavigationView {
                TrainerRespondView(review: review)
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private func miniRating(_ icon: String, _ value: Double) -> some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 11))
            Text(String(format: "%.1f", value))
                .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold)
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: ALL REVIEWS LIST
// MARK: ─────────────────────────────────────────────

struct TrainerReviewsListView: View {
    let trainerId:   String
    var isTrainerView: Bool = false
    @ObservedObject private var store = ReviewStore.shared

    private var reviews: [TrainerReview] { store.reviews(forTrainer: trainerId) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if reviews.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48)).foregroundColor(.white.opacity(0.1))
                        .padding(.top, 60)
                    Text("No reviews yet").font(.title3).foregroundColor(.white.opacity(0.4))
                    Text("Reviews from verified clients will appear here.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.25))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        TrainerRatingSummary(trainerId: trainerId)
                        ForEach(reviews) { review in
                            ReviewCard(review: review, isTrainerView: isTrainerView)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Reviews")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: TRAINER RESPOND VIEW
// MARK: ─────────────────────────────────────────────

struct TrainerRespondView: View {
    let review: TrainerReview
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = ReviewStore.shared
    @State private var response = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                // Show the review
                ReviewCard(review: review).padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR RESPONSE").font(.system(size: 10, weight: .black))
                        .tracking(1.5).foregroundColor(.tmGold).padding(.horizontal, 20)
                    TextField("Thank the client and address their feedback...",
                              text: $response, axis: .vertical)
                        .foregroundColor(.white).lineLimit(3...8).padding(14)
                        .background(RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.06)))
                        .padding(.horizontal, 20)
                }

                Button(action: {
                    store.respondToReview(reviewId: review.id, response: response)
                    dismiss()
                }) {
                    Text("POST RESPONSE")
                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        .foregroundColor(response.isEmpty ? .white.opacity(0.3) : .black)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26)
                            .fill(response.isEmpty ? Color.white.opacity(0.08) : Color.tmGold))
                }
                .disabled(response.isEmpty)
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 20)
        }
        .navigationTitle("Respond to Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: VERIFICATION VIEW (trainer side)
// MARK: ─────────────────────────────────────────────

struct TrainerVerificationView: View {
    let trainerId: String
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = ReviewStore.shared

    @State private var certBody    = "NASM"
    @State private var certNumber  = ""
    @State private var certExpiry  = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    @State private var isUploading = false
    @State private var showSuccess = false

    private let certBodies = ["NASM", "ISSA", "ACE", "ACSM", "NSCA", "AFAA",
                               "NCSF", "NESTA", "NFPT", "PTA Global", "Other"]

    private var existing: TrainerVerification? { store.verification(forTrainer: trainerId) }
    private var status: VerificationStatus { store.verificationStatus(forTrainer: trainerId) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    // Current status
                    statusHeader

                    if status != .verified {
                        // Step 1 — claim certification
                        step1_claimCert

                        // Step 2 — upload photo
                        step2_uploadPhoto
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20).padding(.top, 20)
            }
        }
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .alert("Submitted!", isPresented: $showSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your certification photo has been submitted for review. You'll receive a gold Verified badge once approved.")
        }
        .onChange(of: selectedPhotoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    await MainActor.run { selectedPhotoData = data }
                }
            }
        }
    }

    private var statusHeader: some View {
        VStack(spacing: 12) {
            switch status {
            case .none:
                Image(systemName: "shield.slash")
                    .font(.system(size: 48)).foregroundColor(.white.opacity(0.2))
                Text("Not Yet Verified")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Add your certification to build client trust and stand out in search results.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            case .claimed:
                Image(systemName: "doc.badge.checkmark")
                    .font(.system(size: 48)).foregroundColor(.white.opacity(0.6))
                Text("Certification on File")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                if let v = existing {
                    Text("\(v.certificationBody) · \(v.certificationNumber)")
                        .font(.subheadline).foregroundColor(.tmGold)
                }
                Text("Upload your certification photo to get the gold Verified badge.")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            case .pending:
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 48)).foregroundColor(.orange)
                Text("Under Review")
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("Your certification photo is being reviewed. This usually takes 24–48 hours.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.45))
                    .multilineTextAlignment(.center)
            case .verified:
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64)).foregroundColor(.tmGold)
                    .shadow(color: .tmGold.opacity(0.4), radius: 16)
                Text("Verified Trainer")
                    .font(.system(size: 22, weight: .black)).foregroundColor(.white)
                VerificationBadge(status: .verified)
                Text("Your certification has been verified. Your gold badge is visible on your profile and in search results.")
                    .font(.caption).foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
    }

    private var step1_claimCert: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(Color.tmGold).frame(width: 24, height: 24)
                    Text("1").font(.system(size: 12, weight: .black)).foregroundColor(.black)
                }
                Text("CLAIM YOUR CERTIFICATION")
                    .font(.system(size: 10, weight: .black)).tracking(1.2).foregroundColor(.tmGold)
            }

            // Body picker
            VStack(alignment: .leading, spacing: 6) {
                Text("CERTIFYING BODY").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.white.opacity(0.5))
                Menu {
                    ForEach(certBodies, id: \.self) { body in
                        Button(body) { certBody = body }
                    }
                } label: {
                    HStack {
                        Text(certBody).foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.tmGold)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
                }
            }

            fieldView("CERTIFICATION NUMBER", placeholder: "e.g. NASM-CPT-123456", text: $certNumber)
            fieldView("EXPIRY DATE (MM/YYYY)", placeholder: "e.g. 06/2027", text: $certExpiry)

            Button(action: {
                store.claimCertification(trainerId: trainerId, body: certBody,
                                          number: certNumber, expiry: certExpiry.isEmpty ? nil : certExpiry)
            }) {
                Text(status == .none ? "SAVE CERTIFICATION" : "UPDATE CERTIFICATION")
                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                    .foregroundColor(certNumber.isEmpty ? .white.opacity(0.3) : .black)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24)
                        .fill(certNumber.isEmpty ? Color.white.opacity(0.08) : Color.tmGold))
            }
            .disabled(certNumber.isEmpty)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04)))
        .onAppear {
            if let v = existing {
                certBody   = v.certificationBody.isEmpty   ? "NASM" : v.certificationBody
                certNumber = v.certificationNumber
                certExpiry = v.certificationExpiry ?? ""
            }
        }
    }

    private var step2_uploadPhoto: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(status == .claimed || status == .pending
                                  ? Color.tmGold : Color.white.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Text("2").font(.system(size: 12, weight: .black))
                        .foregroundColor(status == .claimed || status == .pending ? .black : .white.opacity(0.4))
                }
                Text("UPLOAD CERTIFICATION PHOTO")
                    .font(.system(size: 10, weight: .black)).tracking(1.2)
                    .foregroundColor(status == .claimed || status == .pending
                                     ? .tmGold : .white.opacity(0.3))
            }

            Text("Take a clear photo of your certification card or certificate. This is reviewed by TrainerMatch staff and never shared publicly.")
                .font(.caption).foregroundColor(.white.opacity(0.4))

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 10) {
                    if let data = selectedPhotoData, let img = UIImage(data: data) {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 80, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("Photo selected — tap to change")
                            .font(.caption).foregroundColor(.tmGold)
                    } else {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20)).foregroundColor(.tmGold)
                        Text("Tap to take or upload photo")
                            .font(.subheadline).foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
            }
            .disabled(status == .none)

            Button(action: submitPhoto) {
                HStack(spacing: 8) {
                    if isUploading { ProgressView().tint(.black) }
                    else { Image(systemName: "arrow.up.circle.fill") }
                    Text(isUploading ? "SUBMITTING..." : "SUBMIT FOR VERIFICATION")
                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                }
                .foregroundColor(selectedPhotoData == nil ? .white.opacity(0.3) : .black)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(RoundedRectangle(cornerRadius: 24)
                    .fill(selectedPhotoData == nil ? Color.white.opacity(0.08) : Color.tmGold))
            }
            .disabled(selectedPhotoData == nil || isUploading || status == .none)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(status == .none ? Color.clear : Color.tmGold.opacity(0.15), lineWidth: 1)))
    }

    private func submitPhoto() {
        isUploading = true
        // In production: upload photo to Supabase storage
        // For now simulate upload with a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            store.uploadCertificationPhoto(trainerId: trainerId,
                                           photoURL: "pending_review_\(trainerId)")
            isUploading  = false
            showSuccess  = true
        }
    }

    private func fieldView(_ label: String, placeholder: String,
                            text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.white.opacity(0.5))
            TextField(placeholder, text: text)
                .foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: SHARED HELPERS
// MARK: ─────────────────────────────────────────────

func starRow(rating: Double, size: CGFloat = 14) -> some View {
    HStack(spacing: 2) {
        ForEach(1...5, id: \.self) { i in
            Image(systemName: Double(i) <= rating ? "star.fill"
                  : (Double(i) - 0.5 <= rating ? "star.leadinghalf.filled" : "star"))
                .font(.system(size: size))
                .foregroundColor(Double(i) <= rating ? .tmGold : .white.opacity(0.2))
        }
    }
}
