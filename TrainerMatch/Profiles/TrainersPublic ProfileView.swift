//
//  TrainerPublicProfileView.swift
//  TrainerMatch
//
//  Clean public-facing trainer profile for clients.
//  Results gallery now uses SBTrainerResultsStore (Supabase).
//

import SwiftUI

struct TrainerPublicProfileView: View {
    let trainer: SavedTrainerProfile

    @Environment(\.dismiss) var dismiss
    @State private var profileImage: UIImage?
    @State private var bannerImage:  UIImage?
    @State private var selectedTab: PublicTab = .about
    @ObservedObject private var store = TrainerConnectionStore.shared
    @ObservedObject private var authManager = AuthManager.shared

    enum PublicTab: String, CaseIterable {
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
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up").foregroundColor(.tmGold)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadPhotos() }
    }

    // MARK: - Load Photos (try Supabase URL first, fall back to local)

    private func loadPhotos() async {
        // Try fetching the trainer row to get Supabase URLs
        if let trainers = try? await SupabaseAuthManager.shared.fetchAllTrainers(),
           let row = trainers.first(where: { $0.id.uuidString == trainer.id }) {
            if let urlStr = row.profileImageUrl, let url = URL(string: urlStr),
               let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                await MainActor.run { profileImage = img }
            }
            if let urlStr = row.bannerImageUrl, let url = URL(string: urlStr),
               let data = try? await URLSession.shared.data(from: url).0,
               let img = UIImage(data: data) {
                await MainActor.run { bannerImage = img }
            }
            return
        }
        // Fall back to local
        await MainActor.run {
            profileImage = ProfileImageManager.shared.loadImage(
                forKey: ProfileImageManager.profileImageKey(for: trainer.id))
            bannerImage = ProfileImageManager.shared.loadImage(
                forKey: "banner_\(trainer.id)")
        }
    }

    // MARK: - Hero / Banner

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
                        .overlay(
                            GeometryReader { geo in
                                ForEach(0..<8) { i in
                                    Circle()
                                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                                        .frame(width: CGFloat(i * 50 + 60))
                                        .offset(x: -20, y: geo.size.height * 0.3)
                                }
                            }
                        )
                    }
                }
                .frame(height: 200).clipped()
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.6)],
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
                        Text(trainer.firstName.prefix(1))
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

    private var reviewCountLabel: String {
        "(" + String(reviewCount) + (reviewCount == 1 ? " review)" : " reviews)")
    }
    private var ratingLabel: String { String(format: "%.1f", avgRating) }
    private var reviewSummaryRow: some View {
        HStack(spacing: 6) {
            starRow(rating: avgRating, size: 13)
            Text(ratingLabel).font(.system(size: 12, weight: .bold)).foregroundColor(.tmGold)
            Text(reviewCountLabel).font(.caption).foregroundColor(.white.opacity(0.4))
            Image(systemName: "chevron.right").font(.caption2).foregroundColor(.white.opacity(0.3))
        }
    }
    private var trainerDisplayName: String { trainer.businessName ?? "\(trainer.firstName) \(trainer.lastName)" }
    private var trainerFullName: String { "\(trainer.firstName) \(trainer.lastName)" }
    private var verifyStatus: VerificationStatus { ReviewStore.shared.verificationStatus(forTrainer: trainer.id) }
    private var avgRating: Double { ReviewStore.shared.averageRating(forTrainer: trainer.id) }
    private var reviewCount: Int  { ReviewStore.shared.reviewCount(forTrainer: trainer.id) }

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(trainerDisplayName)
                        .font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    if trainer.businessName != nil {
                        Text(trainerFullName).font(.subheadline).foregroundColor(.white.opacity(0.55))
                    }
                    VerificationBadge(status: verifyStatus)
                    if reviewCount > 0 {
                        NavigationLink(destination: TrainerReviewsListView(trainerId: trainer.id)) {
                            reviewSummaryRow
                        }
                        .buttonStyle(.plain)
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
                if let rate = trainer.hourlyRate {
                    VStack(spacing: 2) {
                        Text("$\(Int(rate))").font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
                        Text("/ hour").font(.system(size: 10, weight: .semibold)).foregroundColor(.white.opacity(0.45))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.tmGold.opacity(0.1))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.tmGold.opacity(0.35), lineWidth: 1)))
                }
            }
            .padding(.horizontal, 22).padding(.bottom, 18)
        }
        .background(Color.black)
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        HStack(spacing: 0) {
            statCell(value: "\(trainer.yearsOfExperience)+", label: "Years Exp", icon: "clock.fill")
            dividerLine
            statCell(value: "\(trainer.specialties.count)", label: "Specialties", icon: "star.fill")
            dividerLine
            statCell(value: "\(trainer.certifications.count)", label: "Certs", icon: "checkmark.seal.fill")
            dividerLine
            statCell(value: serviceLabel, label: "Service", icon: "figure.run")
        }
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
    }

    private var dividerLine: some View {
        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 1, height: 30)
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundColor(.tmGold)
            Text(value).font(.system(size: 14, weight: .bold)).foregroundColor(.white)
            Text(label).font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.45)).tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }

    private var serviceLabel: String {
        if trainer.serviceTypes.contains(.both) { return "In-Person & Online" }
        if trainer.serviceTypes.contains(.inPerson) && trainer.serviceTypes.contains(.online) { return "In-Person & Online" }
        if trainer.serviceTypes.contains(.online) { return "Online" }
        return "In-Person"
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(PublicTab.allCases, id: \.self) { tab in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab } }) {
                    VStack(spacing: 5) {
                        Image(systemName: tab.icon).font(.caption)
                        Text(tab.rawValue.uppercased()).font(.system(size: 9, weight: .bold)).tracking(0.8)
                    }
                    .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.4))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.tmGold.opacity(0.08) : Color.clear)
                    .overlay(Rectangle().frame(height: 2)
                        .foregroundColor(selectedTab == tab ? .tmGold : .clear), alignment: .bottom)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.white.opacity(0.08)), alignment: .bottom)
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
                publicSection(title: "About", icon: "text.quote") {
                    Text(trainer.bio).font(.body).foregroundColor(.white.opacity(0.85))
                        .lineSpacing(6).fixedSize(horizontal: false, vertical: true)
                }
            }
            if !trainer.serviceTypes.isEmpty {
                publicSection(title: "Training Format", icon: "figure.run.circle.fill") {
                    VStack(spacing: 10) {
                        ForEach(trainer.serviceTypes, id: \.self) { type in
                            HStack(spacing: 12) {
                                Image(systemName: type == .online ? "wifi" : type == .both ? "arrow.left.arrow.right" : "location.fill")
                                    .foregroundColor(.tmGold).frame(width: 20)
                                Text(type == .both ? "In-Person & Online" : type.rawValue)
                                    .font(.subheadline).foregroundColor(.white)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.tmGold).font(.caption)
                            }
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
                        }
                    }
                }
            }
            if !trainer.specialties.isEmpty {
                publicSection(title: "Specialties", icon: "star.fill") {
                    PublicChipGrid(items: trainer.specialties.map(\.rawValue))
                }
            }
            if !trainer.certifications.isEmpty {
                publicSection(title: "Certifications", icon: "checkmark.seal.fill") {
                    PublicChipGrid(items: trainer.certifications.map(\.rawValue))
                }
            }
            if !trainer.schools.isEmpty {
                publicSection(title: "Education & Training", icon: "graduationcap.fill") {
                    PublicChipGrid(items: trainer.schools.map(\.rawValue))
                }
            }
            if trainer.hourlyRate != nil || trainer.monthlyRate != nil {
                publicSection(title: "Pricing", icon: "dollarsign.circle.fill") {
                    VStack(spacing: 10) {
                        if let h = trainer.hourlyRate {
                            ratRow(label: "In-Person Session", value: "$\(Int(h)) / hour")
                        }
                        if let m = trainer.monthlyRate {
                            ratRow(label: "Virtual Monthly", value: "$\(Int(m)) / month")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20).padding(.top, 24)
    }

    // MARK: - Results Tab (✅ now uses Supabase via PublicResultsTab)

    private var resultsTab: some View {
        PublicResultsTab(trainerId: trainer.id).padding(.top, 20)
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
            TrainerRequestButton(trainer: trainer)
        }
        .padding(.horizontal, 20).padding(.top, 24).padding(.bottom, 40)
    }

    private func publicSection<Content: View>(title: String, icon: String,
                                              @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.caption).foregroundColor(.tmGold)
                Text(title).font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white).tracking(0.3)
            }
            content()
        }
    }

    private func ratRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.white.opacity(0.65))
            Spacer()
            Text(value).font(.system(size: 15, weight: .bold)).foregroundColor(.tmGold)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))
    }
}

// MARK: - Public Contact Form

struct PublicContactForm: View {
    let trainerName: String
    @State private var name    = ""
    @State private var phone   = ""
    @State private var email   = ""
    @State private var message = ""
    @State private var agreed  = false
    @State private var sent    = false

    var body: some View {
        VStack(spacing: 14) {
            formField("Your Name", text: $name)
            formField("Phone Number", text: $phone, keyboard: .phonePad)
            formField("Email Address", text: $email, keyboard: .emailAddress)
            VStack(alignment: .leading, spacing: 6) {
                Text("Message").font(.caption).foregroundColor(.white.opacity(0.5))
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $message)
                        .frame(minHeight: 100).scrollContentBackground(.hidden)
                        .foregroundColor(.white).padding(10)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1))
                    if message.isEmpty {
                        Text("Hi \(trainerName), I'm interested in training...")
                            .foregroundColor(.white.opacity(0.25)).font(.body)
                            .padding(.top, 18).padding(.leading, 14).allowsHitTesting(false)
                    }
                }
            }
            Button(action: { agreed.toggle() }) {
                HStack(spacing: 10) {
                    Image(systemName: agreed ? "checkmark.square.fill" : "square")
                        .foregroundColor(agreed ? .tmGold : .white.opacity(0.3))
                    Text("I agree to the Terms of Use")
                        .font(.caption).foregroundColor(.white.opacity(0.5))
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            Button(action: { if isValid { sent = true } }) {
                HStack(spacing: 8) {
                    Image(systemName: sent ? "checkmark.circle.fill" : "paperplane.fill")
                    Text(sent ? "MESSAGE SENT!" : "SEND MESSAGE")
                        .font(.system(size: 14, weight: .heavy)).tracking(0.5)
                }
                .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 26)
                    .fill(isValid ? Color.tmGold : Color.gray.opacity(0.3))
                    .shadow(color: isValid ? Color.tmGold.opacity(0.4) : .clear,
                            radius: 10, x: 0, y: 5))
            }
            .disabled(!isValid || sent).padding(.top, 4).padding(.bottom, 30)
        }
    }

    private func formField(_ label: String, text: Binding<String>,
                            keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.5))
            TextField("", text: text)
                .keyboardType(keyboard).autocorrectionDisabled()
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .foregroundColor(.white).padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
    }

    private var isValid: Bool {
        !name.isEmpty && !phone.isEmpty && !email.isEmpty && !message.isEmpty && agreed
    }
}

// MARK: - Public Chip Grid

struct PublicChipGrid: View {
    let items: [String]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            let rows = items.chunked(into: 3)
            ForEach(rows.indices, id: \.self) { i in
                HStack(spacing: 8) {
                    ForEach(rows[i], id: \.self) { item in
                        Text(item).font(.caption).lineLimit(1)
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.07))
                                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)))
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        TrainerPublicProfileView(trainer: SavedTrainerProfile(
            id: "preview", businessName: "Elite Fitness Studio",
            firstName: "John", lastName: "Doe",
            email: "john@test.com", password: "test",
            city: "Las Vegas", state: "NV", gender: "Male",
            yearsOfExperience: 10, hourlyRate: 75, monthlyRate: 200,
            bio: "Certified trainer with 10 years experience.",
            certifications: [.nasmCpt, .aceCpt], schools: [.nasm],
            specialties: [.personalTraining, .hiit, .strength],
            serviceTypes: [.inPerson, .online], dateCreated: Date()
        ))
    }
    .preferredColorScheme(.dark)
}
