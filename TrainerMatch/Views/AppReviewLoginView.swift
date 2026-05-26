//
//  AppReviewLoginView.swift
//  TrainerMatch
//
//  Shown on the login screen when App Review Mode is ON.
//  Lets Apple reviewers sign in with a pre-made demo account
//  and build a full trainer or client profile without Apple ID.
//
//  Demo credentials (set these up in Supabase Auth first):
//    Trainer:  reviewer.trainer@TrainerMatch.app / ReviewPass2026!
//    Client:   reviewer.client@TrainerMatch.app  / ReviewPass2026!
//

import SwiftUI

// MARK: - Review Login Button (add to SupabaseLoginView)

struct AppReviewLoginSection: View {
    @State private var showingReviewSheet = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1))
                Text("App Review").font(.caption2).foregroundColor(.white.opacity(0.3))
                Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.1))
            }

            Button(action: { showingReviewSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "appstore.fill")
                        .font(.subheadline)
                    Text("App Store Reviewer Access")
                        .font(.footnote).fontWeight(.semibold)
                }
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)))
            }
        }
        .sheet(isPresented: $showingReviewSheet) {
            AppReviewLoginView()
        }
    }
}

// MARK: - Full Review Login Sheet

struct AppReviewLoginView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var auth = SupabaseAuthManager.shared

    @State private var selectedRole: ReviewRole = .trainer
    @State private var isSigningIn = false
    @State private var errorMessage: String?

    enum ReviewRole: String, CaseIterable {
        case trainer = "Trainer"
        case client  = "Client"

        var icon: String {
            switch self {
            case .trainer: return "dumbbell.fill"
            case .client:  return "figure.walk"
            }
        }

        var email: String {
            switch self {
            case .trainer: return "reviewer.trainer@TrainerMatch.app"
            case .client:  return "reviewer.client@TrainerMatch.app"
            }
        }

        var password: String { "ReviewPass2026!" }

        var description: String {
            switch self {
            case .trainer:
                return "Explore the trainer dashboard, manage clients, create workouts, meal plans, and see the full trainer experience."
            case .client:
                return "Browse trainers, connect with a trainer, submit check-ins, track weight, and see the full client experience."
            }
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 80, height: 80)
                        Image(systemName: "appstore.fill")
                            .font(.system(size: 36)).foregroundColor(.tmGold)
                    }
                    .padding(.top, 40)

                    Text("App Store Review Access")
                        .font(.title2.bold()).foregroundColor(.white)
                    Text("This login is for Apple reviewers only.\nSign in to explore the full Nearby Trainers experience.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center).padding(.horizontal, 30)
                }
                .padding(.bottom, 32)

                // Role picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("CHOOSE A ROLE TO REVIEW")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                        .padding(.horizontal, 24)

                    HStack(spacing: 12) {
                        ForEach(ReviewRole.allCases, id: \.self) { role in
                            Button(action: { selectedRole = role }) {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(selectedRole == role
                                                  ? Color.tmGold : Color.white.opacity(0.08))
                                            .frame(width: 56, height: 56)
                                        Image(systemName: role.icon)
                                            .font(.title2)
                                            .foregroundColor(selectedRole == role ? .black : .white.opacity(0.5))
                                    }
                                    Text(role.rawValue)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(selectedRole == role ? .tmGold : .white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedRole == role
                                              ? Color.tmGold.opacity(0.08) : Color.white.opacity(0.04))
                                        .overlay(RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedRole == role
                                                    ? Color.tmGold : Color.white.opacity(0.08), lineWidth: 1.5))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Description card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: selectedRole.icon).foregroundColor(.tmGold).font(.caption)
                        Text("\(selectedRole.rawValue) Experience")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold)
                    }
                    Text(selectedRole.description)
                        .font(.subheadline).foregroundColor(.white.opacity(0.7)).lineSpacing(4)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
                .padding(.horizontal, 24).padding(.top, 20)

                // What you can do
                VStack(alignment: .leading, spacing: 8) {
                    Text("WHAT YOU CAN DO")
                        .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.white.opacity(0.4))

                    reviewFeatureRow(icon: "person.fill",           text: "Build a complete profile with photo")
                    reviewFeatureRow(icon: "dumbbell.fill",         text: "Create or receive workout plans")
                    reviewFeatureRow(icon: "fork.knife",            text: "Create or receive meal plans")
                    reviewFeatureRow(icon: "camera.fill",           text: "Submit or review weekly check-ins")
                    reviewFeatureRow(icon: "bubble.left.fill",      text: "Send and receive messages")
                    reviewFeatureRow(icon: "trophy.fill",           text: "View proof-of-work results gallery")
                    reviewFeatureRow(icon: "creditcard.fill",       text: "All features unlocked — no paywall")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
                .padding(.horizontal, 24).padding(.top, 16)

                Spacer()

                // Error
                if let err = errorMessage {
                    Text(err).font(.caption).foregroundColor(.red)
                        .padding(.horizontal, 24).multilineTextAlignment(.center)
                }

                // Sign in button
                Button(action: { Task { await signInAsReviewer() } }) {
                    HStack(spacing: 10) {
                        if isSigningIn {
                            ProgressView().tint(.black)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                            Text("SIGN IN AS \(selectedRole.rawValue.uppercased()) REVIEWER")
                                .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold))
                    .shadow(color: .tmGold.opacity(0.4), radius: 10, y: 5)
                }
                .disabled(isSigningIn)
                .padding(.horizontal, 24).padding(.bottom, 8)

                Button(action: { dismiss() }) {
                    Text("Cancel").foregroundColor(.white.opacity(0.4)).font(.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Sign In

    private func signInAsReviewer() async {
        await MainActor.run { isSigningIn = true; errorMessage = nil }

        do {
            try await supabase.auth.signIn(
                email:    selectedRole.email,
                password: selectedRole.password
            )
            await auth.restoreSession()
            await MainActor.run { isSigningIn = false; dismiss() }
        } catch {
            await MainActor.run {
                isSigningIn = false
                errorMessage = "Could not sign in. Make sure the reviewer accounts are set up in Supabase Auth."
            }
        }
    }

    // MARK: - Helper

    private func reviewFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.caption).foregroundColor(.tmGold).frame(width: 16)
            Text(text).font(.caption).foregroundColor(.white.opacity(0.6))
        }
    }
}
