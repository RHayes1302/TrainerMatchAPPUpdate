//
//  GymAdStore.swift
//  TrainerMatch
//
//  Gym & Studio advertising system.
//  Location-aware: local gyms show within 25 miles.
//  Online/supplement businesses (null lat/lon) ALWAYS stay in rotation.
//

import SwiftUI
import CoreLocation

// MARK: - Models

struct GymAd: Identifiable, Codable {
    var id:              UUID
    var businessName:    String
    var tagline:         String
    var category:        GymCategory
    var phone:           String?
    var websiteURL:      String?
    var imageURL:        String?
    var address:         String?
    var city:            String?
    var state:           String?
    var zipCode:         String?
    var latitude:        Double?    // nil = online/national — always shown
    var longitude:       Double?    // nil = online/national — always shown
    var status:          AdStatus
    var plan:            AdPlan
    var advertiserEmail: String?
    var advertiserPin:   String?
    var paymentStatus:   String?
    var paidUntil:       Date?
    var amenities:       [String]
    var notes:           String?
    var createdAt:       Date?

    enum CodingKeys: String, CodingKey {
        case id, category, phone, address, city, state, notes, amenities
        case businessName    = "business_name"
        case tagline
        case websiteURL      = "website_url"
        case imageURL        = "image_url"
        case zipCode         = "zip_code"
        case latitude, longitude
        case status, plan
        case advertiserEmail = "advertiser_email"
        case advertiserPin   = "advertiser_pin"
        case paymentStatus   = "payment_status"
        case paidUntil       = "paid_until"
        case createdAt       = "created_at"
    }

    /// True if this is an online/national advertiser — always stays in rotation
    var isNational: Bool {
        latitude == nil || longitude == nil
    }

    enum AdStatus: String, Codable {
        case pending  = "pending"
        case active   = "active"
        case inactive = "inactive"
    }

    enum AdPlan: String, Codable, CaseIterable {
        case basic    = "basic"
        case featured = "featured"
        case premium  = "premium"

        var monthlyPrice: Double {
            switch self {
            case .basic:    return 19.99
            case .featured: return 29.99
            case .premium:  return 49.99
            }
        }

        var displayPrice: String { String(format: "$%.2f/mo", monthlyPrice) }

        var borderColor: Color {
            switch self {
            case .basic:    return Color.tmGold.opacity(0.5)
            case .featured: return .orange
            case .premium:  return Color.tmGold
            }
        }

        var glowColor: Color {
            switch self {
            case .premium:  return Color.tmGold.opacity(0.4)
            case .featured: return Color.orange.opacity(0.3)
            case .basic:    return .clear
            }
        }

        var badge: String? {
            switch self {
            case .premium:  return "👑 PREMIUM"
            case .featured: return "⭐ FEATURED"
            case .basic:    return nil
            }
        }
    }
}

enum GymCategory: String, Codable, CaseIterable {
    case gym             = "gym"
    case studio          = "studio"
    case crossfit        = "crossfit"
    case yoga            = "yoga"
    case pilates         = "pilates"
    case boxing          = "boxing"
    case martialArts     = "martial_arts"
    case cycling         = "cycling"
    case swimming        = "swimming"
    case personalTraining = "personal_training"
    case nutrition       = "nutrition"
    case physicalTherapy = "physical_therapy"
    case wellness        = "wellness"
    case sports          = "sports"
    case dance           = "dance"

    /// Categories that are always national — no location filter applied
    var isAlwaysNational: Bool {
        self == .nutrition
    }

    var label: String {
        switch self {
        case .gym:              return "Gym"
        case .studio:           return "Fitness Studio"
        case .crossfit:         return "CrossFit Box"
        case .yoga:             return "Yoga Studio"
        case .pilates:          return "Pilates Studio"
        case .boxing:           return "Boxing Gym"
        case .martialArts:      return "Martial Arts"
        case .cycling:          return "Cycling Studio"
        case .swimming:         return "Swim Center"
        case .personalTraining: return "Training Studio"
        case .nutrition:        return "Nutrition & Supplements"
        case .physicalTherapy:  return "Physical Therapy"
        case .wellness:         return "Wellness Center"
        case .sports:           return "Sports Complex"
        case .dance:            return "Dance Studio"
        }
    }

    var icon: String {
        switch self {
        case .gym:              return "🏋️"
        case .studio:           return "💪"
        case .crossfit:         return "🔥"
        case .yoga:             return "🧘"
        case .pilates:          return "🤸"
        case .boxing:           return "🥊"
        case .martialArts:      return "🥋"
        case .cycling:          return "🚴"
        case .swimming:         return "🏊"
        case .personalTraining: return "🎯"
        case .nutrition:        return "🥗"
        case .physicalTherapy:  return "🩺"
        case .wellness:         return "🌿"
        case .sports:           return "🏅"
        case .dance:            return "💃"
        }
    }

    var accentColor: Color {
        switch self {
        case .gym:              return Color.tmGold
        case .studio:           return Color.orange
        case .crossfit:         return Color.red
        case .yoga:             return Color(red: 0.5, green: 0.8, blue: 0.6)
        case .pilates:          return Color(red: 0.8, green: 0.5, blue: 0.9)
        case .boxing:           return Color.red
        case .martialArts:      return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .cycling:          return Color.blue
        case .swimming:         return Color(red: 0.0, green: 0.6, blue: 0.9)
        case .personalTraining: return Color.tmGold
        case .nutrition:        return Color.green
        case .physicalTherapy:  return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .wellness:         return Color(red: 0.3, green: 0.8, blue: 0.5)
        case .sports:           return Color.orange
        case .dance:            return Color(red: 0.9, green: 0.3, blue: 0.6)
        }
    }
}

let gymAmenityOptions = [
    "Free Weights", "Cardio Equipment", "Group Classes", "Personal Training",
    "Locker Rooms", "Showers", "Sauna", "Pool", "Basketball Court",
    "Racquetball", "Childcare", "Parking", "24/7 Access", "Smoothie Bar",
    "Supplement Shop", "Physical Therapy", "Massage", "Tanning",
    "Wi-Fi", "Virtual Classes", "Outdoor Area", "Functional Training Area"
]

// MARK: - GymAdManager

class GymAdManager: ObservableObject {
    static let shared = GymAdManager()

    @Published var activeAds: [GymAd] = []
    @Published var isLoading = false

    private let supabaseURL     = "https://axmxhxdqfxedltjclssz.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF4bXhoeGRxZnhlZGx0amNsc3N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MTYzMjQsImV4cCI6MjA5MjM5MjMyNH0.pUP1qRfN_ugKfBPjERiPiV7C9lEpsmwe8wGHXPh7HVg"

    private init() {}

    // MARK: - Fetch all active ads

    func fetchActiveAds() async {
        isLoading = true
        guard let url = URL(string: "\(supabaseURL)/rest/v1/gym_ads?status=eq.active&select=*&order=plan.desc") else {
            isLoading = false; return
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey,              forHTTPHeaderField: "apikey")
        req.setValue("application/json",           forHTTPHeaderField: "Accept")

        do {
            let (data, _) = try await URLSession.shared.data(for: req)

            // Debug: print raw response
            if let raw = String(data: data, encoding: .utf8) {
                print("📦 GymAdManager raw response: \(raw.prefix(300))")
            }

            let decoder = JSONDecoder()
            // Supabase returns timestamps with microseconds — handle both formats
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let formatterNoFraction = ISO8601DateFormatter()
            formatterNoFraction.formatOptions = [.withInternetDateTime]
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let str = try container.decode(String.self)
                if let date = formatter.date(from: str) { return date }
                if let date = formatterNoFraction.date(from: str) { return date }
                throw DecodingError.dataCorruptedError(in: container,
                    debugDescription: "Cannot decode date: \(str)")
            }
            let ads = try decoder.decode([GymAd].self, from: data)
            await MainActor.run { self.activeAds = ads; self.isLoading = false }
            print("✅ GymAdManager: fetched \(ads.count) active ads")
        } catch {
            await MainActor.run { self.isLoading = false }
            print("❌ GymAdManager fetchActiveAds error: \(error)")
        }
    }

    // MARK: - Location-aware filter
    //
    // Rules (same logic as OnThaSet):
    //   1. No lat/lon on the ad  → ALWAYS show (online/national)
    //   2. Category is .nutrition → ALWAYS show (supplement companies)
    //   3. User has no location  → show ALL ads
    //   4. User has location     → show ads within radiusMiles + all national ads

    func adsForLocation(
        latitude: Double?,
        longitude: Double?,
        radiusMiles: Double = 50
    ) -> [GymAd] {
        guard let userLat = latitude, let userLon = longitude else {
            // No user location — show everything
            return activeAds
        }

        return activeAds.filter { ad in
            // Rule 1 & 2: national/online always in rotation
            if ad.isNational || ad.category.isAlwaysNational { return true }

            // Rule 3: ad has coordinates — check distance
            guard let adLat = ad.latitude, let adLon = ad.longitude else { return true }
            return haversineDistance(
                lat1: userLat, lon1: userLon,
                lat2: adLat,   lon2: adLon
            ) <= radiusMiles
        }
    }

    // MARK: - Submit

    func submitAd(_ ad: GymAd) async throws {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/gym_ads") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue(supabaseAnonKey,              forHTTPHeaderField: "apikey")
        req.setValue("application/json",           forHTTPHeaderField: "Content-Type")
        req.setValue("return=minimal",             forHTTPHeaderField: "Prefer")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        req.httpBody = try encoder.encode(ad)
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 201 else {
            throw GymAdError.submitFailed
        }
    }

    // MARK: - Image upload

    func uploadImage(data: Data, fileName: String) async throws -> String {
        guard let url = URL(string: "\(supabaseURL)/storage/v1/object/gym-ads/\(fileName)") else {
            throw GymAdError.uploadFailed
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("image/jpeg",                forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw GymAdError.uploadFailed
        }
        return "\(supabaseURL)/storage/v1/object/public/gym-ads/\(fileName)"
    }

    // MARK: - Haversine distance (miles)

    private func haversineDistance(lat1: Double, lon1: Double,
                                   lat2: Double, lon2: Double) -> Double {
        let R = 3958.8  // Earth radius in miles
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2)
            + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180)
            * sin(dLon/2) * sin(dLon/2)
        return R * 2 * atan2(sqrt(a), sqrt(1 - a))
    }
}

enum GymAdError: LocalizedError {
    case submitFailed
    case uploadFailed
    var errorDescription: String? {
        switch self {
        case .submitFailed: return "Failed to submit ad. Please try again."
        case .uploadFailed: return "Failed to upload image. Please try again."
        }
    }
}
