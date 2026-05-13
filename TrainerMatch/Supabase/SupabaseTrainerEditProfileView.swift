//
//  SupabaseTrainerEditProfileView.swift
//  TrainerMatch
//

import SwiftUI
import PhotosUI

struct SupabaseTrainerEditProfileView: View {
    @ObservedObject private var auth = SupabaseAuthManager.shared
    @Environment(\.dismiss) var dismiss

    // Basic
    @State private var businessName    = ""
    @State private var firstName       = ""
    @State private var lastName        = ""
    @State private var city            = ""
    @State private var state           = ""
    @State private var gender          = ""
    @State private var bio             = ""

    // Professional
    @State private var yearsOfExperience = ""
    @State private var hourlyRate        = ""
    @State private var monthlyRate       = ""

    // Skills
    @State private var specialties:    Set<TrainerSpecialty>      = []
    @State private var serviceTypes:   Set<ServiceType>           = []
    @State private var certifications: Set<TrainerCertification>  = []
    @State private var schools:        Set<TrainingSchool>        = []

    // Photos
    @State private var profileImage:      UIImage?
    @State private var bannerImage:       UIImage?
    @State private var profilePickerItem: PhotosPickerItem?
    @State private var bannerPickerItem:  PhotosPickerItem?
    @State private var isUploadingProfile = false
    @State private var isUploadingBanner  = false

    // UI
    @State private var currentSection = 0
    @State private var isSaving       = false
    @State private var showingSaved   = false
    @State private var showingDiscard = false
    @State private var errorMessage   = ""
    @State private var showingError   = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                tabBar.padding(.top, 8)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        tabContent
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 120)
                }
            }
            VStack {
                Spacer()
                saveButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0), Color.black],
                            startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                        .allowsHitTesting(false),
                        alignment: .bottom
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
                Button("Cancel") { showingDiscard = true }.foregroundColor(.tmGold)
            }
        }
        .onAppear { loadCurrentProfile() }
        .onChange(of: profilePickerItem) { _, item in Task { await handleProfilePick(item) } }
        .onChange(of: bannerPickerItem)  { _, item in Task { await handleBannerPick(item) } }
        .alert("Discard Changes?", isPresented: $showingDiscard) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) {}
        } message: { Text("Your unsaved changes will be lost.") }
        .alert("Profile Updated!", isPresented: $showingSaved) {
            Button("Done") { dismiss() }
        } message: { Text("Your profile has been saved.") }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: { Text(errorMessage) }
    }

    // MARK: - Load

    private func loadCurrentProfile() {
        guard let t = auth.currentTrainer else { return }
        businessName      = t.businessName ?? ""
        firstName         = t.firstName
        lastName          = t.lastName
        city              = t.city
        state             = t.state
        gender            = t.gender
        bio               = t.bio
        yearsOfExperience = String(t.yearsOfExperience)
        hourlyRate        = t.hourlyRate.map { String(Int($0)) } ?? ""
        monthlyRate       = t.monthlyRate.map { String(Int($0)) } ?? ""
        specialties       = Set(t.specialties.compactMap   { TrainerSpecialty(rawValue: $0) })
        serviceTypes      = Set(t.serviceTypes.compactMap  { ServiceType(rawValue: $0) })
        certifications    = Set(t.certifications.compactMap { TrainerCertification(rawValue: $0) })
        schools           = Set(t.schools.compactMap        { TrainingSchool(rawValue: $0) })

        if let urlStr = t.profileImageUrl, let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { profileImage = img }
                }
            }
        }
        if let urlStr = t.bannerImageUrl, let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { bannerImage = img }
                }
            }
        }
    }

    // MARK: - Photo handlers

    private func handleProfilePick(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        let resized = resize(img, maxDim: 500)
        await MainActor.run { profileImage = resized; isUploadingProfile = true }
        if let jpeg = resized.jpegData(compressionQuality: 0.8) {
            do { _ = try await auth.uploadProfilePhoto(imageData: jpeg) }
            catch { print("❌ Profile upload: \(error)") }
        }
        await MainActor.run { isUploadingProfile = false }
    }

    private func handleBannerPick(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        let resized = resize(img, maxDim: 1200)
        await MainActor.run { bannerImage = resized; isUploadingBanner = true }
        if let jpeg = resized.jpegData(compressionQuality: 0.8) {
            do { _ = try await auth.uploadBannerPhoto(imageData: jpeg) }
            catch { print("❌ Banner upload: \(error)") }
        }
        await MainActor.run { isUploadingBanner = false }
    }

    private func resize(_ image: UIImage, maxDim: CGFloat) -> UIImage {
        let scale = min(maxDim / image.size.width, maxDim / image.size.height, 1)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: image.size.width * scale,
                             height: image.size.height * scale)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBtn(icon: "person.fill",    title: "BASIC",  idx: 0)
            tabBtn(icon: "briefcase.fill", title: "WORK",   idx: 1)
            tabBtn(icon: "star.fill",      title: "SKILLS", idx: 2)
        }
        .background(Color.white.opacity(0.05))
    }

    private func tabBtn(icon: String, title: String, idx: Int) -> some View {
        Button(action: { withAnimation { currentSection = idx } }) {
            VStack(spacing: 5) {
                Image(systemName: icon).font(.caption)
                Text(title).font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(currentSection == idx ? .tmGold : .white.opacity(0.4))
            .frame(maxWidth: .infinity).padding(.vertical, 12)
            .background(currentSection == idx ? Color.tmGold.opacity(0.1) : Color.clear)
            .overlay(Rectangle().frame(height: 2)
                .foregroundColor(currentSection == idx ? .tmGold : .clear),
                     alignment: .bottom)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch currentSection {
        case 0: basicSection
        case 1: professionalSection
        case 2: skillsSection
        default: EmptyView()
        }
    }

    // MARK: - Basic Section

    private var basicSection: some View {
        VStack(spacing: 16) {
            eCard(title: "PHOTOS", icon: "camera.fill") {
                VStack(spacing: 0) {
                    PhotosPicker(selection: $bannerPickerItem, matching: .images) {
                        ZStack {
                            if let img = bannerImage {
                                Image(uiImage: img).resizable().scaledToFill()
                            } else {
                                LinearGradient(colors: [.tmGold, .tmGoldDark],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
                            }
                            if isUploadingBanner {
                                Color.black.opacity(0.5)
                                ProgressView().tint(.tmGold)
                            } else {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Label(bannerImage == nil ? "Add Cover" : "Change Cover",
                                              systemImage: "camera.fill")
                                            .font(.caption).fontWeight(.semibold)
                                            .foregroundColor(bannerImage == nil
                                                             ? .black.opacity(0.6) : .white)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Capsule().fill(Color.black.opacity(0.2)))
                                            .padding(8)
                                    }
                                }
                            }
                        }
                        .frame(height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    HStack {
                        PhotosPicker(selection: $profilePickerItem, matching: .images) {
                            ZStack {
                                Circle().fill(Color.black).frame(width: 80, height: 80)
                                if let img = profileImage {
                                    Image(uiImage: img).resizable().scaledToFill()
                                        .frame(width: 76, height: 76).clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                                             startPoint: .topLeading,
                                                             endPoint: .bottomTrailing))
                                        .frame(width: 76, height: 76)
                                        .overlay(Text(firstName.prefix(1).uppercased())
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.black))
                                }
                                if isUploadingProfile {
                                    Circle().fill(Color.black.opacity(0.5)).frame(width: 76, height: 76)
                                    ProgressView().tint(.tmGold)
                                } else {
                                    Circle().fill(Color.tmGold).frame(width: 24, height: 24)
                                        .overlay(Image(systemName: "camera.fill")
                                            .font(.system(size: 10)).foregroundColor(.black))
                                        .offset(x: 26, y: 26)
                                }
                            }
                            .overlay(Circle().stroke(Color.black, lineWidth: 3).frame(width: 80))
                        }
                        .offset(y: -20).padding(.leading, 12)
                        Spacer()
                        Text("Tap to change photos")
                            .font(.caption2).foregroundColor(.white.opacity(0.4))
                            .padding(.trailing, 12).padding(.top, 8)
                    }
                    .frame(height: 40).padding(.bottom, 8)
                }
                .padding(.horizontal, -16).padding(.top, -14)
            }

            eCard(title: "NAME & BUSINESS", icon: "person.text.rectangle.fill") {
                eField("Business / Studio Name", placeholder: "93/7 Fitness", text: $businessName)
                eDivider
                eField("First Name *", placeholder: "Ramone", text: $firstName)
                eDivider
                eField("Last Name *", placeholder: "Hayes", text: $lastName)
            }

            eCard(title: "LOCATION", icon: "mappin.circle.fill") {
                eField("City *", placeholder: "Las Vegas", text: $city)
                eDivider
                eField("State *", placeholder: "NV", text: $state)
            }

            eCard(title: "ABOUT ME", icon: "text.quote") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bio").font(.caption).foregroundColor(.white.opacity(0.55))
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $bio)
                            .frame(minHeight: 110)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(.white)
                        if bio.isEmpty {
                            Text("Tell clients about your background and philosophy...")
                                .foregroundColor(.white.opacity(0.3)).font(.body)
                                .padding(.top, 8).padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                    Text("\(bio.count) characters")
                        .font(.caption2).foregroundColor(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }

            eCard(title: "GENDER", icon: "person.fill") {
                VStack(spacing: 8) {
                    ForEach(["Male", "Female", "Non-binary", "Prefer not to say"], id: \.self) { opt in
                        Button(action: { gender = opt }) {
                            HStack {
                                Image(systemName: gender == opt ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(gender == opt ? .tmGold : .white.opacity(0.4))
                                Text(opt).foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(gender == opt ? Color.tmGold.opacity(0.1) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(gender == opt ? Color.tmGold : Color.white.opacity(0.15),
                                                lineWidth: 1)))
                        }
                    }
                }
            }

            nextBtn("Next: Work Info →") { currentSection = 1 }
        }
    }

    // MARK: - Professional Section

    private var professionalSection: some View {
        VStack(spacing: 16) {
            eCard(title: "EXPERIENCE & RATES", icon: "dollarsign.circle.fill") {
                eField("Years of Experience *", placeholder: "6",
                       text: $yearsOfExperience, keyboard: .numberPad)
                eDivider
                eField("Hourly Rate (In-Person, $)", placeholder: "50",
                       text: $hourlyRate, keyboard: .numberPad)
                eDivider
                eField("Monthly Rate (Virtual, $)", placeholder: "200",
                       text: $monthlyRate, keyboard: .numberPad)
            }

            eCard(title: "CERTIFICATIONS", icon: "checkmark.seal.fill") {
                VStack(alignment: .leading, spacing: 14) {
                    certGroup("General CPT",
                              certs: TrainerCertification.allCases.filter { $0.category == "General CPT" })
                    certGroup("Specialty",
                              certs: TrainerCertification.allCases.filter { $0.category == "Specialty" })
                    certGroup("Yoga / Pilates",
                              certs: TrainerCertification.allCases.filter { $0.category == "Yoga/Pilates" })
                    certGroup("Special Populations",
                              certs: TrainerCertification.allCases.filter { $0.category == "Special Populations" })
                    certGroup("Other",
                              certs: TrainerCertification.allCases.filter { $0.category == "Other" })
                }
            }

            eCard(title: "EDUCATION & TRAINING", icon: "graduationcap.fill") {
                wrapLayout(items: TrainingSchool.allCases) { school in
                    ToggleChip(label: school.rawValue, icon: school.icon,
                               isSelected: schools.contains(school)) {
                        if schools.contains(school) { schools.remove(school) }
                        else { schools.insert(school) }
                    }
                }
            }

            nextBtn("Next: Skills →") { currentSection = 2 }
        }
    }

    // MARK: - Skills Section

    private var skillsSection: some View {
        VStack(spacing: 16) {
            eCard(title: "SERVICE TYPES *", icon: "figure.run.circle.fill") {
                VStack(spacing: 8) {
                    ForEach(ServiceType.allCases, id: \.self) { type in
                        Button(action: {
                            if serviceTypes.contains(type) { serviceTypes.remove(type) }
                            else { serviceTypes.insert(type) }
                        }) {
                            HStack {
                                Image(systemName: serviceTypes.contains(type)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(serviceTypes.contains(type)
                                                     ? .tmGold : .white.opacity(0.4))
                                Text(type.rawValue).foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.vertical, 10).padding(.horizontal, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(serviceTypes.contains(type)
                                          ? Color.tmGold.opacity(0.1) : Color.white.opacity(0.04))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(serviceTypes.contains(type)
                                                ? Color.tmGold : Color.white.opacity(0.15),
                                                lineWidth: 1)))
                        }
                    }
                }
            }

            eCard(title: "SPECIALTIES *", icon: "star.circle.fill") {
                Text("Select all that apply")
                    .font(.caption).foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
                wrapLayout(items: TrainerSpecialty.allCases) { specialty in
                    ToggleChip(label: specialty.rawValue,
                               isSelected: specialties.contains(specialty)) {
                        if specialties.contains(specialty) { specialties.remove(specialty) }
                        else { specialties.insert(specialty) }
                    }
                }
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: saveProfile) {
            HStack(spacing: 10) {
                if isSaving { ProgressView().tint(.black) }
                else { Image(systemName: "checkmark.circle.fill") }
                Text(isSaving ? "SAVING..." : "SAVE CHANGES")
                    .font(.system(size: 15, weight: .heavy))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 27)
                    .fill(isValid ? Color.tmGold : Color.gray.opacity(0.4))
                    .shadow(color: isValid ? Color.tmGold.opacity(0.35) : .clear,
                            radius: 12, y: 6))
        }
        .disabled(!isValid || isSaving)
    }

    private var isValid: Bool {
        !firstName.isEmpty && !lastName.isEmpty &&
        !city.isEmpty && !state.isEmpty &&
        !yearsOfExperience.isEmpty &&
        !specialties.isEmpty && !serviceTypes.isEmpty
    }

    private func saveProfile() {
        guard var trainer = auth.currentTrainer else { return }
        isSaving = true
        trainer.businessName      = businessName.isEmpty ? nil : businessName
        trainer.firstName         = firstName
        trainer.lastName          = lastName
        trainer.city              = city
        trainer.state             = state
        trainer.gender            = gender
        trainer.bio               = bio
        trainer.yearsOfExperience = Int(yearsOfExperience) ?? trainer.yearsOfExperience
        trainer.hourlyRate        = Double(hourlyRate)
        trainer.monthlyRate       = Double(monthlyRate)
        trainer.specialties       = specialties.map    { $0.rawValue }
        trainer.serviceTypes      = serviceTypes.map   { $0.rawValue }
        trainer.certifications    = certifications.map { $0.rawValue }
        trainer.schools           = schools.map        { $0.rawValue }

        Task {
            do {
                try await auth.updateTrainerProfile(trainer)
                await MainActor.run { isSaving = false; showingSaved = true }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func eCard<Content: View>(title: String, icon: String,
                                      @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.caption).foregroundColor(.black)
                Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.black)
            }
            .padding(.horizontal, 12).padding(.vertical, 6).background(Color.tmGold)
            content().padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
    }

    private func eField(_ label: String, placeholder: String,
                         text: Binding<String>,
                         keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.55))
            TextField(placeholder, text: text)
                .keyboardType(keyboard).foregroundColor(.white).autocorrectionDisabled()
        }
        .padding(.vertical, 6)
    }

    private var eDivider: some View {
        Divider().background(Color.white.opacity(0.1))
    }

    private func nextBtn(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 14, weight: .bold)).foregroundColor(.tmGold)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 22).stroke(Color.tmGold, lineWidth: 1.5))
        }
    }

    private func certGroup(_ category: String, certs: [TrainerCertification]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category).font(.caption).fontWeight(.semibold)
                .foregroundColor(.tmGold.opacity(0.8))
            wrapLayout(items: certs) { cert in
                ToggleChip(label: cert.rawValue, isSelected: certifications.contains(cert)) {
                    if certifications.contains(cert) { certifications.remove(cert) }
                    else { certifications.insert(cert) }
                }
            }
        }
    }

    private func wrapLayout<Item: Hashable, ItemView: View>(
        items: [Item],
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) -> some View {
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
