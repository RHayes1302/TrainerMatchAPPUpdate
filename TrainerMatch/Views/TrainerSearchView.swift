//
//  TrainerSearchView.swift
//  TrainerMatch
//

import SwiftUI

struct TrainerSearchView: View {
    @Environment(\.dismiss) var dismiss

    @State private var city                  = ""
    @State private var selectedSpecialty:   TrainerSpecialty? = nil
    @State private var selectedServiceType:  ServiceType      = .inPerson
    @State private var selectedGender        = "Any"
    @State private var showingResults        = false
    @State private var supabaseTrainers:    [TrainerRow] = []
    @State private var isLoading             = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.tmGold, Color.tmGoldDark],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    VStack(spacing: 24) {
                        TrainerMatchLogo(size: .large)
                            .shadow(color: .tmGold.opacity(0.3), radius: 20, x: 0, y: 10)

                        VStack(spacing: 8) {
                            Text("It's Match Time!")
                                .font(.system(size: 42, weight: .bold)).italic().foregroundColor(.black)
                            Text("Tweak the filters to match with trainers who fit your goals.")
                                .font(.subheadline).foregroundColor(.black.opacity(0.8))
                                .multilineTextAlignment(.center).padding(.horizontal)
                        }

                        VStack(spacing: 16) {
                            TextField("Enter City", text: $city)
                                .padding().background(Color.white).cornerRadius(25)
                                .overlay(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))

                            Menu {
                                Button("Any Specialty") { selectedSpecialty = nil }
                                ForEach(TrainerSpecialty.allCases.prefix(20), id: \.self) { s in
                                    Button(s.rawValue) { selectedSpecialty = s }
                                }
                            } label: {
                                HStack {
                                    Text(selectedSpecialty?.rawValue ?? "Specialty")
                                        .foregroundColor(selectedSpecialty == nil ? .gray : .black)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(.gray)
                                }
                                .padding().background(Color.white).cornerRadius(25)
                                .overlay(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            }

                            Menu {
                                Button("In-Person") { selectedServiceType = .inPerson }
                                Button("Online")    { selectedServiceType = .online }
                                Button("Both")      { selectedServiceType = .both }
                            } label: {
                                HStack {
                                    Text(selectedServiceType.rawValue).foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(.gray)
                                }
                                .padding().background(Color.white).cornerRadius(25)
                                .overlay(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            }

                            Menu {
                                Button("Any")    { selectedGender = "Any" }
                                Button("Male")   { selectedGender = "Male" }
                                Button("Female") { selectedGender = "Female" }
                            } label: {
                                HStack {
                                    Text(selectedGender == "Any" ? "Any Gender" : selectedGender)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down").foregroundColor(.gray)
                                }
                                .padding().background(Color.white).cornerRadius(25)
                                .overlay(RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            }

                            Button(action: {
                                Task {
                                    isLoading = true
                                    supabaseTrainers = (try? await SupabaseAuthManager.shared.searchTrainers(
                                        city: city.isEmpty ? nil : city,
                                        specialties: selectedSpecialty.map { [$0.rawValue] } ?? [],
                                        serviceType: selectedServiceType == .both ? nil : selectedServiceType.rawValue,
                                        gender: selectedGender == "Any" ? nil : selectedGender
                                    )) ?? []
                                    isLoading = false
                                    showingResults = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if isLoading { ProgressView().tint(.white).scaleEffect(0.8) }
                                    Text("SHOW MATCHES")
                                        .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(RoundedRectangle(cornerRadius: 27).fill(Color.black))
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding(.vertical, 40)
                    .background(RoundedRectangle(cornerRadius: 30).fill(Color.white))
                    .padding(.horizontal, 20)
                    Spacer().frame(height: 60)
                }
            }
        }
        .navigationTitle("Find Trainers")
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
        .sheet(isPresented: $showingResults) {
            SupabaseTrainerResultsView(trainers: supabaseTrainers)
        }
    }
}

// MARK: - Supabase Results Sheet

struct SupabaseTrainerResultsView: View {
    @Environment(\.dismiss) var dismiss
    let trainers: [TrainerRow]
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 12) {
                            TrainerMatchLogo(size: .medium)
                                .shadow(color: .tmGold.opacity(0.3), radius: 15, x: 0, y: 5)
                            Text("Match Results")
                                .font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            Text("\(trainers.count) trainer\(trainers.count == 1 ? "" : "s") found")
                                .font(.subheadline).foregroundColor(.tmGold)
                        }
                        .padding(.top, 30).padding(.bottom, 10)

                        GymAdBannerView().padding(.horizontal, 16).padding(.bottom, 10)

                        if trainers.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 48)).foregroundColor(.white.opacity(0.15))
                                Text("No matches found").font(.title3).foregroundColor(.white.opacity(0.4))
                                Text("Try adjusting your filters.")
                                    .font(.subheadline).foregroundColor(.white.opacity(0.25))
                            }
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(trainers) { trainer in
                                    NavigationLink(destination:
                                        SupabaseTrainerPublicProfileView(trainer: trainer)) {
                                        SupabaseTrainerNearbyCard(trainer: trainer)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Keep old results for backward compat
struct TrainerResultsView: View {
    @Environment(\.dismiss) var dismiss
    let city: String
    let specialty: TrainerSpecialty?
    let serviceType: ServiceType
    let gender: String
    let allTrainers: [SavedTrainerProfile]

    private var results: [SavedTrainerProfile] {
        allTrainers.filter { matchesFilters($0) }
    }

    private func matchesFilters(_ t: SavedTrainerProfile) -> Bool {
        if !city.trimmingCharacters(in: .whitespaces).isEmpty {
            if !t.city.localizedCaseInsensitiveContains(city) { return false }
        }
        if let s = specialty { if !t.specialties.contains(s) { return false } }
        if gender != "Any" {
            if !t.gender.isEmpty && t.gender.lowercased() != gender.lowercased() { return false }
        }
        return true
    }

    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        VStack(spacing: 12) {
                            TrainerMatchLogo(size: .medium)
                            Text("Match Results").font(.system(size: 26, weight: .bold)).foregroundColor(.white)
                            Text("\(results.count) trainer\(results.count == 1 ? "" : "s") found")
                                .font(.subheadline).foregroundColor(.tmGold)
                        }
                        .padding(.top, 30).padding(.bottom, 10)
                        GymAdBannerView().padding(.horizontal, 16).padding(.bottom, 10)
                        if results.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 48)).foregroundColor(.white.opacity(0.15))
                                Text("No matches found").font(.title3).foregroundColor(.white.opacity(0.4))
                            }.padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(results) { trainer in
                                    NavigationLink(destination: TrainerPublicProfileView(trainer: trainer)) {
                                        TrainerNearbyCard(trainer: trainer)
                                    }.buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16).padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left"); Text("Back")
                        }.foregroundColor(.tmGold)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    NavigationView { TrainerSearchView() }
}
