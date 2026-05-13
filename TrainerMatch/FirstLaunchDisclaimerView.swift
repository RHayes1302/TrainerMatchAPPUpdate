//
//  FirstLaunchDisclaimerView.swift
//  TrainerMatch
//
//  First-launch liability + terms disclaimer, styled after OnThaSet.
//  Show this before WelcomeView on first launch only.
//

import SwiftUI

struct FirstLaunchDisclaimerView: View {
    @Binding var hasAcceptedTerms: Bool
    @State private var agreedToTerms     = false
    @State private var agreedToLiability = false
    @State private var shake             = false
    @State private var showingTerms      = false
    @State private var showingPrivacy    = false

    private var canProceed: Bool { agreedToTerms && agreedToLiability }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Logo
                    VStack(spacing: 12) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.4), radius: 20, x: 0, y: 10)
                            .padding(.top, 60)
                        Text("TrainerMatch")
                            .font(.system(size: 32, weight: .heavy)).italic()
                            .foregroundColor(.white)
                        Text("Local Trainers, Real Results")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.tmGold)
                    }

                    // Important notice header
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.tmGold).font(.title2)
                        Text("BEFORE YOU CONTINUE")
                            .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                            .foregroundColor(.tmGold)
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(Color.tmGold.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))
                    .padding(.horizontal, 20)

                    // Disclaimer card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange).font(.caption)
                            Text("LIABILITY NOTICE")
                                .font(.system(size: 11, weight: .black)).tracking(0.5)
                                .foregroundColor(.orange)
                        }

                        Text("TrainerMatch is a technology platform that connects clients with independent personal trainers. We do not employ, supervise, or control any trainer listed on this platform.")
                            .font(.caption).foregroundColor(.gray)

                        Text("Participation in any fitness program, session, or activity arranged through TrainerMatch is entirely at your own risk. TrainerMatch, its owners, operators, and affiliates are NOT responsible for any injury, death, property damage, or harm of any kind that occurs in connection with any trainer or activity found on this platform.")
                            .font(.caption).fontWeight(.semibold).foregroundColor(.white)

                        Text("Always consult a physician before beginning any exercise program. Trainers listed are independent contractors and not employees of TrainerMatch.")
                            .font(.caption).foregroundColor(.gray)
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.orange.opacity(0.06)))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 20)

                    // Checkboxes
                    VStack(spacing: 12) {
                        // Terms checkbox
                        Button(action: { agreedToTerms.toggle() }) {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: agreedToTerms
                                      ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(agreedToTerms ? .tmGold : .gray)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("I agree to the Terms of Service and Privacy Policy")
                                        .font(.subheadline).foregroundColor(.white)
                                    HStack(spacing: 10) {
                                        Button(action: { showingTerms = true }) {
                                            Text("Read Terms")
                                                .font(.caption.bold()).foregroundColor(.tmGold)
                                                .underline()
                                        }
                                        Button(action: { showingPrivacy = true }) {
                                            Text("Read Privacy Policy")
                                                .font(.caption.bold()).foregroundColor(.tmGold)
                                                .underline()
                                        }
                                    }
                                }
                                Spacer()
                            }
                            .padding(14)
                            .background(agreedToTerms
                                        ? Color.tmGold.opacity(0.08) : Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(agreedToTerms
                                        ? Color.tmGold.opacity(0.5) : Color.gray.opacity(0.2),
                                        lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        // Liability checkbox
                        Button(action: { agreedToLiability.toggle() }) {
                            HStack(alignment: .top, spacing: 14) {
                                Image(systemName: agreedToLiability
                                      ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(agreedToLiability ? .tmGold : .gray)

                                Text("I understand that TrainerMatch is not responsible for any harm, injury, or damage that occurs in connection with any trainer or fitness activity found on this platform. I participate at my own risk.")
                                    .font(.subheadline).foregroundColor(.white)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(14)
                            .background(agreedToLiability
                                        ? Color.tmGold.opacity(0.08) : Color.white.opacity(0.04))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(agreedToLiability
                                        ? Color.tmGold.opacity(0.5) : Color.gray.opacity(0.2),
                                        lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .offset(x: shake ? -8 : 0)
                    .animation(shake
                               ? .easeInOut(duration: 0.1).repeatCount(4) : .default,
                               value: shake)

                    if !canProceed {
                        Text("You must agree to both statements to continue")
                            .font(.caption).foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    }

                    // Enter button
                    Button(action: {
                        if canProceed {
                            UserDefaults.standard.set(true, forKey: "tm_hasAcceptedTerms")
                            UserDefaults.standard.set(
                                Date().timeIntervalSince1970, forKey: "tm_termsAcceptedDate")
                            withAnimation { hasAcceptedTerms = true }
                        } else {
                            shake = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shake = false }
                        }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: canProceed
                                  ? "checkmark.shield.fill" : "lock.fill")
                            Text(canProceed ? "ENTER TRAINERMATCH" : "AGREE TO CONTINUE")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(RoundedRectangle(cornerRadius: 28)
                            .fill(canProceed ? Color.tmGold : Color.gray.opacity(0.4)))
                        .shadow(color: canProceed ? .tmGold.opacity(0.4) : .clear, radius: 12)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showingTerms)   { TermsOfServiceDisclaimerView() }
        .sheet(isPresented: $showingPrivacy) { PrivacyPolicyDisclaimerView() }
    }
}

// MARK: - Terms Sheet

struct TermsOfServiceDisclaimerView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("TERMS OF SERVICE")
                        .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                        .padding(.top, 40)
                    Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                        .font(.caption).foregroundColor(.gray)

                    legalSection("1. Acceptance of Terms",
                        "By using TrainerMatch, you agree to these Terms of Service. If you do not agree, do not use the app.")
                    legalSection("2. Platform Role",
                        "TrainerMatch is a marketplace platform only. We connect clients with independent personal trainers. We do not employ trainers and are not responsible for the quality, safety, or legality of their services.")
                    legalSection("3. User Responsibility",
                        "Users are responsible for verifying trainer credentials, qualifications, and fitness to provide services. Always consult a physician before beginning any fitness program.")
                    legalSection("4. Liability Limitation",
                        "TrainerMatch is not liable for any injury, illness, death, property damage, or financial loss arising from use of the platform or participation in any training session.")
                    legalSection("5. Payments",
                        "Payments are processed securely via Stripe. TrainerMatch does not store payment card data. All transactions are between the client and trainer directly.")
                    legalSection("6. Privacy",
                        "We collect only the information necessary to operate the platform. We do not sell your personal information. See our Privacy Policy for details.")
                    legalSection("7. Termination",
                        "We reserve the right to suspend or terminate accounts that violate these terms or engage in fraudulent or harmful behavior.")
                }
                .padding(.horizontal, 24).padding(.bottom, 60)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.tmGold).padding(20)
            }
        }
    }

    private func legalSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(body).font(.caption).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }
}

// MARK: - Privacy Policy Sheet

struct PrivacyPolicyDisclaimerView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("PRIVACY POLICY")
                        .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                        .padding(.top, 40)
                    Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                        .font(.caption).foregroundColor(.gray)

                    legalSection("Data We Collect",
                        "We collect your email, name, fitness goals, and location when you create an account. We also collect usage data to improve the app.")
                    legalSection("How We Use Your Data",
                        "Your data is used to match you with trainers, process bookings, send notifications, and improve app functionality. We do not sell your personal information.")
                    legalSection("Location Data",
                        "Location is used to show nearby trainers and gyms. You can disable location access in your device settings at any time.")
                    legalSection("Third Parties",
                        "We use Stripe for payment processing and Supabase for data storage. Both are subject to their own privacy policies and security standards.")
                    legalSection("Data Security",
                        "We use industry-standard encryption and security practices to protect your data. Passwords are never stored in plain text.")
                    legalSection("Your Rights",
                        "You may request deletion of your account and associated data at any time by contacting us through the app.")
                    legalSection("Contact",
                        "For privacy questions, contact us through the TrainerMatch app support channel.")
                }
                .padding(.horizontal, 24).padding(.bottom, 60)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.tmGold).padding(20)
            }
        }
    }

    private func legalSection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(body).font(.caption).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
    }
}
