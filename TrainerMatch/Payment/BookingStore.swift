//
//  BookingStore.swift
//  TrainerMatch
//
//  Complete booking & payments system.
//  Supports: single sessions, session packages, memberships.
//  Payments via Stripe + Supabase backend.
//

import SwiftUI

// MARK: ─────────────────────────────────────────────
// MARK: MODELS
// MARK: ─────────────────────────────────────────────

// MARK: Service (single session type)

struct TrainerService: Identifiable, Codable {
    let id: String
    var trainerId:    String
    var title:        String
    var description:  String
    var durationMins: Int
    var price:        Double   // USD
    var serviceType:  SessionType
    var isActive:     Bool
    var createdAt:    Date

    enum SessionType: String, Codable, CaseIterable {
        case inPerson  = "In-Person"
        case virtual   = "Virtual"
        case hybrid    = "In-Person or Virtual"
    }

    var formattedPrice: String { String(format: "$%.2f", price) }
    var formattedDuration: String { "\(durationMins) min" }

    init(trainerId: String, title: String, description: String = "",
         durationMins: Int = 60, price: Double,
         serviceType: SessionType = .inPerson) {
        self.id           = UUID().uuidString
        self.trainerId    = trainerId
        self.title        = title
        self.description  = description
        self.durationMins = durationMins
        self.price        = price
        self.serviceType  = serviceType
        self.isActive     = true
        self.createdAt    = Date()
    }
}

// MARK: Package (bundle of sessions)

struct SessionPackage: Identifiable, Codable {
    let id: String
    var trainerId:     String
    var title:         String
    var description:   String
    var sessionCount:  Int
    var durationMins:  Int
    var totalPrice:    Double
    var serviceType:   TrainerService.SessionType
    var validityDays:  Int    // how long before sessions expire
    var isActive:      Bool
    var createdAt:     Date

    var pricePerSession: Double { totalPrice / Double(sessionCount) }
    var formattedPrice:  String { String(format: "$%.2f", totalPrice) }
    var savings:         Double?  // vs buying individually
    var formattedSavings: String? {
        guard let s = savings else { return nil }
        return String(format: "Save $%.2f", s)
    }

    init(trainerId: String, title: String, description: String = "",
         sessionCount: Int, durationMins: Int = 60, totalPrice: Double,
         serviceType: TrainerService.SessionType = .inPerson,
         validityDays: Int = 90, savings: Double? = nil) {
        self.id            = UUID().uuidString
        self.trainerId     = trainerId
        self.title         = title
        self.description   = description
        self.sessionCount  = sessionCount
        self.durationMins  = durationMins
        self.totalPrice    = totalPrice
        self.serviceType   = serviceType
        self.validityDays  = validityDays
        self.savings       = savings
        self.isActive      = true
        self.createdAt     = Date()
    }
}

// MARK: Membership

struct TrainerMembership: Identifiable, Codable {
    let id: String
    var trainerId:       String
    var title:           String
    var description:     String
    var monthlyPrice:    Double
    var sessionsPerMonth: Int
    var durationMins:    Int
    var perks:           [String]   // e.g. "Unlimited messaging", "Nutrition plan"
    var serviceType:     TrainerService.SessionType
    var isActive:        Bool
    var createdAt:       Date

    var formattedPrice: String { String(format: "$%.2f/mo", monthlyPrice) }

    init(trainerId: String, title: String, description: String = "",
         monthlyPrice: Double, sessionsPerMonth: Int,
         durationMins: Int = 60, perks: [String] = [],
         serviceType: TrainerService.SessionType = .inPerson) {
        self.id               = UUID().uuidString
        self.trainerId        = trainerId
        self.title            = title
        self.description      = description
        self.monthlyPrice     = monthlyPrice
        self.sessionsPerMonth = sessionsPerMonth
        self.durationMins     = durationMins
        self.perks            = perks
        self.serviceType      = serviceType
        self.isActive         = true
        self.createdAt        = Date()
    }
}

// MARK: Booking

struct Booking: Identifiable, Codable {
    let id: String
    var trainerId:      String
    var trainerName:    String
    var clientId:       String
    var clientName:     String
    var bookingType:    BookingType
    var serviceId:      String    // service/package/membership id
    var serviceTitle:   String
    var amount:         Double
    var status:         BookingStatus
    var scheduledAt:    Date?
    var createdAt:      Date
    var paymentIntentId: String?  // Stripe
    var stripeStatus:   StripePaymentStatus
    var notes:          String?

    // For packages — sessions remaining
    var sessionsTotal:     Int?
    var sessionsRemaining: Int?

    // For memberships
    var membershipExpiresAt: Date?

    enum BookingType: String, Codable {
        case singleSession = "Session"
        case package       = "Package"
        case membership    = "Membership"
    }

    enum BookingStatus: String, Codable {
        case pending    = "Pending"
        case confirmed  = "Confirmed"
        case completed  = "Completed"
        case cancelled  = "Cancelled"
        case refunded   = "Refunded"
    }

    enum StripePaymentStatus: String, Codable {
        case unpaid    = "Unpaid"
        case processing = "Processing"
        case paid      = "Paid"
        case failed    = "Failed"
        case refunded  = "Refunded"
    }

    var formattedAmount: String { String(format: "$%.2f", amount) }

    var statusColor: Color {
        switch status {
        case .pending:   return .orange
        case .confirmed: return .tmGold
        case .completed: return .green
        case .cancelled: return .red
        case .refunded:  return .gray
        }
    }

    var isPaid: Bool { stripeStatus == .paid }

    init(trainerId: String, trainerName: String, clientId: String, clientName: String,
         bookingType: BookingType, serviceId: String, serviceTitle: String, amount: Double,
         scheduledAt: Date? = nil, notes: String? = nil,
         sessionsTotal: Int? = nil, membershipExpiresAt: Date? = nil) {
        self.id                  = UUID().uuidString
        self.trainerId           = trainerId
        self.trainerName         = trainerName
        self.clientId            = clientId
        self.clientName          = clientName
        self.bookingType         = bookingType
        self.serviceId           = serviceId
        self.serviceTitle        = serviceTitle
        self.amount              = amount
        self.status              = .pending
        self.scheduledAt         = scheduledAt
        self.createdAt           = Date()
        self.paymentIntentId     = nil
        self.stripeStatus        = .unpaid
        self.notes               = notes
        self.sessionsTotal       = sessionsTotal
        self.sessionsRemaining   = sessionsTotal
        self.membershipExpiresAt = membershipExpiresAt
    }
}

// MARK: Trainer Stripe Account

struct TrainerStripeAccount: Codable {
    var trainerId:       String
    var stripeAccountId: String?    // Stripe Connect account ID
    var onboardingComplete: Bool
    var chargesEnabled:  Bool
    var payoutsEnabled:  Bool
    var onboardingURL:   String?    // temporary onboarding link
}

// MARK: ─────────────────────────────────────────────
// MARK: STORE
// MARK: ─────────────────────────────────────────────

class BookingStore: ObservableObject {
    static let shared = BookingStore()

    @Published var services:    [TrainerService]    = []
    @Published var packages:    [SessionPackage]    = []
    @Published var memberships: [TrainerMembership] = []
    @Published var bookings:    [Booking]           = []
    @Published var stripeAccounts: [String: TrainerStripeAccount] = [:]

    private let supabase = SupabaseBookingClient.shared
    private var svcURL:  URL { docURL("tmServices.json")    }
    private var pkgURL:  URL { docURL("tmPackages.json")    }
    private var memURL:  URL { docURL("tmMemberships.json") }
    private var bkgURL:  URL { docURL("tmBookings.json")    }

    private init() { loadLocal() }

    // MARK: Queries

    func services(forTrainer id: String) -> [TrainerService] {
        services.filter { $0.trainerId == id && $0.isActive }
                .sorted { $0.price < $1.price }
    }

    func packages(forTrainer id: String) -> [SessionPackage] {
        packages.filter { $0.trainerId == id && $0.isActive }
                .sorted { $0.totalPrice < $1.totalPrice }
    }

    func memberships(forTrainer id: String) -> [TrainerMembership] {
        memberships.filter { $0.trainerId == id && $0.isActive }
                   .sorted { $0.monthlyPrice < $1.monthlyPrice }
    }

    func bookings(forClient id: String) -> [Booking] {
        bookings.filter { $0.clientId == id }
                .sorted { $0.createdAt > $1.createdAt }
    }

    func bookings(forTrainer id: String) -> [Booking] {
        bookings.filter { $0.trainerId == id }
                .sorted { $0.createdAt > $1.createdAt }
    }

    func activeBookings(forClient id: String) -> [Booking] {
        bookings(forClient: id).filter { $0.status == .confirmed || $0.status == .pending }
    }

    func stripeAccount(forTrainer id: String) -> TrainerStripeAccount? {
        stripeAccounts[id]
    }

    func isOnboarded(trainerId: String) -> Bool {
        stripeAccounts[trainerId]?.onboardingComplete == true
    }

    // MARK: Trainer — manage services

    func addService(_ service: TrainerService) {
        services.insert(service, at: 0); saveLocal()
    }

    func updateService(_ service: TrainerService) {
        if let i = services.firstIndex(where: { $0.id == service.id }) {
            services[i] = service; saveLocal()
        }
    }

    func deleteService(_ service: TrainerService) {
        services.removeAll { $0.id == service.id }; saveLocal()
    }

    func addPackage(_ pkg: SessionPackage) {
        packages.insert(pkg, at: 0); saveLocal()
    }

    func updatePackage(_ pkg: SessionPackage) {
        if let i = packages.firstIndex(where: { $0.id == pkg.id }) {
            packages[i] = pkg; saveLocal()
        }
    }

    func deletePackage(_ pkg: SessionPackage) {
        packages.removeAll { $0.id == pkg.id }; saveLocal()
    }

    func addMembership(_ mem: TrainerMembership) {
        memberships.insert(mem, at: 0); saveLocal()
    }

    func updateMembership(_ mem: TrainerMembership) {
        if let i = memberships.firstIndex(where: { $0.id == mem.id }) {
            memberships[i] = mem; saveLocal()
        }
    }

    func deleteMembership(_ mem: TrainerMembership) {
        memberships.removeAll { $0.id == mem.id }; saveLocal()
    }

    // MARK: Booking flow (calls Supabase/Stripe)

    func createBooking(_ booking: Booking,
                       completion: @escaping (Result<Booking, Error>) -> Void) {
        var b = booking
        bookings.insert(b, at: 0); saveLocal()
        // Call Supabase to create Stripe PaymentIntent
        supabase.createPaymentIntent(booking: b) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let intentId):
                    b.paymentIntentId = intentId
                    b.stripeStatus    = .processing
                    self.updateBookingLocal(b)
                    completion(.success(b))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func confirmPayment(bookingId: String, paymentIntentId: String) {
        if let i = bookings.firstIndex(where: { $0.id == bookingId }) {
            bookings[i].stripeStatus    = .paid
            bookings[i].status          = .confirmed
            bookings[i].paymentIntentId = paymentIntentId
            saveLocal()
            let b = bookings[i]
            NotificationManager.shared.send(
                recipientId: b.trainerId, recipientRole: .trainer,
                senderId: b.clientId, senderName: b.clientName,
                category: .message,
                title: "New booking from \(b.clientName)",
                body: "\(b.serviceTitle) — \(b.formattedAmount) paid"
            )
        }
    }

    func cancelBooking(_ booking: Booking) {
        if let i = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[i].status = .cancelled; saveLocal()
        }
    }

    func completeSession(bookingId: String) {
        if let i = bookings.firstIndex(where: { $0.id == bookingId }) {
            if bookings[i].bookingType == .package,
               let rem = bookings[i].sessionsRemaining, rem > 0 {
                bookings[i].sessionsRemaining = rem - 1
                if bookings[i].sessionsRemaining == 0 {
                    bookings[i].status = .completed
                }
            } else {
                bookings[i].status = .completed
            }
            saveLocal()
        }
    }

    // MARK: Stripe Connect onboarding

    func startStripeOnboarding(trainerId: String,
                                completion: @escaping (Result<String, Error>) -> Void) {
        supabase.createConnectAccount(trainerId: trainerId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let (accountId, url)):
                    self.stripeAccounts[trainerId] = TrainerStripeAccount(
                        trainerId: trainerId,
                        stripeAccountId: accountId,
                        onboardingComplete: false,
                        chargesEnabled: false,
                        payoutsEnabled: false,
                        onboardingURL: url
                    )
                    completion(.success(url))
                case .failure(let e):
                    completion(.failure(e))
                }
            }
        }
    }

    func refreshStripeStatus(trainerId: String) {
        supabase.getAccountStatus(trainerId: trainerId) { result in
            DispatchQueue.main.async {
                if case .success(let account) = result {
                    self.stripeAccounts[trainerId] = account
                }
            }
        }
    }

    // MARK: Persistence

    private func updateBookingLocal(_ booking: Booking) {
        if let i = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[i] = booking; saveLocal()
        }
    }

    private func docURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(name)
    }

    private func saveLocal() {
        try? JSONEncoder().encode(services).write(to: svcURL)
        try? JSONEncoder().encode(packages).write(to: pkgURL)
        try? JSONEncoder().encode(memberships).write(to: memURL)
        try? JSONEncoder().encode(bookings).write(to: bkgURL)
    }

    private func loadLocal() {
        if let d = try? Data(contentsOf: svcURL),
           let v = try? JSONDecoder().decode([TrainerService].self, from: d)    { services    = v }
        if let d = try? Data(contentsOf: pkgURL),
           let v = try? JSONDecoder().decode([SessionPackage].self, from: d)    { packages    = v }
        if let d = try? Data(contentsOf: memURL),
           let v = try? JSONDecoder().decode([TrainerMembership].self, from: d) { memberships = v }
        if let d = try? Data(contentsOf: bkgURL),
           let v = try? JSONDecoder().decode([Booking].self, from: d)           { bookings    = v }
    }
}

// MARK: ─────────────────────────────────────────────
// MARK: SUPABASE CLIENT
// MARK: ─────────────────────────────────────────────

class SupabaseBookingClient {
    static let shared = SupabaseBookingClient()

    // Set these from your Supabase project settings
    private let supabaseURL    = "https://axmxhxdqfxedltjclssz.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4bXhoeGRxZnhlZGx0amNsc3N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MTYzMjQsImV4cCI6MjA5MjM5MjMyNH0.pUP1qRfN_ugKfBPjERiPiV7C9lEpsmwe8wGHXPh7HVg"

    private var functionsURL: String { "\(supabaseURL)/functions/v1" }

    private init() {}

    func createPaymentIntent(booking: Booking,
                              completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "\(functionsURL)/create-payment-intent") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",      forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "bookingId":  booking.id,
            "amount":     Int(booking.amount * 100),  // cents
            "currency":   "usd",
            "trainerId":  booking.trainerId,
            "clientId":   booking.clientId,
            "description": booking.serviceTitle
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error { completion(.failure(error)); return }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String else {
                completion(.failure(BookingError.invalidResponse)); return
            }
            completion(.success(clientSecret))
        }.resume()
    }

    func createConnectAccount(trainerId: String,
                               completion: @escaping (Result<(String, String), Error>) -> Void) {
        guard let url = URL(string: "\(functionsURL)/create-connect-account") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",         forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["trainerId": trainerId])
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error { completion(.failure(error)); return }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let accountId  = json["accountId"]     as? String,
                  let onboardURL = json["onboardingUrl"]  as? String else {
                completion(.failure(BookingError.invalidResponse)); return
            }
            completion(.success((accountId, onboardURL)))
        }.resume()
    }

    func getAccountStatus(trainerId: String,
                           completion: @escaping (Result<TrainerStripeAccount, Error>) -> Void) {
        guard let url = URL(string: "\(functionsURL)/stripe-account-status?trainerId=\(trainerId)") else { return }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, error in
            if let error { completion(.failure(error)); return }
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                completion(.failure(BookingError.invalidResponse)); return
            }
            let account = TrainerStripeAccount(
                trainerId:          trainerId,
                stripeAccountId:    json["accountId"]         as? String,
                onboardingComplete: json["onboardingComplete"] as? Bool ?? false,
                chargesEnabled:     json["chargesEnabled"]     as? Bool ?? false,
                payoutsEnabled:     json["payoutsEnabled"]     as? Bool ?? false,
                onboardingURL:      nil
            )
            completion(.success(account))
        }.resume()
    }
}

enum BookingError: LocalizedError {
    case invalidResponse
    case paymentFailed(String)
    case notOnboarded

    var errorDescription: String? {
        switch self {
        case .invalidResponse:     return "Invalid server response"
        case .paymentFailed(let m): return "Payment failed: \(m)"
        case .notOnboarded:        return "Trainer has not set up payments yet"
        }
    }
}
