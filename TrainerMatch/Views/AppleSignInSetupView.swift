//
//  AppleSignInSetupView.swift
//  TrainerMatch
//
//  Post-Apple-Sign-In setup flow.
//  Shown when a new Apple user logs in for the first time.
//  Collects role-specific info before entering the app.
//

import SwiftUI

// MARK: - Setup Router

struct AppleSignInSetupView: View {
    let userId:    String
    let email:     String
    let firstName: String
    let lastName:  String
    let role:      UserRole
    @ObservedObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if role == .trainer {
            AppleTrainerSetupView(
                userId: userId, email: email,
                firstName: firstName, lastName: lastName
            )
        } else {
            AppleClientSetupView(
                userId: userId, email: email,
                firstName: firstName, lastName: lastName
            )
        }
    }
}

// MARK: - Trainer Setup

struct AppleTrainerSetupView: View {
    let userId:    String
    let email:     String
    let firstName: String
    let lastName:  String

    @ObservedObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var businessName    = ""
    @State private var city            = ""
    @State private var state           = ""
    @State private var bio             = ""
    @State private var hourlyRateStr   = ""
    @State private var yearsStr        = ""
    @State private var selectedSpecialties: Set<TrainerSpecialty> = []
    @State private var selectedServices:    Set<ServiceType>      = []
    @State private var showingSpecialties   = false
    @State private var step = 0

    private var canFinish: Bool {
        !city.isEmpty && !state.isEmpty && !selectedSpecialties.isEmpty
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Progress
                progressBar(step: step, total: 3)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            TrainerMatchLogo(size: .medium)
                            Text("Complete Your Profile")
                                .font(.system(size: 24, weight: .black)).foregroundColor(.white)
                            Text("Just a few more details so clients can find you.")
                                .font(.subheadline).foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)

                        if step == 0 { trainerStep0 }
                        else if step == 1 { trainerStep1 }
                        else { trainerStep2 }

                        // Navigation buttons
                        HStack(spacing: 12) {
                            if step > 0 {
                                Button(action: { step -= 1 }) {
                                    Text("BACK")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.tmGold)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.tmGold, lineWidth: 1.5))
                                }
                            }
                            Button(action: {
                                if step < 2 { step += 1 }
                                else { saveTrainer() }
                            }) {
                                Text(step < 2 ? "NEXT" : "ENTER TRAINERMATCH")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(RoundedRectangle(cornerRadius: 25)
                                        .fill(canFinish || step < 2 ? Color.tmGold : Color.gray.opacity(0.4)))
                                    .shadow(color: .tmGold.opacity(0.4), radius: 10)
                            }
                            .disabled(step == 2 && !canFinish)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSpecialties) {
            SpecialtyPickerSheet(selected: $selectedSpecialties)
        }
    }

    private var trainerStep0: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 1 OF 3 — IDENTITY")
            field("BUSINESS / GYM NAME (OPTIONAL)",
                  placeholder: "e.g. Elite Fitness by \(firstName)", text: $businessName)
            field("YOUR CITY", placeholder: "e.g. Las Vegas", text: $city)
            field("STATE", placeholder: "e.g. NV", text: $state)
        }
    }

    private var trainerStep1: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 2 OF 3 — YOUR EXPERTISE")
            Button(action: { showingSpecialties = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPECIALTIES").font(.system(size: 10, weight: .bold))
                            .tracking(1.2).foregroundColor(.tmGold)
                        Text(selectedSpecialties.isEmpty
                             ? "Tap to select your specialties"
                             : selectedSpecialties.map { $0.rawValue }.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(selectedSpecialties.isEmpty
                                             ? .white.opacity(0.3) : .white)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.tmGold.opacity(0.5))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tmGold.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text("SERVICE TYPE").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                HStack(spacing: 8) {
                    ForEach([ServiceType.inPerson, .online, .both], id: \.self) { type in
                        Button(action: {
                            if selectedServices.contains(type) { selectedServices.remove(type) }
                            else { selectedServices.insert(type) }
                        }) {
                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedServices.contains(type) ? .black : .white.opacity(0.5))
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .background(Capsule().fill(selectedServices.contains(type)
                                    ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }

            field("YEARS OF EXPERIENCE", placeholder: "e.g. 5", text: $yearsStr)
                .keyboardType(.numberPad)
        }
    }

    private var trainerStep2: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 3 OF 3 — RATES & BIO")
            VStack(alignment: .leading, spacing: 8) {
                Text("HOURLY RATE (USD)").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                HStack {
                    Text("$").font(.system(size: 20, weight: .bold)).foregroundColor(.tmGold)
                    TextField("0.00", text: $hourlyRateStr).keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("/hr").font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("BIO (OPTIONAL)").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                TextField("Tell clients about yourself...", text: $bio, axis: .vertical)
                    .foregroundColor(.white).lineLimit(3...6).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func saveTrainer() {
        let trainer = SavedTrainerProfile(
            id:                userId,
            businessName:      businessName.isEmpty ? nil : businessName,
            firstName:         firstName.isEmpty ? "Trainer" : firstName,
            lastName:          lastName,
            email:             email,
            password:          "apple_sso_\(userId)",
            city:              city,
            state:             state,
            gender:            "",
            yearsOfExperience: Int(yearsStr) ?? 0,
            hourlyRate:        Double(hourlyRateStr),
            monthlyRate:       nil,
            bio:               bio,
            certifications:    [],
            schools:           [],
            specialties:       Array(selectedSpecialties),
            serviceTypes:      selectedServices.isEmpty ? [.inPerson] : Array(selectedServices),
            dateCreated:       Date()
        )
        authManager.saveTrainerPublic(trainer)
        authManager.isAuthenticated    = true
        authManager.currentUserRole    = .trainer
        authManager.currentUserId      = userId
        authManager.currentUserEmail   = email
        authManager.currentTrainerProfile = trainer
        authManager.saveSession()
        dismiss()
    }

    private func field(_ label: String, placeholder: String,
                       text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            TextField(placeholder, text: text)
                .foregroundColor(.white).padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Client Setup

struct AppleClientSetupView: View {
    let userId:    String
    let email:     String
    let firstName: String
    let lastName:  String

    @ObservedObject private var authManager = AuthManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var displayName    = ""
    @State private var city           = ""
    @State private var state          = ""
    @State private var fitnessLevel   = "Beginner"
    @State private var selectedGoals: Set<FitnessGoal> = []
    @State private var step = 0

    private var canFinish: Bool { !city.isEmpty && !selectedGoals.isEmpty }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar(step: step, total: 2)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        VStack(spacing: 8) {
                            TrainerMatchLogo(size: .medium)
                            Text("Complete Your Profile")
                                .font(.system(size: 24, weight: .black)).foregroundColor(.white)
                            Text("Help us find the right trainer for you.")
                                .font(.subheadline).foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.top, 20)

                        if step == 0 { clientStep0 }
                        else { clientStep1 }

                        HStack(spacing: 12) {
                            if step > 0 {
                                Button(action: { step -= 1 }) {
                                    Text("BACK")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.tmGold)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.tmGold, lineWidth: 1.5))
                                }
                            }
                            Button(action: {
                                if step < 1 { step += 1 }
                                else { saveClient() }
                            }) {
                                Text(step < 1 ? "NEXT" : "ENTER TRAINERMATCH")
                                    .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(RoundedRectangle(cornerRadius: 25)
                                        .fill(canFinish || step < 1
                                              ? Color.tmGold : Color.gray.opacity(0.4)))
                                    .shadow(color: .tmGold.opacity(0.4), radius: 10)
                            }
                            .disabled(step == 1 && !canFinish)
                        }
                        .padding(.horizontal, 20).padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var clientStep0: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 1 OF 2 — LOCATION")
            field("YOUR NAME", placeholder: firstName.isEmpty ? "Your name" : firstName,
                  text: $displayName)
            field("CITY", placeholder: "e.g. Las Vegas", text: $city)
            field("STATE", placeholder: "e.g. NV", text: $state)
        }
    }

    private var clientStep1: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 2 OF 2 — FITNESS GOALS")
            VStack(alignment: .leading, spacing: 10) {
                Text("FITNESS LEVEL").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                HStack(spacing: 8) {
                    ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                        Button(action: { fitnessLevel = level }) {
                            Text(level)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(fitnessLevel == level ? .black : .white.opacity(0.5))
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(fitnessLevel == level
                                          ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("YOUR GOALS (SELECT ALL THAT APPLY)")
                    .font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                FlowLayout(spacing: 8) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        Button(action: {
                            if selectedGoals.contains(goal) { selectedGoals.remove(goal) }
                            else { selectedGoals.insert(goal) }
                        }) {
                            HStack(spacing: 4) {
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                                Text(goal.rawValue).font(.system(size: 12))
                            }
                            .foregroundColor(selectedGoals.contains(goal) ? .black : .white.opacity(0.6))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(selectedGoals.contains(goal)
                                ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }
        }
    }

    private func saveClient() {
        let name = displayName.isEmpty ? "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces) : displayName
        let parts = name.split(separator: " ")
        let fName = parts.first.map(String.init) ?? firstName
        let lName = parts.dropFirst().joined(separator: " ")

        let client = SavedClientProfile(
            id:                userId,
            firstName:         fName.isEmpty ? "Client" : fName,
            lastName:          lName,
            email:             email,
            password:          "apple_sso_\(userId)",
            city:              city,
            state:             state,
            birthDate:         Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
            fitnessGoals:      selectedGoals.isEmpty ? [.generalFitness] : Array(selectedGoals),
            fitnessLevel:      fitnessLevel,
            targetWeight:      nil,
            medicalConditions: "",
            injuries:          "",
            allergies:         "",
            medications:       "",
            dateCreated:       Date()
        )
        authManager.saveClientPublic(client)
        authManager.isAuthenticated   = true
        authManager.currentUserRole   = .client
        authManager.currentUserId     = userId
        authManager.currentUserEmail  = email
        authManager.currentClientProfile = client
        authManager.saveSession()
        dismiss()
    }

    private func field(_ label: String, placeholder: String,
                       text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            TextField(placeholder, text: text)
                .foregroundColor(.white).padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
        }
    }
}

// MARK: - Shared Helpers

private func progressBar(step: Int, total: Int) -> some View {
    HStack(spacing: 6) {
        ForEach(0..<total, id: \.self) { i in
            Capsule()
                .fill(i <= step ? Color.tmGold : Color.white.opacity(0.15))
                .frame(height: 4)
        }
    }
    .padding(.horizontal, 20).padding(.vertical, 14)
}

private func sectionLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 10, weight: .black)).tracking(1.5)
        .foregroundColor(.tmGold).frame(maxWidth: .infinity, alignment: .leading)
}
