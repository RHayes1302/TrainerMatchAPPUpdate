//
//  LoginView.swift (UPDATED WITH REAL AUTH)
//  TrainerMatch
//
//  Now uses AuthManager for real user authentication
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @ObservedObject private var authManager = AuthManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isTrainerLogin = true
    @State private var showingSignup = false
    @State private var showingError = false
    @State private var showingAppleSetup = false
    @State private var appleUserId    = ""
    @State private var appleEmail     = ""
    @State private var appleFirstName = ""
    @State private var appleLastName  = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Black background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Logo
                        VStack(spacing: 20) {
                            TrainerMatchLogo(size: .large)
                                .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)
                                .padding(.top, 60)
                            
                            Text("TrainerMatch")
                                .font(.system(size: 44, weight: .heavy))
                                .italic()
                                .foregroundColor(.white)
                            
                            Text("Local Trainers, Real Results")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.tmGold)
                        }
                        .padding(.bottom, 40)
                        
                        // Login Type Selector
                        HStack(spacing: 0) {
                            Button(action: {
                                withAnimation {
                                    isTrainerLogin = false
                                }
                            }) {
                                Text("CLIENT")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(isTrainerLogin ? .white.opacity(0.5) : .black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        isTrainerLogin ? Color.clear : Color.tmGold
                                    )
                            }
                            
                            Button(action: {
                                withAnimation {
                                    isTrainerLogin = true
                                }
                            }) {
                                Text("TRAINER")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(isTrainerLogin ? .black : .white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        isTrainerLogin ? Color.tmGold : Color.clear
                                    )
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.tmGold, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                        
                        // Login Form
                        VStack(spacing: 20) {
                            // Apple Sign In — top for prominence
                            SignInWithAppleButton(.signIn) { request in
                                request.requestedScopes = [.fullName, .email]
                            } onCompletion: { result in
                                handleAppleSignIn(result: result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .cornerRadius(27)
                            .shadow(color: .white.opacity(0.15), radius: 8, x: 0, y: 4)

                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                                Text("OR")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.horizontal, 12)
                                Rectangle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 12)

                            // Error Message
                            if showingError {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.1))
                                    )
                            }

                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("EMAIL")
                                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                                    .foregroundColor(.tmGold)
                                TextField("your@email.com", text: $email)
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.tmGold.opacity(0.25), lineWidth: 1))
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("PASSWORD")
                                    .font(.system(size: 10, weight: .bold)).tracking(1.2)
                                    .foregroundColor(.tmGold)
                                SecureField("Enter password", text: $password)
                                    .padding(14)
                                    .background(Color.white.opacity(0.07))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.tmGold.opacity(0.25), lineWidth: 1))
                                    .foregroundColor(.white)
                                    .textContentType(.password)
                            }

                            // Forgot Password
                            Button(action: {}) {
                                Text("Forgot Password?")
                                    .font(.caption)
                                    .foregroundColor(.tmGold)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            // Login Button
                            Button(action: handleLogin) {
                                Text("LOGIN WITH EMAIL")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 27)
                                            .fill(Color.tmGold)
                                    )
                                    .shadow(color: .tmGold.opacity(0.45), radius: 12, x: 0, y: 6)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 60)
                    }
                }
                
                // Navigate when authenticated
                if authManager.isAuthenticated {
                    NavigationLink(destination: destinationView(), isActive: .constant(true)) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSignup) {
            // Pass authManager as environment object to signup views
            if isTrainerLogin {
                TrainerSignupView()
                    .environmentObject(authManager)
            } else {
                ClientSignupView()
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showingAppleSetup) {
            AppleSignInSetupView(
                userId:    appleUserId,
                email:     appleEmail,
                firstName: appleFirstName,
                lastName:  appleLastName,
                role:      isTrainerLogin ? .trainer : .client
            )
        }
        .onChange(of: authManager.isAuthenticated) { newValue in
            // When authentication changes, dismiss any signup sheet
            if newValue {
                print("🔐 Authentication detected! Dismissing signup...")
                showingSignup = false
            }
        }
    }
    
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let userId    = credential.user
            let email     = credential.email ?? "\(userId)@privaterelay.appleid.com"
            let firstName = credential.fullName?.givenName ?? ""
            let lastName  = credential.fullName?.familyName ?? ""
            let role: UserRole = isTrainerLogin ? .trainer : .client

            // Check if this is a new Apple user
            let isNewTrainer = role == .trainer &&
                !authManager.getAllTrainers().contains(where: { $0.id == userId })
            let isNewClient  = role == .client &&
                !authManager.getAllClients().contains(where: { $0.id == userId })

            if isNewTrainer || isNewClient {
                // New user — show setup flow
                appleUserId    = userId
                appleEmail     = email
                appleFirstName = firstName
                appleLastName  = lastName
                showingAppleSetup = true
            } else {
                // Returning user — log straight in
                authManager.loginOrRegisterWithApple(
                    userId: userId, email: email,
                    firstName: firstName, lastName: lastName, role: role
                )
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func handleLogin() {
        showingError = false
        
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter email and password"
            showingError = true
            return
        }
        
        let success: Bool
        if isTrainerLogin {
            success = authManager.loginTrainer(email: email, password: password)
        } else {
            success = authManager.loginClient(email: email, password: password)
        }
        
        if !success {
            errorMessage = "Invalid email or password"
            showingError = true
        }
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        if authManager.currentUserRole == .trainer {
            // TRAINER → Profile/Dashboard (TrainerProfileMySpaceView)
            TrainerDashboardView_Wrapper()
                .environmentObject(authManager)
        } else {
            // CLIENT → Profile
            if let clientProfile = authManager.currentClientProfile {
                ClientProfileMySpaceView(client: clientProfile.toClientProfile())
                    .environmentObject(authManager)
            } else {
                Text("Error loading profile")
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Trainer Dashboard Wrapper

struct TrainerDashboardView_Wrapper: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if let saved = authManager.currentTrainerProfile {
            let profile = TrainerProfile(
                id: saved.id,
                userId: saved.id,
                businessName: saved.businessName ?? saved.fullName,
                bio: saved.bio.isEmpty ? nil : saved.bio,
                specialties: saved.specialties,
                certifications: saved.certifications.map { $0.rawValue },
                yearsOfExperience: saved.yearsOfExperience,
                serviceTypes: saved.serviceTypes,
                location: TrainerLocation(city: saved.city, state: saved.state),
                hourlyRate: saved.hourlyRate,
                profileImageURL: nil,
                websiteURL: nil,
                instagramHandle: nil,
                isVerified: false,
                rating: 5.0,
                totalReviews: 0
            )
            TrainerProfileMySpaceView(trainer: profile)
                .environmentObject(authManager)
        } else {
            Text("Loading profile...")
                .foregroundColor(.white)
                .onAppear { authManager.loadSession() }
        }
    }
}

// MARK: - Extension to convert SavedClientProfile to ClientProfile
extension SavedClientProfile {
    func toClientProfile() -> ClientProfile {
        print("🔄 Converting SavedClientProfile to ClientProfile")
        print("   Name: \(fullName)")
        print("   Goals count: \(fitnessGoals.count)")
        
        return ClientProfile(
            name: fullName,
            age: age,
            city: city,
            state: state,
            memberSince: dateCreated,
            currentTrainer: nil,
            preferredServiceType: .inPerson,
            fitnessLevel: fitnessLevel,
            goals: fitnessGoals.isEmpty ? [.generalFitness] : Array(fitnessGoals),
            startingWeight: Int(targetWeight ?? 150),
            currentWeight: Int(targetWeight ?? 150),
            targetWeight: Int(targetWeight ?? 150),
            medicalConditions: medicalConditions.isEmpty ? "None" : medicalConditions,
            injuries: injuries.isEmpty ? "None" : injuries,
            allergies: allergies.isEmpty ? "None" : allergies,
            medications: medications.isEmpty ? "None" : medications,
            currentStreak: 0,
            workoutsCompleted: 0,
            workoutsThisWeek: 0,
            progressPhotoCount: 0,
            measurements: ClientProfile.ClientMeasurements(
                chest: 0,
                waist: 0,
                hips: 0,
                arms: 0
            )
        )
    }
}

#Preview {
    LoginView()
}
