//
//  GymAdViews.swift
//  TrainerMatch
//
//  Rotating banner + Gyms Near You section + Ad detail view.
//  Shown to both trainers and clients.
//

import SwiftUI
import PhotosUI
import CoreLocation

// MARK: ─────────────────────────────────────────────
// MARK: ROTATING BANNER
// MARK: ─────────────────────────────────────────────

struct GymAdBannerView: View {
    @StateObject private var manager    = GymAdManager.shared
    @StateObject private var locManager = LocationManager()
    @State private var currentIndex     = 0
    @State private var timer: Timer?
    @State private var showingDetail: GymAd? = nil

    private var ads: [GymAd] {
        manager.adsForLocation(
            latitude:    locManager.location?.coordinate.latitude,
            longitude:   locManager.location?.coordinate.longitude,
            radiusMiles: 50
        )
    }

    var body: some View {
        Group {
            if !ads.isEmpty {
                VStack(spacing: 6) {
                    HStack {
                        Text("SPONSORED · GYMS & STUDIOS")
                            .font(.system(size: 8, weight: .black)).tracking(1.2)
                            .foregroundColor(.white.opacity(0.35))
                        Spacer()
                        if ads.count > 1 {
                            HStack(spacing: 5) {
                                ForEach(0..<min(ads.count, 5), id: \.self) { i in
                                    Circle()
                                        .fill(i == currentIndex % ads.count
                                              ? Color.tmGold : Color.white.opacity(0.2))
                                        .frame(width: i == currentIndex % ads.count ? 7 : 4,
                                               height: i == currentIndex % ads.count ? 7 : 4)
                                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    TabView(selection: $currentIndex) {
                        ForEach(ads.indices, id: \.self) { i in
                            GymAdBannerCard(ad: ads[i])
                                .padding(.horizontal, 16)
                                .tag(i)
                                .onTapGesture { stopTimer(); showingDetail = ads[i] }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 110)
                    .onChange(of: currentIndex) { _, _ in stopTimer(); startTimer() }

                    if ads.count > 1 {
                        Text("Swipe to browse • Tap for details")
                            .font(.system(size: 8)).foregroundColor(.white.opacity(0.25))
                    }
                }
                .onAppear  { startTimer() }
                .onDisappear { stopTimer() }
            }
        }
        .task {
            await manager.fetchActiveAds()
            locManager.requestLocation()
            // Start timer after fetch completes
            if !ads.isEmpty { startTimer() }
        }
        .onReceive(manager.$activeAds) { _ in
            // Restart timer whenever ads load/change
            if !ads.isEmpty { stopTimer(); startTimer() }
        }
        .sheet(item: $showingDetail, onDismiss: { startTimer() }) { ad in
            GymAdDetailView(ad: ad)
        }
    }

    private func startTimer() {
        guard ads.count > 1 else { return }
        stopTimer()
        let t = Timer(timeInterval: 7.0, repeats: true) { _ in
            withAnimation { currentIndex = (currentIndex + 1) % ads.count }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    private func stopTimer() { timer?.invalidate(); timer = nil }
}

// MARK: - Banner Card

struct GymAdBannerCard: View {
    let ad: GymAd

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(ad.plan.borderColor, lineWidth: ad.plan == .basic ? 1.0 : 1.5))
                .shadow(color: ad.plan.glowColor, radius: ad.plan == .premium ? 8 : 4)

            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    adImage
                    if let badge = ad.plan.badge {
                        Text(badge == "👑 PREMIUM" ? "👑" : "⭐")
                            .font(.system(size: 11)).offset(x: 6, y: -6)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    if let badge = ad.plan.badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .black)).foregroundColor(.black)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(ad.plan == .premium ? Color.tmGold : Color.orange)
                            .cornerRadius(3)
                    }
                    Text(ad.businessName)
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(1)
                    Text(ad.tagline)
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                    HStack(spacing: 4) {
                        Text(ad.category.icon).font(.system(size: 10))
                        Text(ad.category.label)
                            .font(.system(size: 9, weight: .bold)).foregroundColor(ad.category.accentColor)
                    }
                    if let city = ad.city, let state = ad.state {
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 9)).foregroundColor(ad.category.accentColor)
                            Text("\(city), \(state)")
                                .font(.system(size: 9)).foregroundColor(.white.opacity(0.4))
                        }
                    }
                }

                Spacer()

                VStack(spacing: 5) {
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(ad.category.accentColor)
                    Text("TAP\nINFO").font(.system(size: 7, weight: .bold))
                        .foregroundColor(.white.opacity(0.3)).multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .frame(height: 100)
    }

    private var adImage: some View {
        Group {
            if let urlStr = ad.imageURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .frame(width: 60, height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
                    default: defaultIcon
                    }
                }
            } else { defaultIcon }
        }
    }

    private var defaultIcon: some View {
        VStack(spacing: 2) {
            Text(ad.category.icon).font(.system(size: 24))
            Text(ad.category.label.uppercased().prefix(6))
                .font(.system(size: 7, weight: .black)).foregroundColor(.black)
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(ad.category.accentColor).cornerRadius(3)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: GYMS NEAR YOU SECTION
// MARK: ─────────────────────────────────────────────

struct GymsNearYouView: View {
    @StateObject private var manager    = GymAdManager.shared
    @StateObject private var locManager = LocationManager()
    @State private var selectedCategory: GymCategory? = nil
    @State private var showingDetail: GymAd?  = nil
    @State private var showingSignup           = false

    private var filteredAds: [GymAd] {
        let base = manager.adsForLocation(
            latitude:    locManager.location?.coordinate.latitude,
            longitude:   locManager.location?.coordinate.longitude,
            radiusMiles: 50
        )
        if let cat = selectedCategory { return base.filter { $0.category == cat } }
        return base
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gyms & Studios")
                            .font(.system(size: 22, weight: .bold)).foregroundColor(.white)
                        if !locManager.city.isEmpty {
                            Label("Near \(locManager.city)", systemImage: "location.fill")
                                .font(.caption).foregroundColor(.tmGold)
                        } else {
                            Text("Fitness spots in your area")
                                .font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                    }
                    Spacer()
                    Button(action: { showingSignup = true }) {
                        HStack(spacing: 5) {
                            Image(systemName: "plus.circle.fill")
                            Text("Advertise")
                        }
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(Color.tmGold))
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 14)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All", selected: selectedCategory == nil) { selectedCategory = nil }
                        ForEach(GymCategory.allCases, id: \.self) { cat in
                            filterChip("\(cat.icon) \(cat.label)", selected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)

                Divider().background(Color.white.opacity(0.08))

                if filteredAds.isEmpty { emptyState }
                else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(filteredAds) { ad in
                                Button(action: { showingDetail = ad }) {
                                    GymAdListCard(ad: ad)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationTitle("Gyms Near You")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await manager.fetchActiveAds()
            locManager.requestLocation()
        }
        .sheet(item: $showingDetail) { ad in GymAdDetailView(ad: ad) }
        .sheet(isPresented: $showingSignup) {
            NavigationView { GymAdvertiserSignupView() }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 52)).foregroundColor(.white.opacity(0.1)).padding(.top, 60)
            Text("No gyms listed yet").font(.title3).foregroundColor(.white.opacity(0.4))
            Text("Be the first gym in your area to advertise on TrainerMatch.")
                .font(.subheadline).foregroundColor(.white.opacity(0.25))
                .multilineTextAlignment(.center).padding(.horizontal)
            Button(action: { showingSignup = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("List Your Gym")
                }
                .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                .padding(.horizontal, 24).padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.tmGold))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.system(size: 12, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

// MARK: - Gym List Card

struct GymAdListCard: View {
    let ad: GymAd

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    if let urlStr = ad.imageURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 12))
                            default: iconBadge
                            }
                        }
                    } else { iconBadge }
                    if let badge = ad.plan.badge {
                        Text(badge == "👑 PREMIUM" ? "👑" : "⭐")
                            .font(.system(size: 12)).offset(x: 5, y: -5)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(ad.businessName).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text(ad.tagline).font(.caption).foregroundColor(.white.opacity(0.5)).lineLimit(1)
                    Text(ad.category.icon + " " + ad.category.label)
                        .font(.system(size: 10, weight: .bold)).foregroundColor(ad.category.accentColor)
                    if let city = ad.city {
                        Label(city + (ad.state != nil ? ", \(ad.state!)" : ""),
                              systemImage: "mappin.circle.fill")
                            .font(.caption2).foregroundColor(.white.opacity(0.35))
                    }
                    // Show ONLINE badge for national ads
                    if ad.isNational {
                        Text("🌐 ONLINE / NATIONWIDE")
                            .font(.system(size: 9, weight: .bold)).foregroundColor(.tmGold)
                    }
                }

                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
            }

            if !ad.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(ad.amenities.prefix(5), id: \.self) { amenity in
                            Text(amenity).font(.system(size: 9, weight: .semibold))
                                .foregroundColor(ad.category.accentColor)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(ad.category.accentColor.opacity(0.1)))
                        }
                        if ad.amenities.count > 5 {
                            Text("+\(ad.amenities.count - 5) more")
                                .font(.system(size: 9)).foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(ad.plan.borderColor.opacity(0.4), lineWidth: ad.plan == .basic ? 1 : 1.5)))
        .shadow(color: ad.plan.glowColor, radius: ad.plan == .premium ? 6 : 0)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12).fill(ad.category.accentColor.opacity(0.15))
                .frame(width: 72, height: 72)
            VStack(spacing: 4) {
                Text(ad.category.icon).font(.system(size: 28))
                Text(ad.category.label.prefix(6).uppercased())
                    .font(.system(size: 7, weight: .black)).foregroundColor(.black)
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(ad.category.accentColor).cornerRadius(3)
            }
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: GYM DETAIL VIEW
// MARK: ─────────────────────────────────────────────

struct GymAdDetailView: View {
    let ad: GymAd
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                        contactSection
                        if !ad.amenities.isEmpty { amenitiesSection }
                        actionButtons
                        Text("SPONSORED ADVERTISEMENT")
                            .font(.caption2).foregroundColor(.white.opacity(0.3)).padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.tmGold).font(.title3)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Advertisement").font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
    }

    private var heroSection: some View {
        VStack(spacing: 14) {
            if let urlStr = ad.imageURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFit().frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: ad.category.accentColor.opacity(0.3), radius: 12)
                    default: Text(ad.category.icon).font(.system(size: 72))
                    }
                }
            } else { Text(ad.category.icon).font(.system(size: 72)) }

            VStack(spacing: 8) {
                if let badge = ad.plan.badge {
                    Text(badge).font(.system(size: 10, weight: .black)).foregroundColor(.black)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(ad.plan == .premium ? Color.tmGold : Color.orange).clipShape(Capsule())
                }
                if ad.isNational {
                    Label("Online / Nationwide", systemImage: "globe")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.tmGold)
                }
                Text(ad.businessName)
                    .font(.system(size: 24, weight: .black)).foregroundColor(.white).multilineTextAlignment(.center)
                Text(ad.tagline)
                    .font(.subheadline).foregroundColor(.white.opacity(0.5)).multilineTextAlignment(.center)
                Text(ad.category.icon + " " + ad.category.label)
                    .font(.system(size: 12, weight: .bold)).foregroundColor(ad.category.accentColor)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(ad.category.accentColor.opacity(0.12)))
            }
        }
        .padding(.horizontal)
    }

    private var contactSection: some View {
        VStack(spacing: 0) {
            if let address = ad.address, !address.isEmpty {
                contactRow("mappin.circle.fill", "Address", address) { openMaps(address) }
                Divider().background(Color.white.opacity(0.07))
            }
            if let city = ad.city {
                contactRow("location.fill", "Location", city + (ad.state != nil ? ", \(ad.state!)" : "")) {}
                Divider().background(Color.white.opacity(0.07))
            }
            if let phone = ad.phone, !phone.isEmpty {
                contactRow("phone.fill", "Phone", phone) { callPhone(phone) }
                Divider().background(Color.white.opacity(0.07))
            }
            if let website = ad.websiteURL, !website.isEmpty {
                contactRow("globe", "Website", website) { openURL(website) }
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))).padding(.horizontal)
    }

    private var amenitiesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AMENITIES").font(.system(size: 10, weight: .bold)).tracking(1.2)
                .foregroundColor(.tmGold).padding(.horizontal, 4)
            FlowLayout(spacing: 8) {
                ForEach(ad.amenities, id: \.self) { amenity in
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10)).foregroundColor(ad.category.accentColor)
                        Text(amenity).font(.system(size: 12)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(ad.category.accentColor.opacity(0.08)))
                }
            }
        }
        .padding(.horizontal)
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let phone = ad.phone, !phone.isEmpty {
                Button(action: { callPhone(phone) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "phone.fill")
                        Text("CALL NOW").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                    }
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                    .background(RoundedRectangle(cornerRadius: 26).fill(ad.category.accentColor))
                }
            }
            if let address = ad.address, !address.isEmpty {
                Button(action: { openMaps(address) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                        Text("GET DIRECTIONS").font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(ad.category.accentColor).frame(maxWidth: .infinity).frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 24).stroke(ad.category.accentColor.opacity(0.4), lineWidth: 1)))
                }
            }
            if let website = ad.websiteURL, !website.isEmpty {
                Button(action: { openURL(website) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "safari.fill")
                        Text("VISIT WEBSITE").font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.7)).frame(maxWidth: .infinity).frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.white.opacity(0.05)))
                }
            }
        }
        .padding(.horizontal)
    }

    private func contactRow(_ icon: String, _ label: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon).foregroundColor(ad.category.accentColor).frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(label).font(.caption).foregroundColor(.white.opacity(0.4))
                    Text(value).font(.subheadline).foregroundColor(.white).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
            }
            .padding(14)
        }
    }

    private func callPhone(_ number: String) {
        let cleaned = number.filter { $0.isNumber }
        if let url = URL(string: "tel://\(cleaned)") { UIApplication.shared.open(url) }
    }
    private func openURL(_ urlString: String) {
        var s = urlString
        if !s.hasPrefix("http") { s = "https://\(s)" }
        if let url = URL(string: s) { UIApplication.shared.open(url) }
    }
    private func openMaps(_ address: String) {
        let enc = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "maps://?q=\(enc)") { UIApplication.shared.open(url) }
    }
}

// LocationManager is defined in LocationServices/LocationBasedOnSearch.swift
