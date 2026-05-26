//
//  ClientEditProfileView.swift
//  TrainerMatch
//
//  Fully linked to Supabase — reads from and saves to ClientRow.
//

import SwiftUI
import PhotosUI

struct ClientEditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var auth = SupabaseAuthManager.shared

    @State private var selectedSection: EditSection = .basic
    @State private var isSaving          = false
    @State private var showingSaveAlert  = false
    @State private var saveError: String?

    // Basic
    @State private var firstName: String
    @State private var lastName:  String
    @State private var city:      String
    @State private var state:     String

    // Goals
    @State private var fitnessLevel:  String
    @State private var targetWeight:  String
    @State private var selectedGoals: Set<String>

    // Health
    @State private var medicalConditions: String
    @State private var injuries:          String
    @State private var allergies:         String
    @State private var medications:       String

    // Photo
    @State private var profileImage:    UIImage?
    @State private var imageSelection:  PhotosPickerItem?
    @State private var isUploadingPhoto = false

    enum EditSection: String, CaseIterable {
        case basic  = "Basic"
        case goals  = "Goals"
        case health = "Health"
        var icon: String {
            switch self {
            case .basic:  return "person.fill"
            case .goals:  return "target"
            case .health: return "heart.fill"
            }
        }
    }

    // Init from ClientRow (Supabase)
    init(client: ClientRow) {
        _firstName        = State(initialValue: client.firstName)
        _lastName         = State(initialValue: client.lastName)
        _city             = State(initialValue: client.city)
        _state            = State(initialValue: client.state)
        _fitnessLevel     = State(initialValue: client.fitnessLevel)
        _targetWeight     = State(initialValue: client.targetWeight.map { String(Int($0)) } ?? "")
        _selectedGoals    = State(initialValue: Set(client.fitnessGoals))
        _medicalConditions = State(initialValue: client.medicalConditions)
        _injuries         = State(initialValue: client.injuries)
        _allergies        = State(initialValue: client.allergies)
        _medications      = State(initialValue: client.medications)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                sectionTabBar.padding(.top, 8)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        switch selectedSection {
                        case .basic:  basicSection
                        case .goals:  goalsSection
                        case .health: healthSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Task { await saveProfile() } }) {
                    if isSaving {
                        ProgressView().tint(.tmGold)
                    } else {
                        Text("Save").fontWeight(.bold).foregroundColor(.tmGold)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear { loadProfilePhoto() }
        .onChange(of: imageSelection) { _, newItem in
            Task { await handlePhotoPick(newItem) }
        }
        .alert("Profile Saved!", isPresented: $showingSaveAlert) {
            Button("Done") { dismiss() }
        } message: {
            Text("Your profile has been updated.")
        }
        .alert("Save Failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "Something went wrong.")
        }
    }

    // MARK: - Photo

    private func loadProfilePhoto() {
        if let urlStr = auth.currentClient?.profileImageUrl,
           let url = URL(string: urlStr) {
            Task {
                if let data = try? await URLSession.shared.data(from: url).0,
                   let img = UIImage(data: data) {
                    await MainActor.run { profileImage = img }
                }
            }
        }
    }

    private func handlePhotoPick(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }

        let maxDim: CGFloat = 500
        let scale = min(maxDim / uiImage.size.width, maxDim / uiImage.size.height, 1)
        let newSize = CGSize(width: uiImage.size.width * scale,
                             height: uiImage.size.height * scale)
        let resized = UIGraphicsImageRenderer(size: newSize).image { _ in
            uiImage.draw(in: CGRect(origin: .zero, size: newSize))
        }

        await MainActor.run { profileImage = resized; isUploadingPhoto = true }

        if let jpegData = resized.jpegData(compressionQuality: 0.8) {
            do {
                _ = try await SupabaseAuthManager.shared.uploadProfilePhoto(imageData: jpegData)
            } catch {
                print("❌ Photo upload failed: \(error)")
            }
        }
        await MainActor.run { isUploadingPhoto = false }
    }

    // MARK: - Save to Supabase

    private func saveProfile() async {
        guard let client = auth.currentClient else { return }
        await MainActor.run { isSaving = true }

        struct ClientUpdate: Encodable {
            let firstName:         String
            let lastName:          String
            let city:              String
            let state:             String
            let fitnessLevel:      String
            let targetWeight:      Double?
            let fitnessGoals:      [String]
            let medicalConditions: String
            let injuries:          String
            let allergies:         String
            let medications:       String

            enum CodingKeys: String, CodingKey {
                case firstName         = "first_name"
                case lastName          = "last_name"
                case city, state
                case fitnessLevel      = "fitness_level"
                case targetWeight      = "target_weight"
                case fitnessGoals      = "fitness_goals"
                case medicalConditions = "medical_conditions"
                case injuries, allergies, medications
            }
        }

        let payload = ClientUpdate(
            firstName:         firstName,
            lastName:          lastName,
            city:              city,
            state:             state,
            fitnessLevel:      fitnessLevel,
            targetWeight:      Double(targetWeight),
            fitnessGoals:      Array(selectedGoals),
            medicalConditions: medicalConditions,
            injuries:          injuries,
            allergies:         allergies,
            medications:       medications
        )

        do {
            try await supabase
                .from("clients")
                .update(payload)
                .eq("id", value: client.id)
                .execute()

            // Refresh the local auth state
            await SupabaseAuthManager.shared.restoreSession()
            await MainActor.run { isSaving = false; showingSaveAlert = true }
        } catch {
            await MainActor.run {
                isSaving = false
                saveError = error.localizedDescription
            }
        }
    }

    // MARK: - Tab Bar

    private var sectionTabBar: some View {
        HStack(spacing: 0) {
            ForEach(EditSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedSection = section }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon).font(.caption)
                        Text(section.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    }
                    .foregroundColor(selectedSection == section ? .tmGold : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(selectedSection == section ? Color.tmGold.opacity(0.08) : Color.clear)
                    .overlay(Rectangle().frame(height: 2)
                        .foregroundColor(selectedSection == section ? .tmGold : .clear),
                             alignment: .bottom)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - Basic Section

    private var basicSection: some View {
        VStack(spacing: 16) {
            editCard(title: "PROFILE PHOTO", icon: "camera.fill") {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $imageSelection, matching: .images) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.06)).frame(width: 100, height: 100)
                            if let img = profileImage {
                                Image(uiImage: img).resizable().scaledToFill()
                                    .frame(width: 100, height: 100).clipShape(Circle())
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.title2).foregroundColor(.tmGold)
                                    Text("Add Photo")
                                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                                }
                            }
                            if isUploadingPhoto {
                                Circle().fill(Color.black.opacity(0.5)).frame(width: 100, height: 100)
                                ProgressView().tint(.tmGold)
                            } else {
                                Circle().fill(Color.tmGold).frame(width: 28, height: 28)
                                    .overlay(Image(systemName: "camera.fill")
                                        .font(.system(size: 11)).foregroundColor(.black))
                                    .offset(x: 34, y: 34)
                            }
                        }
                        .overlay(Circle().stroke(Color.tmGold.opacity(0.4), lineWidth: 2)
                            .frame(width: 100, height: 100))
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }

            editCard(title: "NAME", icon: "person.fill") {
                VStack(spacing: 12) {
                    editField("First Name", text: $firstName)
                    editField("Last Name",  text: $lastName)
                }
            }

            editCard(title: "LOCATION", icon: "mappin.circle.fill") {
                VStack(spacing: 12) {
                    editField("City",  text: $city)
                    editField("State", text: $state)
                }
            }

            nextButton("Next: Fitness Goals →") { selectedSection = .goals }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(spacing: 16) {
            editCard(title: "FITNESS LEVEL", icon: "chart.bar.fill") {
                VStack(spacing: 8) {
                    ForEach(["Beginner", "Intermediate", "Advanced", "Athlete"], id: \.self) { level in
                        Button(action: { fitnessLevel = level }) {
                            HStack(spacing: 12) {
                                Image(systemName: fitnessLevel == level
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(fitnessLevel == level ? .tmGold : .white.opacity(0.3))
                                Text(level).foregroundColor(.white).font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }

            editCard(title: "TARGET WEIGHT (lbs)", icon: "scalemass.fill") {
                editField("e.g. 180", text: $targetWeight, keyboard: .numberPad)
            }

            editCard(title: "FITNESS GOALS", icon: "target") {
                VStack(spacing: 0) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        Button(action: {
                            if selectedGoals.contains(goal.rawValue) {
                                selectedGoals.remove(goal.rawValue)
                            } else {
                                selectedGoals.insert(goal.rawValue)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: selectedGoals.contains(goal.rawValue)
                                      ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedGoals.contains(goal.rawValue)
                                                     ? .tmGold : .white.opacity(0.3))
                                    .font(.title3)
                                Text(goal.rawValue).foregroundColor(.white).font(.subheadline)
                                Spacer()
                            }
                            .padding(.vertical, 12).padding(.horizontal, 4)
                            .background(selectedGoals.contains(goal.rawValue)
                                ? Color.tmGold.opacity(0.07) : Color.clear)
                        }
                        Divider().background(Color.white.opacity(0.06))
                    }
                }
            }

            nextButton("Next: Health Info →") { selectedSection = .health }
        }
    }

    // MARK: - Health Section

    private var healthSection: some View {
        VStack(spacing: 16) {
            infoCard("This information helps trainers provide safe, personalised programming.")

            editCard(title: "MEDICAL CONDITIONS", icon: "cross.fill") {
                editTextEditor("e.g. Type 2 diabetes, high blood pressure, or None",
                               text: $medicalConditions)
            }

            editCard(title: "INJURIES", icon: "bandage.fill") {
                editTextEditor("e.g. Previous ACL repair, lower back pain, or None",
                               text: $injuries)
            }

            editCard(title: "ALLERGIES", icon: "allergens") {
                editTextEditor("e.g. Pollen, latex, or None", text: $allergies)
            }

            editCard(title: "MEDICATIONS", icon: "pills.fill") {
                editTextEditor("e.g. Metformin, or None", text: $medications)
            }

            Button(action: { Task { await saveProfile() } }) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView().tint(.black)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                        Text("SAVE PROFILE")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(RoundedRectangle(cornerRadius: 27)
                    .fill(Color.tmGold)
                    .shadow(color: Color.tmGold.opacity(0.4), radius: 10, y: 5))
            }
            .disabled(isSaving)
            .padding(.top, 8)
        }
    }

    // MARK: - Reusable Components

    private func editCard<Content: View>(title: String, icon: String,
                                         @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.tmGold).font(.caption)
                Text(title).font(.system(size: 11, weight: .bold)).tracking(1)
                    .foregroundColor(.white.opacity(0.6))
            }
            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)))
    }

    private func editField(_ label: String, text: Binding<String>,
                           keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.45))
            TextField("", text: text)
                .keyboardType(keyboard)
                .foregroundColor(.white)
                .accentColor(.tmGold)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private func editTextEditor(_ placeholder: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .frame(minHeight: 80)
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .accentColor(.tmGold)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.25)).font(.body)
                    .padding(.top, 18).padding(.leading, 14)
                    .allowsHitTesting(false)
            }
        }
    }

    private func infoCard(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundColor(.tmGold)
            Text(message).font(.caption).foregroundColor(.white.opacity(0.6)).lineSpacing(3)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.tmGold.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.tmGold.opacity(0.25), lineWidth: 1)))
    }

    private func nextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(label).font(.system(size: 13, weight: .semibold)).foregroundColor(.tmGold)
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.tmGold)
            }
        }
        .padding(.top, 4)
    }
}
