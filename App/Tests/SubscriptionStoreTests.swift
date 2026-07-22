import Foundation
import StoreKit
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
        var productID: String
        var displayPrice: String
        var recurringSubscriptionPeriod: String
        var subscriptionGroupID: String
        var familyShareable: Bool
        var type: String
    }

    var subscriptionGroups: [Group]
}

private final class BundleToken {}

@MainActor
struct SubscriptionStoreTests {
    /// With no products loaded there is nothing to buy, and the caller learns
    /// that without a StoreKit sheet ever appearing.
    @Test func purchasingAPlanWithNoLoadedProductFailsCleanly() async throws {
        let store = SubscriptionStore()
        await #expect(throws: SubscriptionError.productUnavailable) {
            try await store.purchase(.monthly)
        }
    }

    /// Gating must never open just because the entitlement check has not run.
    @Test func statusStartsUnknownAndGatesClosed() {
        let store = SubscriptionStore()
        #expect(store.status == .unknown)
        #expect(store.isSubscribed == false)
    }

    /// No entitlements on a fresh simulator: the derivation must settle on
    /// free rather than staying unknown forever.
    @Test func refreshSettlesOnFreeWithoutEntitlements() async {
        let store = SubscriptionStore()
        await store.refreshStatus()
        #expect(store.status == .free)
    }
}
