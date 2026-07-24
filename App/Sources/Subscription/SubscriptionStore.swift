import Foundation
import StoreKit

enum SubscriptionError: Error, Equatable {
    /// The store has no product for that plan — offline, or the SKU is not
    /// live yet in App Store Connect.
    case productUnavailable
    /// StoreKit could not vouch for the transaction's signature.
    case unverifiedTransaction
}

/// What actually happened when the family tried to subscribe. The paywall
/// speaks to each honestly — a pending Ask-to-Buy is not a cancellation
/// (2026-07-24 external money-path review, P2).
enum PurchaseOutcome: Equatable {
    case subscribed
    /// Waiting for a parent's approval (Ask to Buy). The approval arrives
    /// later through the update stream; the paywall stays ready for it.
    case pending
    case cancelled
    /// The App Store could not complete the purchase (offline, verification).
    case failed
}

enum RestoreOutcome: Equatable {
    case subscribed
    case nothingToRestore
    /// The App Store could not be reached.
    case failed
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

    private let client: any StoreClient
    private var updatesTask: Task<Void, Never>?
    private var hasStarted = false
    /// Monotonic guard against interleaved refreshes: an entitlement snapshot
    /// read before a newer refresh began must never overwrite the newer
    /// truth (2026-07-24 external money-path review — a refund landing
    /// mid-refresh could be undone by the stale first snapshot).
    private var refreshGeneration = 0

    /// The client is injectable so entitlement lifecycle transitions can be
    /// forced in tests; production always talks to the real App Store.
    init(client: any StoreClient = LiveStoreClient()) {
        self.client = client
    }

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
    /// Genuinely idempotent: repeat calls are no-ops for the listener AND
    /// the bootstrap, so overlapping catalog requests cannot race.
    func start() {
        guard !hasStarted else { return }
        hasStarted = true
        updatesTask = Task { [weak self] in
            // Renewals, refunds, Ask-to-Buy approvals, and purchases made
            // on another device all arrive here.
            guard let self else { return }
            for await _ in client.updates {
                await self.refreshStatus()
            }
        }
        Task {
            await refreshStatus()
            await loadProducts()
        }
    }

    /// Re-checks entitlements and retries a failed catalog load. Called on
    /// foregrounding and when the paywall appears, so an offline first launch
    /// is not sticky until restart and a subscription that lapsed or renewed
    /// while backgrounded is noticed promptly.
    func refreshOnReturn() async {
        await refreshStatus()
        if products.isEmpty, !isLoadingProducts {
            await loadProducts()
        }
    }

    func loadProducts() async {
        guard !isLoadingProducts else { return }
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

    /// What happened, honestly — the paywall narrates each outcome instead
    /// of collapsing pending/offline/verification into "nothing happened".
    func purchase(_ plan: FablePlus.Plan) async -> PurchaseOutcome {
        guard let product = product(for: plan) else { return .failed }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    return .failed
                }
                await transaction.finish()
                await refreshStatus()
                return status.isSubscribed ? .subscribed : .failed
            case .pending:
                // Ask to Buy: approval arrives later via the update stream,
                // which refreshes status; the paywall auto-dismisses then.
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed
            }
        } catch {
            return .failed
        }
    }

    /// "Restore purchases" — required by App Review for any subscription app.
    func restore() async -> RestoreOutcome {
        do {
            try await client.sync()
        } catch {
            return .failed
        }
        await refreshStatus()
        return status.isSubscribed ? .subscribed : .nothingToRestore
    }

    /// Recomputes `status` from the entitlements StoreKit can currently
    /// verify. Latest-wins: if a newer refresh started while this one was
    /// suspended reading entitlements, this snapshot is stale and discarded.
    func refreshStatus() async {
        refreshGeneration += 1
        let generation = refreshGeneration
        let records = await client.currentEntitlements()
        guard generation == refreshGeneration else { return }
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
