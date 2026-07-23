import Foundation
import StoreKit

enum SubscriptionError: Error, Equatable {
    /// The store has no product for that plan — offline, or the SKU is not
    /// live yet in App Store Connect.
    case productUnavailable
    /// StoreKit could not vouch for the transaction's signature.
    case unverifiedTransaction
}

/// Owns every StoreKit interaction in the app: loading the Fable+ products,
/// purchasing, restoring, and keeping `status` current as entitlements change.
///
/// StoreKit 2 talks to the App Store, not to us — this is the one place in
/// Fable that reaches the network, and no child data goes with it.
@MainActor
@Observable
final class SubscriptionStore {
    private(set) var status: SubscriptionStatus = .unknown
    /// Loaded products in paywall order (yearly first). Empty until loaded.
    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    /// True while the family can still claim the introductory free week.
    /// StoreKit applies the offer automatically at purchase; this only
    /// controls whether the paywall talks about it.
    private(set) var isEligibleForIntroOffer = false
    /// Set when the store could not be reached. The paywall shows a quiet
    /// "try again later" rather than an error alert — never break bedtime.
    private(set) var productsUnavailable = false

    private var updatesTask: Task<Void, Never>?

    // In the app this store lives as long as the process, but nothing should
    // rely on that: without the cancel, the updates listener would keep a
    // deallocating store's task alive in tests or previews. `isolated` so the
    // main-actor property is legal to touch here.
    isolated deinit {
        updatesTask?.cancel()
    }

    var isSubscribed: Bool {
        #if DEBUG
        // UI verification in plain simulators, where StoreKit test purchases
        // can't run: `simctl launch <udid> com.markusskov.fable -fable-debug-plus`.
        // DEBUG builds only; release builds never compile this branch.
        if ProcessInfo.processInfo.arguments.contains("-fable-debug-plus") { return true }
        #endif
        return status.isSubscribed
    }

    /// Begins listening for entitlement changes and loads the catalog.
    /// Idempotent, so it is safe to call from a view's `.task`.
    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                // Renewals, refunds, Ask-to-Buy approvals, and purchases made
                // on another device all arrive here.
                for await update in Transaction.updates {
                    guard let self else { return }
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    await self.refreshStatus()
                }
            }
        }
        Task {
            await refreshStatus()
            await loadProducts()
        }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: FablePlus.productIDs)
            products = loaded.sorted { lhs, rhs in
                Self.sortOrder(of: lhs) < Self.sortOrder(of: rhs)
            }
            productsUnavailable = products.isEmpty
            if let subscription = products.first?.subscription {
                isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
            }
        } catch {
            products = []
            productsUnavailable = true
        }
    }

    /// The introductory free-trial line for a plan ("1 week free"), or nil
    /// when there is no free trial or the family already used it.
    func freeTrialText(for plan: FablePlus.Plan) -> String? {
        guard isEligibleForIntroOffer,
              let offer = product(for: plan)?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial
        else { return nil }
        // Singular forms ("1 week free") live in the string catalog's plural
        // variations; one key per unit because unit words decline differently
        // across languages.
        let count = offer.period.value
        switch offer.period.unit {
        case .day: return String(localized: "\(count) days free")
        case .week: return String(localized: "\(count) weeks free")
        case .month: return String(localized: "\(count) months free")
        case .year: return String(localized: "\(count) years free")
        @unknown default: return String(localized: "\(count) periods free")
        }
    }

    func product(for plan: FablePlus.Plan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    /// Returns true when the family now has Fable+. A cancelled sheet or a
    /// purchase awaiting a parent's approval returns false without throwing —
    /// neither is an error worth surfacing.
    @discardableResult
    func purchase(_ plan: FablePlus.Plan) async throws -> Bool {
        guard let product = product(for: plan) else { throw SubscriptionError.productUnavailable }
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw SubscriptionError.unverifiedTransaction
            }
            await transaction.finish()
            await refreshStatus()
            return status.isSubscribed
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    /// "Restore purchases" — required by App Review for any subscription app.
    func restore() async throws {
        try await AppStore.sync()
        await refreshStatus()
    }

    /// Recomputes `status` from the entitlements StoreKit can currently verify.
    func refreshStatus() async {
        var records: [EntitlementRecord] = []
        for await result in Transaction.currentEntitlements {
            // Unverified entitlements are ignored outright: a signature we
            // cannot check is not a purchase we honour.
            guard case .verified(let transaction) = result else { continue }
            records.append(
                EntitlementRecord(
                    productID: transaction.productID,
                    expirationDate: transaction.expirationDate,
                    revocationDate: transaction.revocationDate,
                    isUpgraded: transaction.isUpgraded
                )
            )
        }
        status = SubscriptionStatus.derive(from: records)
    }

    // MARK: - Paywall copy helpers

    /// Honest saving of yearly over monthly, or nil when both prices are not
    /// loaded or the saving does not round to a whole percent.
    var yearlySavingPercent: Int? {
        guard let monthly = product(for: .monthly), let yearly = product(for: .annual) else { return nil }
        return FablePlus.yearlySavingPercent(monthlyPrice: monthly.price, yearlyPrice: yearly.price)
    }

    /// A plan's price expressed per month, in the storefront's currency, so
    /// the two options can be compared without mental arithmetic.
    func monthlyEquivalentPrice(for plan: FablePlus.Plan) -> String? {
        guard let product = product(for: plan) else { return nil }
        let perMonth = FablePlus.monthlyEquivalent(of: product.price, plan: plan)
        return perMonth.formatted(product.priceFormatStyle)
    }

    private static func sortOrder(of product: Product) -> Int {
        FablePlus.plan(forProductID: product.id)?.sortOrder ?? .max
    }
}
