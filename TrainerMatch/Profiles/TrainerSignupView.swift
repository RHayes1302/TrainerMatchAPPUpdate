//
//  TrainerSignupView.swift
//  TrainerMatch
//
//  Wired to SupabaseAuthManager — all UI unchanged.
//

import SwiftUI
import PhotosUI

struct TrainerSignupView: View {
    @StateObject private var auth = SupabaseAuthManager.shared

    @State private var businessName    = ""
    @State private var firstName       = ""
    @State private var lastName        = ""
    @State private var email           = ""
    @State private var phoneNumber     = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var city            = ""
    @State private var state           = ""
    @State private var yearsOfExperience = ""
    @State private var hourlyRate      = ""
    @State private var monthlyRate     = ""
    @State private var bio             = ""
    @State private var selectedPhoto:  PhotosPickerItem?
    @State private var profileImage:   Image?
    @State private var profileUIImage: UIImage?
    @State private var selectedSpecialties:    Set<TrainerSpecialty>     = []
    @State private var selectedServiceTypes:   Set<ServiceType>          = []
    @State private var selectedCertifications: Set<TrainerCertification> = []
    @State private var selectedSchools:        Set<TrainingSchool>       = []
    @State private var agreedToTerms   = false
    @State private var currentSection  = 0
    @State private var errorMessage    = ""
    @State private var showingError    = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            mainContent

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

    // MARK: - Main content (unchanged UI)

    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                formCard
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            TrainerMatchLogo(size: .medium)
                .shadow(color: .tmGold.opacity(0.3), radius: 15, x: 0, y: 5)
            Text("Join TrainerMatch")
                .font(.system(size: 32, weight: .bold)).italic().foregroundColor(.white)
            Text("Start growing your fitness business today")
                .font(.subheadline).foregroundColor(.white.opacity(0.8))
        }
        .padding(.top, 40).padding(.bottom, 30)
    }

    private var formCard: some View {
        VStack(spacing: 24) {
            sectionTabs
            formContent
            navigationButtons
        }
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.1)))
        .padding(.horizontal, 20).padding(.bottom, 40)
    }

    private var sectionTabs: some View {
        HStack(spacing: 0) {
            SectionTab(title: "Basic",        number: 1, isActive: currentSection == 0).onTapGesture { currentSection = 0 }
            SectionTab(title: "Professional", number: 2, isActive: currentSection == 1).onTapGesture { currentSection = 1 }
            SectionTab(title: "Services",     number: 3, isActive: currentSection == 2).onTapGesture { currentSection = 2 }
        }
    }

    private var formContent: some View {
        VStack {
            if currentSection == 0 {
                BasicInfoSection(
                    businessName: $businessName, firstName: $firstName,
                    lastName: $lastName, email: $email, phoneNumber: $phoneNumber,
                    password: $password, confirmPassword: $confirmPassword,
                    city: $city, state: $state,
                    selectedPhoto: $selectedPhoto, profileImage: $profileImage
                )
            } else if currentSection == 1 {
                ProfessionalInfoSection(
                    yearsOfExperience: $yearsOfExperience,
                    hourlyRate: $hourlyRate, monthlyRate: $monthlyRate, bio: $bio,
                    selectedCertifications: $selectedCertifications,
                    selectedSchools: $selectedSchools
                )
            } else {
                ServicesSection(
                    selectedSpecialties: $selectedSpecialties,
                    selectedServiceTypes: $selectedServiceTypes,
                    agreedToTerms: $agreedToTerms
                )
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentSection > 0 { backButton }
            if currentSection < 2 { nextButton } else { createAccountButton }
        }
        .padding(.top, 8)
    }

    private var backButton: some View {
        Button(action: { withAnimation { currentSection -= 1 } }) {
            Text("BACK").font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 25).stroke(Color.tmGold, lineWidth: 2))
        }
    }

    private var nextButton: some View {
        Button(action: { withAnimation { currentSection += 1 } }) {
            Text("NEXT").font(.system(size: 14, weight: .heavy)).foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(RoundedRectangle(cornerRadius: 25).fill(Color.tmGold))
        }
    }

    private var createAccountButton: some View {
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
                    if firstName.isEmpty             { validationRow("First Name") }
                    if lastName.isEmpty              { validationRow("Last Name") }
                    if email.isEmpty                 { validationRow("Email") }
                    if password.isEmpty              { validationRow("Password") }
                    if password != confirmPassword   { validationRow("Passwords don't match") }
                    if city.isEmpty                  { validationRow("City") }
                    if state.isEmpty                 { validationRow("State") }
                    if yearsOfExperience.isEmpty     { validationRow("Years of Experience") }
                    if hourlyRate.isEmpty && monthlyRate.isEmpty { validationRow("Need hourly OR monthly rate") }
                    if selectedSpecialties.isEmpty   { validationRow("Select a specialty") }
                    if selectedServiceTypes.isEmpty  { validationRow("Select a service type") }
                    if !agreedToTerms                { validationRow("Check Terms agreement") }
                }
                .padding(.top, 8)
            }
        }
    }

    private func validationRow(_ message: String) -> some View {
        Text("❌ \(message)").font(.caption).foregroundColor(.red)
    }

    private var isFormValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !email.isEmpty &&
        !password.isEmpty && password == confirmPassword &&
        !city.isEmpty && !state.isEmpty &&
        !yearsOfExperience.isEmpty && (!hourlyRate.isEmpty || !monthlyRate.isEmpty) &&
        !selectedSpecialties.isEmpty && !selectedServiceTypes.isEmpty &&
        agreedToTerms
    }

    // MARK: - Submit → Supabase

    private func submitRegistration() {
        Task {
            do {
                try await auth.signUpTrainer(
                    email:             email,
                    password:          password,
                    businessName:      businessName.isEmpty ? nil : businessName,
                    firstName:         firstName,
                    lastName:          lastName,
                    city:              city,
                    state:             state,
                    gender:            "",
                    yearsOfExperience: Int(yearsOfExperience) ?? 0,
                    hourlyRate:        Double(hourlyRate),
                    monthlyRate:       Double(monthlyRate),
                    bio:               bio,
                    certifications:    selectedCertifications.map { $0.rawValue },
                    schools:           selectedSchools.map { $0.rawValue },
                    specialties:       selectedSpecialties.map { $0.rawValue },
                    serviceTypes:      selectedServiceTypes.map { $0.rawValue }
                )

                // Upload profile photo if selected
                if let img = profileUIImage,
                   let data = img.jpegData(compressionQuality: 0.7) {
                    try? await auth.uploadProfilePhoto(imageData: data)
                }

                // Auth manager is now authenticated — RootView will navigate automatically
                await MainActor.run { dismiss() }

            } catch {
                await MainActor.run {
                    errorMessage  = error.localizedDescription
                    showingError  = true
                }
            }
        }
    }
}

// MARK: - Section Tab
struct SectionTab: View {
    let title: String
    let number: Int
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isActive ? Color.tmGold : Color.white.opacity(0.2))
                    .frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isActive ? .black : .white.opacity(0.5))
            }
            Text(title)
                .font(.caption)
                .fontWeight(isActive ? .bold : .regular)
                .foregroundColor(isActive ? .tmGold : .white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Basic Info Section
struct BasicInfoSection: View {
    @Binding var businessName:    String
    @Binding var firstName:       String
    @Binding var lastName:        String
    @Binding var email:           String
    @Binding var phoneNumber:     String
    @Binding var password:        String
    @Binding var confirmPassword: String
    @Binding var city:            String
    @Binding var state:           String
    @Binding var selectedPhoto:   PhotosPickerItem?
    @Binding var profileImage:    Image?

    var body: some View {
        VStack(spacing: 16) {
            Text("Basic Information")
                .font(.headline).foregroundColor(.tmGold)
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
                Text("Upload a professional headshot").font(.caption).foregroundColor(.white.opacity(0.6))
            }
            .padding(.bottom, 8)

            FormField(label: "Business Name (Optional)", text: $businessName,
                      placeholder: "Your Gym/Studio Name", contentType: .organizationName)
            HStack(spacing: 12) {
                FormField(label: "First Name *", text: $firstName, placeholder: "John", contentType: .givenName)
                FormField(label: "Last Name *",  text: $lastName,  placeholder: "Doe",  contentType: .familyName)
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

// MARK: - Professional Info Section
struct ProfessionalInfoSection: View {
    @Binding var yearsOfExperience:    String
    @Binding var hourlyRate:           String
    @Binding var monthlyRate:          String
    @Binding var bio:                  String
    @Binding var selectedCertifications: Set<TrainerCertification>
    @Binding var selectedSchools:        Set<TrainingSchool>

    var body: some View {
        VStack(spacing: 16) {
            Text("Professional Details").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            FormField(label: "Years of Experience *", text: $yearsOfExperience,
                      placeholder: "10", keyboardType: .numberPad)
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            pricingSection
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            bioSection
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            certificationsSection
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            schoolsSection
        }
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing").font(.headline).foregroundColor(.tmGold)
            Text("Set your rates based on training type").font(.caption).foregroundColor(.white.opacity(0.6))
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill").font(.caption).foregroundColor(.tmGold)
                    Text("In-Person Training").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                }
                FormField(label: "Hourly Rate ($)", text: $hourlyRate, placeholder: "75", keyboardType: .numberPad)
                Text("Your rate per hour for in-person training sessions").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "video.fill").font(.caption).foregroundColor(.tmGold)
                    Text("Virtual Training").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                }
                FormField(label: "Monthly Rate ($)", text: $monthlyRate, placeholder: "200", keyboardType: .numberPad)
                Text("Your monthly rate for virtual training programs").font(.caption).foregroundColor(.white.opacity(0.5))
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.3), lineWidth: 1)))

            Text("💡 Tip: Fill in rates for the service types you offer")
                .font(.caption).foregroundColor(.tmGold.opacity(0.8)).italic()
        }
    }

    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio/About You *").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
            TextEditor(text: $bio)
                .frame(height: 100).padding(8)
                .background(Color.white.opacity(0.1)).cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .foregroundColor(.white)
            Text("Tell potential clients about your background and training philosophy")
                .font(.caption).foregroundColor(.white.opacity(0.6))
        }
    }

    private var certificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Certifications").font(.headline).foregroundColor(.tmGold)
            Text("Select all that apply").font(.caption).foregroundColor(.white.opacity(0.6))
            VStack(alignment: .leading, spacing: 16) {
                CertificationCategorySection(title: "General CPT",
                    certs: TrainerCertification.allCases.filter { $0.category == "General CPT" },
                    selected: $selectedCertifications)
                CertificationCategorySection(title: "Specialty Certifications",
                    certs: TrainerCertification.allCases.filter { $0.category == "Specialty" },
                    selected: $selectedCertifications)
                CertificationCategorySection(title: "Yoga & Pilates",
                    certs: TrainerCertification.allCases.filter { $0.category == "Yoga/Pilates" },
                    selected: $selectedCertifications)
                CertificationCategorySection(title: "Special Populations",
                    certs: TrainerCertification.allCases.filter { $0.category == "Special Populations" },
                    selected: $selectedCertifications)
                CertificationCategorySection(title: "Other",
                    certs: TrainerCertification.allCases.filter { $0.category == "Other" },
                    selected: $selectedCertifications)
            }
        }
    }

    private var schoolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training & Education").font(.headline).foregroundColor(.tmGold)
            Text("Where did you get certified? (Optional)").font(.caption).foregroundColor(.white.opacity(0.6))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(TrainingSchool.allCases, id: \.self) { school in
                    SchoolSelectionButton(school: school,
                        isSelected: selectedSchools.contains(school),
                        action: {
                            if selectedSchools.contains(school) { selectedSchools.remove(school) }
                            else { selectedSchools.insert(school) }
                        })
                }
            }
        }
    }
}

// MARK: - Certification Category Section
struct CertificationCategorySection: View {
    let title: String
    let certs: [TrainerCertification]
    @Binding var selected: Set<TrainerCertification>
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline).fontWeight(.semibold).foregroundColor(.tmGold.opacity(0.8))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(certs, id: \.self) { cert in
                    CertificationButton(cert: cert, isSelected: selected.contains(cert),
                        action: {
                            if selected.contains(cert) { selected.remove(cert) }
                            else { selected.insert(cert) }
                        })
                }
            }
        }
    }
}

struct CertificationButton: View {
    let cert: TrainerCertification; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(cert.rawValue).font(.caption).fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .white)
                .lineLimit(2).minimumScaleFactor(0.7)
                .padding(.horizontal, 10).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.tmGold : Color.white.opacity(0.05))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 1.5)))
        }
    }
}

struct SchoolSelectionButton: View {
    let school: TrainingSchool; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: school.icon).font(.caption2)
                    .foregroundColor(isSelected ? .black : .tmGold.opacity(0.7))
                Text(school.rawValue).font(.caption).fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .black : .white).lineLimit(3).minimumScaleFactor(0.6)
            }
            .padding(.horizontal, 8).padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.tmGold : Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 1.5)))
        }
    }
}

// MARK: - Services Section
struct ServicesSection: View {
    @Binding var selectedSpecialties:  Set<TrainerSpecialty>
    @Binding var selectedServiceTypes: Set<ServiceType>
    @Binding var agreedToTerms:        Bool
    let specialtyOptions = Array(TrainerSpecialty.allCases.prefix(12))

    var body: some View {
        VStack(spacing: 16) {
            Text("Services & Specialties").font(.headline).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Specialties *").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Text("Select at least one").font(.caption).foregroundColor(.white.opacity(0.6))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(specialtyOptions, id: \.self) { specialty in
                        SpecialtySelectionButton(specialty: specialty,
                            isSelected: selectedSpecialties.contains(specialty),
                            action: {
                                if selectedSpecialties.contains(specialty) { selectedSpecialties.remove(specialty) }
                                else { selectedSpecialties.insert(specialty) }
                            })
                    }
                }
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            VStack(alignment: .leading, spacing: 8) {
                Text("Service Types *").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                ForEach(ServiceType.allCases, id: \.self) { serviceType in
                    ServiceTypeSelectionButton(serviceType: serviceType,
                        isSelected: selectedServiceTypes.contains(serviceType),
                        action: {
                            if selectedServiceTypes.contains(serviceType) { selectedServiceTypes.remove(serviceType) }
                            else { selectedServiceTypes.insert(serviceType) }
                        })
                }
            }
            Divider().background(Color.white.opacity(0.2)).padding(.vertical, 8)
            HStack(alignment: .top, spacing: 8) {
                Button(action: { agreedToTerms.toggle() }) {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreedToTerms ? Color.tmGold : .white.opacity(0.5)).font(.title3)
                }
                Text("I agree to the TrainerMatch Terms of Service and Privacy Policy")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

struct SpecialtySelectionButton: View {
    let specialty: TrainerSpecialty; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(specialty.rawValue).font(.caption).fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12).padding(.vertical, 8).frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.tmGold : Color.white.opacity(0.1)))
        }
    }
}

struct ServiceTypeSelectionButton: View {
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
            .background(RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 2))
        }
    }
}

#Preview { TrainerSignupView() }
