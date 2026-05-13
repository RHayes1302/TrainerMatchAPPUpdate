//
//  TrainerBookingViews.swift
//  TrainerMatch
//
//  Trainer-side: Stripe onboarding, manage services/packages/memberships, view bookings.
//

import SwiftUI

// MARK: ─────────────────────────────────────────────
// MARK: TRAINER: BOOKING HUB (entry point in profile)
// MARK: ─────────────────────────────────────────────

struct TrainerBookingHubView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @ObservedObject private var authManager = AuthManager.shared
    @State private var selectedTab: HubTab = .services
    @State private var showingOnboarding = false

    enum HubTab: String, CaseIterable {
        case services    = "Services"
        case packages    = "Packages"
        case memberships = "Memberships"
        case bookings    = "Bookings"

        var icon: String {
            switch self {
            case .services:    return "calendar.badge.plus"
            case .packages:    return "square.stack.fill"
            case .memberships: return "creditcard.fill"
            case .bookings:    return "list.bullet.clipboard"
            }
        }
    }

    private var stripeAccount: TrainerStripeAccount? {
        store.stripeAccount(forTrainer: trainerId)
    }
    private var isOnboarded: Bool { store.isOnboarded(trainerId: trainerId) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                if !isOnboarded { stripeOnboardingBanner }
                tabBar
                Divider().background(Color.white.opacity(0.08))
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) { tabContent }.padding(20)
                }
            }
        }
        .navigationTitle("Bookings & Payments")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { store.refreshStripeStatus(trainerId: trainerId) }
        .sheet(isPresented: $showingOnboarding) {
            StripeOnboardingView(trainerId: trainerId)
        }
    }

    private var stripeOnboardingBanner: some View {
        Button(action: { showingOnboarding = true }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set up payments to get paid")
                        .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    Text("Connect your Stripe account to accept bookings")
                        .font(.caption).foregroundColor(.white.opacity(0.5))
                }
                Spacer()
                Text("Setup →")
                    .font(.caption).fontWeight(.bold).foregroundColor(.black)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange))
            }
            .padding(14)
            .background(Color.orange.opacity(0.1))
        }
        .buttonStyle(.plain)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(HubTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon).font(.system(size: 14))
                        Text(tab.rawValue).font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.35))
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .overlay(Rectangle()
                        .fill(selectedTab == tab ? Color.tmGold : Color.clear)
                        .frame(height: 2), alignment: .bottom)
                }
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .services:    ServicesManagerView(trainerId: trainerId)
        case .packages:    PackagesManagerView(trainerId: trainerId)
        case .memberships: MembershipsManagerView(trainerId: trainerId)
        case .bookings:    TrainerBookingsListView(trainerId: trainerId)
        }
    }
}

// MARK: - Services Manager

struct ServicesManagerView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @State private var showingAdd = false
    @State private var editingService: TrainerService? = nil

    private var services: [TrainerService] { store.services(forTrainer: trainerId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("SINGLE SESSIONS")
                Spacer()
                addButton { showingAdd = true }
            }
            if services.isEmpty {
                emptyState("No services yet", "Add your first session type — set a title, duration and price.")
            } else {
                ForEach(services) { service in
                    ServiceCard(service: service, onEdit: { editingService = service },
                                onDelete: { store.deleteService(service) })
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationView { ServiceEditorView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(item: $editingService) { s in
            NavigationView { ServiceEditorView(trainerId: trainerId, existing: s) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct ServiceCard: View {
    let service: TrainerService
    let onEdit:   () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(service.title)
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                HStack(spacing: 8) {
                    Label(service.formattedDuration, systemImage: "clock")
                    Label(service.serviceType.rawValue, systemImage: "location")
                }
                .font(.caption).foregroundColor(.white.opacity(0.45))
                if !service.description.isEmpty {
                    Text(service.description).font(.caption2)
                        .foregroundColor(.white.opacity(0.35)).lineLimit(2)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(service.formattedPrice)
                    .font(.system(size: 18, weight: .black)).foregroundColor(.tmGold)
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil").font(.caption).foregroundColor(.tmGold)
                            .padding(7).background(Circle().fill(Color.tmGold.opacity(0.1)))
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.7))
                            .padding(7).background(Circle().fill(Color.red.opacity(0.08)))
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)))
    }
}

// MARK: - Service Editor

struct ServiceEditorView: View {
    let trainerId: String
    var existing: TrainerService? = nil
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = BookingStore.shared

    @State private var title        = ""
    @State private var description  = ""
    @State private var priceStr     = ""
    @State private var durationMins = 60
    @State private var sessionType: TrainerService.SessionType = .inPerson

    private var canSave: Bool { !title.isEmpty && (Double(priceStr) ?? 0) > 0 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    editorField("SERVICE NAME", placeholder: "e.g. 1-on-1 Personal Training", text: $title)
                    editorField("DESCRIPTION (OPTIONAL)", placeholder: "What's included...",
                                text: $description, multiline: true)
                    priceField
                    durationPicker
                    typePicker
                    saveButton
                }
                .padding(20)
            }
        }
        .navigationTitle(existing == nil ? "Add Service" : "Edit Service")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .onAppear { if let s = existing { populate(s) } }
    }

    private var priceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel("PRICE (USD)")
            HStack(spacing: 8) {
                Text("$").font(.system(size: 20, weight: .bold)).foregroundColor(.tmGold)
                TextField("0.00", text: $priceStr).keyboardType(.decimalPad)
                    .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
        }
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel("DURATION")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach([30, 45, 60, 75, 90, 120], id: \.self) { mins in
                        Button(action: { durationMins = mins }) {
                            Text("\(mins) min")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(durationMins == mins ? .black : .white.opacity(0.5))
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(durationMins == mins
                                    ? Color.tmGold : Color.white.opacity(0.08)))
                        }
                    }
                }
            }
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel("SESSION TYPE")
            HStack(spacing: 8) {
                ForEach(TrainerService.SessionType.allCases, id: \.self) { type in
                    Button(action: { sessionType = type }) {
                        Text(type.rawValue)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(sessionType == type ? .black : .white.opacity(0.5))
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(Capsule().fill(sessionType == type
                                ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                }
            }
        }
    }

    private var saveButton: some View {
        Button(action: save) {
            Text(existing == nil ? "ADD SERVICE" : "SAVE CHANGES")
                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                .foregroundColor(canSave ? .black : .white.opacity(0.3))
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 26)
                    .fill(canSave ? Color.tmGold : Color.white.opacity(0.08)))
                .shadow(color: canSave ? Color.tmGold.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!canSave)
    }

    private func save() {
        let price = Double(priceStr) ?? 0
        if var s = existing {
            s.title = title; s.description = description
            s.price = price; s.durationMins = durationMins; s.serviceType = sessionType
            store.updateService(s)
        } else {
            store.addService(TrainerService(trainerId: trainerId, title: title,
                description: description, durationMins: durationMins,
                price: price, serviceType: sessionType))
        }
        dismiss()
    }

    private func populate(_ s: TrainerService) {
        title = s.title; description = s.description
        priceStr = String(format: "%.2f", s.price)
        durationMins = s.durationMins; sessionType = s.serviceType
    }

    private func editorField(_ label: String, placeholder: String,
                              text: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel(label)
            if multiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .foregroundColor(.white).lineLimit(2...5).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            } else {
                TextField(placeholder, text: text)
                    .foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func formLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Packages Manager

struct PackagesManagerView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @State private var showingAdd  = false
    @State private var editingPkg: SessionPackage? = nil

    private var packages: [SessionPackage] { store.packages(forTrainer: trainerId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("SESSION PACKAGES")
                Spacer()
                addButton { showingAdd = true }
            }
            if packages.isEmpty {
                emptyState("No packages yet", "Bundle sessions together at a discount to boost client commitment.")
            } else {
                ForEach(packages) { pkg in
                    PackageCard(package: pkg,
                                onEdit:   { editingPkg = pkg },
                                onDelete: { store.deletePackage(pkg) })
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationView { PackageEditorView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(item: $editingPkg) { pkg in
            NavigationView { PackageEditorView(trainerId: trainerId, existing: pkg) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct PackageCard: View {
    let package:  SessionPackage
    let onEdit:   () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.title)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 8) {
                        Label("\(package.sessionCount) sessions", systemImage: "repeat")
                        Label("\(package.durationMins) min each", systemImage: "clock")
                    }
                    .font(.caption).foregroundColor(.white.opacity(0.45))
                    Label("Valid \(package.validityDays) days", systemImage: "calendar")
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.formattedPrice)
                        .font(.system(size: 18, weight: .black)).foregroundColor(.tmGold)
                    Text(String(format: "$%.2f/session", package.pricePerSession))
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                    if let savings = package.formattedSavings {
                        Text(savings).font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
            }
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.tmGold.opacity(0.1)))
                }
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.red.opacity(0.7))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.red.opacity(0.08)))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Package Editor

struct PackageEditorView: View {
    let trainerId: String
    var existing: SessionPackage? = nil
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = BookingStore.shared

    @State private var title         = ""
    @State private var description   = ""
    @State private var sessionCount  = 5
    @State private var durationMins  = 60
    @State private var priceStr      = ""
    @State private var validityDays  = 90
    @State private var sessionType: TrainerService.SessionType = .inPerson

    private var totalPrice: Double { Double(priceStr) ?? 0 }
    private var canSave: Bool { !title.isEmpty && totalPrice > 0 && sessionCount > 0 }
    private var perSession: String {
        guard sessionCount > 0, totalPrice > 0 else { return "" }
        return String(format: "$%.2f/session", totalPrice / Double(sessionCount))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    editorField("PACKAGE NAME", placeholder: "e.g. 10-Session Starter Pack", text: $title)
                    editorField("DESCRIPTION", placeholder: "What's included...", text: $description, multiline: true)

                    // Session count
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("NUMBER OF SESSIONS")
                        HStack(spacing: 8) {
                            ForEach([3, 5, 8, 10, 12, 20], id: \.self) { n in
                                Button(action: { sessionCount = n }) {
                                    Text("\(n)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(sessionCount == n ? .black : .white.opacity(0.5))
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(sessionCount == n ? Color.tmGold : Color.white.opacity(0.08)))
                                }
                            }
                        }
                    }

                    // Total price
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("TOTAL PRICE (USD)")
                        HStack(spacing: 8) {
                            Text("$").font(.system(size: 20, weight: .bold)).foregroundColor(.tmGold)
                            TextField("0.00", text: $priceStr).keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            if !perSession.isEmpty {
                                Text(perSession).font(.caption).foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("SESSION DURATION")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([30, 45, 60, 75, 90], id: \.self) { mins in
                                    Button(action: { durationMins = mins }) {
                                        Text("\(mins) min")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(durationMins == mins ? .black : .white.opacity(0.5))
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(Capsule().fill(durationMins == mins
                                                ? Color.tmGold : Color.white.opacity(0.08)))
                                    }
                                }
                            }
                        }
                    }

                    // Validity
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("VALIDITY PERIOD")
                        HStack(spacing: 8) {
                            ForEach([30, 60, 90, 180, 365], id: \.self) { days in
                                Button(action: { validityDays = days }) {
                                    Text(days >= 365 ? "1 yr" : "\(days)d")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(validityDays == days ? .black : .white.opacity(0.5))
                                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(validityDays == days ? Color.tmGold : Color.white.opacity(0.08)))
                                }
                            }
                        }
                    }

                    Button(action: save) {
                        Text(existing == nil ? "CREATE PACKAGE" : "SAVE CHANGES")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            .foregroundColor(canSave ? .black : .white.opacity(0.3))
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26)
                                .fill(canSave ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                    .disabled(!canSave)
                }
                .padding(20)
            }
        }
        .navigationTitle(existing == nil ? "Add Package" : "Edit Package")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .onAppear { if let p = existing { populate(p) } }
    }

    private func save() {
        if var p = existing {
            p.title = title; p.description = description
            p.sessionCount = sessionCount; p.durationMins = durationMins
            p.totalPrice = totalPrice; p.validityDays = validityDays
            store.updatePackage(p)
        } else {
            store.addPackage(SessionPackage(trainerId: trainerId, title: title,
                description: description, sessionCount: sessionCount,
                durationMins: durationMins, totalPrice: totalPrice,
                serviceType: sessionType, validityDays: validityDays))
        }
        dismiss()
    }

    private func populate(_ p: SessionPackage) {
        title = p.title; description = p.description
        sessionCount = p.sessionCount; durationMins = p.durationMins
        priceStr = String(format: "%.2f", p.totalPrice)
        validityDays = p.validityDays; sessionType = p.serviceType
    }

    private func editorField(_ label: String, placeholder: String,
                              text: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel(label)
            if multiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .foregroundColor(.white).lineLimit(2...4).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            } else {
                TextField(placeholder, text: text)
                    .foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func formLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Memberships Manager

struct MembershipsManagerView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @State private var showingAdd  = false
    @State private var editingMem: TrainerMembership? = nil

    private var memberships: [TrainerMembership] { store.memberships(forTrainer: trainerId) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionLabel("MEMBERSHIPS")
                Spacer()
                addButton { showingAdd = true }
            }
            if memberships.isEmpty {
                emptyState("No memberships yet", "Create monthly membership plans for recurring revenue.")
            } else {
                ForEach(memberships) { mem in
                    MembershipCard(membership: mem,
                                   onEdit:   { editingMem = mem },
                                   onDelete: { store.deleteMembership(mem) })
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationView { MembershipEditorView(trainerId: trainerId) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
        .sheet(item: $editingMem) { mem in
            NavigationView { MembershipEditorView(trainerId: trainerId, existing: mem) }
                .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

struct MembershipCard: View {
    let membership: TrainerMembership
    let onEdit:     () -> Void
    let onDelete:   () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(membership.title)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Label("\(membership.sessionsPerMonth) sessions/month · \(membership.durationMins) min",
                          systemImage: "arrow.clockwise")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                }
                Spacer()
                Text(membership.formattedPrice)
                    .font(.system(size: 18, weight: .black)).foregroundColor(.tmGold)
            }
            if !membership.perks.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(membership.perks, id: \.self) { perk in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold))
                            Text(perk).font(.system(size: 10))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.1)))
                    }
                }
            }
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.tmGold)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.tmGold.opacity(0.1)))
                }
                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .font(.caption).fontWeight(.semibold).foregroundColor(.red.opacity(0.7))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(Color.red.opacity(0.08)))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.tmGold.opacity(0.15), lineWidth: 1)))
    }
}

// MARK: - Membership Editor

struct MembershipEditorView: View {
    let trainerId: String
    var existing: TrainerMembership? = nil
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = BookingStore.shared

    @State private var title          = ""
    @State private var description    = ""
    @State private var priceStr       = ""
    @State private var sessionsPerMonth = 4
    @State private var durationMins   = 60
    @State private var perks:  [String] = []
    @State private var newPerk = ""
    @State private var sessionType: TrainerService.SessionType = .inPerson

    private let perkSuggestions = ["Unlimited messaging", "Custom meal plan",
        "Weekly check-ins", "Priority scheduling", "Nutrition guidance",
        "Workout program", "Progress tracking", "Video feedback"]

    private var canSave: Bool { !title.isEmpty && (Double(priceStr) ?? 0) > 0 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    editorField("MEMBERSHIP NAME", placeholder: "e.g. Elite Monthly", text: $title)
                    editorField("DESCRIPTION", placeholder: "What's included...", text: $description, multiline: true)

                    // Price
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("MONTHLY PRICE (USD)")
                        HStack(spacing: 8) {
                            Text("$").font(.system(size: 20, weight: .bold)).foregroundColor(.tmGold)
                            TextField("0.00", text: $priceStr).keyboardType(.decimalPad)
                                .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                            Text("/month").font(.caption).foregroundColor(.white.opacity(0.4))
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
                    }

                    // Sessions per month
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("SESSIONS PER MONTH")
                        HStack(spacing: 8) {
                            ForEach([2, 4, 8, 12, 16, 20], id: \.self) { n in
                                Button(action: { sessionsPerMonth = n }) {
                                    Text("\(n)")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(sessionsPerMonth == n ? .black : .white.opacity(0.5))
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(RoundedRectangle(cornerRadius: 10)
                                            .fill(sessionsPerMonth == n ? Color.tmGold : Color.white.opacity(0.08)))
                                }
                            }
                        }
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 8) {
                        formLabel("SESSION DURATION")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([30, 45, 60, 75, 90], id: \.self) { mins in
                                    Button(action: { durationMins = mins }) {
                                        Text("\(mins) min")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(durationMins == mins ? .black : .white.opacity(0.5))
                                            .padding(.horizontal, 14).padding(.vertical, 8)
                                            .background(Capsule().fill(durationMins == mins
                                                ? Color.tmGold : Color.white.opacity(0.08)))
                                    }
                                }
                            }
                        }
                    }

                    // Perks
                    VStack(alignment: .leading, spacing: 10) {
                        formLabel("INCLUDED PERKS")
                        FlowLayout(spacing: 8) {
                            ForEach(perkSuggestions, id: \.self) { perk in
                                let selected = perks.contains(perk)
                                Button(action: {
                                    if selected { perks.removeAll { $0 == perk } }
                                    else        { perks.append(perk) }
                                }) {
                                    HStack(spacing: 4) {
                                        if selected { Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)) }
                                        Text(perk).font(.system(size: 11))
                                    }
                                    .foregroundColor(selected ? .black : .white.opacity(0.55))
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
                                }
                            }
                        }
                        // Custom perk
                        HStack(spacing: 8) {
                            TextField("Add custom perk...", text: $newPerk)
                                .foregroundColor(.white).padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                            Button(action: {
                                if !newPerk.isEmpty { perks.append(newPerk); newPerk = "" }
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 20)).foregroundColor(.tmGold)
                            }
                        }
                    }

                    Button(action: save) {
                        Text(existing == nil ? "CREATE MEMBERSHIP" : "SAVE CHANGES")
                            .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                            .foregroundColor(canSave ? .black : .white.opacity(0.3))
                            .frame(maxWidth: .infinity).frame(height: 52)
                            .background(RoundedRectangle(cornerRadius: 26)
                                .fill(canSave ? Color.tmGold : Color.white.opacity(0.08)))
                    }
                    .disabled(!canSave)
                }
                .padding(20)
            }
        }
        .navigationTitle(existing == nil ? "Add Membership" : "Edit Membership")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .onAppear { if let m = existing { populate(m) } }
    }

    private func save() {
        if var m = existing {
            m.title = title; m.description = description
            m.monthlyPrice = Double(priceStr) ?? 0
            m.sessionsPerMonth = sessionsPerMonth; m.durationMins = durationMins
            m.perks = perks
            store.updateMembership(m)
        } else {
            store.addMembership(TrainerMembership(trainerId: trainerId, title: title,
                description: description, monthlyPrice: Double(priceStr) ?? 0,
                sessionsPerMonth: sessionsPerMonth, durationMins: durationMins,
                perks: perks, serviceType: sessionType))
        }
        dismiss()
    }

    private func populate(_ m: TrainerMembership) {
        title = m.title; description = m.description
        priceStr = String(format: "%.2f", m.monthlyPrice)
        sessionsPerMonth = m.sessionsPerMonth; durationMins = m.durationMins
        perks = m.perks
    }

    private func editorField(_ label: String, placeholder: String,
                              text: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            formLabel(label)
            if multiline {
                TextField(placeholder, text: text, axis: .vertical)
                    .foregroundColor(.white).lineLimit(2...4).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            } else {
                TextField(placeholder, text: text)
                    .foregroundColor(.white).padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
            }
        }
    }

    private func formLabel(_ t: String) -> some View {
        Text(t).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
    }
}

// MARK: - Trainer Bookings List

struct TrainerBookingsListView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @State private var filter: Booking.BookingStatus? = nil

    private var allBookings: [Booking] { store.bookings(forTrainer: trainerId) }
    private var filtered: [Booking] {
        guard let f = filter else { return allBookings }
        return allBookings.filter { $0.status == f }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("INCOMING BOOKINGS")
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip("All", selected: filter == nil) { filter = nil }
                    ForEach([Booking.BookingStatus.pending, .confirmed, .completed, .cancelled], id: \.self) { s in
                        filterChip(s.rawValue, selected: filter == s) { filter = s }
                    }
                }
            }
            if filtered.isEmpty {
                emptyState("No bookings yet", "Once clients book sessions they'll appear here.")
            } else {
                ForEach(filtered) { booking in
                    TrainerBookingCard(booking: booking)
                }
            }
        }
    }

    private func filterChip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(selected ? .black : .white.opacity(0.5))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(selected ? Color.tmGold : Color.white.opacity(0.08)))
        }
    }
}

struct TrainerBookingCard: View {
    let booking: Booking
    @ObservedObject private var store = BookingStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.clientName)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text(booking.serviceTitle)
                        .font(.caption).foregroundColor(.white.opacity(0.5))
                    Text(booking.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.formattedAmount)
                        .font(.system(size: 16, weight: .black)).foregroundColor(.tmGold)
                    statusBadge(booking.status)
                }
            }
            if let rem = booking.sessionsRemaining, let tot = booking.sessionsTotal {
                HStack(spacing: 6) {
                    ProgressView(value: Double(tot - rem) / Double(tot))
                        .tint(.tmGold)
                    Text("\(rem) of \(tot) sessions left")
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                }
            }
            if booking.status == .confirmed {
                Button(action: { store.completeSession(bookingId: booking.id) }) {
                    Text("Mark Session Complete")
                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 18).fill(Color.tmGold))
                }
            }
        }
        .padding(14)
        .background(
            Group {
                if booking.status == .pending {
                    LinearGradient(
                        colors: [Color.tmGold.opacity(0.12), Color.white.opacity(0.03)],
                        startPoint: .leading, endPoint: .trailing)
                } else {
                    LinearGradient(
                        colors: [Color.white.opacity(0.04), Color.white.opacity(0.04)],
                        startPoint: .leading, endPoint: .trailing)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(booking.statusColor.opacity(0.25), lineWidth: 1))
    }

    private func statusBadge(_ status: Booking.BookingStatus) -> some View {
        Text(status.rawValue)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(status == .confirmed || status == .completed ? .black : .white)
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(booking.statusColor))
    }
}

// MARK: - Stripe Onboarding View

struct StripeOnboardingView: View {
    let trainerId: String
    @ObservedObject private var store = BookingStore.shared
    @Environment(\.dismiss) var dismiss
    @State private var isLoading  = false
    @State private var errorMsg:  String? = nil
    @State private var onboardURL: String? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 64)).foregroundColor(.tmGold)

                VStack(spacing: 10) {
                    Text("Get Paid via Stripe")
                        .font(.system(size: 26, weight: .black)).foregroundColor(.white)
                    Text("TrainerMatch uses Stripe Connect to send payments directly to your bank account. There are no platform fees — you keep 100%.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                VStack(spacing: 14) {
                    featureRow("bank.building.2.fill", "Direct bank deposits", .tmGold)
                    featureRow("lock.shield.fill",      "Secure payment processing", .green)
                    featureRow("percent",               "0% platform fee — keep everything", .blue)
                    featureRow("clock.fill",            "Payouts in 2 business days", .purple)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04)))
                .padding(.horizontal)

                if let error = errorMsg {
                    Text(error).font(.caption).foregroundColor(.red)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                Button(action: startOnboarding) {
                    HStack(spacing: 10) {
                        if isLoading { ProgressView().tint(.black) }
                        else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("CONNECT WITH STRIPE")
                                .font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        }
                    }
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 54)
                    .background(RoundedRectangle(cornerRadius: 27).fill(Color.tmGold))
                }
                .disabled(isLoading).padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Stripe Setup")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundColor(color).frame(width: 22)
            Text(text).font(.subheadline).foregroundColor(.white)
            Spacer()
        }
    }

    private func startOnboarding() {
        isLoading = true; errorMsg = nil
        store.startStripeOnboarding(trainerId: trainerId) { result in
            isLoading = false
            switch result {
            case .success(let url):
                onboardURL = url
                if let u = URL(string: url) { UIApplication.shared.open(u) }
                dismiss()
            case .failure(let error):
                errorMsg = error.localizedDescription
            }
        }
    }
}

// MARK: - Shared helpers

private func sectionLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 10, weight: .black)).tracking(1.5).foregroundColor(.tmGold)
}

private func addButton(action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack(spacing: 5) {
            Image(systemName: "plus.circle.fill")
            Text("Add")
        }
        .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
        .padding(.horizontal, 14).padding(.vertical, 7)
        .background(Capsule().fill(Color.tmGold))
    }
}

private func emptyState(_ title: String, _ subtitle: String) -> some View {
    VStack(spacing: 8) {
        Image(systemName: "plus.circle.dashed")
            .font(.system(size: 36)).foregroundColor(.white.opacity(0.1))
        Text(title).font(.subheadline).foregroundColor(.white.opacity(0.4))
        Text(subtitle).font(.caption).foregroundColor(.white.opacity(0.25))
            .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity).padding(.vertical, 24)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
}
