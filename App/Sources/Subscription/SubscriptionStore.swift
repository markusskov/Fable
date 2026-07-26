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
    /// The last settled answer from Apple. PRIVATE on purpose: every
    /// customer-facing decision must go through `canAdvertiseIntroOffer`, so
    /// the raw flag cannot be wired back into copy by accident (round ten).
    private var isEligibleForIntroOffer = false
    /// The epoch the current answer was obtained FOR. Nil means unsettled.
    private var settledEpoch: Int?
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
    /// Transactions an update has told us are revoked. Kept for the life of
    /// the process: a refund is irreversible for THAT transaction, and a
    /// renewal always carries a new ID, so a tombstone can never wrongly
    /// deny future access. Round five retired them against the entitlement
    /// snapshot, which meant a refund arriving before the purchase had even
    /// propagated deleted its own tombstone and let the next stale read
    /// grant access back (round six, P1).
    private var revokedTransactionIDs: Set<UInt64> = []
    /// Latest-wins for eligibility: a query that suspended before a purchase
    /// must not resume afterwards and re-advertise a spent free week.
    /// Bumped by every event that casts doubt on the trial answer: a display
    /// boundary, an access transition, any verified subscription-group
    /// update. A query answers for the epoch it STARTED in and may only
    /// commit if that epoch is still current — round eleven let the query
    /// create its own newer generation, which meant any late workflow could
    /// declare the offer settled and undo a boundary's invalidation
    /// (round twelve, P2).
    private var doubtEpoch = 0
    /// Queries in flight. SEPARATE from the epoch on purpose: the epoch
    /// decides whether an answer is still VALID, this decides whether we are
    /// currently sure enough to say anything. Merging them was the round
    /// eleven mistake — a query that minted its own epoch could declare the
    /// offer settled and undo a boundary's invalidation (round twelve).
    /// Commit ORDER among concurrent queries, which is a third concern again:
    /// two queries in the same epoch must still not let the older one
    /// overwrite the newer one's answer.
    private var nextEligibilityQueryID = 0
    private var lastCommittedEligibilityQueryID = 0
    /// The epochs of queries currently in flight. Scoped, not a global count:
    /// a stalled query from an old epoch must not keep hiding a valid current
    /// answer forever (round thirteen, P2).
    private var inFlightEligibilityEpochs: [Int] = []
    /// The epoch in which ENTITLEMENT status was last committed. Advertising
    /// requires this to be current, which is what makes the boundary hold:
    /// an eligibility answer cannot speak for an epoch whose access status
    /// has not been re-read yet, no matter when the query itself started
    /// (round thirteen, P2 — capturing the epoch at query start was too
    /// late, because a workflow that read status BEFORE the boundary could
    /// still start its query after it).
    private var statusSettledEpoch: Int?
    /// Whether the paywall may SAY there is a free week: a settled answer,
    /// still eligible, and no live access.
    var canAdvertiseIntroOffer: Bool {
        // Also: not while the authoritative entitlement read is outstanding.
        // Generations order QUERIES, not whole refresh workflows, so an
        // older catalog workflow could otherwise settle the offer against a
        // status a newer read was already in the middle of replacing
        // (round eleven, P2).
        isEligibleForIntroOffer
            && settledEpoch == doubtEpoch
            && statusSettledEpoch == doubtEpoch
            && !inFlightEligibilityEpochs.contains(doubtEpoch)
            && refreshTask == nil
            && !status.isSubscribed
    }

    /// Marks the offer unsettled. Synchronous by contract: entry points call
    /// it BEFORE their first suspension, so a cached "free week" is never on
    /// screen while entitlement or catalog work is still in flight
    /// (round ten, P2 — round nine only hid it once the query itself began).
    func invalidateIntroEligibility() {
        doubtEpoch += 1
        settledEpoch = nil
    }
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
                } else {
                    // An unverified update carries no facts to honour, but it
                    // is still news about this account's purchases: the trial
                    // claim becomes unsettled until re-queried.
                    self.invalidateIntroEligibility()
                }
                await self.refreshStatus()
                await update.finish()
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
        invalidateIntroEligibility()
        await refreshStatus()
        await ensureCatalog()
        await refreshIntroEligibility()
    }

    /// Eligibility is a fact about the Apple Account, not about the catalog,
    /// and it changes the moment a trial is used on any device. Re-asked on
    /// every return so a stale yes cannot keep selling a free week.
    func refreshIntroEligibility() async {
        // Answer FOR the current epoch; do not mint a new one. A query is
        // never itself a reason to trust the answer.
        let epoch = doubtEpoch
        nextEligibilityQueryID += 1
        let queryID = nextEligibilityQueryID
        inFlightEligibilityEpochs.append(epoch)
        defer {
            if let index = inFlightEligibilityEpochs.firstIndex(of: epoch) {
                inFlightEligibilityEpochs.remove(at: index)
            }
        }
        let eligible = await client.isEligibleForIntroOffer(
            productID: FablePlus.Plan.annual.productID,
            loaded: product(for: .annual)
        )
        // A purchase (or any verified subscription) that landed while this
        // query was suspended has already spent the offer.
        // Valid for the current epoch AND not already superseded by a newer
        // query that has committed.
        guard epoch == doubtEpoch, queryID > lastCommittedEligibilityQueryID else { return }
        lastCommittedEligibilityQueryID = queryID
        // And a lagging `true` from a query that started AFTER the purchase
        // carries the newest generation, so the generation guard cannot see
        // it: eligibility may never contradict live access. Deliberately not
        // a permanent local flag — a lapsed family that never used an offer
        // can become eligible again, and this re-asks whenever they are free.
        isEligibleForIntroOffer = eligible && !status.isSubscribed
        settledEpoch = epoch
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
        // Tests opt out of the live catalog entirely: `loadsCatalog` gated
        // only start() before, so refreshOnReturn still reached
        // Product.products and made completion environment-dependent
        // (round eleven, test finding).
        guard loadsCatalog else { return }
        // Coalesce: a retry joins the in-flight request instead of being
        // dropped, so "request skipped while loading, then the load failed"
        // can no longer strand the paywall (round three).
        if let running = catalogTask {
            return await running.value
        }
        let task = Task<Void, Never> {
            do {
                let loaded = try await Product.products(for: FablePlus.productIDs)  // catalog only
                let sorted = loaded.sorted { lhs, rhs in
                    Self.sortOrder(of: lhs) < Self.sortOrder(of: rhs)
                }
                // A SUCCESSFUL but partial response is a degradation too:
                // it must not replace a catalog that already offers more
                // (round four, P2 — only thrown failures were preserved).
                if products.isEmpty || sorted.count >= products.count {
                    products = sorted
                }
                await refreshIntroEligibility()
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
        guard canAdvertiseIntroOffer,
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
                // Access stays fail-closed, but the App Store accepted a
                // purchase we could not verify: the free week may well be
                // spent now, so the CLAIM must stop being made until a
                // fresh query says otherwise (round thirteen, P2).
                invalidateIntroEligibility()
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
                // Stamped AFTER recompute: a transition discovered BY this
                // read bumps the epoch, and this read is the very news that
                // settles it. Stamping first left status permanently one
                // epoch behind its own discovery.
                self.statusSettledEpoch = self.doubtEpoch
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
        // Any verified news about our subscription group — purchase, renewal,
        // refund — makes the cached trial answer suspect, even when access
        // does not change. A refund arriving while already free left the old
        // `true` advertisable (round twelve, P2). An authoritative query
        // re-establishes it afterwards.
        if FablePlus.plan(forProductID: record.productID) != nil {
            invalidateIntroEligibility()
        }
        unconfirmedPurchases.removeAll { $0.transactionID == record.transactionID }
        if record.revocationDate != nil {
            revokedTransactionIDs.insert(record.transactionID)
        } else if grantsAccessOnItsOwn(record) {
            // A revoked transaction stays revoked no matter which source
            // reports it, or in what order. A purchase result that was
            // suspended while the refund landed carries a snapshot from
            // before the refund; honouring it re-granted access the account
            // no longer has (round seven, P1).
            if !revokedTransactionIDs.contains(record.transactionID) {
                unconfirmedPurchases.append(record)
                isEligibleForIntroOffer = false
            }
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
        // Revocation dominates every source, so it is applied to both the
        // entitlement view and the bridge before anything else.
        unconfirmedPurchases.removeAll { revokedTransactionIDs.contains($0.transactionID) }
        let live = lastRecords.filter { !revokedTransactionIDs.contains($0.transactionID) }
        // Identity is the transaction, never the SKU.
        let confirmed = Set(live.map(\.transactionID))
        unconfirmedPurchases.removeAll { confirmed.contains($0.transactionID) }
        // A bridge entry that expires mid-session stops bridging.
        unconfirmedPurchases.removeAll { !grantsAccessOnItsOwn($0, now: now) }
        let wasSubscribed = status.isSubscribed
        status = SubscriptionStatus.derive(from: live + unconfirmedPurchases)
        if status.isSubscribed != wasSubscribed {
            // BOTH directions invalidate an eligibility query that spans the
            // transition. Round eight only invalidated on the way in, so an
            // answer captured while subscribed could commit after a lapse
            // (round nine, P2).
            invalidateIntroEligibility()
        }
        if status.isSubscribed {
            isAwaitingApproval = false
            // ANY active subscription spends the free week, including one
            // discovered only through the entitlement view (a restore, a
            // cold launch, another device).
            isEligibleForIntroOffer = false
        }
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
