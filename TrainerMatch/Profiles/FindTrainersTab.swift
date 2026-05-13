//
//  FindTrainersTab.swift
//  TrainerMatch
//

import SwiftUI

struct FindTrainersTab: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var city = ""
    @State private var selectedSpecialties: Set<TrainerSpecialty> = []
    @State private var selectedServiceType: ServiceType = .inPerson
    @State private var selectedGender: String = "Any"
    @State private var showingSpecialtyPicker = false
    @State private var trainers: [TrainerRow] = []
    @State private var isLoading = false

    private var filteredTrainers: [TrainerRow] {
        trainers.filter { t in
            let cityMatch = city.trimmingCharacters(in: .whitespaces).isEmpty ||
                t.city.lowercased().contains(city.lowercased())
            let specialtyMatch = selectedSpecialties.isEmpty ||
                t.specialties.contains { s in selectedSpecialties.contains { $0.rawValue == s } }
            let serviceMatch: Bool = {
                switch selectedServiceType {
                case .inPerson: return t.serviceTypes.contains("In-Person") || t.serviceTypes.contains("Both")
                case .online:   return t.serviceTypes.contains("Online") || t.serviceTypes.contains("Both")
                case .both:     return true
                }
            }()
            let genderMatch = selectedGender == "Any" ||
                t.gender.lowercased() == selectedGender.lowercased()
            return cityMatch && specialtyMatch && serviceMatch && genderMatch
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(.tmGold)
                    TextField("City (e.g. Las Vegas)", text: $city)
                        .foregroundColor(.white).accentColor(.tmGold).autocorrectionDisabled()
                    if !city.isEmpty {
                        Button(action: { city = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(.white.opacity(0.35))
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.4), lineWidth: 1))

                Button(action: { showingSpecialtyPicker = true }) {
                    filterRow(
                        icon: "star.fill",
                        text: selectedSpecialties.isEmpty ? "Any Specialty" :
                            selectedSpecialties.count == 1 ? selectedSpecialties.first!.rawValue :
                            "\(selectedSpecialties.count) Specialties",
                        isDefault: selectedSpecialties.isEmpty
                    )
                }
                .sheet(isPresented: $showingSpecialtyPicker) {
                    SpecialtyPickerSheet(selected: $selectedSpecialties)
                }

                HStack(spacing: 10) {
                    Menu {
                        Button("In-Person") { selectedServiceType = .inPerson }
                        Button("Online")    { selectedServiceType = .online }
                        Button("Both")      { selectedServiceType = .both }
                    } label: {
                        filterRow(icon: "figure.run", text: selectedServiceType.rawValue, isDefault: false)
                    }
                    Menu {
                        Button("Any Gender") { selectedGender = "Any" }
                        Button("Male")       { selectedGender = "Male" }
                        Button("Female")     { selectedGender = "Female" }
                        Button("Non-binary") { selectedGender = "Non-binary" }
                    } label: {
                        filterRow(icon: "person.fill",
                                  text: selectedGender == "Any" ? "Any Gender" : selectedGender,
                                  isDefault: selectedGender == "Any")
                    }
                }

                if !selectedSpecialties.isEmpty || selectedGender != "Any" || !city.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if !city.isEmpty { activeChip(city, icon: "mappin.fill") { city = "" } }
                            if selectedGender != "Any" { activeChip(selectedGender, icon: "person.fill") { selectedGender = "Any" } }
                            ForEach(Array(selectedSpecialties), id: \.self) { s in
                                activeChip(s.rawValue, icon: "star.fill") { selectedSpecialties.remove(s) }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 14)

            Divider().background(Color.white.opacity(0.08))

            if isLoading {
                Spacer()
                ProgressView().tint(.tmGold).scaleEffect(1.3)
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let client = authManager.currentClientProfile {
                            MyTrainersSection(clientId: client.id, clientName: client.fullName)
                                .padding(.horizontal, 20).padding(.top, 14)
                        }

                        if trainers.isEmpty {
                            noTrainersState
                        } else if filteredTrainers.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.4)).padding(.top, 40)
                                Text("No Exact Matches").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                                Text("Try adjusting your filters.")
                                    .font(.subheadline).foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 20)
                        } else {
                            HStack {
                                Text("\(filteredTrainers.count) TRAINER\(filteredTrainers.count == 1 ? "" : "S") FOUND")
                                    .font(.system(size: 11, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
                                Spacer()
                            }
                            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 10)

                            LazyVStack(spacing: 12) {
                                ForEach(filteredTrainers) { trainer in
                                    NavigationLink(destination:
                                        SupabaseTrainerPublicProfileView(trainer: trainer)
                                    ) {
                                        SupabaseClientTrainerCard(trainer: trainer)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20).padding(.bottom, 40)
                        }
                    }
                }
            }
        }
        .task { await loadTrainers() }
    }

    private func loadTrainers() async {
        isLoading = true
        trainers = (try? await SupabaseAuthManager.shared.fetchAllTrainers()) ?? []
        isLoading = false
    }

    private func filterRow(icon: String, text: String, isDefault: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(.tmGold).font(.caption)
            Text(text).foregroundColor(isDefault ? .white.opacity(0.4) : .white)
                .font(.subheadline).lineLimit(1)
            Spacer()
            Image(systemName: "chevron.down").font(.caption2).foregroundColor(.white.opacity(0.35))
        }
        .padding(12).frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func activeChip(_ text: String, icon: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 8)).foregroundColor(.black)
            Text(text).font(.caption).fontWeight(.semibold).foregroundColor(.black)
            Button(action: onRemove) {
                Image(systemName: "xmark").font(.system(size: 8, weight: .bold)).foregroundColor(.black)
            }
        }
        .padding(.horizontal, 9).padding(.vertical, 5)
        .background(Capsule().fill(Color.tmGold))
    }

    private var noTrainersState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash").font(.system(size: 48))
                .foregroundColor(.tmGold.opacity(0.4)).padding(.top, 60)
            Text("No Trainers Yet").font(.title3).fontWeight(.bold).foregroundColor(.white)
            Text("Once trainers sign up, they'll appear here.")
                .font(.subheadline).foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }
}

// MARK: - Supabase Client Trainer Card

struct SupabaseClientTrainerCard: View {
    let trainer: TrainerRow
    @State private var profileImage: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                if let img = profileImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(Circle())
                } else {
                    Text(trainer.firstName.prefix(1).uppercased())
                        .font(.title2).fontWeight(.bold).foregroundColor(.black)
                }
            }
            .overlay(Circle().stroke(Color.tmGold.opacity(0.4), lineWidth: 2))

            VStack(alignment: .leading, spacing: 5) {
                if let biz = trainer.businessName, !biz.isEmpty {
                    Text(biz).font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text(trainer.fullName).font(.caption).foregroundColor(.white.opacity(0.55))
                } else {
                    Text(trainer.fullName)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                }
                if !trainer.city.isEmpty {
                    Label("\(trainer.city), \(trainer.state)", systemImage: "mappin.fill")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                }
                HStack(spacing: 6) {
                    ForEach(trainer.specialties.prefix(2), id: \.self) { s in
                        Text(s).font(.system(size: 9, weight: .semibold)).foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color.tmGold))
                    }
                    if trainer.specialties.count > 2 {
                        Text("+\(trainer.specialties.count - 2)")
                            .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let rate = trainer.hourlyRate {
                    Text("$\(Int(rate))/hr")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                }
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1)))
        .task {
            if let urlStr = trainer.profileImageUrl,
               let url = URL(string: urlStr),
               let data = try? Data(contentsOf: url),
               let img = UIImage(data: data) {
                profileImage = img
            }
        }
    }
}

// MARK: - Specialty Picker Sheet

struct SpecialtyPickerSheet: View {
    @Binding var selected: Set<TrainerSpecialty>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(TrainerSpecialty.allCases, id: \.self) { specialty in
                            Button(action: {
                                if selected.contains(specialty) { selected.remove(specialty) }
                                else { selected.insert(specialty) }
                            }) {
                                HStack {
                                    Text(specialty.rawValue)
                                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: selected.contains(specialty)
                                          ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selected.contains(specialty) ? .tmGold : .white.opacity(0.3))
                                }
                                .padding(14)
                                .background(RoundedRectangle(cornerRadius: 12)
                                    .fill(selected.contains(specialty) ? Color.tmGold.opacity(0.1) : Color.white.opacity(0.05))
                                    .overlay(RoundedRectangle(cornerRadius: 12)
                                        .stroke(selected.contains(specialty) ? Color.tmGold.opacity(0.4) : Color.clear, lineWidth: 1)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Select Specialties")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") { selected.removeAll() }.foregroundColor(.tmGold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.font(.system(size: 14, weight: .bold)).foregroundColor(.tmGold)
                }
            }
        }
        .tint(.tmGold)
    }
}

// MARK: - No Match Apology View

struct NoMatchApologyView: View {
    let gender: String
    let city: String
    let specialties: Set<TrainerSpecialty>
    let serviceType: ServiceType
    let allTrainers: [SavedTrainerProfile]

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48)).foregroundColor(.tmGold.opacity(0.4)).padding(.top, 40)
            VStack(spacing: 8) {
                Text("No Exact Matches").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                Text("No trainers match all your current filters.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Client Trainer Card (old - kept for compat)

struct ClientTrainerCard: View {
    let trainer: SavedTrainerProfile
    @State private var profileImage: UIImage?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.tmGold, .tmGoldDark],
                                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 64, height: 64)
                if let img = profileImage {
                    Image(uiImage: img).resizable().scaledToFill()
                        .frame(width: 64, height: 64).clipShape(Circle())
                } else {
                    Text(trainer.firstName.prefix(1))
                        .font(.title2).fontWeight(.bold).foregroundColor(.black)
                }
            }
            .overlay(Circle().stroke(Color.tmGold.opacity(0.4), lineWidth: 2))

            VStack(alignment: .leading, spacing: 5) {
                Text(trainer.businessName ?? "\(trainer.firstName) \(trainer.lastName)")
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white).lineLimit(1)
                if trainer.businessName != nil {
                    Text("\(trainer.firstName) \(trainer.lastName)")
                        .font(.caption).foregroundColor(.white.opacity(0.55))
                }
                if !trainer.city.isEmpty {
                    Label("\(trainer.city), \(trainer.state)", systemImage: "mappin.fill")
                        .font(.caption2).foregroundColor(.white.opacity(0.5))
                }
                HStack(spacing: 6) {
                    ForEach(Array(trainer.specialties.prefix(2)), id: \.self) { s in
                        Text(s.rawValue).font(.system(size: 9, weight: .semibold)).foregroundColor(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Capsule().fill(Color.tmGold))
                    }
                    if trainer.specialties.count > 2 {
                        Text("+\(trainer.specialties.count - 2)")
                            .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if let rate = trainer.hourlyRate {
                    Text("$\(Int(rate))/hr").font(.system(size: 13, weight: .bold)).foregroundColor(.tmGold)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1)))
        .onAppear {
            profileImage = ProfileImageManager.shared.loadImage(
                forKey: ProfileImageManager.profileImageKey(for: trainer.id))
        }
    }
}
