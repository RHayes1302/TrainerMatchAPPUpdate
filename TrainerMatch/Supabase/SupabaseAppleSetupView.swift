//
//  SupabaseAppleSetupView.swift
//  TrainerMatch
//

import SwiftUI

struct SupabaseAppleSetupView: View {
    let role: UserRole
    @EnvironmentObject var auth: SupabaseAuthManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
            if role == .trainer {
                SupabaseTrainerSetupView(onComplete: { dismiss() })
                    .environmentObject(auth)
            } else {
                SupabaseClientSetupView(onComplete: { dismiss() })
                    .environmentObject(auth)
            }
        }
        .interactiveDismissDisabled()
    }
}

// MARK: - Trainer Setup

struct SupabaseTrainerSetupView: View {
    let onComplete: () -> Void
    @EnvironmentObject var auth: SupabaseAuthManager

    @State private var step           = 0
    @State private var businessName   = ""
    @State private var city           = ""
    @State private var state          = ""
    @State private var gender         = ""
    @State private var yearsStr       = ""
    @State private var hourlyRateStr  = ""
    @State private var bio            = ""
    @State private var selectedSpecialties: Set<TrainerSpecialty> = []
    @State private var selectedServices:    Set<ServiceType>      = [.inPerson]
    @State private var showingSpecialties   = false
    @State private var isLoading      = false
    @State private var errorMessage   = ""

    private var canProceed: Bool {
        switch step {
        case 0: return !city.isEmpty && !state.isEmpty
        case 1: return !selectedSpecialties.isEmpty
        default: return true
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar(step: step, total: 3)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                        if step == 0 { step0 }
                        else if step == 1 { step1 }
                        else { step2 }
                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.caption).foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        navButtons.padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingSpecialties) {
            SpecialtyPickerSheet(selected: $selectedSpecialties)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            TrainerMatchLogo(size: .medium)
            Text("Complete Your Profile")
                .font(.system(size: 24, weight: .black)).foregroundColor(.white)
            Text("Step \(step + 1) of 3")
                .font(.subheadline).foregroundColor(.tmGold)
        }
        .padding(.top, 20)
    }

    private var step0: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 1 — YOUR LOCATION")
            field("BUSINESS / GYM NAME (OPTIONAL)",
                  placeholder: "e.g. Elite Fitness", text: $businessName)
            field("CITY", placeholder: "e.g. Las Vegas", text: $city)
            field("STATE", placeholder: "e.g. NV", text: $state)
            genderPicker
        }
    }

    private var step1: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 2 — YOUR EXPERTISE")
            Button(action: { showingSpecialties = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SPECIALTIES").font(.system(size: 10, weight: .bold))
                            .tracking(1.2).foregroundColor(.tmGold)
                        Text(selectedSpecialties.isEmpty
                             ? "Tap to select specialties"
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
        }
    }

    private var step2: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 3 — RATES & BIO")
            VStack(alignment: .leading, spacing: 6) {
                Text("HOURLY RATE (USD)").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                HStack {
                    Text("$").font(.system(size: 20, weight: .bold)).foregroundColor(.tmGold)
                    TextField("75", text: $hourlyRateStr).keyboardType(.decimalPad)
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("/hr").font(.caption).foregroundColor(.white.opacity(0.4))
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("BIO (OPTIONAL)").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                TextField("Tell clients about yourself...", text: $bio, axis: .vertical)
                    .foregroundColor(.white).lineLimit(3...6).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("GENDER (OPTIONAL)").font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            HStack(spacing: 8) {
                ForEach(["Male", "Female", "Non-binary", "Prefer not to say"], id: \.self) { g in
                    Button(action: { gender = g }) {
                        Text(g).font(.system(size: 11, weight: .bold))
                            .foregroundColor(gender == g ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(Capsule().fill(gender == g
                                ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                }
            }
        }
    }

    private var navButtons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button(action: { step -= 1 }) {
                    Text("BACK")
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.tmGold)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .stroke(Color.tmGold, lineWidth: 1.5))
                }
            }
            Button(action: {
                if step < 2 { if canProceed { step += 1 } }
                else { saveTrainer() }
            }) {
                if isLoading {
                    ProgressView().tint(.black)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.tmGold))
                } else {
                    Text(step < 2 ? "NEXT" : "ENTER TRAINERMATCH")
                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                        .foregroundColor(canProceed ? .black : .white.opacity(0.3))
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(RoundedRectangle(cornerRadius: 25)
                            .fill(canProceed ? Color.tmGold : Color.white.opacity(0.08)))
                        .shadow(color: canProceed ? Color.tmGold.opacity(0.4) : .clear, radius: 10)
                }
            }
            .disabled(!canProceed || isLoading)
        }
    }

    private func saveTrainer() {
        isLoading = true
        errorMessage = ""
        print("🔍 pendingAppleAuthId: \(auth.pendingAppleAuthId?.uuidString ?? "NIL")")
        print("🔍 pendingAppleEmail: \(auth.pendingAppleEmail)")
        print("🔍 city: \(city), state: \(state)")
        Task {
            do {
                try await auth.completeAppleTrainerSetup(
                    businessName: businessName.isEmpty ? nil : businessName,
                    city: city, state: state, gender: gender,
                    yearsOfExperience: Int(yearsStr) ?? 0,
                    hourlyRate: Double(hourlyRateStr),
                    bio: bio,
                    specialties: selectedSpecialties.map { $0.rawValue },
                    serviceTypes: selectedServices.isEmpty
                        ? ["In-Person"] : selectedServices.map { $0.rawValue }
                )
                print("✅ Trainer setup complete")
                await MainActor.run { onComplete() } // ✅ FIXED: calls parent dismiss
            } catch {
                print("❌ Setup error: \(error)")
                print("❌ Localized: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
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

struct SupabaseClientSetupView: View {
    let onComplete: () -> Void
    @EnvironmentObject var auth: SupabaseAuthManager

    @State private var step           = 0
    @State private var displayName    = ""
    @State private var city           = ""
    @State private var state          = ""
    @State private var fitnessLevel   = "Beginner"
    @State private var selectedGoals: Set<FitnessGoal> = []
    @State private var isLoading      = false
    @State private var errorMessage   = ""

    private var canProceed: Bool {
        step == 0 ? (!city.isEmpty) : (!selectedGoals.isEmpty)
    }

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
                            Text("Step \(step + 1) of 2")
                                .font(.subheadline).foregroundColor(.tmGold)
                        }
                        .padding(.top, 20)

                        if step == 0 { step0 } else { step1 }

                        if !errorMessage.isEmpty {
                            Text(errorMessage).font(.caption).foregroundColor(.red)
                        }

                        HStack(spacing: 12) {
                            if step > 0 {
                                Button(action: { step -= 1 }) {
                                    Text("BACK").font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.tmGold)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .stroke(Color.tmGold, lineWidth: 1.5))
                                }
                            }
                            Button(action: {
                                if step < 1 { if canProceed { step += 1 } }
                                else { saveClient() }
                            }) {
                                if isLoading {
                                    ProgressView().tint(.black)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.tmGold))
                                } else {
                                    Text(step < 1 ? "NEXT" : "ENTER TRAINERMATCH")
                                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                                        .foregroundColor(canProceed ? .black : .white.opacity(0.3))
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25)
                                            .fill(canProceed ? Color.tmGold : Color.white.opacity(0.08)))
                                }
                            }
                            .disabled(!canProceed || isLoading)
                        }
                    }
                    .padding(.horizontal, 20).padding(.bottom, 80)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var step0: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 1 — YOUR LOCATION")
            field("YOUR NAME", placeholder: auth.pendingAppleFirstName.isEmpty
                  ? "Your name" : auth.pendingAppleFirstName, text: $displayName)
            field("CITY", placeholder: "e.g. Las Vegas", text: $city)
            field("STATE", placeholder: "e.g. NV", text: $state)
        }
    }

    private var step1: some View {
        VStack(spacing: 16) {
            sectionLabel("STEP 2 — FITNESS GOALS")
            VStack(alignment: .leading, spacing: 10) {
                Text("FITNESS LEVEL").font(.system(size: 10, weight: .bold))
                    .tracking(1.2).foregroundColor(.tmGold)
                HStack(spacing: 8) {
                    ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                        Button(action: { fitnessLevel = level }) {
                            Text(level).font(.system(size: 12, weight: .bold))
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
        isLoading = true
        errorMessage = ""
        print("🔍 client pendingAppleAuthId: \(auth.pendingAppleAuthId?.uuidString ?? "NIL")")
        print("🔍 client pendingAppleEmail: \(auth.pendingAppleEmail)")
        Task {
            do {
                try await auth.completeAppleClientSetup(
                    displayName: displayName,
                    city: city, state: state,
                    fitnessLevel: fitnessLevel,
                    fitnessGoals: selectedGoals.map { $0.rawValue }
                )
                print("✅ Client setup complete")
                await MainActor.run { onComplete() } // ✅ FIXED: calls parent dismiss
            } catch {
                print("❌ Client setup error: \(error)")
                print("❌ Localized: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
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

// MARK: - Shared helpers

private func progressBar(step: Int, total: Int) -> some View {
    HStack(spacing: 6) {
        ForEach(0..<total, id: \.self) { i in
            Capsule().fill(i <= step ? Color.tmGold : Color.white.opacity(0.15))
                .frame(height: 4)
        }
    }
    .padding(.horizontal, 20).padding(.vertical, 14)
}

private func sectionLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 10, weight: .black)).tracking(1.5)
        .foregroundColor(.tmGold).frame(maxWidth: .infinity, alignment: .leading)
}
