import Foundation
import Testing
@testable import Fable

struct FablePlusTests {
    @Test func catalogCoversBothPlans() {
        #expect(FablePlus.productIDs.count == 2)
        #expect(FablePlus.productIDs.contains("com.markusskov.fable.plus.monthlyy"))
        #expect(FablePlus.productIDs.contains("com.markusskov.fable.plus.annualy"))
        #expect(FablePlus.plan(forProductID: "com.markusskov.fable.plus.annualy") == .annual)
        #expect(FablePlus.plan(forProductID: "com.markusskov.fable.lifetime") == nil)
    }

    @Test func yearlyLeadsThePaywall() {
        let ordered = FablePlus.Plan.allCases.sorted { $0.sortOrder < $1.sortOrder }
        #expect(ordered == [.annual, .monthly])
    }

    @Test func savingIsRealOrNotClaimed() {
        // 4.99 × 12 = 59.88 against 39.99 → 33%.
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 4.99, yearlyPrice: 39.99) == 33)
        // No claim when yearly is not actually cheaper.
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 4.99, yearlyPrice: 59.88) == nil)
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 4.99, yearlyPrice: 79.99) == nil)
        // Nor when it rounds away to nothing.
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 5.00, yearlyPrice: 59.87) == nil)
        // Nor from prices we do not have yet.
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 0, yearlyPrice: 39.99) == nil)
        #expect(FablePlus.yearlySavingPercent(monthlyPrice: 4.99, yearlyPrice: 0) == nil)
    }

    @Test func monthlyEquivalentPutsBothPlansOnOneAxis() {
        #expect(FablePlus.monthlyEquivalent(of: 39.99, plan: .annual) == Decimal(string: "3.33"))
        #expect(FablePlus.monthlyEquivalent(of: 4.99, plan: .monthly) == Decimal(string: "4.99"))
    }
}

struct SubscriptionStatusTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var future: Date { now.addingTimeInterval(86_400) }
    private var past: Date { now.addingTimeInterval(-86_400) }

    @Test func noEntitlementsMeansFree() {
        #expect(SubscriptionStatus.derive(from: [], now: now) == .free)
    }

    @Test func liveEntitlementGrantsItsPlan() {
        let record = EntitlementRecord(productID: FablePlus.Plan.monthly.productID, expirationDate: future)
        #expect(SubscriptionStatus.derive(from: [record], now: now) == .subscribed(.monthly))
    }

    @Test func expiredRevokedAndUpgradedEntitlementsGrantNothing() {
        let expired = EntitlementRecord(productID: FablePlus.Plan.monthly.productID, expirationDate: past)
        let revoked = EntitlementRecord(
            productID: FablePlus.Plan.annual.productID,
            expirationDate: future,
            revocationDate: past
        )
        let upgraded = EntitlementRecord(
            productID: FablePlus.Plan.monthly.productID,
            expirationDate: future,
            isUpgraded: true
        )
        #expect(SubscriptionStatus.derive(from: [expired, revoked, upgraded], now: now) == .free)
    }

    @Test func unknownProductIDsAreIgnored() {
        let stray = EntitlementRecord(productID: "com.markusskov.fable.someOtherThing", expirationDate: future)
        #expect(SubscriptionStatus.derive(from: [stray], now: now) == .free)
    }

    @Test func overlappingPlansResolveToYearly() {
        let monthly = EntitlementRecord(productID: FablePlus.Plan.monthly.productID, expirationDate: future)
        let annual = EntitlementRecord(productID: FablePlus.Plan.annual.productID, expirationDate: future)
        #expect(SubscriptionStatus.derive(from: [monthly, annual], now: now) == .subscribed(.annual))
        #expect(SubscriptionStatus.derive(from: [annual, monthly], now: now) == .subscribed(.annual))
    }

    @Test func statusExposesGatingAndPlan() {
        #expect(SubscriptionStatus.unknown.isSubscribed == false)
        #expect(SubscriptionStatus.free.isSubscribed == false)
        #expect(SubscriptionStatus.free.plan == nil)
        #expect(SubscriptionStatus.subscribed(.annual).isSubscribed)
        #expect(SubscriptionStatus.subscribed(.annual).plan == .annual)
    }
}
