//
//  ClientBookingViews.swift
//  TrainerMatch
//
//  Client-side: browse trainer services, book sessions, pay via Stripe.
//

import SwiftUI
import StripePaymentSheet

// MARK: ─────────────────────────────────────────────
// MARK: CLIENT: TRAINER SERVICES BROWSE
// MARK: ─────────────────────────────────────────────

struct ClientTrainerServicesView: View {
    let trainer: TrainerProfile
    let clientId:   String
    let clientName: String
    @ObservedObject private var store = BookingStore.shared
    @State private var selectedTab: ServiceTab = .sessions

    enum ServiceTab: String, CaseIterable {
        case sessions    = "Sessions"
        case packages    = "Packages"
        case memberships = "Memberships"
    }

    private var services:    [TrainerService]    { store.services(forTrainer: trainer.userId) }
    private var packages:    [SessionPackage]    { store.packages(forTrainer: trainer.userId) }
    private var memberships: [TrainerMembership] { store.memberships(forTrainer: trainer.userId) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                trainerHeader
                tabBar
                Divider().background(Color.white.opacity(0.08))
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) { tabContent }.padding(20)
                }
            }
        }
        .navigationTitle("Book a Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var trainerHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 52, height: 52)
                Text(String((trainer.businessName ?? "T").prefix(1)))
                    .font(.system(size: 20, weight: .black)).foregroundColor(.tmGold)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(trainer.businessName ?? "Personal Trainer")
                    .font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                if let rate = trainer.hourlyRate {
                    Text(String(format: "From $%.0f/hr", rate))
                        .font(.caption).foregroundColor(.tmGold)
                }
            }
            Spacer()
        }
        .padding(16)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ServiceTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedTab == tab ? .tmGold : .white.opacity(0.35))
                        .frame(maxWidth: .infinity).padding(.vertical, 12)
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
        case .sessions:
            if services.isEmpty {
                clientEmptyState("No sessions listed yet")
            } else {
                ForEach(services) { service in
                    ClientServiceCard(service: service, trainer: trainer,
                                      clientId: clientId, clientName: clientName)
                }
            }
        case .packages:
            if packages.isEmpty {
                clientEmptyState("No packages available yet")
            } else {
                ForEach(packages) { pkg in
                    ClientPackageCard(package: pkg, trainer: trainer,
                                      clientId: clientId, clientName: clientName)
                }
            }
        case .memberships:
            if memberships.isEmpty {
                clientEmptyState("No memberships available yet")
            } else {
                ForEach(memberships) { mem in
                    ClientMembershipCard(membership: mem, trainer: trainer,
                                         clientId: clientId, clientName: clientName)
                }
            }
        }
    }
}

// MARK: - Client Service Card

struct ClientServiceCard: View {
    let service:    TrainerService
    let trainer:    TrainerProfile
    let clientId:   String
    let clientName: String
    @State private var showingBooking = false

    var body: some View {
        VStack(alignment: .leading, spacing:12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.title)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    HStack(spacing: 8) {
                        Label(service.formattedDuration, systemImage: "clock")
                        Label(service.serviceType.rawValue, systemImage: "location")
                    }
                    .font(.caption).foregroundColor(.white.opacity(0.45))
                    if !service.description.isEmpty {
                        Text(service.description).font(.caption)
                            .foregroundColor(.white.opacity(0.4)).lineLimit(2)
                    }
                }
                Spacer()
                Text(service.formattedPrice)
                    .font(.system(size: 20, weight: .black)).foregroundColor(.tmGold)
            }
            Button(action: { showingBooking = true }) {
                Text("BOOK NOW")
                    .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 21).fill(Color.tmGold))
                    .shadow(color: .tmGold.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)))
        .sheet(isPresented: $showingBooking) {
            NavigationView {
                BookingCheckoutView(
                    trainer: trainer, clientId: clientId, clientName: clientName,
                    title: service.title, amount: service.price,
                    bookingType: .singleSession, serviceId: service.id
                )
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Client Package Card

struct ClientPackageCard: View {
    let package:    SessionPackage
    let trainer:    TrainerProfile
    let clientId:   String
    let clientName: String
    @State private var showingBooking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(package.title)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Label("\(package.sessionCount) sessions · \(package.durationMins) min each",
                          systemImage: "square.stack.fill")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    Label("Valid for \(package.validityDays) days", systemImage: "calendar")
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                    if !package.description.isEmpty {
                        Text(package.description).font(.caption)
                            .foregroundColor(.white.opacity(0.4)).lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(package.formattedPrice)
                        .font(.system(size: 20, weight: .black)).foregroundColor(.tmGold)
                    Text(String(format: "$%.2f/session", package.pricePerSession))
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                    if let savings = package.formattedSavings {
                        Text(savings).font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.12)))
                    }
                }
            }
            Button(action: { showingBooking = true }) {
                Text("BUY PACKAGE")
                    .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 21).fill(Color.tmGold))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(Color.tmGold.opacity(0.2), lineWidth: 1)))
        .sheet(isPresented: $showingBooking) {
            NavigationView {
                BookingCheckoutView(
                    trainer: trainer, clientId: clientId, clientName: clientName,
                    title: package.title, amount: package.totalPrice,
                    bookingType: .package, serviceId: package.id,
                    sessionsTotal: package.sessionCount
                )
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: - Client Membership Card

struct ClientMembershipCard: View {
    let membership: TrainerMembership
    let trainer:    TrainerProfile
    let clientId:   String
    let clientName: String
    @State private var showingBooking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(membership.title)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Label("\(membership.sessionsPerMonth) sessions/month · \(membership.durationMins) min",
                          systemImage: "arrow.clockwise")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    if !membership.description.isEmpty {
                        Text(membership.description).font(.caption)
                            .foregroundColor(.white.opacity(0.4)).lineLimit(2)
                    }
                }
                Spacer()
                Text(membership.formattedPrice)
                    .font(.system(size: 20, weight: .black)).foregroundColor(.tmGold)
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
            Button(action: { showingBooking = true }) {
                Text("SUBSCRIBE")
                    .font(.system(size: 13, weight: .heavy)).tracking(0.5)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 42)
                    .background(RoundedRectangle(cornerRadius: 21).fill(Color.tmGold))
            }
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color.tmGold.opacity(0.08), Color.white.opacity(0.03)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color.tmGold.opacity(0.3), lineWidth: 1))
        .sheet(isPresented: $showingBooking) {
            NavigationView {
                BookingCheckoutView(
                    trainer: trainer, clientId: clientId, clientName: clientName,
                    title: membership.title, amount: membership.monthlyPrice,
                    bookingType: .membership, serviceId: membership.id,
                    membershipExpiresAt: Calendar.current.date(byAdding: .month, value: 1, to: Date())
                )
            }
            .tint(.tmGold).navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: BOOKING CHECKOUT + PAYMENT
// MARK: ─────────────────────────────────────────────

struct BookingCheckoutView: View {
    let trainer:      TrainerProfile
    let clientId:     String
    let clientName:   String
    let title:        String
    let amount:       Double
    let bookingType:  Booking.BookingType
    let serviceId:    String
    var sessionsTotal: Int? = nil
    var membershipExpiresAt: Date? = nil

    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = BookingStore.shared
    @State private var scheduledDate: Date = Date().addingTimeInterval(86400)
    @State private var notes        = ""
    @State private var isProcessing = false
    @State private var errorMsg:     String? = nil
    @State private var showingSuccess = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    orderSummary
                    if bookingType == .singleSession { datePicker }
                    notesField
                    paymentInfo
                    if let error = errorMsg {
                        Text(error).font(.caption).foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    payButton
                }
                .padding(20)
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }.foregroundColor(.tmGold)
            }
        }
        .sheet(isPresented: $showingSuccess) {
            BookingSuccessView(booking: buildBooking(), onDone: { dismiss() })
        }
    }

    private var orderSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("ORDER SUMMARY").font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)

            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.tmGold.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: bookingType == .membership ? "creditcard.fill"
                          : bookingType == .package ? "square.stack.fill" : "calendar")
                        .foregroundColor(.tmGold)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    Text("with \(trainer.businessName ?? "Trainer")")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    if let tot = sessionsTotal {
                        Text("\(tot) sessions included").font(.caption2)
                            .foregroundColor(.tmGold)
                    }
                    if bookingType == .membership {
                        Text("Billed monthly · cancel anytime").font(.caption2)
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                Spacer()
                Text(String(format: "$%.2f", amount))
                    .font(.system(size: 22, weight: .black)).foregroundColor(.tmGold)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05)))
        }
    }

    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREFERRED DATE & TIME").font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            DatePicker("", selection: $scheduledDate, in: Date()...,
                       displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact).colorScheme(.dark).tint(.tmGold).labelsHidden()
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES (OPTIONAL)").font(.system(size: 10, weight: .bold))
                .tracking(1.2).foregroundColor(.tmGold)
            TextField("Any requests or info for your trainer...", text: $notes, axis: .vertical)
                .foregroundColor(.white).lineLimit(3...5).padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.06)))
        }
    }

    private var paymentInfo: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.shield.fill").foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Secure payment powered by Stripe")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(.white)
                Text("Your card details are never stored on our servers.")
                    .font(.caption2).foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.06))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)))
    }

    private var payButton: some View {
        Button(action: initiatePayment) {
            HStack(spacing: 10) {
                if isProcessing {
                    ProgressView().tint(.black)
                } else {
                    Image(systemName: "creditcard.fill")
                    Text("PAY \(String(format: "$%.2f", amount))")
                        .font(.system(size: 16, weight: .heavy)).tracking(0.5)
                }
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 28).fill(Color.tmGold))
        }
        .disabled(isProcessing)
    }

    private func buildBooking() -> Booking {
        Booking(
            trainerId: trainer.userId,
            trainerName: trainer.businessName ?? "Trainer",
            clientId: clientId, clientName: clientName,
            bookingType: bookingType, serviceId: serviceId,
            serviceTitle: title, amount: amount,
            scheduledAt: bookingType == .singleSession ? scheduledDate : nil,
            notes: notes.isEmpty ? nil : notes,
            sessionsTotal: sessionsTotal,
            membershipExpiresAt: membershipExpiresAt
        )
    }

    private func initiatePayment() {
        isProcessing = true; errorMsg = nil
        let booking = buildBooking()
        store.createBooking(booking) { result in
            switch result {
            case .success(let b):
                guard let clientSecret = b.paymentIntentId else {
                    self.isProcessing = false
                    self.errorMsg = "Payment setup failed — please try again."
                    return
                }
                var config = PaymentSheet.Configuration()
                config.merchantDisplayName = "TrainerMatch"
                let paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: clientSecret,
                    configuration: config
                )
                DispatchQueue.main.async {
                    guard let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first?.rootViewController else { return }
                    paymentSheet.present(from: rootVC) { paymentResult in
                        switch paymentResult {
                        case .completed:
                            self.store.confirmPayment(bookingId: b.id,
                                                      paymentIntentId: clientSecret)
                            self.isProcessing = false
                            self.showingSuccess = true
                        case .failed(let error):
                            self.isProcessing = false
                            self.errorMsg = error.localizedDescription
                        case .canceled:
                            self.isProcessing = false
                        }
                    }
                }
            case .failure(let error):
                self.isProcessing = false
                self.errorMsg = error.localizedDescription
            }
        }
    }
}

// MARK: - Booking Success

struct BookingSuccessView: View {
    let booking: Booking
    let onDone:  () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72)).foregroundColor(.tmGold)
                VStack(spacing: 10) {
                    Text("Booking Confirmed!").font(.system(size: 28, weight: .black))
                        .foregroundColor(.white)
                    Text(booking.serviceTitle).font(.title3).foregroundColor(.tmGold)
                    Text("Your trainer has been notified and will confirm your session time.")
                        .font(.subheadline).foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center).padding(.horizontal)
                }
                VStack(spacing: 12) {
                    confirmRow("Amount paid",   booking.formattedAmount)
                    if let date = booking.scheduledAt {
                        confirmRow("Requested time",
                                   date.formatted(date: .long, time: .shortened))
                    }
                    if let rem = booking.sessionsRemaining {
                        confirmRow("Sessions included", "\(rem)")
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
                .padding(.horizontal)

                Button(action: onDone) {
                    Text("DONE").font(.system(size: 15, weight: .heavy)).tracking(0.5)
                        .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 26).fill(Color.tmGold))
                }
                .padding(.horizontal)
                Spacer()
            }
        }
    }

    private func confirmRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.45))
            Spacer()
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(.white)
        }
    }
}

// MARK: - Client Bookings History

struct ClientBookingsView: View {
    let clientId: String
    @ObservedObject private var store = BookingStore.shared

    private var bookings: [Booking] { store.bookings(forClient: clientId) }
    private var active:   [Booking] { bookings.filter { $0.status == .confirmed || $0.status == .pending } }
    private var past:     [Booking] { bookings.filter { $0.status == .completed || $0.status == .cancelled } }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if !active.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("ACTIVE")
                            ForEach(active) { booking in ClientBookingCard(booking: booking) }
                        }
                    }
                    if !past.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("HISTORY")
                            ForEach(past) { booking in ClientBookingCard(booking: booking) }
                        }
                    }
                    if bookings.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 48)).foregroundColor(.white.opacity(0.1))
                                .padding(.top, 40)
                            Text("No bookings yet").font(.title3).foregroundColor(.white.opacity(0.4))
                            Text("Book a session with your trainer to get started.")
                                .font(.subheadline).foregroundColor(.white.opacity(0.25))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("My Bookings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct ClientBookingCard: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(booking.serviceTitle)
                        .font(.system(size: 14, weight: .bold)).foregroundColor(.white)
                    Text("with \(booking.trainerName)")
                        .font(.caption).foregroundColor(.white.opacity(0.45))
                    if let date = booking.scheduledAt {
                        Label(date.formatted(date: .abbreviated, time: .shortened),
                              systemImage: "calendar")
                            .font(.caption2).foregroundColor(.tmGold)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.formattedAmount)
                        .font(.system(size: 16, weight: .black)).foregroundColor(.tmGold)
                    Text(booking.status.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(booking.status == .confirmed ? .black : .white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(booking.statusColor))
                }
            }
            if let rem = booking.sessionsRemaining, let tot = booking.sessionsTotal {
                VStack(spacing: 4) {
                    ProgressView(value: Double(tot - rem) / Double(tot)).tint(.tmGold)
                    Text("\(rem) of \(tot) sessions remaining")
                        .font(.caption2).foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(booking.statusColor.opacity(0.2), lineWidth: 1)))
    }
}

private func sectionLabel(_ text: String) -> some View {
    Text(text).font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundColor(.tmGold)
}

private func clientEmptyState(_ message: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: "calendar.badge.exclamationmark")
            .font(.system(size: 36)).foregroundColor(.white.opacity(0.1))
        Text(message).font(.subheadline).foregroundColor(.white.opacity(0.35))
    }
    .frame(maxWidth: .infinity).padding(.vertical, 30)
    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.03)))
}
