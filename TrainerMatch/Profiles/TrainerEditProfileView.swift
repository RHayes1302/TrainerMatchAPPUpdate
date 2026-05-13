//
//  TrainerEditProfileView.swift
//  TrainerMatch
//
//  NOTE: EditCard, EditField, EditDivider, ToggleChip, WrapLayout are defined
//  at the bottom of this file. ClientEditProfileView uses CEP-prefixed versions
//  of its private helpers so there are zero naming conflicts.
//

import SwiftUI
import PhotosUI

struct TrainerEditProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var businessName: String
    @State private var firstName: String
    @State private var lastName: String
    @State private var city: String
    @State private var state: String
    @State private var yearsOfExperience: String
    @State private var hourlyRate: String
    @State private var monthlyRate: String
    @State private var bio: String
    @State private var certifications: Set<TrainerCertification>
    @State private var schools: Set<TrainingSchool>
    @State private var specialties: Set<TrainerSpecialty>
    @State private var serviceTypes: Set<ServiceType>
    @State private var websiteURL: String
    @State private var instagramHandle: String
    @State private var gender: String

    @State private var currentSection = 0
    @State private var showingSaveConfirmation = false
    @State private var showingDiscardAlert = false
    @State private var isSaving = false

    init(profile: SavedTrainerProfile) {
        _businessName      = State(initialValue: profile.businessName ?? "")
        _firstName         = State(initialValue: profile.firstName)
        _lastName          = State(initialValue: profile.lastName)
        _city              = State(initialValue: profile.city)
        _state             = State(initialValue: profile.state)
        _yearsOfExperience = State(initialValue: String(profile.yearsOfExperience))
        _hourlyRate        = State(initialValue: profile.hourlyRate.map { String(Int($0)) } ?? "")
        _monthlyRate       = State(initialValue: profile.monthlyRate.map { String(Int($0)) } ?? "")
        _bio               = State(initialValue: profile.bio)
        _certifications    = State(initialValue: Set(profile.certifications))
        _schools           = State(initialValue: Set(profile.schools))
        _specialties       = State(initialValue: Set(profile.specialties))
        _serviceTypes      = State(initialValue: Set(profile.serviceTypes))
        _websiteURL        = State(initialValue: "")
        _instagramHandle   = State(initialValue: "")
        _gender            = State(initialValue: profile.gender)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                sectionTabBar.padding(.top, 8)
                ScrollView {
                    VStack(spacing: 0) {
                        tabContent
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 100)
                    }
                }
            }

            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .background(
                        LinearGradient(colors: [Color.black.opacity(0), Color.black],
                                       startPoint: .top, endPoint: .bottom)
                        .frame(height: 100)
                        .allowsHitTesting(false)
                    )
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { showingDiscardAlert = true }.foregroundColor(.tmGold)
            }
        }
        .alert("Discard Changes?", isPresented: $showingDiscardAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: { Text("Your unsaved changes will be lost.") }
        .alert("Profile Updated!", isPresented: $showingSaveConfirmation) {
            Button("Done") { dismiss() }
        } message: { Text("Your profile has been saved successfully.") }
    }

    // MARK: - Tab Bar

    private var sectionTabBar: some View {
        HStack(spacing: 0) {
            TEPTab(icon: "person.fill",    title: "BASIC",  number: 0, current: currentSection) { currentSection = 0 }
            TEPTab(icon: "briefcase.fill", title: "WORK",   number: 1, current: currentSection) { currentSection = 1 }
            TEPTab(icon: "star.fill",      title: "SKILLS", number: 2, current: currentSection) { currentSection = 2 }
            TEPTab(icon: "link",           title: "LINKS",  number: 3, current: currentSection) { currentSection = 3 }
        }
        .background(Color.white.opacity(0.05))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch currentSection {
        case 0: basicSection
        case 1: professionalSection
        case 2: skillsSection
        case 3: linksSection
        default: EmptyView()
        }
    }

    // MARK: - Basic

    private var basicSection: some View {
        VStack(spacing: 20) {
            if let profile = authManager.currentTrainerProfile {
                // ── Banner + Profile photo preview ──────────────────
                EditCard(title: "COVER PHOTO & PROFILE PICTURE", icon: "photo.on.rectangle.angled") {
                    VStack(spacing: 0) {
                        // Banner picker — full width, tappable
                        BannerEditPicker(userId: profile.id)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        // Profile photo sitting on the banner edge
                        HStack {
                            ProfileImagePickerView(
                                userId: profile.id,
                                size: 84,
                                isEditable: true,
                                placeholder: "person.fill"
                            )
                            .offset(y: -28)
                            .padding(.leading, 14)

                            Spacer()

                            Text("Tap either photo to change")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.trailing, 14)
                                .padding(.top, 8)
                        }
                        .frame(height: 32)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, -16) // bleed to card edges
                    .padding(.top, -14)        // bleed to card top
                }
            }

            EditCard(title: "NAME & BUSINESS", icon: "person.text.rectangle.fill") {
                EditField(label: "Business / Studio Name", placeholder: "Elite Fitness Studio", text: $businessName)
                EditDivider()
                EditField(label: "First Name *", placeholder: "John", text: $firstName)
                EditDivider()
                EditField(label: "Last Name *", placeholder: "Doe", text: $lastName)
            }

            EditCard(title: "LOCATION", icon: "mappin.circle.fill") {
                EditField(label: "City *", placeholder: "Las Vegas", text: $city)
                EditDivider()
                EditField(label: "State *", placeholder: "NV", text: $state)
            }

            EditCard(title: "ABOUT ME", icon: "text.quote") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio").font(.caption).foregroundColor(.white.opacity(0.55))
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bio)
                            .frame(minHeight: 110)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(.white)
                        if bio.isEmpty {
                            Text("Tell clients about your background, philosophy, and what makes you unique...")
                                .foregroundColor(.white.opacity(0.3)).font(.body)
                                .padding(.top, 8).padding(.leading, 4).allowsHitTesting(false)
                        }
                    }
                    Text("\(bio.count) characters")
                        .font(.caption2).foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            EditCard(title: "GENDER", icon: "person.fill") {
                VStack(spacing: 10) {
                    ForEach(["Male", "Female", "Non-binary", "Prefer not to say"], id: \.self) { option in
                        Button(action: { gender = option }) {
                            HStack {
                                Image(systemName: gender == option ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(gender == option ? .tmGold : .white.opacity(0.4))
                                Text(option).foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(gender == option ? Color.tmGold.opacity(0.1) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(gender == option ? Color.tmGold : Color.white.opacity(0.15), lineWidth: 1))
                            )
                        }
                    }
                }
            }

            nextSectionButton(label: "Next: Work Info →")
        }
    }

    // MARK: - Professional

    private var professionalSection: some View {
        VStack(spacing: 20) {
            EditCard(title: "EXPERIENCE & RATES", icon: "dollarsign.circle.fill") {
                EditField(label: "Years of Experience *", placeholder: "10", text: $yearsOfExperience, keyboard: .numberPad)
                EditDivider()
                EditField(label: "Hourly Rate (In-Person, $)", placeholder: "75", text: $hourlyRate, keyboard: .numberPad)
                EditDivider()
                EditField(label: "Monthly Rate (Virtual, $)", placeholder: "200", text: $monthlyRate, keyboard: .numberPad)
            }

            EditCard(title: "CERTIFICATIONS", icon: "checkmark.seal.fill") {
                VStack(alignment: .leading, spacing: 14) {
                    TEPCertGroup(category: "General CPT",
                                 certs: TrainerCertification.allCases.filter { $0.category == "General CPT" },
                                 selected: $certifications)
                    TEPCertGroup(category: "Specialty",
                                 certs: TrainerCertification.allCases.filter { $0.category == "Specialty" },
                                 selected: $certifications)
                    TEPCertGroup(category: "Yoga / Pilates",
                                 certs: TrainerCertification.allCases.filter { $0.category == "Yoga/Pilates" },
                                 selected: $certifications)
                    TEPCertGroup(category: "Special Populations",
                                 certs: TrainerCertification.allCases.filter { $0.category == "Special Populations" },
                                 selected: $certifications)
                    TEPCertGroup(category: "Other",
                                 certs: TrainerCertification.allCases.filter { $0.category == "Other" },
                                 selected: $certifications)
                }
            }

            EditCard(title: "EDUCATION & TRAINING", icon: "graduationcap.fill") {
                TEPWrapLayout(items: TrainingSchool.allCases) { school in
                    ToggleChip(label: school.rawValue, icon: school.icon,
                               isSelected: schools.contains(school)) {
                        if schools.contains(school) { schools.remove(school) } else { schools.insert(school) }
                    }
                }
            }

            nextSectionButton(label: "Next: Skills →")
        }
    }

    // MARK: - Skills

    private var skillsSection: some View {
        VStack(spacing: 20) {
            EditCard(title: "SERVICE TYPES *", icon: "figure.run.circle.fill") {
                VStack(spacing: 10) {
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        Button(action: {
                            if serviceTypes.contains(type) { serviceTypes.remove(type) } else { serviceTypes.insert(type) }
                        }) {
                            HStack {
                                Image(systemName: serviceTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(serviceTypes.contains(type) ? .tmGold : .white.opacity(0.4))
                                Text(type.rawValue).foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(serviceTypes.contains(type) ? Color.tmGold.opacity(0.1) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(serviceTypes.contains(type) ? Color.tmGold : Color.white.opacity(0.15), lineWidth: 1))
                            )
                        }
                    }
                }
            }

            EditCard(title: "SPECIALTIES *", icon: "star.circle.fill") {
                Text("Select all that apply").font(.caption).foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                TEPWrapLayout(items: TrainerSpecialty.allCases) { specialty in
                    ToggleChip(label: specialty.rawValue, isSelected: specialties.contains(specialty)) {
                        if specialties.contains(specialty) { specialties.remove(specialty) } else { specialties.insert(specialty) }
                    }
                }
            }

            nextSectionButton(label: "Next: Links →")
        }
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(spacing: 20) {
            EditCard(title: "ONLINE PRESENCE", icon: "globe") {
                EditField(label: "Website URL", placeholder: "https://yourwebsite.com", text: $websiteURL, keyboard: .URL)
                EditDivider()
                HStack(spacing: 6) {
                    Text("@").foregroundColor(.tmGold).font(.body)
                    EditField(label: "Instagram Handle", placeholder: "yourhandle", text: $instagramHandle, keyboard: .twitter)
                }
            }

            // Summary preview
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill").font(.caption).foregroundColor(.black)
                    Text("PROFILE SUMMARY").font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                }
                .padding(.horizontal, 12).padding(.vertical, 6).background(Color.tmGold)

                VStack(alignment: .leading, spacing: 10) {
                    TEPSummaryRow(label: "Name",        value: "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces))
                    TEPSummaryRow(label: "Location",    value: city.isEmpty ? "—" : "\(city), \(state)")
                    TEPSummaryRow(label: "Experience",  value: yearsOfExperience.isEmpty ? "—" : "\(yearsOfExperience) yrs")
                    TEPSummaryRow(label: "Hourly Rate", value: hourlyRate.isEmpty ? "—" : "$\(hourlyRate)/hr")
                    TEPSummaryRow(label: "Specialties", value: specialties.isEmpty ? "None selected" : "\(specialties.count) selected")
                    TEPSummaryRow(label: "Certs",       value: certifications.isEmpty ? "None" : "\(certifications.count) selected")
                }
                .padding(.horizontal, 16).padding(.bottom, 16)
            }
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack(spacing: 10) {
                if isSaving { ProgressView().tint(.black) }
                else { Image(systemName: "checkmark.circle.fill") }
                Text(isSaving ? "SAVING..." : "SAVE CHANGES").font(.system(size: 15, weight: .heavy))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 27)
                    .fill(isValid ? AnyShapeStyle(Color.tmGoldGradient()) : AnyShapeStyle(Color.gray.opacity(0.4)))
            )
            .shadow(color: isValid ? .tmGold.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!isValid || isSaving)
    }

    private func nextSectionButton(label: String) -> some View {
        Button(action: { withAnimation { currentSection = min(currentSection + 1, 3) } }) {
            Text(label).font(.system(size: 14, weight: .bold)).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 22).stroke(Color.tmGold, lineWidth: 1.5))
        }
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty && !city.isEmpty && !state.isEmpty &&
        !yearsOfExperience.isEmpty && !specialties.isEmpty && !serviceTypes.isEmpty
    }

    private func saveProfile() {
        guard let current = authManager.currentTrainerProfile else { return }
        isSaving = true
        let updated = SavedTrainerProfile(
            id: current.id,
            businessName: businessName.isEmpty ? nil : businessName,
            firstName: firstName, lastName: lastName,
            email: current.email, password: current.password,
            city: city, state: state,
            gender: gender,
            yearsOfExperience: Int(yearsOfExperience) ?? current.yearsOfExperience,
            hourlyRate: Double(hourlyRate), monthlyRate: Double(monthlyRate),
            bio: bio,
            certifications: Array(certifications), schools: Array(schools),
            specialties: Array(specialties), serviceTypes: Array(serviceTypes),
            dateCreated: current.dateCreated
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            authManager.updateTrainerProfile(updated)
            isSaving = false
            showingSaveConfirmation = true
        }
    }
}

// MARK: - Private helpers (TEP-prefixed to avoid any module conflicts)

private struct TEPTab: View {
    let icon: String; let title: String; let number: Int; let current: Int; let action: () -> Void
    var isActive: Bool { current == number }
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(isActive ? .tmGold : .white.opacity(0.4))
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(isActive ? Color.tmGold.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct TEPCertGroup: View {
    let category: String; let certs: [TrainerCertification]
    @Binding var selected: Set<TrainerCertification>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category).font(.caption).fontWeight(.semibold).foregroundColor(.tmGold.opacity(0.8))
            TEPWrapLayout(items: certs) { cert in
                ToggleChip(label: cert.rawValue, isSelected: selected.contains(cert)) {
                    if selected.contains(cert) { selected.remove(cert) } else { selected.insert(cert) }
                }
            }
        }
    }
}

private struct TEPWrapLayout<Item: Hashable, ItemView: View>: View {
    let items: [Item]; let itemView: (Item) -> ItemView
    init(items: [Item], @ViewBuilder itemView: @escaping (Item) -> ItemView) {
        self.items = items; self.itemView = itemView
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let chunks = items.chunked(into: 3)
            ForEach(chunks.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    ForEach(chunks[i], id: \.self) { item in itemView(item) }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

private struct TEPSummaryRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.white).multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Shared components (used by both TrainerEditProfileView and ClientEditProfileView)

struct EditCard<Content: View>: View {
    let title: String; let icon: String; let content: Content
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.icon = icon; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.caption).foregroundColor(.black)
                Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 12).padding(.vertical, 6).background(Color.tmGold)
            content.padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }
}

struct EditField: View {
    let label: String; let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.55))
            TextField(placeholder, text: $text)
                .keyboardType(keyboard).foregroundColor(.white).autocorrectionDisabled()
        }
        .padding(.vertical, 6)
    }
}

struct EditDivider: View {
    var body: some View { Divider().background(Color.white.opacity(0.1)) }
}

struct ToggleChip: View {
    let label: String; var icon: String? = nil; let isSelected: Bool; let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption2) }
                Text(label).font(.caption).lineLimit(1)
            }
            .foregroundColor(isSelected ? .black : .white)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.tmGold : Color.white.opacity(0.08))
                    .overlay(Capsule().stroke(isSelected ? Color.tmGold : Color.white.opacity(0.2), lineWidth: 1))
            )
        }
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Banner Edit Picker (inline version for edit form)

struct BannerEditPicker: View {
    let userId: String

    @State private var bannerImage: UIImage?
    @State private var showingOptions = false
    @State private var showingPicker  = false
    @State private var showingCamera  = false
    @State private var selectedItem: PhotosPickerItem?

    private var bannerKey: String { "banner_\(userId)" }

    var body: some View {
        ZStack(alignment: .center) {
            // Current banner or gold gradient fallback
            if let img = bannerImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color.tmGold, Color.tmGoldDark],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Dark scrim + tap hint
            Color.black.opacity(bannerImage == nil ? 0.0 : 0.35)

            VStack(spacing: 6) {
                Image(systemName: bannerImage == nil ? "photo.badge.plus.fill" : "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(bannerImage == nil ? .black.opacity(0.5) : .white)
                Text(bannerImage == nil ? "TAP TO ADD COVER PHOTO" : "TAP TO CHANGE COVER")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(bannerImage == nil ? .black.opacity(0.5) : .white)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { showingOptions = true }
        .onAppear {
            bannerImage = ProfileImageManager.shared.loadImage(forKey: bannerKey)
        }
        .confirmationDialog("Cover Photo", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Take Photo")           { showingCamera = true }
            Button("Choose from Library")  { showingPicker = true }
            if bannerImage != nil {
                Button("Remove Cover Photo", role: .destructive) {
                    ProfileImageManager.shared.deleteImage(forKey: bannerKey)
                    bannerImage = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let raw  = UIImage(data: data) {
                    let resized = resizeBanner(raw)
                    ProfileImageManager.shared.saveImage(resized, forKey: bannerKey)
                    await MainActor.run { bannerImage = resized }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraImagePicker { captured in
                let resized = resizeBanner(captured)
                ProfileImageManager.shared.saveImage(resized, forKey: bannerKey)
                bannerImage = resized
                showingCamera = false
            }
        }
    }

    private func resizeBanner(_ image: UIImage) -> UIImage {
        let maxW: CGFloat = 1200, maxH: CGFloat = 450
        let scale = min(maxW / image.size.width, maxH / image.size.height)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

#Preview {
    NavigationView {
        TrainerEditProfileView(profile: SavedTrainerProfile(
            id: "preview", businessName: "Elite Fitness",
            firstName: "John", lastName: "Doe",
            email: "john@test.com", password: "test",
            city: "Las Vegas", state: "NV",
            gender: "Male",
            yearsOfExperience: 10, hourlyRate: 75, monthlyRate: 200,
            bio: "Certified trainer with 10 years experience.",
            certifications: [.nasmCpt, .aceCpt], schools: [.nasm],
            specialties: [.personalTraining, .hiit],
            serviceTypes: [.inPerson, .online], dateCreated: Date()
        ))
        .environmentObject(AuthManager.shared)
    }
}
