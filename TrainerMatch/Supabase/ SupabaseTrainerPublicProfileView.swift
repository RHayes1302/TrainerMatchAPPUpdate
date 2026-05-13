//
//  SupabaseTrainerPublicProfileView.swift
//  TrainerMatch
//

import SwiftUI

struct SupabaseTrainerPublicProfileView: View {
    let trainer: TrainerRow

    @Environment(\.dismiss) var dismiss
    @State private var profileImage: UIImage?
    @State private var bannerImage:  UIImage?
    @State private var selectedTab: SPubTab = .about

    enum SPubTab: String, CaseIterable {
        case about   = "About"
        case results = "Results"
        case contact = "Contact"

        var icon: String {
            switch self {
            case .about:   return "person.fill"
            case .results: return "trophy.fill"
            case .contact: return "envelope.fill"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    identityBlock
                    quickStatsBar
                    tabBar
                    tabContent.padding(.bottom, 60)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black.opacity(0.9), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.tmGold)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").fontWeight(.semibold)
                        Text("Back")
                    }
                    .foregroundColor(.tmGold)
                }
            }
            ToolbarItem(placement: .principal) {
                Text(trainer.businessName ?? trainer.firstName)
                    .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadImages() }
    }

    // MARK: - Load Images ✅ fixed to use URLSession

    private func loadImages() async {
        if let urlStr = trainer.profileImageUrl,
           let url = URL(string: urlStr),
           let data = try? await URLSession.shared.data(from: url).0,
           let img = UIImage(data: data) {
            await MainActor.run { profileImage = img }
        }
        if let urlStr = trainer.bannerImageUrl,
           let url = URL(string: urlStr),
           let data = try? await URLSession.shared.data(from: url).0,
           let img = UIImage(data: data) {
            await MainActor.run { bannerImage = img }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Group {
                    if let banner = bannerImage {
                        Image(uiImage: banner).resizable().scaledToFill()
                    } else {
                        LinearGradient(
                            colors: [Color.tmGold, Color.tmGoldDark],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                }
                .frame(height: 200).clipped()
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.6)],
                    startPoint: .center, endPoint: .bottom)
                .frame(height: 200)
            }
            .frame(height: 200)

            HStack {
                ZStack {
                    Circle().fill(Color.black).frame(width: 108, height: 108)
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.tmGold.opacity(0.6), Color.tmGoldDark.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 104, height: 104)
                    if let img = profileImage {
                        Image(uiImage: img).resizable().scaledToFill()
                            .frame(width: 100, height: 100).clipShape(Circle())
                    } else {
                        Text(trainer.firstName.prefix(1).uppercased())
                            .font(.system(size: 38, weight: .black)).foregroundColor(.black)
                    }
                }
                .offset(y: -28).padding(.leading, 22)
                Spacer()
            }
            .frame(height: 54).background(Color.black)
        }
    }

    // MARK: - Identity Block

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    if let biz = trainer.businessName, !biz.isEmpty {
                        Text(biz)
                            .font(.system(size: 24, weight: .black)).foregroundColor(.white)
                        Text(trainer.fullName)
                            .font(.subheadline).foregroundColor(.white.opacity(0.55))
                    } else {
                        Text(trainer.fullName)
                            .font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    }
                    if !trainer.city.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.fill").font(.caption2).foregroundColor(.tmGold)
                            Text("\(trainer.city), \(trainer.state)")
                                .font(.caption).foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                Spacer()
                VStack(spacing: 6) {
                    if let rate = trainer.hourlyRate {
                        VStack(spacing: 2) {
                            Text("$\(Int(rate))")
                                .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                            Text("/ hour")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tmGold.opacity(0.35), lineWidth: 1)))
                    }
                    if let rate = trainer.monthlyRate {
                        VStack(spacing: 2) {
                            Text("$\(Int(rate))")
                                .font(.system(size: 18, weight: .black)).foregroundColor(.tmGold)
                            Text("/ month")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.1))
                                .overlay(RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.tmGold.opacity(0.35), lineWidth: 1)))
                    }
                }
            }
            .padding(.horizontal, 22).padding(.bottom, 18)
        }
        .background(Color.black)
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        HStack(spacing: 0) {
            sStatCell(value: "\(trainer.yearsOfExperience)+",
                      label: "Years Exp", icon: "clock.fill")
            sDivider
            sStatCell(value: "\(trainer.specialties.count)",
                      label: "Specialties", icon: "star.fill")
            sDivider
            sStatCell(value: "\(trainer.certifications.count)",
                      label: "Certs", icon: "checkmark.seal.fill")
            sDivider
            sStatCell(value: serviceLabel,
                      label: "Service", icon: "figure.run")
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
    }

    private var sDivider: some View {
        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 30)
    }

    private func sStatCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundColor(.tmGold)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.45)).tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    private var serviceLabel: String {
        if trainer.serviceTypes.contains("Both") { return "Both" }
        if trainer.serviceTypes.contains("Online") { return "Online" }
        return "In-Person"
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(SPubTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
                }) {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon).font(.caption)
                        Text(tab.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold)).tracking(0.8)
                    }
                    .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.tmGold.opacity(0.08) : Color.clear)
                    .overlay(Rectangle().frame(height: 2)
                        .foregroundColor(selectedTab == tab ? .tmGold : .clear),
                             alignment: .bottom)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .about:   aboutTab
        case .results: resultsTab
        case .contact: contactTab
        }
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 24) {

            if !trainer.bio.isEmpty {
                sSection(title: "About", icon: "text.quote") {
                    Text(trainer.bio)
                        .font(.body).foregroundColor(.white.opacity(0.85))
                        .lineSpacing(6).fixedSize(horizontal: false, vertical: true)
                }
            }

            if !trainer.serviceTypes.isEmpty {
                sSection(title: "Training Format", icon: "figure.run.circle.fill") {
                    VStack(spacing: 10) {
                        ForEach(trainer.serviceTypes, id: \.self) { type in
                            HStack(spacing: 12) {
                                Image(systemName: type == "Online" ? "wifi" :
                                        type == "Both" ? "arrow.left.arrow.right" : "location.fill")
                                    .foregroundColor(.tmGold).frame(width: 20)
                                Text(type == "Both" ? "In-Person & Online" : type)
                                    .font(.subheadline).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.tmGold).font(.caption)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.05)))
                        }
                    }
                }
            }

            if !trainer.specialties.isEmpty {
                sSection(title: "Specialties", icon: "star.fill") {
                    PublicChipGrid(items: trainer.specialties)
                }
            }

            if !trainer.certifications.isEmpty {
                sSection(title: "Certifications", icon: "checkmark.seal.fill") {
                    PublicChipGrid(items: trainer.certifications)
                }
            }

            if !trainer.schools.isEmpty {
                sSection(title: "Education & Training", icon: "graduationcap.fill") {
                    PublicChipGrid(items: trainer.schools)
                }
            }

            if trainer.hourlyRate != nil || trainer.monthlyRate != nil {
                sSection(title: "Pricing", icon: "dollarsign.circle.fill") {
                    VStack(spacing: 10) {
                        if let h = trainer.hourlyRate {
                            sRateRow(label: "In-Person Session", value: "$\(Int(h)) / hour")
                        }
                        if let m = trainer.monthlyRate {
                            sRateRow(label: "Virtual Monthly", value: "$\(Int(m)) / month")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.top, 24)
    }

    // MARK: - Results Tab

    private var resultsTab: some View {
        PublicResultsTab(trainerId: trainer.id.uuidString)
            .padding(.top, 20)
    }

    // MARK: - Contact Tab

    private var contactTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Get in Touch")
                    .font(.system(size: 22, weight: .black)).foregroundColor(.white)
                Text("Send \(trainer.firstName) a message and they'll get back to you shortly.")
                    .font(.subheadline).foregroundColor(.white.opacity(0.55))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
            PublicContactForm(trainerName: trainer.firstName)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
    }

    // MARK: - Helpers

    private func sSection<Content: View>(
        title: String, icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
                Text(title).font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white).tracking(0.3)
            }
            content()
        }
    }

    private func sRateRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.white.opacity(0.65))
            Spacer()
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.tmGold)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
    }
}
