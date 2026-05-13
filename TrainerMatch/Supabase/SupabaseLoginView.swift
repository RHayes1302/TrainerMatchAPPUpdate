//
//  SupabaseLoginView.swift
//  TrainerMatch
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct SupabaseLoginView: View {
    @ObservedObject private var auth = SupabaseAuthManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var email                 = ""
    @State private var password              = ""
    @State private var isTrainerLogin        = true
    @State private var showingError          = false
    @State private var errorMessage          = ""
    @State private var isLoading             = false
    @State private var showingForgotPassword = false
    @State private var nonce: String         = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20)
                            .padding(.top, 60)
                        Text("TrainerMatch")
                            .font(.system(size: 44, weight: .heavy)).italic()
                            .foregroundColor(.white)
                        Text("Local Trainers, Real Results")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.tmGold)
                    }
                    .padding(.bottom, 36)

                    roleToggle.padding(.horizontal, 40).padding(.bottom, 28)

                    VStack(spacing: 18) {
                        appleSignInButton.padding(.top, 4)
                        divider

                        if showingError {
                            errorBanner
                        }

                        fieldBlock("EMAIL", placeholder: "your@email.com",
                                   text: $email, keyboard: .emailAddress,
                                   contentType: .emailAddress, secure: false)

                        fieldBlock("PASSWORD", placeholder: "Enter password",
                                   text: $password, keyboard: .default,
                                   contentType: .password, secure: true)

                        Button(action: { showingForgotPassword = true }) {
                            Text("Forgot Password?")
                                .font(.caption).foregroundColor(.tmGold)
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        loginButton

                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.caption).foregroundColor(.white.opacity(0.5))
                            Button(action: { dismiss() }) {
                                Text("Sign Up")
                                    .font(.caption).fontWeight(.bold).foregroundColor(.tmGold)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05)))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 60)
                }
            }

            if isLoading {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView().tint(.tmGold).scaleEffect(1.5)
                    Text("Signing in...").foregroundColor(.white).font(.subheadline)
                }
            }
        }
        .alert("Reset Password", isPresented: $showingForgotPassword) {
            TextField("your@email.com", text: $email)
                .keyboardType(.emailAddress).autocapitalization(.none)
            Button("Send Reset Link") { sendPasswordReset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter your email and we'll send a reset link.")
        }
    }

    // MARK: - Sub views

    private var roleToggle: some View {
        HStack(spacing: 0) {
            roleButton("CLIENT",  selected: !isTrainerLogin) { isTrainerLogin = false }
            roleButton("TRAINER", selected:  isTrainerLogin) { isTrainerLogin = true  }
        }
        .background(RoundedRectangle(cornerRadius: 22).stroke(Color.tmGold, lineWidth: 2))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func roleButton(_ label: String, selected: Bool,
                             action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action() } }) {
            Text(label)
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(selected ? .black : .white.opacity(0.5))
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(selected ? Color.tmGold : Color.clear)
        }
    }

    private var appleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            print("🍎 Apple Sign In request started")
            nonce = randomNonceString()
            request.requestedScopes = [.fullName, .email]
            request.nonce           = sha256(nonce)
        } onCompletion: { result in
            print("🍎 Apple Sign In completed: \(result)")
            handleAppleResult(result)
        }
        .signInWithAppleButtonStyle(.white)
        .frame(maxWidth: .infinity).frame(height: 54)
        .cornerRadius(27)
        .shadow(color: .white.opacity(0.15), radius: 8, x: 0, y: 4)
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
            Text("OR").font(.caption).foregroundColor(.white.opacity(0.5)).padding(.horizontal, 12)
            Rectangle().fill(Color.white.opacity(0.2)).frame(height: 1)
        }
    }

    private var errorBanner: some View {
        Text(errorMessage)
            .font(.caption).foregroundColor(.red)
            .padding(.horizontal).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
            .frame(maxWidth: .infinity)
    }

    private func fieldBlock(_ label: String, placeholder: String,
                             text: Binding<String>,
                             keyboard: UIKeyboardType,
                             contentType: UITextContentType,
                             secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            Group {
                if secure {
                    SecureField(placeholder, text: text)
                        .textContentType(contentType)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(keyboard)
                        .autocapitalization(.none)
                        .textContentType(contentType)
                }
            }
            .foregroundColor(.white).padding(14)
            .background(Color.white.opacity(0.07))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tmGold.opacity(0.25), lineWidth: 1))
        }
    }

    private var loginButton: some View {
        Button(action: handleEmailLogin) {
            Text("LOGIN WITH EMAIL")
                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold))
                .shadow(color: .tmGold.opacity(0.45), radius: 12, x: 0, y: 6)
        }
        .padding(.top, 4)
    }

    // MARK: - Actions

    private func handleEmailLogin() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter your email and password"
            showingError = true
            return
        }
        isLoading = true
        showingError = false
        Task {
            do {
                try await auth.signIn(
                    email: email, password: password,
                    role: isTrainerLogin ? .trainer : .client
                )
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
            await MainActor.run { isLoading = false }
        }
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        print("🍎 handleAppleResult fired")
        switch result {
        case .success(let authResult):
            print("🍎 Apple success")
            guard let cred = authResult.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = cred.identityToken,
                  let token = String(data: tokenData, encoding: .utf8) else {
                print("🍎 Failed to get token")
                return
            }
            let firstName = cred.fullName?.givenName  ?? ""
            let lastName  = cred.fullName?.familyName ?? ""
            print("🍎 Token obtained, firstName: \(firstName)")
            isLoading = true
            Task {
                do {
                    print("🍎 Calling signInWithApple...")
                    let _ = try await SupabaseAuthManager.shared.signInWithApple(
                        idToken: token, nonce: nonce,
                        role: isTrainerLogin ? .trainer : .client,
                        firstName: firstName, lastName: lastName
                    )
                    print("🍎 signInWithApple succeeded, dismissing...")
                    await MainActor.run {
                        isLoading = false
                        dismiss()
                    }
                } catch {
                    print("🍎 signInWithApple ERROR: \(error)")
                    await MainActor.run {
                        errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        showingError = true
                        isLoading = false
                    }
                }
            }
        case .failure(let error):
            print("🍎 Apple failure: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func sendPasswordReset() {
        guard !email.isEmpty else { return }
        Task { try? await auth.resetPassword(email: email) }
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            SecRandomCopyBytes(Security.kSecRandomDefault, randoms.count, &randoms)
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed    = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
