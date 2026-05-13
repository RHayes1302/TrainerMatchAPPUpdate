//
//  ClientSignupView.swift
//  TrainerMatch
//
//  Wired to SupabaseAuthManager — all UI unchanged.
//

import SwiftUI
import PhotosUI

// MARK: - Fitness Level Enum
enum FitnessLevel: String, CaseIterable {
    case beginner     = "Beginner"
    case intermediate = "Intermediate"
    case advanced     = "Advanced"
}

struct ClientSignupView: View {
    @StateObject private var auth = SupabaseAuthManager.shared

    @State private var firstName       = ""
    @State private var lastName        = ""
    @State private var email           = ""
    @State private var phoneNumber     = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var city            = ""
    @State private var state           = ""
    @State private var birthDate       = Date()
    @State private var selectedPhoto:  PhotosPickerItem?
    @State private var profileImage:   Image?
    @State private var profileUIImage: UIImage?
    @State private var selectedGoals:  Set<FitnessGoal> = []
    @State private var targetWeight    = ""
    @State private var fitnessLevel:   FitnessLevel = .beginner
    @State private var medicalConditions = ""
    @State private var injuries        = ""
    @State private var allergies       = ""
    @State private var medications     = ""
    @State private var preferredServiceType: ServiceType = .inPerson
    @State private var agreedToTerms   = false
    @State private var currentSection  = 0
    @State private var errorMessage    = ""
    @State private var showingError    = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        TrainerMatchLogo(size: .medium)
                            .shadow(color: .tmGold.opacity(0.3), radius: 15, x: 0, y: 5)
                        Text("Join TrainerMatch")
                            .font(.system(size: 32, weight: .bold)).italic().foregroundColor(.white)
                        Text("Find your perfect trainer match")
                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 40).padding(.bottom, 30)

                    // Form Card
                    VStack(spacing: 24) {
                        // Section Tabs
                        HStack(spacing: 0) {
                            ClientSectionTab(title: "Basic",  number: 1, isActive: currentSection == 0).onTapGesture { currentSection = 0 }
                            ClientSectionTab(title: "Goals",  number: 2, isActive: currentSection == 1).onTapGesture { currentSection = 1 }
                            ClientSectionTab(title: "Health", number: 3, isActive: currentSection == 2).onTapGesture { currentSection = 2 }
                        }

                        clientFormContent

                        // Navigation Buttons
                        HStack(spacing: 12) {
                            if currentSection > 0 {
                                Button(action: { withAnimation { currentSection -= 1 } }) {
                                    Text("BACK").font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25).stroke(Color.tmGold, lineWidth: 2))
                                }
                            }

                            if currentSection < 2 {
                                Button(action: { withAnimation { currentSection += 1 } }) {
                                    Text("NEXT").font(.system(size: 14, weight: .heavy)).foregroundColor(.black)
                                        .frame(maxWidth: .infinity).frame(height: 50)
                                        .background(RoundedRectangle(cornerRadius: 25).fill(Color.tmGold))
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Button(action: submitRegistration) {
                                        Text("CREATE ACCOUNT").font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 50)
                                            .background(RoundedRectangle(cornerRadius: 25)
                                                .fill(isFormValid ? Color.tmGold : Color.gray.opacity(0.5)))
                                    }
                                    .disabled(!isFormValid || auth.isLoading)

                                    if !isFormValid {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Please complete the following:")
                                                .font(.caption).fontWeight(.semibold).foregroundColor(.red.opacity(0.9)).padding(.bottom, 4)
                                            if firstName.isEmpty            { Text("• First Name").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if lastName.isEmpty             { Text("• Last Name").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if email.isEmpty                { Text("• Email Address").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if password.isEmpty             { Text("• Password").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if password != confirmPassword  { Text("• Passwords must match").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if city.isEmpty                 { Text("• City").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if state.isEmpty                { Text("• State").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if selectedGoals.isEmpty        { Text("• Select at least one goal").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                            if !agreedToTerms               { Text("• Agree to Terms of Service").font(.caption2).foregroundColor(.red.opacity(0.8)) }
                                        }
                                        .padding(.top, 12).padding(.horizontal, 4)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
                    .padding(.horizontal, 20).padding(.bottom, 40)
                }
            }

            // Loading overlay
            if auth.isLoading {
                Color.black.opacity(0.6).ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView().tint(.tmGold).scaleEffect(1.4)
                    Text("Creating your account...").foregroundColor(.white).font(.subheadline)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    profileImage   = Image(uiImage: uiImage)
                    profileUIImage = uiImage
                }
            }
        }
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty &&
        !password.isEmpty && password == confirmPassword &&
        !city.isEmpty && !state.isEmpty &&
        !selectedGoals.isEmpty && agreedToTerms
    }

    @ViewBuilder
    private var clientFormContent: some View {
        switch currentSection {
        case 0:
            ClientBasicInfoSection(
                firstName: $firstName, lastName: $lastName,
                email: $email, phoneNumber: $phoneNumber,
                password: $password, confirmPassword: $confirmPassword,
                city: $city, state: $state, birthDate: $birthDate,
                selectedPhoto: $selectedPhoto, profileImage: $profileImage
            )
        case 1:
            ClientGoalsSection(
                selectedGoals: $selectedGoals, targetWeight: $targetWeight,
                fitnessLevel: $fitnessLevel, preferredServiceType: $preferredServiceType
            )
        case 2:
            ClientHealthSection(
                medicalConditions: $medicalConditions, injuries: $injuries,
                allergies: $allergies, medications: $medications,
                agreedToTerms: $agreedToTerms
            )
        default:
            EmptyView()
        }
    }

    // MARK: - Submit → Supabase

    private func submitRegistration() {
        Task {
            do {
                try await auth.signUpClient(
                    email:             email,
                    password:          password,
                    firstName:         firstName,
                    lastName:          lastName,
                    city:              city,
                    state:             state,
                    fitnessGoals:      selectedGoals.map { $0.rawValue },
                    fitnessLevel:      fitnessLevel.rawValue,
                    targetWeight:      Double(targetWeight),
                    medicalConditions: medicalConditions,
                    injuries:          injuries,
                    allergies:         allergies,
                    medications:       medications
                )

                // Upload profile photo if selected
                if let img = profileUIImage,
                   let data = img.jpegData(compressionQuality: 0.7) {
                    try? await auth.uploadProfilePhoto(imageData: data)
                }

                // RootView navigates automatically on auth state change
                await MainActor.run { dismiss() }

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Client Section Tab
struct ClientSectionTab: View {
    let title: String
    let number: Int
    let isActive: Bool
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(isActive ? Color.tmGold : Color.white.opacity(0.2)).frame(width: 30, height: 30)
                Text("\(number)").font(.system(size: 14, weight: .bold))
                    .foregroundColor(isActive ? .black : .white.opacity(0.5))
            }
            Text(title).font(.caption).fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .tmGold : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Client Basic Info Section
struct ClientBasicInfoSection: View {
    @Binding var firstName: String;  @Binding var lastName: String
    @Binding var email: String;      @Binding var phoneNumber: String
    @Binding var password: String;   @Binding var confirmPassword: String
    @Binding var city: String;       @Binding var state: String
    @Binding var birthDate: Date
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImage: Image?

    var body: some View {
        VStack(spacing: 16) {
            Text("Basic Information").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(spacing: 12) {
                Text("Profile Photo").font(.subheadline).fontWeight(.semibold)
                    .foregroundColor(.white).frame(maxWidth: .infinity, alignment: .leading)
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    ZStack {
                        if let profileImage {
                            profileImage.resizable().scaledToFill()
                                .frame(width: 120, height: 120).clipShape(Circle())
                        } else {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 120, height: 120)
                                .overlay(VStack(spacing: 8) {
                                    Image(systemName: "camera.fill").font(.title2).foregroundColor(.tmGold)
                                    Text("Add Photo").font(.caption).foregroundColor(.white)
                                })
                        }
                        Circle().fill(Color.tmGold).frame(width: 36, height: 36)
                            .overlay(Image(systemName: "pencil").font(.caption).foregroundColor(.black))
                            .offset(x: 40, y: 40)
                    }
                }
            }
            .padding(.bottom, 8)

            HStack(spacing: 12) {
                FormField(label: "First Name *", text: $firstName, placeholder: "John", contentType: .givenName)
                FormField(label: "Last Name *",  text: $lastName,  placeholder: "Doe",  contentType: .familyName)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text("Birth Date *").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                DatePicker("", selection: $birthDate, displayedComponents: .date)
                    .datePickerStyle(.compact).colorScheme(.dark).labelsHidden()
                    .padding().background(Color.white.opacity(0.1)).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
            }
            FormField(label: "Email Address *", text: $email, placeholder: "john@example.com",
                      keyboardType: .emailAddress, autocapitalization: .never, contentType: .emailAddress)
            FormField(label: "Phone Number *", text: $phoneNumber, placeholder: "(555) 123-4567",
                      keyboardType: .phonePad, contentType: .telephoneNumber)
            FormField(label: "Password *", text: $password, placeholder: "Min. 8 characters",
                      isSecure: true, contentType: .newPassword)
            FormField(label: "Confirm Password *", text: $confirmPassword, placeholder: "Re-enter password",
                      isSecure: true, contentType: .newPassword)
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            Text("Location").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                FormField(label: "City *",  text: $city,  placeholder: "Las Vegas", contentType: .addressCity)
                FormField(label: "State *", text: $state, placeholder: "NV",        contentType: .addressState)
            }
        }
    }
}

// MARK: - Client Goals Section
struct ClientGoalsSection: View {
    @Binding var selectedGoals:          Set<FitnessGoal>
    @Binding var targetWeight:           String
    @Binding var fitnessLevel:           FitnessLevel
    @Binding var preferredServiceType:   ServiceType

    private let weightGoals:      [FitnessGoal] = [.weightLoss, .toneUp, .muscleGain, .bodyRecomposition]
    private let healthGoals:      [FitnessGoal] = [.generalFitness, .improveHealth, .heartHealth, .betterSleep, .increaseEnergy, .stressRelief]
    private let performanceGoals: [FitnessGoal] = [.athleticPerformance, .increaseStrength, .buildEndurance, .improveSpeed]
    private let flexibilityGoals: [FitnessGoal] = [.flexibility, .rehabilitation, .preventInjury, .posture]
    private let lifestyleGoals:   [FitnessGoal] = [.wedding, .postPregnancy, .seniorFitness, .sportSpecific]
    private let supportGoals:     [FitnessGoal] = [.nutrition, .accountability, .learnProperForm, .buildConfidence]

    var body: some View {
        VStack(spacing: 16) {
            Text("Fitness Goals").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) {
                Text("What are your goals? *").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text("Select all that apply").font(.caption).foregroundColor(.white.opacity(0.6))
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        GoalCategorySection(title: "Weight & Body Composition", icon: "scalemass.fill",    goals: weightGoals,      selectedGoals: $selectedGoals)
                        GoalCategorySection(title: "Health & Wellness",         icon: "heart.fill",        goals: healthGoals,      selectedGoals: $selectedGoals)
                        GoalCategorySection(title: "Athletic Performance",       icon: "figure.run",        goals: performanceGoals, selectedGoals: $selectedGoals)
                        GoalCategorySection(title: "Flexibility & Recovery",     icon: "figure.yoga",       goals: flexibilityGoals, selectedGoals: $selectedGoals)
                        GoalCategorySection(title: "Lifestyle & Special Events", icon: "star.fill",         goals: lifestyleGoals,   selectedGoals: $selectedGoals)
                        GoalCategorySection(title: "Support & Guidance",         icon: "person.2.fill",     goals: supportGoals,     selectedGoals: $selectedGoals)
                    }
                }
                .frame(maxHeight: 400)
            }
            FormField(label: "Target Weight (Optional)", text: $targetWeight, placeholder: "150 lbs")
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 8) {
                Text("Fitness Level").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                ForEach(FitnessLevel.allCases, id: \.self) { level in
                    FitnessLevelButton(level: level, isSelected: fitnessLevel == level, action: { fitnessLevel = level })
                }
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferred Training Type").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                ForEach(ServiceType.allCases, id: \.self) { st in
                    ServiceTypeButton(serviceType: st, isSelected: preferredServiceType == st, action: { preferredServiceType = st })
                }
            }
        }
    }
}

struct FitnessLevelButton: View {
    let level: FitnessLevel; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.tmGold : .white.opacity(0.5))
                Text(level.rawValue).font(.body).foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 2))
        }
    }
}

struct ServiceTypeButton: View {
    let serviceType: ServiceType; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color.tmGold : .white.opacity(0.5))
                Text(serviceType.rawValue).font(.body).foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 2))
        }
    }
}

// MARK: - Client Health Section
struct ClientHealthSection: View {
    @Binding var medicalConditions: String
    @Binding var injuries:          String
    @Binding var allergies:         String
    @Binding var medications:       String
    @Binding var agreedToTerms:     Bool

    var body: some View {
        VStack(spacing: 16) {
            Text("Health & Medical Information").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("This information helps trainers create safe, personalized programs")
                .font(.caption).foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity, alignment: .leading)
            HealthTextArea(label: "Medical Conditions",          text: $medicalConditions, placeholder: "List any medical conditions")
            HealthTextArea(label: "Injuries or Limitations",     text: $injuries,          placeholder: "List any injuries or physical limitations")
            HealthTextArea(label: "Allergies",                   text: $allergies,         placeholder: "List any allergies")
            HealthTextArea(label: "Current Medications",         text: $medications,       placeholder: "List any current medications")
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            HStack(alignment: .top, spacing: 8) {
                Button(action: { agreedToTerms.toggle() }) {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? Color.tmGold : .white.opacity(0.5)).font(.title3)
                }
                Text("I agree to the TrainerMatch Terms of Service and Privacy Policy. I understand trainers will have access to my health information.")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct HealthTextArea: View {
    let label: String; @Binding var text: String; let placeholder: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text).frame(height: 80).padding(8)
                    .background(Color.white.opacity(0.1)).cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .foregroundColor(.white)
                if text.isEmpty {
                    Text(placeholder).font(.body).foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 12).padding(.vertical, 16).allowsHitTesting(false)
                }
            }
        }
    }
}

// MARK: - Goal Category Section
struct GoalCategorySection: View {
    let title: String; let icon: String
    let goals: [FitnessGoal]
    @Binding var selectedGoals: Set<FitnessGoal>
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.tmGold).font(.caption)
                Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.tmGold)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(goals, id: \.self) { goal in
                    GoalSelectionButton(goal: goal, isSelected: selectedGoals.contains(goal),
                        action: {
                            if selectedGoals.contains(goal) { selectedGoals.remove(goal) }
                            else { selectedGoals.insert(goal) }
                        })
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct GoalSelectionButton: View {
    let goal: FitnessGoal; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: goal.icon).font(.caption2)
                    .foregroundColor(isSelected ? .black : .tmGold.opacity(0.7))
                Text(goal.rawValue).font(.caption).fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .black : .white).lineLimit(2).minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.tmGold : Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 1.5)))
        }
    }
}

#Preview { ClientSignupView() }
