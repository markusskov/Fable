import Foundation
import StoreKit
import Synchronization
import Testing
@testable import Fable

/// Checks `App/StoreKit/Fable.storekit` against the catalog the app compiles
/// against, so a hand-edit to either one cannot drift silently.
///
/// This reads the configuration as data rather than driving it through
/// `SKTestSession`: under `xcodebuild` (which is how both this machine and CI
/// run tests) the simulator's storekitd rejects every attempt to install a
/// test configuration — `saveConfigurationData` fails with
/// `SKInternalErrorDomain` 3 even for a minimal, canonical file. Live purchase
/// flows therefore have to be exercised from Xcode's Run action, which does
/// apply the configuration; see the note in docs/ROADMAP.md.
struct StoreKitConfigurationTests {
    private let configuration: StoreKitConfiguration

    init() throws {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "Fable", withExtension: "storekit"))
        configuration = try JSONDecoder().decode(StoreKitConfiguration.self, from: Data(contentsOf: url))
    }

    @Test func hasOneGroupMatchingTheAppsCatalog() throws {
        let group = try #require(configuration.subscriptionGroups.first)
        #expect(configuration.subscriptionGroups.count == 1)
        #expect(group.id == FablePlus.subscriptionGroupID)
        #expect(Set(group.subscriptions.map(\.productID)) == Set(FablePlus.productIDs))
        for subscription in group.subscriptions {
            #expect(subscription.subscriptionGroupID == FablePlus.subscriptionGroupID)
            #expect(subscription.type == "RecurringSubscription")
        }
    }

    @Test func periodsMatchThePlanTheyClaimToBe() throws {
        let group = try #require(configuration.subscriptionGroups.first)
        let periods = Dictionary(
            uniqueKeysWithValues: group.subscriptions.map { ($0.productID, $0.recurringSubscriptionPeriod) }
        )
        #expect(periods[FablePlus.Plan.monthly.productID] == "P1M")
        #expect(periods[FablePlus.Plan.annual.productID] == "P1Y")
    }

    /// The paywall will advertise a yearly saving. Anchor it to the prices
    /// actually configured, so a price edit that makes the claim dishonest
    /// fails here first.
    @Test func configuredPricesSupportAnHonestSavingsClaim() throws {
        let group = try #require(configuration.subscriptionGroups.first)
        let prices = Dictionary(uniqueKeysWithValues: group.subscriptions.map { ($0.productID, $0.displayPrice) })
        let monthlyPrice = try #require(prices[FablePlus.Plan.monthly.productID])
        let yearlyPrice = try #require(prices[FablePlus.Plan.annual.productID])
        let monthly = try #require(Decimal(string: monthlyPrice))
        let yearly = try #require(Decimal(string: yearlyPrice))

        #expect(FablePlus.yearlySavingPercent(monthlyPrice: monthly, yearlyPrice: yearly) == 33)
        #expect(FablePlus.monthlyEquivalent(of: yearly, plan: .annual) == Decimal(string: "3.33"))
    }

    /// Bedtime stories are a household purchase, not a per-parent one.
    @Test func bothPlansAreFamilyShareable() throws {
        let group = try #require(configuration.subscriptionGroups.first)
        let shareable = group.subscriptions.allSatisfy(\.familyShareable)
        #expect(shareable)
    }
}

/// The slice of the `.storekit` schema this project cares about.
private struct StoreKitConfiguration: Decodable {
    struct Group: Decodable {
        var id: String
        var subscriptions: [Subscription]
    }

    struct Subscription: Decodable {
        struct IntroductoryOffer: Decodable {
            var paymentMode: String
            var subscriptionPeriod: String
            var numberOfPeriods: Int
        }

        var productID: String
        var displayPrice: String
        var recurringSubscriptionPeriod: String
        var subscriptionGroupID: String
        var familyShareable: Bool
        var type: String
        var introductoryOffer: IntroductoryOffer?
    }

    var subscriptionGroups: [Group]
}

private final class BundleToken {}

extension StoreKitConfigurationTests {
    /// The paywall sells a 7-day free trial on the yearly plan ONLY. The
    /// local configuration must model it, or trial eligibility and pricing
    /// copy are never exercised before App Store review is
    /// (2026-07-24 money-path review test verdict).
    @Test func yearlyCarriesTheFreeWeekAndMonthlyDoesNot() throws {
        let group = try #require(configuration.subscriptionGroups.first)
        let offers = Dictionary(
            uniqueKeysWithValues: group.subscriptions.map { ($0.productID, $0.introductoryOffer) }
        )
        let yearly = try #require(offers[FablePlus.Plan.annual.productID] ?? nil)
        #expect(yearly.paymentMode == "free")
        #expect(yearly.subscriptionPeriod == "P1W")
        #expect(yearly.numberOfPeriods == 1)
        #expect((offers[FablePlus.Plan.monthly.productID] ?? nil) == nil)
    }
}

/// Boxed shared state for the stub's nonisolated observations. `Mutex` is
/// noncopyable, so closures cannot capture it directly.
private final class Cell<Value: Sendable>: Sendable {
    private let mutex: Mutex<Value>
    init(_ value: Value) { mutex = Mutex(value) }
    func with<R>(_ body: (inout sending Value) -> sending R) -> sending R { mutex.withLock(body) }
    var value: Value { mutex.withLock { $0 } }
}

/// A StoreKit stand-in whose entitlement answers, update signals, purchase
/// results, and sync behaviour the tests control completely — the injectable
/// boundary the money-path review required so lifecycle transitions are
/// provable instead of environment-dependent.
///
/// Ordering is signalled, not slept on: `readStarted` fires when a read
/// begins, so tests await a real event rather than polling a clock
/// (2026-07-24 review round three, test verdict).
private actor StubStoreClient: StoreClient {
    /// Answers for successive `currentEntitlements()` calls. The last entry
    /// repeats once exhausted, so a test can script "read 1 sees the old
    /// world, every later read sees the new one".
    private var scriptedReads: [[EntitlementRecord]] = [[]]
    private var readIndex = 0
    private var heldReads: [CheckedContinuation<Void, Never>] = []
    private var holdsRemaining = 0
    private var shouldFailSync = false
    private var purchaseResult: ClientPurchaseResult?
    /// Product IDs `purchase` was actually asked for, and whether the caller
    /// handed over an already loaded product.
    private(set) var purchaseRequests: [String] = []
    private(set) var purchasedWithLoadedProduct: [Bool] = []

    private nonisolated let stream: AsyncStream<StoreUpdate>
    private nonisolated let updatesContinuation: AsyncStream<StoreUpdate>.Continuation
    private nonisolated let readStartedStream: AsyncStream<Void>
    private nonisolated let readStartedContinuation: AsyncStream<Void>.Continuation

    private nonisolated let readCountCell = Cell(0)
    private nonisolated let terminated = Cell(false)
    private nonisolated let updatesAccesses = Cell(0)
    /// Set by a test after building its store: answers "was access already
    /// applied?" at the instant `finish` runs, which is the only way to
    /// prove Apple's deliver-then-finish order from the outside.
    nonisolated let accessAtFinish = Cell<Bool?>(nil)
    nonisolated let observeAccess = Cell<(@Sendable () async -> Bool)?>(nil)

    nonisolated var updates: AsyncStream<StoreUpdate> {
        updatesAccesses.with { $0 += 1 }
        return stream
    }

    nonisolated var updatesAccessCount: Int { updatesAccesses.value }
    nonisolated var wasTerminated: Bool { terminated.value }
    /// Every entitlement read, from any caller — the honest measure of
    /// "start() bootstrapped once", which counting stream accesses was not.
    nonisolated var readCount: Int { readCountCell.value }

    init() {
        (stream, updatesContinuation) = AsyncStream<StoreUpdate>.makeStream()
        (readStartedStream, readStartedContinuation) = AsyncStream<Void>.makeStream()
        let terminated = terminated
        updatesContinuation.onTermination = { _ in terminated.with { $0 = true } }
    }

    /// Suspends until a read begins. A real signal: if the read never
    /// happens the test hangs and fails, rather than sleeping past it.
    nonisolated func waitForReadToStart() async {
        var iterator = readStartedStream.makeAsyncIterator()
        _ = await iterator.next()
    }

    func script(reads: [[EntitlementRecord]]) { scriptedReads = reads; readIndex = 0 }
    func set(entitlements records: [EntitlementRecord]) { scriptedReads = [records]; readIndex = 0 }
    func failSync(_ fail: Bool) { shouldFailSync = fail }
    func stubPurchase(_ result: ClientPurchaseResult?) { purchaseResult = result }

    /// The next `currentEntitlements` call snapshots its answer, then
    /// suspends until released — the seam that reproduces "an older read is
    /// still in flight when a newer cause lands".
    func holdNextRead() { holdsRemaining += 1 }
    var heldReadCount: Int { heldReads.count }

    func releaseHeldReads() {
        heldReads.forEach { $0.resume() }
        heldReads.removeAll()
    }

    nonisolated func signalUpdate(record: EntitlementRecord? = nil, finish: @escaping @Sendable () async -> Void = {}) {
        updatesContinuation.yield(StoreUpdate(record: record, finish: finish))
    }

    func currentEntitlements() async -> [EntitlementRecord] {
        readCountCell.with { $0 += 1 }
        // Snapshot BEFORE suspending: models a read that already has its
        // (possibly soon-stale) answer and is merely waiting to return.
        let snapshot = scriptedReads[min(readIndex, scriptedReads.count - 1)]
        readIndex += 1
        if holdsRemaining > 0 {
            holdsRemaining -= 1
            readStartedContinuation.yield()
            await withCheckedContinuation { heldReads.append($0) }
        }
        return snapshot
    }

    func sync() async throws {
        if shouldFailSync { throw SubscriptionError.productUnavailable }
    }

    private var introEligible = false
    private var heldPurchases: [CheckedContinuation<Void, Never>] = []
    private var holdNextPurchase = false

    func setIntroEligible(_ eligible: Bool) { introEligible = eligible }
    func isEligibleForIntroOffer(productID: String, loaded: Product?) async -> Bool {
        introEligible
    }

    /// The next purchase suspends after its result is decided but before it
    /// is returned — the shape of a result that was in flight while a refund
    /// landed (round seven, P1).
    func holdNextPurchaseResult() { holdNextPurchase = true }
    var heldPurchaseCount: Int { heldPurchases.count }
    func releaseHeldPurchases() {
        heldPurchases.forEach { $0.resume() }
        heldPurchases.removeAll()
    }

    func purchase(productID: String, loaded: Product?) async throws -> ClientPurchaseResult {
        purchaseRequests.append(productID)
        purchasedWithLoadedProduct.append(loaded != nil)
        guard let purchaseResult else { throw SubscriptionError.productUnavailable }
        if holdNextPurchase {
            holdNextPurchase = false
            readStartedContinuation.yield()
            await withCheckedContinuation { heldPurchases.append($0) }
        }
        // Verified results carry a finish hook; wrap it so the test can see
        // whether access was live at the moment it ran.
        if case .successVerified(let record, _) = purchaseResult {
            let observe = observeAccess
            let accessAtFinish = accessAtFinish
            return .successVerified(record, finish: {
                let granted = await observe.value?() ?? false
                accessAtFinish.with { $0 = granted }
            })
        }
        return purchaseResult
    }
}

@MainActor
struct SubscriptionStoreTests {
    private static func activeRecord(_ plan: FablePlus.Plan = .monthly) -> EntitlementRecord {
        EntitlementRecord(productID: plan.productID, expirationDate: .now.addingTimeInterval(86_400))
    }

    /// A store wired to a stub, with the live catalog request disabled so
    /// `start()` touches nothing real (round-three test verdict).
    private static func makeStore(_ client: StubStoreClient) -> SubscriptionStore {
        SubscriptionStore(client: client, loadsCatalog: false)
    }

    /// Awaits a main-actor condition driven by a background task. Returns
    /// false on timeout so callers can fail loudly with `#require`.
    private func settles(within seconds: Double = 5, _ condition: () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if condition() { return true }
            await Task.yield()
        }
        return condition()
    }

    /// With no products loaded and no scripted result, the client refuses
    /// and the caller learns that without a StoreKit sheet ever appearing.
    @Test func purchasingAPlanWithNoLoadedProductFailsCleanly() async {
        let store = Self.makeStore(StubStoreClient())
        #expect(await store.purchase(.monthly) == .failed)
    }

    /// Gating must never open just because the entitlement check has not run.
    @Test func statusStartsUnknownAndGatesClosed() {
        let store = Self.makeStore(StubStoreClient())
        #expect(store.status == .unknown)
        #expect(store.isSubscribed == false)
    }

    /// No entitlements: the derivation must settle on free rather than
    /// staying unknown forever.
    @Test func refreshSettlesOnFreeWithoutEntitlements() async {
        let store = Self.makeStore(StubStoreClient())
        await store.refreshStatus()
        #expect(store.status == .free)
    }

    /// THE grace-period reproduction: Apple vends the entitlement with a
    /// past expiration date while it retries billing; the family keeps Fable+.
    @Test func billingGraceFamilyKeepsFablePlus() async {
        let client = StubStoreClient()
        await client.set(entitlements: [
            EntitlementRecord(
                productID: FablePlus.Plan.annual.productID,
                expirationDate: .now.addingTimeInterval(-3 * 86_400)
            ),
        ])
        let store = Self.makeStore(client)
        await store.refreshStatus()
        #expect(store.status == .subscribed(.annual))
    }

    // MARK: - Apple's deliver-then-finish order (round three, P1)

    /// A verified purchase grants access from the transaction's OWN facts,
    /// before the transaction is finished — so a later empty entitlement
    /// read cannot turn a real sale into a reported failure, and Fable never
    /// acknowledges a purchase it has not yet honoured.
    @Test func aVerifiedPurchaseGrantsAccessFromItsOwnTransactionBeforeFinishing() async throws {
        let client = StubStoreClient()
        // Every entitlement read is EMPTY: the propagation delay that used
        // to make a successful purchase report .failed.
        await client.set(entitlements: [])
        await client.stubPurchase(.successVerified(Self.activeRecord(.annual), finish: {}))
        let store = Self.makeStore(client)
        client.observeAccess.with { $0 = { @Sendable in await MainActor.run { store.isSubscribed } } }

        let outcome = await store.purchase(.annual)
        #expect(outcome == .subscribed)
        // The order Apple documents: access applied, THEN finish.
        let accessAtFinish = try #require(client.accessAtFinish.value)
        #expect(accessAtFinish, "the transaction was finished before access was granted")
        // And it must SURVIVE the reconcile that follows. Round three
        // granted, finished, then let the empty read revoke access while
        // still reporting success: the paywall dismissed and the charged
        // family landed back in free-tier gating (round four, P1).
        #expect(store.isSubscribed, "the reconcile revoked access the family had just paid for")
        #expect(await settles { store.isSubscribed }, "access was revoked moments after the purchase")
    }

    /// A verified purchase is not immortal: a refund arriving through the
    /// update stream retires the unconfirmed grant.
    @Test func arefundRetiresAnUnconfirmedPurchase() async {
        let client = StubStoreClient()
        await client.set(entitlements: [])
        await client.stubPurchase(.successVerified(Self.activeRecord(.annual), finish: {}))
        let store = Self.makeStore(client)
        store.start()
        #expect(await store.purchase(.annual) == .subscribed)
        #expect(store.isSubscribed)

        var refunded = Self.activeRecord(.annual)
        refunded.revocationDate = .now
        client.signalUpdate(record: refunded)
        #expect(await settles { store.status == .free }, "a refunded purchase kept its access")
    }

    /// An unverified purchase is never honoured and never finished, so
    /// StoreKit can redeliver it once verification succeeds.
    @Test func anUnverifiedPurchaseIsRefusedAndLeftUnfinished() async {
        let client = StubStoreClient()
        await client.stubPurchase(.successUnverified)
        let store = Self.makeStore(client)
        #expect(await store.purchase(.annual) == .failed)
        #expect(store.isSubscribed == false)
        #expect(client.accessAtFinish.value == nil, "an unverified purchase must not be finished")
    }

    @Test func purchaseOutcomesMapHonestlyThroughTheSeam() async {
        let client = StubStoreClient()
        let store = Self.makeStore(client)

        await client.stubPurchase(.pending)
        #expect(await store.purchase(.annual) == .pending)
        #expect(store.isSubscribed == false, "Ask to Buy must not grant access before approval")

        await client.stubPurchase(.cancelled)
        #expect(await store.purchase(.annual) == .cancelled)

        await client.stubPurchase(nil) // client throws: offline/unavailable
        #expect(await store.purchase(.annual) == .failed)
    }

    /// The purchase reaches the client with the plan the family chose, and
    /// hands over the already displayed product rather than forcing a second
    /// catalog lookup (round three, P2). Tests cannot construct a `Product`,
    /// so the flag is false here; the assertion pins the plumbing.
    @Test func purchaseForwardsTheSelectedPlanToTheClient() async {
        let client = StubStoreClient()
        await client.stubPurchase(.cancelled)
        let store = Self.makeStore(client)
        _ = await store.purchase(.annual)
        _ = await store.purchase(.monthly)
        #expect(await client.purchaseRequests == [
            FablePlus.Plan.annual.productID,
            FablePlus.Plan.monthly.productID,
        ])
        #expect(await client.purchasedWithLoadedProduct == [false, false])
    }

    // MARK: - One winning answer per refresh (round three, P1)

    /// A refund landing while a restore's entitlement read is in flight must
    /// decide BOTH the global state and the restore's own answer. The reads
    /// are scripted differently on purpose: read 1 sees the pre-refund world,
    /// every later read sees the refund. The old shape returned that first,
    /// knowingly superseded snapshot to the caller and answered .subscribed.
    @Test func aRestoreCannotReportSubscribedFromASupersededRead() async throws {
        let client = StubStoreClient()
        await client.script(reads: [[Self.activeRecord()], []])
        await client.holdNextRead()
        let store = Self.makeStore(client)

        let restore = Task { await store.restore() }
        await client.waitForReadToStart()

        // The refund arrives while that read is suspended.
        let refund = Task { await store.refreshStatus() }
        // Wait for the refund to actually JOIN the in-flight read: a
        // single Task.yield() left the interleaving to the scheduler.
        #expect(await settles { store.refreshJoinCount == 1 }, "the refund never joined the in-flight read")
        await client.releaseHeldReads()

        #expect(await restore.value == .nothingToRestore)
        #expect(await refund.value == .free)
        #expect(store.status == .free)
    }

    /// The mirror: an approval landing mid-read must not be hidden, and the
    /// operation that asked must be told the winning truth.
    @Test func arefreshCannotReportFreeFromASupersededRead() async {
        let client = StubStoreClient()
        await client.script(reads: [[], [Self.activeRecord()]])
        await client.holdNextRead()
        let store = Self.makeStore(client)

        let firstRefresh = Task { await store.refreshStatus() }
        await client.waitForReadToStart()

        let approval = Task { await store.refreshStatus() }
        #expect(await settles { store.refreshJoinCount == 1 }, "the approval never joined the in-flight read")
        await client.releaseHeldReads()

        #expect(await firstRefresh.value == .subscribed(.monthly))
        #expect(await approval.value == .subscribed(.monthly))
        #expect(store.isSubscribed)
    }

    // MARK: - The update stream

    /// Ask-to-Buy's second half: the approval arrives later through the
    /// update stream and must flip status without any UI involvement —
    /// and must be finished only after access is applied.
    @Test func anApprovalArrivingThroughTheUpdateStreamGrantsAccessBeforeFinishing() async throws {
        let client = StubStoreClient()
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.status == .free })

        await client.set(entitlements: [Self.activeRecord()])
        let accessAtFinish = Cell<Bool?>(nil)
        client.signalUpdate(record: Self.activeRecord(), finish: {
            let granted = await MainActor.run { store.isSubscribed }
            accessAtFinish.with { $0 = granted }
        })

        #expect(await settles { store.isSubscribed }, "update-stream approval never granted access")
        #expect(await settles { accessAtFinish.value != nil }, "the update was never finished")
        #expect(try #require(accessAtFinish.value), "the update was finished before access was applied")
    }

    /// The update carries the authoritative verified transaction. Ignoring
    /// it and trusting only a refresh means an Ask-to-Buy approval or a
    /// renewal can be acknowledged without access ever being delivered
    /// (round four, P1). Entitlement reads stay EMPTY here on purpose: the
    /// previous test hid this by seeding the same record into them first.
    @Test func averifiedApprovalGrantsAccessBeforeEntitlementsCatchUp() async throws {
        let client = StubStoreClient()
        await client.set(entitlements: [])
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.status == .free })

        let accessAtFinish = Cell<Bool?>(nil)
        client.signalUpdate(record: Self.activeRecord(.annual), finish: {
            let granted = await MainActor.run { store.isSubscribed }
            accessAtFinish.with { $0 = granted }
        })

        #expect(await settles { store.isSubscribed }, "the approval's own record was ignored")
        #expect(await settles { accessAtFinish.value != nil }, "the update was never finished")
        #expect(try #require(accessAtFinish.value), "finished before access was applied")
    }

    // MARK: - The entitlement bridge is not a blank cheque (round five)

    /// `Transaction.updates` can replay an unfinished transaction that
    /// expired long ago. `currentEntitlements` membership is pre-vetted by
    /// Apple (which is why grace periods must not be expiry-filtered), but a
    /// RAW update is not: round five found a replayed expired transaction
    /// granting Fable+ for the rest of the process.
    @Test func anExpiredTransactionReplayedThroughUpdatesGrantsNothing() async {
        let client = StubStoreClient()
        await client.set(entitlements: [])
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.status == .free })

        let handled = Cell(false)
        client.signalUpdate(
            record: EntitlementRecord(
                transactionID: 9,
                originalID: 9,
                productID: FablePlus.Plan.annual.productID,
                expirationDate: .now.addingTimeInterval(-90 * 86_400)
            ),
            finish: { handled.with { $0 = true } }
        )
        #expect(await settles { handled.value }, "the update was never handled")
        #expect(store.status == .free, "a long expired replay was honoured as a live entitlement")
    }

    /// Every monthly renewal carries the same product ID, so reconciling by
    /// SKU treated a fresh renewal as one already confirmed and discarded
    /// the bridge covering it. Identity is the transaction (round five, P1).
    @Test func arenewalIsNotMistakenForTheTransactionItReplaces() async {
        let confirmed = EntitlementRecord(
            transactionID: 1, originalID: 1,
            productID: FablePlus.Plan.monthly.productID,
            expirationDate: .now.addingTimeInterval(3_600)
        )
        let client = StubStoreClient()
        // The renewal lands in the gap: the old transaction has dropped out
        // of the entitlement view and the new one has not appeared yet.
        await client.script(reads: [[confirmed], []])
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.isSubscribed })

        // Observe access INSIDE finish: a Boolean set by finish only proves
        // ordering if the access check happens at that instant (round seven).
        let accessAtFinish = Cell<Bool?>(nil)
        client.signalUpdate(
            record: EntitlementRecord(
                transactionID: 2, originalID: 1,
                productID: FablePlus.Plan.monthly.productID,
                expirationDate: .now.addingTimeInterval(30 * 86_400)
            ),
            finish: {
                let granted = await MainActor.run { store.isSubscribed }
                accessAtFinish.with { $0 = granted }
            }
        )
        #expect(await settles { accessAtFinish.value != nil }, "the update was never handled")
        #expect(accessAtFinish.value == true, "the renewal was finished without access being delivered")
        #expect(store.isSubscribed, "the renewal was discarded as a duplicate SKU and access lapsed")
    }

    /// A refund can arrive before the entitlement view stops reporting the
    /// transaction. Without a tombstone, Fable acknowledged the refund with
    /// `finish()` while the stale snapshot kept granting (round five, P1).
    @Test func arefundBeatsAStaleActiveSnapshot() async {
        let active = EntitlementRecord(
            transactionID: 7, originalID: 7,
            productID: FablePlus.Plan.annual.productID,
            expirationDate: .now.addingTimeInterval(300 * 86_400)
        )
        let client = StubStoreClient()
        // Both reads still report it as active: the refund is newer than
        // anything the entitlement view knows.
        await client.set(entitlements: [active])
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.isSubscribed })

        var revoked = active
        revoked.revocationDate = .now
        let accessAtFinish = Cell<Bool?>(nil)
        client.signalUpdate(record: revoked, finish: {
            let granted = await MainActor.run { store.isSubscribed }
            accessAtFinish.with { $0 = granted }
        })
        #expect(await settles { accessAtFinish.value != nil }, "the refund was never handled")
        #expect(accessAtFinish.value == false, "the refund was acknowledged while access was still granted")
        #expect(store.status == .free, "a refund lost to a stale active snapshot")
        // And it must STAY revoked: the entitlement view still reports the
        // transaction as active, so a later refresh must not resurrect it.
        _ = await store.refreshStatus()
        #expect(store.status == .free, "a stale read resurrected a refunded subscription")
    }

    /// The crossing round six found: a refund can arrive BEFORE the purchase
    /// it refunds has propagated into the entitlement view. Round five
    /// retired the tombstone against the pre-refund snapshot (empty), so it
    /// deleted itself, and the next read — which finally showed the purchase
    /// as active — granted access back while `finish()` acknowledged the
    /// refund. A tombstone now lives for the process: a refunded transaction
    /// is refunded forever, and renewals carry new IDs.
    @Test func arefundArrivingBeforeThePurchaseHasPropagatedStaysRevoked() async {
        let purchased = EntitlementRecord(
            transactionID: 42, originalID: 42,
            productID: FablePlus.Plan.annual.productID,
            expirationDate: .now.addingTimeInterval(300 * 86_400)
        )
        let client = StubStoreClient()
        // Reads: empty while the purchase propagates, then it shows up as
        // active — after the refund has already been reported.
        await client.script(reads: [[], [], [purchased], [purchased], [purchased]])
        await client.stubPurchase(.successVerified(purchased, finish: {}))
        let store = Self.makeStore(client)
        store.start()
        client.observeAccess.with { $0 = { @Sendable in await MainActor.run { store.isSubscribed } } }
        #expect(await settles { store.status == .free })

        #expect(await store.purchase(.annual) == .subscribed)
        #expect(store.isSubscribed)

        var refunded = purchased
        refunded.revocationDate = .now
        let handled = Cell(false)
        client.signalUpdate(record: refunded, finish: { handled.with { $0 = true } })
        #expect(await settles { handled.value }, "the refund was never handled")
        #expect(store.status == .free, "the refund was acknowledged but access survived")

        // Every later read still reports the stale active transaction.
        _ = await store.refreshStatus()
        _ = await store.refreshStatus()
        #expect(store.status == .free, "a stale read resurrected a refunded purchase")
    }

    /// Round seven's crossing: the refund lands while a positive purchase
    /// result is still in flight. Its snapshot predates the refund, so
    /// honouring it re-granted access the account no longer has. A tombstone
    /// must dominate EVERY source, not only the entitlement view.
    @Test func astalePurchaseResultCannotOutliveTheRefundThatBeatItHome() async {
        let purchased = EntitlementRecord(
            transactionID: 77, originalID: 77,
            productID: FablePlus.Plan.annual.productID,
            expirationDate: .now.addingTimeInterval(300 * 86_400)
        )
        let client = StubStoreClient()
        await client.set(entitlements: [])
        await client.stubPurchase(.successVerified(purchased, finish: {}))
        await client.holdNextPurchaseResult()
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.status == .free })

        // The purchase is decided but has not returned yet.
        let purchase = Task { await store.purchase(.annual) }
        await client.waitForReadToStart()

        // The refund arrives and is handled first.
        var refunded = purchased
        refunded.revocationDate = .now
        let handled = Cell(false)
        client.signalUpdate(record: refunded, finish: { handled.with { $0 = true } })
        #expect(await settles { handled.value }, "the refund was never handled")
        #expect(store.status == .free)

        // Now the stale positive result comes home.
        await client.releaseHeldPurchases()
        let outcome = await purchase.value
        #expect(store.status == .free, "a stale purchase result resurrected a refunded transaction")
        #expect(outcome != .subscribed, "a refunded purchase reported success")
    }

    /// A verified subscription spends the free week immediately, and an
    /// eligibility query that suspended beforehand must not resurrect it
    /// (round seven, P2).
    @Test func astaleEligibilityAnswerCannotReadvertiseASpentFreeWeek() async {
        let client = StubStoreClient()
        await client.setIntroEligible(true)
        let store = Self.makeStore(client)
        await store.refreshIntroEligibility()
        #expect(store.isEligibleForIntroOffer)

        // A subscription arrives through the update stream, then the stale
        // "still eligible" answer lands.
        let handled = Cell(false)
        client.signalUpdate(
            record: EntitlementRecord(
                transactionID: 5, originalID: 5,
                productID: FablePlus.Plan.annual.productID,
                expirationDate: .now.addingTimeInterval(300 * 86_400)
            ),
            finish: { handled.with { $0 = true } }
        )
        store.start()
        #expect(await settles { handled.value })
        #expect(store.isSubscribed)
        #expect(!store.isEligibleForIntroOffer, "the paywall would still sell a spent free week")
    }

    @Test func aRevocationArrivingThroughTheUpdateStreamRemovesAccess() async {
        let client = StubStoreClient()
        await client.set(entitlements: [Self.activeRecord()])
        let store = Self.makeStore(client)
        store.start()
        #expect(await settles { store.isSubscribed })

        await client.set(entitlements: [])
        client.signalUpdate()
        #expect(await settles { store.status == .free }, "revocation never removed access")
    }

    // MARK: - Operation honesty and lifecycle

    @Test func restoreReportsEachOutcomeHonestly() async {
        let client = StubStoreClient()
        let store = Self.makeStore(client)

        await client.failSync(true)
        #expect(await store.restore() == .failed)

        await client.failSync(false)
        #expect(await store.restore() == .nothingToRestore)

        await client.set(entitlements: [Self.activeRecord()])
        #expect(await store.restore() == .subscribed)
    }

    /// One money operation at a time, ACROSS paywall presentations: the
    /// per-sheet flag reset on reopen, letting a second purchase start while
    /// the first was still running (round three, P2).
    @Test func aSecondMoneyOperationIsRefusedWhileOneIsRunning() async throws {
        let client = StubStoreClient()
        await client.script(reads: [[], []])
        await client.stubPurchase(.successVerified(Self.activeRecord(), finish: {}))
        await client.holdNextRead()
        let store = Self.makeStore(client)
        client.observeAccess.with { $0 = { @Sendable in await MainActor.run { store.isSubscribed } } }

        // The first purchase suspends inside its post-grant reconcile read.
        let first = Task { await store.purchase(.annual) }
        await client.waitForReadToStart()

        #expect(await store.purchase(.monthly) == .alreadyInProgress)
        #expect(await store.restore() == .alreadyInProgress)

        await client.releaseHeldReads()
        #expect(await first.value == .subscribed)
        // Only the first purchase ever reached the App Store.
        #expect(await client.purchaseRequests == [FablePlus.Plan.annual.productID])
    }

    /// start() is genuinely idempotent: one listener AND one bootstrap.
    /// Counting entitlement reads is the honest measure — the previous test
    /// counted stream accesses and would have passed with three bootstraps.
    @Test func repeatedStartCallsBootstrapOnlyOnce() async {
        let client = StubStoreClient()
        let store = Self.makeStore(client)
        store.start()
        store.start()
        store.start()
        #expect(await settles { store.status == .free })
        // Let any duplicate bootstrap land before counting.
        await Task.yield()
        #expect(client.readCount == 1, "start() bootstrapped \(client.readCount) times")
        #expect(client.updatesAccessCount == 1, "start() attached \(client.updatesAccessCount) listeners")
    }

    /// The listener must not retain its store: promoting `self` before the
    /// stream loop was a store → task → store cycle that kept `deinit` — and
    /// therefore the cancel — from ever running (round two), and round three
    /// asked for the weak reference itself to be observed.
    @Test func theStoreDeallocatesAndItsListenerIsTornDown() async {
        let client = StubStoreClient()
        weak var weakStore: SubscriptionStore?

        await {
            let store = Self.makeStore(client)
            weakStore = store
            store.start()
            // Drain the bootstrap so its task stops holding the store.
            _ = await store.refreshStatus()
        }()

        #expect(await settles { weakStore == nil }, "the store outlived its last strong reference")
        #expect(await settles { client.wasTerminated }, "the update stream was never torn down")
    }

    // MARK: - Catalog retry (round three, P2)

    /// A retry must never leave the paywall worse off than it found it. The
    /// old shape cleared `products` at the start of every attempt, so a
    /// retry that failed destroyed a catalog that already worked, and a
    /// retry arriving during an in-flight load was dropped entirely
    /// (round three, P2). `Product.products` cannot be forced to fail from
    /// a test, so this pins the observable half: repeated and concurrent
    /// loads coalesce and keep a usable catalog.
    @Test func repeatedAndConcurrentCatalogLoadsKeepAUsableCatalog() async {
        let store = Self.makeStore(StubStoreClient())
        await store.loadProducts()
        let loaded = store.products.count
        #expect(loaded == FablePlus.productIDs.count, "the test host's StoreKit configuration did not resolve")

        // A retry while one is in flight joins it instead of being dropped.
        async let first: Void = store.loadProducts()
        async let second: Void = store.loadProducts()
        _ = await (first, second)
        #expect(store.products.count == loaded)
        #expect(store.productsUnavailable == false)
        #expect(store.isLoadingProducts == false)

        // A complete catalog needs no further request.
        await store.ensureCatalog()
        #expect(store.products.count == loaded)
    }
}
