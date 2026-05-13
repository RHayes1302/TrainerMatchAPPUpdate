//
//  NearbyTrainers.swift
//  TrainerMatch
//

import SwiftUI

struct NearbyTrainersView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var selectedType: ServiceType? = nil
    @State private var trainers: [TrainerRow] = []
    @State private var isLoading = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                searchBar
                filterBar
                Divider().background(Color.white.opacity(0.08))
                if isLoading {
                    Spacer()
                    ProgressView().tint(.tmGold).scaleEffect(1.3)
                    Spacer()
                } else {
                    resultsList
                }
            }
        }
        .navigationTitle("Trainers Nearby")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.tmGold)
                }
            }
        }
        .task { await loadTrainers() }
        .onAppear { locationManager.requestLocation() }
    }

    private func loadTrainers() async {
        isLoading = true
        trainers = (try? await SupabaseAuthManager.shared.fetchAllTrainers()) ?? []
        isLoading = false
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.4))
            TextField("Search trainers or specialties...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All",       selected: selectedType == nil)       { selectedType = nil }
                filterChip("In-Person", selected: selectedType == .inPerson) { selectedType = .inPerson }
                filterChip("Online",    selected: selectedType == .online)   { selectedType = .online }
                filterChip("Both",      selected: selectedType == .both)     { selectedType = .both }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 10)
    }

    private var resultsList: some View {
        let filtered = filteredTrainers()
        return Group {
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        GymAdBannerView()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        Divider()
                            .background(Color.white.opacity(0.08))
                            .padding(.horizontal, 16)
                        trainerGridRows(trainers: filtered)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            GymAdBannerView().padding(.horizontal, 16).padding(.top, 10)
            Image(systemName: "person.2.slash")
                .font(.system(size: 52)).foregroundColor(.white.opacity(0.1)).padding(.top, 40)
            Text("No trainers found").font(.title3).foregroundColor(.white.opacity(0.4))
            Text("Try a different search or filter.").font(.subheadline).foregroundColor(.white.opacity(0.25))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func filteredTrainers() -> [TrainerRow] {
        trainers.filter { trainer in
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let nameMatch = trainer.fullName.lowercased().contains(q)
                let bizMatch  = (trainer.businessName ?? "").lowercased().contains(q)
                let specMatch = trainer.specialties.contains { $0.lowercased().contains(q) }
                if !nameMatch && !bizMatch && !specMatch { return false }
            }
            if let type = selectedType {
                if !trainer.serviceTypes.contains(type.rawValue) &&
                   !trainer.serviceTypes.contains("Both") { return false }
            }
            return true
        }
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Trainer Grid

private struct trainerGridRows: View {
    let trainers: [TrainerRow]
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(trainers.count) TRAINER\(trainers.count == 1 ? "" : "S")")
                .font(.system(size: 10, weight: .black)).tracking(1.5)
                .foregroundColor(.tmGold)
                .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(trainers) { trainer in
                    NavigationLink(destination: SupabaseTrainerPublicProfileView(trainer: trainer)) {
                        SupabaseTrainerNearbyCard(trainer: trainer)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 30)
        }
    }
}

// MARK: - Supabase Trainer Nearby Card

struct SupabaseTrainerNearbyCard: View {
    let trainer: TrainerRow
    @State private var profileImage: UIImage? = nil

    private var primarySpecialty: String {
        trainer.specialties.first ?? "Personal Training"
    }

    private var serviceLabel: String {
        trainer.serviceTypes.first ?? "In-Person"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [Color.tmGold.opacity(0.25), Color.black],
                    startPoint: .top, endPoint: .bottom)
                .frame(height: 110)
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.tmGold.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.tmGold, lineWidth: 1.5))
                        if let img = profileImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                                .frame(width: 60, height: 60).clipShape(Circle())
                        } else {
                            Text(trainer.firstName.prefix(1).uppercased())
                                .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                        }
                    }
                    Text(serviceLabel)
                        .font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.tmGold))
                }
            }
            .task {
                if let urlStr = trainer.profileImageUrl,
                   let url = URL(string: urlStr),
                   let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    profileImage = img
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Business name + trainer name
                if let biz = trainer.businessName, !biz.isEmpty {
                    Text(biz)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text(trainer.fullName)
                        .font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                } else {
                    Text(trainer.fullName)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(1)
                }
                Text(primarySpecialty.uppercased())
                    .font(.system(size: 9, weight: .black)).tracking(0.5)
                    .foregroundColor(.tmGold).lineLimit(1)
                if !trainer.city.isEmpty {
                    Label(trainer.city, systemImage: "mappin.circle.fill")
                        .font(.system(size: 9)).foregroundColor(.white.opacity(0.35)).lineLimit(1)
                }
                if let rate = trainer.hourlyRate {
                    Text(String(format: "$%.0f/hr", rate))
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.white.opacity(0.04))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Keep old card for backward compat
struct TrainerNearbyCard: View {
    let trainer: SavedTrainerProfile
    @State private var profileImage: UIImage? = nil

    private var primarySpecialty: String {
        trainer.specialties.first?.rawValue ?? "Personal Training"
    }
    private var initials: String {
        "\(trainer.firstName.prefix(1))\(trainer.lastName.prefix(1))".uppercased()
    }
    private var serviceLabel: String {
        trainer.serviceTypes.first?.rawValue ?? "In-Person"
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                LinearGradient(colors: [Color.tmGold.opacity(0.25), Color.black],
                               startPoint: .top, endPoint: .bottom).frame(height: 110)
                VStack(spacing: 6) {
                    ZStack {
                        Circle().fill(Color.tmGold.opacity(0.2)).frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.tmGold, lineWidth: 1.5))
                        if let img = profileImage {
                            Image(uiImage: img).resizable().scaledToFill()
                                .frame(width: 60, height: 60).clipShape(Circle())
                        } else {
                            Text(initials).font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                        }
                    }
                    Text(serviceLabel).font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Color.tmGold))
                }
            }
            .onAppear {
                profileImage = ProfileImageManager.shared.loadImage(
                    forKey: ProfileImageManager.profileImageKey(for: trainer.id))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(trainer.businessName ?? trainer.fullName)
                    .font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(1)
                if trainer.businessName != nil {
                    Text(trainer.fullName)
                        .font(.system(size: 10)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                }
                Text(primarySpecialty.uppercased())
                    .font(.system(size: 9, weight: .black)).tracking(0.5)
                    .foregroundColor(.tmGold).lineLimit(1)
                if !trainer.city.isEmpty {
                    Label(trainer.city, systemImage: "mappin.circle.fill")
                        .font(.system(size: 9)).foregroundColor(.white.opacity(0.35)).lineLimit(1)
                }
                if let rate = trainer.hourlyRate {
                    Text(String(format: "$%.0f/hr", rate))
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10).background(Color.white.opacity(0.04))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.tmGold.opacity(0.2), lineWidth: 1))
    }
}

extension SavedTrainerProfile {
    func toTrainerProfile() -> TrainerProfile {
        TrainerProfile(
            id: id, userId: id,
            businessName: businessName ?? fullName,
            bio: bio.isEmpty ? nil : bio,
            specialties: specialties,
            certifications: certifications.map { $0.rawValue },
            yearsOfExperience: yearsOfExperience,
            serviceTypes: serviceTypes,
            location: TrainerLocation(city: city, state: state),
            hourlyRate: hourlyRate,
            profileImageURL: nil,
            websiteURL: nil, instagramHandle: nil,
            isVerified: false, rating: 5.0, totalReviews: 0
        )
    }
}
