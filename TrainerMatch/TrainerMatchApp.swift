import SwiftUI

@main
struct TrainerMatchApp: App {
    init() {
        PushNotificationManager.shared.initialize()
        _ = MemoryWarningObserver.shared
    }
    var body: some Scene {
        WindowGroup {
            AppEntryView()
        }
    }
}

struct AppEntryView: View {
    @ObservedObject private var auth = SupabaseAuthManager.shared
    @AppStorage("tm_hasAcceptedTerms") private var hasAcceptedTerms = false
    @State private var navigateToPending = false

    var body: some View {
        Group {
            if !hasAcceptedTerms {
                FirstLaunchDisclaimerView(hasAcceptedTerms: $hasAcceptedTerms)

            } else if auth.isLoading {
                SplashView()

            } else if auth.isAuthenticated,
                      auth.currentUserRole == .trainer,
                      let trainer = auth.currentTrainer {
                // ✅ Trainer bottom nav
                TrainerMainTabView(trainer: trainer)
                    .environmentObject(auth)
                    .environmentObject(AuthManager.shared)
                    .task {
                        await GymAdManager.shared.fetchActiveAds()
                        SBConnectionStore.shared.loadForTrainer(trainer.id.uuidString)
                    }

            } else if auth.isAuthenticated,
                      auth.currentUserRole == .client,
                      let client = auth.currentClient {
                // ✅ Client bottom nav
                ClientMainTabView(client: client)
                    .environmentObject(auth)
                    .environmentObject(AuthManager.shared)
                    .task {
                        await GymAdManager.shared.fetchActiveAds()
                        PushNotificationManager.shared.loginUser(
                            userId: client.authId?.uuidString ?? client.id.uuidString
                        )
                        SBConnectionStore.shared.loadForClient(client.id.uuidString)
                    }

            } else if auth.isAuthenticated, auth.pendingAppleAuthId != nil {
                SupabaseAppleSetupView(role: auth.pendingAppleRole)
                    .environmentObject(auth)
                    .environmentObject(AuthManager.shared)

            } else if auth.isAuthenticated {
                SplashView()

            } else {
                WelcomeView()
                    .environmentObject(auth)
                    .environmentObject(AuthManager.shared)
                    .tint(.tmGold)
                    .task { await GymAdManager.shared.fetchActiveAds() }
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                TrainerMatchLogo(size: .large)
                    .shadow(color: .tmGold.opacity(0.4), radius: 20)
                Text("Nearby Trainers")
                    .font(.system(size: 40, weight: .heavy)).italic()
                    .foregroundColor(.white)
                ProgressView().tint(.tmGold).scaleEffect(1.2)
            }
        }
    }
}

// MARK: - TrainerRow → TrainerProfile

extension TrainerRow {
    func toLocalTrainerProfile() -> TrainerProfile {
        TrainerProfile(
            id:                id.uuidString,
            userId:            id.uuidString,
            businessName:      businessName ?? fullName,
            bio:               bio.isEmpty ? nil : bio,
            specialties:       specialties.compactMap { TrainerSpecialty(rawValue: $0) },
            certifications:    certifications,
            yearsOfExperience: yearsOfExperience,
            serviceTypes:      serviceTypes.compactMap { ServiceType(rawValue: $0) },
            location:          TrainerLocation(city: city, state: state),
            hourlyRate:        hourlyRate,
            profileImageURL:   profileImageUrl,
            websiteURL:        nil,
            instagramHandle:   nil,
            isVerified:        false,
            rating:            nil,
            totalReviews:      0
        )
    }
}

// MARK: - ClientRow → ClientProfile

extension ClientRow {
    func toClientProfile() -> ClientProfile {
        ClientProfile(
            name:                fullName,
            age:                 0,
            city:                city,
            state:               state,
            memberSince:         createdAt ?? Date(),
            currentTrainer:      nil,
            preferredServiceType: .inPerson,
            fitnessLevel:        fitnessLevel,
            goals:               fitnessGoals.compactMap { FitnessGoal(rawValue: $0) },
            startingWeight:      Int(targetWeight ?? 0),
            currentWeight:       Int(targetWeight ?? 0),
            targetWeight:        Int(targetWeight ?? 0),
            medicalConditions:   medicalConditions.isEmpty ? "None" : medicalConditions,
            injuries:            injuries.isEmpty ? "None" : injuries,
            allergies:           allergies.isEmpty ? "None" : allergies,
            medications:         medications.isEmpty ? "None" : medications,
            currentStreak:       0,
            workoutsCompleted:   0,
            workoutsThisWeek:    0,
            progressPhotoCount:  0,
            measurements:        ClientProfile.ClientMeasurements(
                chest: 0, waist: 0, hips: 0, arms: 0)
        )
    }
}
