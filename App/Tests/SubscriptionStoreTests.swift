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

/// A StoreKit stand-in whose entitlement answers, update signals, and sync
/// behaviour the tests control completely — the injectable boundary the
/// 2026-07-24 money-path review required so lifecycle transitions are
/// provable instead of environment-dependent.
private actor StubStoreClient: StoreClient {
    private var entitlements: [EntitlementRecord] = []
    private var heldReads: [CheckedContinuation<Void, Never>] = []
    private var holdsRemaining = 0
    var shouldFailSync = false
    /// What the next purchase(productID:) reports; nil throws instead.
    private var purchaseResult: ClientPurchaseResult?

    private nonisolated let stream: AsyncStream<Void>
    private nonisolated let updatesContinuation: AsyncStream<Void>.Continuation
    /// How many consumers attached, and whether the stream was torn down —
    /// the observable facts behind "exactly one listener" and "deinit
    /// actually cancels it" (review round two: the old idempotency test
    /// would have passed with three listeners, and deallocation was
    /// untested). Boxed because Mutex itself is noncopyable and closures
    /// cannot capture it directly.
    private final class Cell<Value: Sendable>: Sendable {
        private let mutex: Mutex<Value>
        init(_ value: Value) { mutex = Mutex(value) }
        func with<R>(_ body: (inout sending Value) -> sending R) -> sending R { mutex.withLock(body) }
    }

    private nonisolated let updatesAccesses = Cell(0)
    private nonisolated let terminated = Cell(false)

    nonisolated var updates: AsyncStream<Void> {
        updatesAccesses.with { $0 += 1 }
        return stream
    }

    nonisolated var updatesAccessCount: Int { updatesAccesses.with { $0 } }
    nonisolated var wasTerminated: Bool { terminated.with { $0 } }

    init() {
        (stream, updatesContinuation) = AsyncStream<Void>.makeStream()
        let terminated = terminated
        updatesContinuation.onTermination = { _ in
            terminated.with { $0 = true }
        }
    }

    func stubPurchase(_ result: ClientPurchaseResult?) { purchaseResult = result }

    func purchase(productID: String) async throws -> ClientPurchaseResult {
        guard let purchaseResult else { throw SubscriptionError.productUnavailable }
        return purchaseResult
    }

    func set(entitlements records: [EntitlementRecord]) {
        entitlements = records
    }

    func failSync(_ fail: Bool) { shouldFailSync = fail }

    /// The next `currentEntitlements` call reads its snapshot, then suspends
    /// until `releaseHeldReads` — the seam that reproduces "an older refresh
    /// commits after a newer one" deterministically.
    func holdNextRead() { holdsRemaining += 1 }

    var heldReadCount: Int { heldReads.count }

    func releaseHeldReads() {
        heldReads.forEach { $0.resume() }
        heldReads.removeAll()
    }

    /// Releases only the OLDEST held read, so tests can order commits
    /// precisely (the round-two P1 needs the stale read released while a
    /// newer one is still held).
    func releaseOneHeldRead() {
        guard !heldReads.isEmpty else { return }
        heldReads.removeFirst().resume()
    }

    nonisolated func signalUpdate() { updatesContinuation.yield() }

    func currentEntitlements() async -> [EntitlementRecord] {
        // Snapshot BEFORE suspending: models a refresh that already read the
        // (now stale) answer and is merely waiting to commit it.
        let snapshot = entitlements
        if holdsRemaining > 0 {
            holdsRemaining -= 1
            await withCheckedContinuation { heldReads.append($0) }
        }
        return snapshot
    }

    func sync() async throws {
        if shouldFailSync { throw SubscriptionError.productUnavailable }
    }
}

@MainActor
struct SubscriptionStoreTests {
    private static func activeRecord(_ plan: FablePlus.Plan = .monthly) -> EntitlementRecord {
        EntitlementRecord(productID: plan.productID, expirationDate: .now.addingTimeInterval(86_400))
    }

    /// Waits for state driven by the update-stream listener task.
    private func expectEventually(
        within seconds: Double = 2,
        _ condition: () async -> Bool
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(seconds)
        while Date() < deadline {
            if await condition() { return true }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return await condition()
    }

    /// With no products loaded there is nothing to buy, and the caller learns
    /// that without a StoreKit sheet ever appearing.
    @Test func purchasingAPlanWithNoLoadedProductFailsCleanly() async {
        let store = SubscriptionStore(client: StubStoreClient())
        #expect(await store.purchase(.monthly) == .failed)
    }

    /// Gating must never open just because the entitlement check has not run.
    @Test func statusStartsUnknownAndGatesClosed() {
        let store = SubscriptionStore(client: StubStoreClient())
        #expect(store.status == .unknown)
        #expect(store.isSubscribed == false)
    }

    /// No entitlements: the derivation must settle on free rather than
    /// staying unknown forever.
    @Test func refreshSettlesOnFreeWithoutEntitlements() async {
        let store = SubscriptionStore(client: StubStoreClient())
        await store.refreshStatus()
        #expect(store.status == .free)
    }

    /// THE grace-period reproduction from the review: Apple vends the
    /// entitlement with a past expiration date while it retries billing;
    /// the family keeps Fable+.
    @Test func billingGraceFamilyKeepsFablePlus() async {
        let client = StubStoreClient()
        await client.set(entitlements: [
            EntitlementRecord(
                productID: FablePlus.Plan.annual.productID,
                expirationDate: .now.addingTimeInterval(-3 * 86_400)
            ),
        ])
        let store = SubscriptionStore(client: client)
        await store.refreshStatus()
        #expect(store.status == .subscribed(.annual))
    }

    /// A refund that lands while an older refresh is mid-read must win:
    /// the stale pre-refund snapshot is discarded, not committed
    /// (review finding 3, reproduced deterministically via the held read).
    @Test func aStaleRefreshCannotOverwriteARefund() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)

        await client.set(entitlements: [Self.activeRecord()])
        await client.holdNextRead()
        let staleRefresh = Task { await store.refreshStatus() }
        let held = await expectEventually { await client.heldReadCount == 1 }
        #expect(held, "the stale refresh never reached its read")

        // The refund arrives and a fresh refresh commits the new truth.
        await client.set(entitlements: [])
        await store.refreshStatus()
        #expect(store.status == .free)

        // The stale snapshot resumes — and must be thrown away.
        await client.releaseHeldReads()
        await staleRefresh.value
        #expect(store.status == .free)
    }

    /// And the mirror image: a restore/approval must not be hidden by a
    /// stale empty snapshot committing late.
    @Test func aStaleEmptyRefreshCannotHideANewSubscription() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)

        await client.holdNextRead()
        let staleRefresh = Task { await store.refreshStatus() }
        let held = await expectEventually { await client.heldReadCount == 1 }
        #expect(held, "the stale refresh never reached its read")

        await client.set(entitlements: [Self.activeRecord()])
        await store.refreshStatus()
        #expect(store.isSubscribed)

        await client.releaseHeldReads()
        await staleRefresh.value
        #expect(store.isSubscribed)
    }

    /// Ask-to-Buy's second half: the approval arrives later through the
    /// update stream and must flip status without any UI involvement.
    @Test func anApprovalArrivingThroughTheUpdateStreamGrantsAccess() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)
        store.start()
        let settled = await expectEventually { store.status == .free }
        #expect(settled, "bootstrap refresh never settled")

        await client.set(entitlements: [Self.activeRecord()])
        client.signalUpdate()
        let granted = await expectEventually { store.isSubscribed }
        #expect(granted, "update-stream approval never granted access")
    }

    /// Revocation through the same stream takes access away again.
    @Test func aRevocationArrivingThroughTheUpdateStreamRemovesAccess() async {
        let client = StubStoreClient()
        await client.set(entitlements: [Self.activeRecord()])
        let store = SubscriptionStore(client: client)
        store.start()
        let granted = await expectEventually { store.isSubscribed }
        #expect(granted, "initial entitlement never granted")

        await client.set(entitlements: [])
        client.signalUpdate()
        let removed = await expectEventually { store.status == .free }
        #expect(removed, "revocation never removed access")
    }

    @Test func restoreReportsEachOutcomeHonestly() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)

        await client.failSync(true)
        #expect(await store.restore() == .failed)

        await client.failSync(false)
        #expect(await store.restore() == .nothingToRestore)

        await client.set(entitlements: [Self.activeRecord()])
        #expect(await store.restore() == .subscribed)
    }

    /// start() is genuinely idempotent: repeated calls must not launch
    /// duplicate bootstraps or listeners (review finding 5).
    @Test func repeatedStartCallsAreNoOps() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)
        store.start()
        store.start()
        store.start()
        let settled = await expectEventually { store.status == .free }
        #expect(settled)
        // Exactly ONE listener attached — the old version of this test
        // would have passed with three (review round two).
        #expect(client.updatesAccessCount == 1)
    }

    // MARK: - Round two of the money-path review

    /// THE round-two P1: a successful purchase whose refresh commit is
    /// superseded by a newer refresh must still report success — the
    /// operation judges by its own read, not the global status.
    @Test func aSupersededRefreshCannotMakeASuccessfulPurchaseReportFailure() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)
        await client.set(entitlements: [Self.activeRecord()])
        await client.stubPurchase(.successVerified)

        // The purchase's own refresh suspends at its read; a competing
        // refresh (foregrounding, Transaction.updates) starts and is held
        // too, so the purchase's commit is superseded before it lands.
        await client.holdNextRead()
        await client.holdNextRead()
        let purchase = Task { await store.purchase(.annual) }
        var held = await expectEventually { await client.heldReadCount == 1 }
        #expect(held, "the purchase refresh never reached its read")
        let competing = Task { await store.refreshStatus() }
        held = await expectEventually { await client.heldReadCount == 2 }
        #expect(held, "the competing refresh never reached its read")

        // Release the purchase's (now superseded) read first.
        await client.releaseOneHeldRead()
        let outcome = await purchase.value
        #expect(outcome == .subscribed,
                "a successful purchase lied about failing because its commit was discarded")

        await client.releaseHeldReads()
        _ = await competing.value
        #expect(store.isSubscribed)
    }

    @Test func purchaseOutcomesMapHonestlyThroughTheSeam() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)

        await client.stubPurchase(.pending)
        #expect(await store.purchase(.annual) == .pending)

        await client.stubPurchase(.cancelled)
        #expect(await store.purchase(.annual) == .cancelled)

        await client.stubPurchase(.successUnverified)
        #expect(await store.purchase(.annual) == .failed)

        await client.stubPurchase(nil) // catalog/offline error path throws
        #expect(await store.purchase(.annual) == .failed)

        await client.set(entitlements: [Self.activeRecord(.annual)])
        await client.stubPurchase(.successVerified)
        #expect(await store.purchase(.annual) == .subscribed)
    }

    /// A verified purchase whose entitlement has not landed yet must not be
    /// reported as subscribed on hope alone.
    @Test func aVerifiedPurchaseWithoutAnEntitlementIsNotCalledSubscribed() async {
        let client = StubStoreClient()
        let store = SubscriptionStore(client: client)
        await client.stubPurchase(.successVerified)
        #expect(await store.purchase(.annual) == .failed)
    }

    /// deinit must actually cancel the listener: the round-two review found
    /// the task's strong `self` promotion kept the store alive forever.
    @Test func deallocatingTheStoreTearsDownItsListener() async {
        let client = StubStoreClient()
        var store: SubscriptionStore? = SubscriptionStore(client: client)
        store?.start()
        let attached = await expectEventually { client.updatesAccessCount == 1 }
        #expect(attached)
        store = nil
        let torn = await expectEventually { client.wasTerminated }
        #expect(torn, "the update listener outlived its store")
    }
}
