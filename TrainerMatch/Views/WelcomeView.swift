//
//  WelcomeView.swift
//  TrainerMatch
//

import SwiftUI

struct WelcomeView: View {
    @State private var selectedDestination: NavigationDestination? = nil
    @State private var showingMenuSheet     = false
    @State private var showingLogin         = false
    @State private var showingSignupChoice  = false
    @State private var showingGymSignup     = false
    @ObservedObject private var auth = SupabaseAuthManager.shared

    enum NavigationDestination: Identifiable {
        case myHealth
        case trainerDashboard
        case aboutUs
        case successStories
        case healthyHacks
        case faqs
        case contact
        case trainerSearch
        case trainerSignup
        case nearbyTrainers
        case clientSignup
        case gymsNearYou

        var id: String {
            switch self {
            case .myHealth:         return "myHealth"
            case .trainerDashboard: return "trainerDashboard"
            case .aboutUs:          return "aboutUs"
            case .successStories:   return "successStories"
            case .healthyHacks:     return "healthyHacks"
            case .faqs:             return "faqs"
            case .contact:          return "contact"
            case .trainerSearch:    return "trainerSearch"
            case .trainerSignup:    return "trainerSignup"
            case .nearbyTrainers:   return "nearbyTrainers"
            case .clientSignup:     return "clientSignup"
            case .gymsNearYou:      return "gymsNearYou"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 20) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)
                        VStack(spacing: 6) {
                            Text("TrainerMatch")
                                .font(.system(size: 50, weight: .heavy)).italic()
                                .foregroundColor(.white)
                                .shadow(color: .tmGold.opacity(0.3), radius: 10, x: 0, y: 4)
                            Text("Local Trainers, Real Results")
                                .font(.system(size: 20, weight: .semibold)).foregroundColor(.tmGold)
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding(.top, 80)

                    Spacer().frame(height: 40)

                    Text("Match with top fitness professionals based on your wellness needs, offering diverse specialties and services, all just one click away.")
                        .font(.system(size: 16)).foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 35)

                    Spacer()

                    VStack(spacing: 14) {
                        Button(action: { selectedDestination = .nearbyTrainers }) {
                            HStack {
                                Image(systemName: "person.2.circle.fill").font(.title3)
                                Text("TRAINERS NEARBY")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            }
                            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tmGoldGradient()))
                            .shadow(color: .tmGold.opacity(0.5), radius: 15, x: 0, y: 8)
                        }

                        Button(action: { selectedDestination = .trainerSearch }) {
                            HStack {
                                Image(systemName: "magnifyingglass").font(.title3)
                                Text("SEARCH ALL TRAINERS")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            }
                            .foregroundColor(.tmGold).frame(maxWidth: .infinity).frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28).fill(Color.black)
                                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.tmGold, lineWidth: 2.5)))
                            .shadow(color: .tmGold.opacity(0.3), radius: 12, x: 0, y: 6)
                        }

                        Button(action: { showingGymSignup = true }) {
                            HStack {
                                Image(systemName: "building.2.crop.circle.fill").font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("ADVERTISE YOUR GYM")
                                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                    Text("From $19.99/mo").font(.system(size: 10, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white.opacity(0.07))
                                .overlay(RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.tmGold.opacity(0.5), lineWidth: 1.5)))
                        }

                        Button(action: { showingSignupChoice = true }) {
                            VStack(spacing: 4) {
                                Text("JOIN THE MOVEMENT")
                                    .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                Text("Start Your Journey").font(.caption).fontWeight(.semibold)
                            }
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 28).fill(Color.black)
                                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white, lineWidth: 2.5)))
                            .shadow(color: .white.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                    }
                    .padding(.horizontal, 30).padding(.bottom, 60)
                }

                NavigationLink(
                    destination: destinationView(for: selectedDestination),
                    tag: selectedDestination ?? .myHealth,
                    selection: $selectedDestination
                ) { EmptyView() }.hidden()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingMenuSheet = true }) {
                        Image(systemName: "line.3.horizontal").font(.title3).foregroundColor(.tmGold)
                            .padding(8).background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingLogin = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill").font(.title3)
                            Text("LOGIN").font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.tmGold).padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            .toolbarBackground(Color.black.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingMenuSheet) {
                MenuSheetView(selectedDestination: $selectedDestination,
                              showingMenuSheet: $showingMenuSheet)
            }
            .sheet(isPresented: $showingSignupChoice) {
                SignupChoiceView(selectedDestination: $selectedDestination,
                                 showingSignupChoice: $showingSignupChoice)
            }
            .sheet(isPresented: $showingGymSignup) {
                NavigationView { GymAdvertiserSignupView() }
                    .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        // ✅ FIXED: fullScreenCover on the NavigationView itself, not inside it
        .fullScreenCover(isPresented: $showingLogin) {
            SupabaseLoginView()
                .environmentObject(SupabaseAuthManager.shared)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: NavigationDestination?) -> some View {
        switch destination {
        case .myHealth:         ContentView()
        case .trainerDashboard: TrainerDashboardView()
        case .aboutUs:          AboutUsView()
        case .successStories:   SuccessStoriesView()
        case .healthyHacks:     HealthyHacksView()
        case .faqs:             FAQsView()
        case .contact:          ContactView()
        case .trainerSearch:    TrainerSearchView()
        case .trainerSignup:    TrainerSignupView()
        case .nearbyTrainers:   NearbyTrainersView()
        case .clientSignup:     ClientSignupView()
        case .gymsNearYou:      GymsNearYouView()
        case .none:             EmptyView()
        }
    }
}

// MARK: - Menu Sheet

struct MenuSheetView: View {
    @Binding var selectedDestination: WelcomeView.NavigationDestination?
    @Binding var showingMenuSheet: Bool
    @ObservedObject private var auth = SupabaseAuthManager.shared
    @State private var showingLogoutAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)
                        Text("TrainerMatch")
                            .font(.system(size: 32, weight: .bold)).italic().foregroundColor(.white)

                        if auth.isAuthenticated {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(auth.currentTrainer?.fullName ?? auth.currentClient?.fullName ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("·")
                                    .foregroundColor(.white.opacity(0.3))
                                Text(auth.currentUserRole == .trainer ? "Trainer" : "Client")
                                    .font(.caption)
                                    .foregroundColor(.tmGold)
                            }
                            .padding(.horizontal, 20).padding(.vertical, 8)
                            .background(Capsule().fill(Color.white.opacity(0.05)))
                        }
                    }
                    .frame(maxWidth: .infinity).padding(.top, 40).padding(.bottom, 40)

                    menuSection("QUICK ACCESS") {
                        MenuButton(icon: "building.2.fill", title: "Gyms Near You") {
                            navigate(to: .gymsNearYou)
                        }
                        MenuButton(icon: "dumbbell.fill", title: "Become a Trainer") {
                            navigate(to: .trainerSignup)
                        }
                    }
                    .padding(.bottom, 32)

                    menuSection("INFORMATION") {
                        MenuButton(icon: "info.circle",        title: "About Us")        { navigate(to: .aboutUs) }
                        MenuButton(icon: "star.fill",           title: "Success Stories") { navigate(to: .successStories) }
                        MenuButton(icon: "heart.text.square",   title: "Healthy Hacks")   { navigate(to: .healthyHacks) }
                        MenuButton(icon: "questionmark.circle", title: "FAQs")            { navigate(to: .faqs) }
                        MenuButton(icon: "envelope",            title: "Contact")         { navigate(to: .contact) }
                    }
                    .padding(.bottom, 32)

                    if auth.isAuthenticated {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("ACCOUNT")
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color.tmGold).padding(.bottom, 12)

                            NavigationLink(destination:
                                SettingsView().environmentObject(auth)
                            ) {
                                HStack(spacing: 16) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title3).foregroundColor(.tmGold).frame(width: 30)
                                    Text("Settings").font(.body).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption).foregroundColor(.white.opacity(0.5))
                                }
                                .padding(.vertical, 16).padding(.horizontal, 20)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05)))
                            }
                            .padding(.horizontal, 20).padding(.bottom, 8)

                            Button(action: { showingLogoutAlert = true }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.title3).foregroundColor(.red).frame(width: 30)
                                    Text("Log Out")
                                        .font(.body).fontWeight(.semibold).foregroundColor(.red)
                                    Spacer()
                                }
                                .padding(.vertical, 16).padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.red.opacity(0.08))
                                        .overlay(RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 1))
                                )
                            }
                            .padding(.horizontal, 20).padding(.bottom, 8)
                        }
                        .padding(.bottom, 32)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showingMenuSheet = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.tmGold).padding(20)
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                showingMenuSheet = false
                Task { await auth.signOut() }
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    private func navigate(to destination: WelcomeView.NavigationDestination) {
        showingMenuSheet = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            selectedDestination = destination
        }
    }

    @ViewBuilder
    private func menuSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Color.tmGold).padding(.bottom, 12)
            content()
        }
    }
}

// MARK: - Menu Button

struct MenuButton: View {
    let icon:   String
    let title:  String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).font(.title3).foregroundColor(.tmGold).frame(width: 30)
                Text(title).font(.body).foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 16).padding(.horizontal, 20)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
        }
        .padding(.horizontal, 20).padding(.bottom, 8)
    }
}

// MARK: - Signup Choice View

struct SignupChoiceView: View {
    @Binding var selectedDestination: WelcomeView.NavigationDestination?
    @Binding var showingSignupChoice: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    TrainerMatchLogo(size: .large)
                        .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)
                        .padding(.top, 60)
                    Text("Join TrainerMatch")
                        .font(.system(size: 36, weight: .bold)).italic().foregroundColor(.white)
                    Text("Choose how you want to get started")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding(.bottom, 40)

                VStack(spacing: 16) {
                    choiceCard(
                        icon: "figure.walk",
                        title: "I'm a Client",
                        subtitle: "Find trainers, track workouts, and reach your fitness goals"
                    ) {
                        showingSignupChoice = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedDestination = .clientSignup
                        }
                    }

                    choiceCard(
                        icon: "dumbbell.fill",
                        title: "I'm a Trainer",
                        subtitle: "Grow your business, manage clients, and build your brand"
                    ) {
                        showingSignupChoice = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            selectedDestination = .trainerSignup
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showingSignupChoice = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(.tmGold).padding(20)
            }
        }
    }

    private func choiceCard(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: icon).font(.system(size: 46)).foregroundColor(.tmGold)
                Text(title).font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(subtitle).font(.subheadline).foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 26)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.tmGold, lineWidth: 2)))
        }
    }
}

#Preview { WelcomeView() }
