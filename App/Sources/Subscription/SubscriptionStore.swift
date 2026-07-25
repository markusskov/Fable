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
    /// Another money operation is still running — possibly started from a
    /// previous paywall presentation (round three: the per-sheet guard
    /// reset on reopen, letting operations overlap).
    case alreadyInProgress
}

enum RestoreOutcome: Equatable {
    case subscribed
    case nothingToRestore
    /// The App Store could not be reached.
    case failed
    case alreadyInProgress
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
    /// The catalog is Product-based and cannot be stubbed; tests pass false
    /// so start() stays fully deterministic (round three test verdict).
    private let loadsCatalog: Bool
    /// Single-flight entitlement refresh (round three, P1): all concurrent
    /// callers await ONE reader; a request arriving mid-read marks it stale
    /// so it loops once more before committing. Every caller therefore
    /// receives the WINNING derivation — never a snapshot that a newer
    /// cause has already invalidated. (The previous generation counter
    /// protected only the global commit and returned the stale value to
    /// the purchase/restore that asked.)
    private var refreshTask: Task<SubscriptionStatus, Never>?
    private var refreshIsStale = false
    /// Test observability for ordering proofs: how many callers have joined
    /// an in-flight refresh. Behaviour-free.
    private(set) var refreshJoinCount = 0
    /// The most recent entitlement snapshot, kept so a verified transaction
    /// arriving between reads can be folded in without another round trip.
    private var lastRecords: [EntitlementRecord] = []
    /// Verified transactions StoreKit has accepted but not yet reflected in
    /// `currentEntitlements`. Its entitlement view can lag a sale it has
    /// already signed, and granting-then-reconciling used to revoke access
    /// moments after taking the money (2026-07-24 review round four, P1).
    /// Keyed by transaction ID, so a renewal is never mistaken for the
    /// already confirmed transaction it replaces (round five, P1). In memory
    /// only: for auto-renewable subscriptions the durable record is Apple's
    /// entitlement, which is re-read at launch and on every foreground, so a
    /// local mirror could only ever be wrong in a staler direction.
    private var unconfirmedPurchases: [EntitlementRecord] = []
    /// Transactions an update has told us are revoked, held until the
    /// entitlement view stops reporting them. Without this, a refund that
    /// arrives before the read catches up is acknowledged with `finish()`
    /// while the stale active snapshot keeps granting (round five, P1).
    private var revokedTransactionIDs: Set<UInt64> = []
    /// A parent's approval is outstanding (Ask to Buy). Store-level so it
    /// survives the paywall being dismissed and reopened.
    private(set) var isAwaitingApproval = false
    /// One money operation at a time, across paywall presentations.
    private var isTransacting = false
    /// Coalesces catalog loads so a retry can never race an in-flight
    /// request or clobber its result.
    private var catalogTask: Task<Void, Never>?

    /// The client is injectable so entitlement lifecycle transitions can be
    /// forced in tests; production always talks to the real App Store.
    init(client: any StoreClient = LiveStoreClient(), loadsCatalog: Bool = true) {
        self.client = client
        self.loadsCatalog = loadsCatalog
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
        // Capture the client, not self: promoting `self` before an
        // effectively infinite loop is a store → task → store cycle that
        // keeps deinit (and thus the cancel) from ever running
        // (2026-07-24 review round two). `self` stays weak per iteration.
        let updates = client.updates
        updatesTask = Task { [weak self] in
            // Renewals, refunds, Ask-to-Buy approvals, and purchases made
            // on another device all arrive here.
            for await update in updates {
                guard let self else { return }
                // Apply the update's OWN verified facts first: a refresh
                // alone can return an entitlement view that has not caught
                // up yet, and finishing then acknowledges an approval or
                // renewal Fable never delivered (round-four P1). Skipping
                // finish on early exit is safe — StoreKit redelivers
                // unfinished transactions.
                if let record = update.record {
                    self.applyVerified(record)
                }
                await self.refreshStatus()
                await update.finish()
            }
        }
        Task {
            await refreshStatus()
            if loadsCatalog { await loadProducts() }
        }
    }

    /// Re-checks entitlements and retries a failed catalog load. Called on
    /// foregrounding and when the paywall appears, so an offline first launch
    /// is not sticky until restart and a subscription that lapsed or renewed
    /// while backgrounded is noticed promptly.
    func refreshOnReturn() async {
        await refreshStatus()
        await ensureCatalog()
    }

    /// Retries the catalog when it is missing or PARTIAL (one of two plans
    /// makes the paywall's default selection unbuyable). Callers that only
    /// care about entitlement (the paywall's dismiss check) should refresh
    /// first and not wait for this (round three).
    func ensureCatalog() async {
        if products.count < FablePlus.productIDs.count {
            await loadProducts()
        }
    }

    func loadProducts() async {
        // Coalesce: a retry joins the in-flight request instead of being
        // dropped, so "request skipped while loading, then the load failed"
        // can no longer strand the paywall (round three).
        if let running = catalogTask {
            return await running.value
        }
        let task = Task<Void, Never> {
            do {
                let loaded = try await Product.products(for: FablePlus.productIDs)
                let sorted = loaded.sorted { lhs, rhs in
                    Self.sortOrder(of: lhs) < Self.sortOrder(of: rhs)
                }
                // A SUCCESSFUL but partial response is a degradation too:
                // it must not replace a catalog that already offers more
                // (round four, P2 — only thrown failures were preserved).
                if products.isEmpty || sorted.count >= products.count {
                    products = sorted
                }
                if let subscription = products.first?.subscription {
                    isEligibleForIntroOffer = await subscription.isEligibleForIntroOffer
                }
            } catch {
                // Keep whatever catalog we already have: a failed RETRY must
                // not destroy a paywall that was already usable (round three).
            }
            productsUnavailable = products.isEmpty
        }
        catalogTask = task
        isLoadingProducts = true
        await task.value
        isLoadingProducts = false
        catalogTask = nil
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
        guard !isTransacting else { return .alreadyInProgress }
        isTransacting = true
        defer { isTransacting = false }
        do {
            switch try await client.purchase(productID: plan.productID, loaded: product(for: plan)) {
            case .successVerified(let record, let finish):
                // Apple's order: grant access from the verified
                // transaction's OWN facts, then finish, then reconcile. The
                // grant is held as unconfirmed until an entitlement read
                // actually shows it, so the reconcile cannot take back what
                // the family just paid for (round four, P1: round three
                // granted, finished, then let an empty read revoke it while
                // still reporting success).
                applyVerified(record)
                await finish()
                await refreshStatus()
                return status.isSubscribed ? .subscribed : .failed
            case .successUnverified:
                // Unfinished on purpose: it redelivers via updates once
                // verification can succeed.
                return .failed
            case .pending:
                // Ask to Buy: approval arrives later via the update stream,
                // which refreshes status; the paywall auto-dismisses then.
                // Remembered on the store so reopening the sheet still says
                // so. Deliberately NOT a permanent block: Apple sends
                // nothing when a parent declines, so a family that can never
                // retry would be stuck forever (round four, P2).
                isAwaitingApproval = true
                return .pending
            case .cancelled:
                return .cancelled
            }
        } catch {
            return .failed
        }
    }

    /// "Restore purchases" — required by App Review for any subscription app.
    func restore() async -> RestoreOutcome {
        guard !isTransacting else { return .alreadyInProgress }
        isTransacting = true
        defer { isTransacting = false }
        do {
            try await client.sync()
        } catch {
            return .failed
        }
        let refreshed = await refreshStatus()
        return refreshed.isSubscribed ? .subscribed : .nothingToRestore
    }

    /// Recomputes `status` from the entitlements StoreKit can currently
    /// verify. Single-flight with a stale-rerun: concurrent callers share
    /// one reader, and a call arriving mid-read forces one more read before
    /// the commit. Every caller gets the WINNING derivation — the round-two
    /// shape returned a knowingly superseded snapshot to the operation that
    /// asked, so a restore could report .subscribed after a refund had
    /// already committed .free (round-three P1).
    @discardableResult
    func refreshStatus() async -> SubscriptionStatus {
        if let running = refreshTask {
            // Joining is only possible while a read is actually in flight:
            // the leader's commit and its handle cleanup are synchronous
            // neighbours below, so there is no window where a caller can
            // attach to an already decided answer.
            refreshIsStale = true
            refreshJoinCount += 1
            return await running.value
        }
        let task = Task<SubscriptionStatus, Never> { [weak self] in
            guard let self else { return .unknown }
            var derived = SubscriptionStatus.unknown
            while true {
                self.refreshIsStale = false
                let records = await self.client.currentEntitlements()
                // A newer cause arrived while we were reading: that read is
                // stale by definition; read again rather than commit it.
                if self.refreshIsStale { continue }
                self.lastRecords = records
                self.recompute()
                derived = self.status
                break
            }
            self.refreshTask = nil
            return derived
        }
        refreshTask = task
        return await task.value
    }

    /// Folds a RAW verified transaction (an update, or a just completed
    /// purchase) into access immediately, before StoreKit's entitlement view
    /// is asked to agree.
    ///
    /// Raw transactions are not the same thing as `currentEntitlements`
    /// membership: Apple pre-vets that view (which is why grace periods must
    /// NOT be expiry-filtered), while `Transaction.updates` can replay an
    /// unfinished transaction that expired long ago. Round five found such a
    /// replay granting Fable+ for the rest of the process, so raw records
    /// are vetted here and trusted records are not.
    private func applyVerified(_ record: EntitlementRecord) {
        unconfirmedPurchases.removeAll { $0.transactionID == record.transactionID }
        if record.revocationDate != nil {
            revokedTransactionIDs.insert(record.transactionID)
        } else if grantsAccessOnItsOwn(record) {
            unconfirmedPurchases.append(record)
        }
        recompute()
    }

    /// Whether a raw transaction, judged alone, should grant access.
    private func grantsAccessOnItsOwn(_ record: EntitlementRecord, now: Date = .now) -> Bool {
        guard record.revocationDate == nil, !record.isUpgraded else { return false }
        // A raw record carries no grace-period context, so an elapsed
        // expiry means exactly what it says.
        if let expiry = record.expirationDate, expiry <= now { return false }
        return FablePlus.plan(forProductID: record.productID) != nil
    }

    /// Access is the entitlement view, minus anything an update has revoked,
    /// plus any verified transaction the view has not caught up with yet.
    private func recompute(now: Date = .now) {
        let live = lastRecords.filter { !revokedTransactionIDs.contains($0.transactionID) }
        // Identity is the transaction, never the SKU.
        let confirmed = Set(live.map(\.transactionID))
        unconfirmedPurchases.removeAll { confirmed.contains($0.transactionID) }
        // A bridge entry that expires mid-session stops bridging.
        unconfirmedPurchases.removeAll { !grantsAccessOnItsOwn($0, now: now) }
        // Tombstones the entitlement view already agrees with are spent.
        revokedTransactionIDs.formIntersection(Set(lastRecords.map(\.transactionID)))
        status = SubscriptionStatus.derive(from: live + unconfirmedPurchases)
        if status.isSubscribed { isAwaitingApproval = false }
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
