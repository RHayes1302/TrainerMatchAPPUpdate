//
//  SubscriptionManager.swift
//  NearbyTrainers
//
//  StoreKit 2 subscription manager for trainer billing tiers
//

import StoreKit
import SwiftUI
import Combine

// MARK: - Subscription Tier

enum TrainerSubscriptionTier: String, CaseIterable {
    case starter = "com.hayesenterprise.NearbyTrainers.starter"
    case growth  = "com.hayesenterprise.NearbyTrainers.growth"
    case pro     = "com.hayesenterprise.NearbyTrainers.pro"
    case elite   = "com.hayesenterprise.NearbyTrainers.elite"

    var displayName: String {
        switch self {
        case .starter: return "Starter"
        case .growth:  return "Growth"
        case .pro:     return "Pro"
        case .elite:   return "Elite"
        }
    }

    var price: String {
        switch self {
        case .starter: return "$1.99"
        case .growth:  return "$2.99"
        case .pro:     return "$5.00"
        case .elite:   return "$10.00"
        }
    }

    var clientRange: String {
        switch self {
        case .starter: return "Up to 2 clients"
        case .growth:  return "Up to 5 clients"
        case .pro:     return "Up to 9 clients"
        case .elite:   return "10+ clients"
        }
    }

    var maxClients: Int {
        switch self {
        case .starter: return 2
        case .growth:  return 5
        case .pro:     return 9
        case .elite:   return Int.max
        }
    }

    var color: Color {
        switch self {
        case .starter: return .tmGold
        case .growth:  return .blue
        case .pro:     return .purple
        case .elite:   return .orange
        }
    }

    var icon: String {
        switch self {
        case .starter: return "star.fill"
        case .growth:  return "chart.line.uptrend.xyaxis"
        case .pro:     return "bolt.fill"
        case .elite:   return "crown.fill"
        }
    }

    /// Recommended tier based on client count
    static func recommended(for clientCount: Int) -> TrainerSubscriptionTier {
        switch clientCount {
        case 0...2:  return .starter
        case 3...5:  return .growth
        case 6...9:  return .pro
        default:     return .elite
        }
    }
}

// MARK: - Subscription Manager

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var products:           [Product] = []
    @Published var purchasedTier:      TrainerSubscriptionTier? = nil
    @Published var isLoading:          Bool = false
    @Published var errorMessage:       String? = nil
    @Published var isInTrialPeriod:    Bool = false
    @Published var trialDaysRemaining: Int = 0
    @Published var subscriptionStatus: String = "No active subscription"

    private var updateListenerTask: Task<Void, Error>? = nil

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await loadProducts() }
        Task { await updateSubscriptionStatus() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let productIds = TrainerSubscriptionTier.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)
            products = storeProducts.sorted {
                let aPrice = $0.price as Decimal
                let bPrice = $1.price as Decimal
                return aPrice < bPrice
            }
        } catch {
            errorMessage = "Failed to load subscription plans."
            print("❌ StoreKit load error: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateSubscriptionStatus()
                await transaction.finish()
                return true
            case .userCancelled:
                return false
            case .pending:
                subscriptionStatus = "Purchase pending approval"
                return false
            @unknown default:
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Update Status

    func updateSubscriptionStatus() async {
        var activeTier: TrainerSubscriptionTier? = nil
        var inTrial = false
        var daysLeft = 0

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let tier = TrainerSubscriptionTier(rawValue: transaction.productID) {
                    activeTier = tier

                    // Check trial period — introductoryOffer = free trial
                    if transaction.offerType != nil {
                        inTrial = true
                        if let expirationDate = transaction.expirationDate {
                            daysLeft = max(0, Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0)
                        }
                    }
                }
            } catch {
                print("❌ Transaction verification failed: \(error)")
            }
        }

        purchasedTier      = activeTier
        isInTrialPeriod    = inTrial
        trialDaysRemaining = daysLeft

        if let tier = activeTier {
            if inTrial {
                subscriptionStatus = "Free Trial · \(daysLeft) days remaining"
            } else {
                subscriptionStatus = "\(tier.displayName) Plan · Active"
            }
        } else {
            subscriptionStatus = "No active subscription"
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("❌ Transaction update error: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let safe): return safe
        }
    }

    func product(for tier: TrainerSubscriptionTier) -> Product? {
        products.first { $0.id == tier.rawValue }
    }

    var isSubscribed: Bool { purchasedTier != nil }
}

// MARK: - Subscription View

struct TrainerSubscriptionView: View {
    @StateObject private var manager = SubscriptionManager.shared
    @ObservedObject private var sbStore = SBConnectionStore.shared
    @Environment(\.dismiss) var dismiss

    let trainerId: String

    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    private var clientCount: Int {
        sbStore.activeClients(forTrainer: trainerId).count
    }

    private var recommendedTier: TrainerSubscriptionTier {
        TrainerSubscriptionTier.recommended(for: clientCount)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48)).foregroundColor(gold)
                        Text("Nearby Trainers Pro")
                            .font(.system(size: 28, weight: .black)).foregroundColor(.white)
                        Text("Grow your business, manage more clients")
                            .font(.subheadline).foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    // Current status
                    if manager.isSubscribed {
                        currentStatusCard
                    } else {
                        // Free trial banner
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill").font(.title2).foregroundColor(gold)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1 Month Free Trial").font(.headline).foregroundColor(.white)
                                Text("No charge for your first month on Starter plan")
                                    .font(.caption).foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(gold.opacity(0.1))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(gold.opacity(0.3), lineWidth: 1)))
                    }

                    // Client count indicator
                    HStack {
                        Image(systemName: "person.2.fill").foregroundColor(gold)
                        Text("You currently have \(clientCount) active client\(clientCount == 1 ? "" : "s")")
                            .font(.subheadline).foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))

                    // Plan cards
                    if manager.isLoading {
                        ProgressView().tint(gold).padding(.vertical, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(TrainerSubscriptionTier.allCases, id: \.self) { tier in
                                PlanCard(
                                    tier: tier,
                                    product: manager.product(for: tier),
                                    isCurrentPlan: manager.purchasedTier == tier,
                                    isRecommended: recommendedTier == tier,
                                    onSelect: {
                                        Task {
                                            if let product = manager.product(for: tier) {
                                                _ = await manager.purchase(product)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }

                    // Error
                    if let error = manager.errorMessage {
                        Text(error).font(.caption).foregroundColor(.red)
                            .padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.1)))
                    }

                    // Restore
                    Button(action: { Task { await manager.restorePurchases() } }) {
                        Text("Restore Purchases")
                            .font(.caption).foregroundColor(.white.opacity(0.4))
                    }

                    Text("Subscriptions auto-renew monthly. Cancel anytime in Settings.")
                        .font(.caption2).foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center).padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Subscription").navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") { dismiss() }.foregroundColor(gold)
            }
        }
    }

    private var currentStatusCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill").font(.title2)
                    .foregroundColor(manager.purchasedTier?.color ?? gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(manager.subscriptionStatus)
                        .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                    if manager.isInTrialPeriod {
                        Text("\(manager.trialDaysRemaining) days left in free trial")
                            .font(.caption).foregroundColor(gold)
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14)
            .fill((manager.purchasedTier?.color ?? gold).opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke((manager.purchasedTier?.color ?? gold).opacity(0.3), lineWidth: 1)))
    }
}

// MARK: - Plan Card

struct PlanCard: View {
    let tier:          TrainerSubscriptionTier
    let product:       Product?
    let isCurrentPlan: Bool
    let isRecommended: Bool
    let onSelect:      () -> Void

    @State private var isPurchasing = false
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        VStack(spacing: 0) {
            // Recommended badge
            if isRecommended && !isCurrentPlan {
                HStack {
                    Spacer()
                    Text("RECOMMENDED FOR YOU")
                        .font(.system(size: 9, weight: .black)).tracking(1)
                        .foregroundColor(.black).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Capsule().fill(tier.color))
                    Spacer()
                }
                .padding(.bottom, 4)
            }

            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(tier.color.opacity(0.15)).frame(width: 44, height: 44)
                    Image(systemName: tier.icon).font(.system(size: 18)).foregroundColor(tier.color)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName).font(.system(size: 16, weight: .bold)).foregroundColor(.white)
                    Text(tier.clientRange).font(.caption).foregroundColor(.white.opacity(0.5))
                    if tier == .starter {
                        Text("1 month free trial").font(.caption).foregroundColor(gold)
                    }
                }

                Spacer()

                // Price + button
                VStack(alignment: .trailing, spacing: 6) {
                    if let product = product {
                        Text(product.displayPrice + "/mo")
                            .font(.system(size: 15, weight: .black)).foregroundColor(.white)
                    } else {
                        Text(tier.price + "/mo")
                            .font(.system(size: 15, weight: .black)).foregroundColor(.white)
                    }

                    if isCurrentPlan {
                        Text("Current").font(.caption).fontWeight(.bold)
                            .foregroundColor(tier.color).padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Capsule().fill(tier.color.opacity(0.15)))
                    } else {
                        Button(action: {
                            isPurchasing = true
                            onSelect()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isPurchasing = false }
                        }) {
                            if isPurchasing {
                                ProgressView().tint(.black).scaleEffect(0.8)
                                    .frame(width: 60, height: 28)
                            } else {
                                Text(tier == .starter ? "Try Free" : "Select")
                                    .font(.caption).fontWeight(.bold).foregroundColor(.black)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Capsule().fill(tier.color))
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(isCurrentPlan ? 0.08 : 0.04))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentPlan ? tier.color : Color.white.opacity(0.08), lineWidth: isCurrentPlan ? 1.5 : 1)))
    }
}

// MARK: - Subscription Status Badge (for Profile tab)

struct SubscriptionStatusBadge: View {
    @ObservedObject private var manager = SubscriptionManager.shared
    private let gold = Color(red: 212/255, green: 175/255, blue: 55/255)

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: manager.isSubscribed ? "checkmark.seal.fill" : "exclamationmark.circle.fill")
                .foregroundColor(manager.isSubscribed ? (manager.purchasedTier?.color ?? gold) : .orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(manager.isSubscribed ? "\(manager.purchasedTier?.displayName ?? "") Plan" : "No Subscription")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
                Text(manager.subscriptionStatus).font(.caption).foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)))
    }
}
