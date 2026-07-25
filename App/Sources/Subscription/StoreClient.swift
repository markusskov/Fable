import Foundation
import StoreKit

/// The app-owned boundary to the App Store (2026-07-24 external money-path
/// review): everything `SubscriptionStore` needs from StoreKit, expressed in
/// plain values so entitlement lifecycle transitions — grace period, refund
/// mid-refresh, Ask-to-Buy approval, offline, every purchase outcome — can be
/// forced deterministically in tests. Product objects for the paywall stay
/// outside this boundary: they cannot be constructed in tests and carry no
/// lifecycle logic.
protocol StoreClient: Sendable {
    /// The verified entitlement facts StoreKit can currently vouch for.
    /// Membership here is Apple's access decision (it includes billing
    /// grace); callers must not re-filter by date.
    func currentEntitlements() async -> [EntitlementRecord]
    /// Emits whenever entitlements may have changed: renewal, refund,
    /// Ask-to-Buy approval, a purchase on another device. The consumer must
    /// apply access FIRST and call `finish` after — Apple's contract is
    /// deliver-then-finish (2026-07-24 review round three, P1: finishing
    /// first can acknowledge a purchase the app then fails to honour).
    var updates: AsyncStream<StoreUpdate> { get }
    /// "Restore purchases" — asks the App Store to sync this device.
    func sync() async throws
    /// Runs the purchase flow. `loaded` is the paywall's already displayed
    /// product, when it has one — buying must not add a second network gate
    /// after the buy button was enabled (round three).
    func purchase(productID: String, loaded: Product?) async throws -> ClientPurchaseResult
    /// Whether the Apple Account can still claim the introductory offer.
    /// Behind the seam so "the paywall stopped advertising a spent free
    /// week" is provable rather than reasoned (round seven, P2).
    func isEligibleForIntroOffer(productID: String, loaded: Product?) async -> Bool
}

/// One entitlement-changing event, with delivery acknowledgement deferred to
/// the consumer so access is always applied before the transaction finishes.
struct StoreUpdate: Sendable {
    /// Verified facts, nil when the update's signature could not be checked
    /// (still worth a refresh — just never worth honouring directly).
    let record: EntitlementRecord?
    /// Acknowledges delivery to StoreKit. Call ONLY after access reflects
    /// the update; not calling it means StoreKit redelivers, which is the
    /// safe direction.
    let finish: @Sendable () async -> Void
}

enum ClientPurchaseResult: Sendable {
    /// The App Store accepted and verified the purchase. `record` is the
    /// transaction's own facts — grant access from THESE, then call
    /// `finish`; no later entitlement read gets to veto a verified sale.
    case successVerified(EntitlementRecord, finish: @Sendable () async -> Void)
    /// The App Store accepted the purchase but could not vouch for the
    /// transaction's signature. Left unfinished, so it redelivers through
    /// `updates` once verification can succeed.
    case successUnverified
    /// Ask to Buy: a parent must approve; the outcome arrives later
    /// through `updates`.
    case pending
    case cancelled
}

extension EntitlementRecord {
    init(_ transaction: Transaction) {
        self.init(
            transactionID: transaction.id,
            originalID: transaction.originalID,
            productID: transaction.productID,
            expirationDate: transaction.expirationDate,
            revocationDate: transaction.revocationDate,
            isUpgraded: transaction.isUpgraded
        )
    }
}

/// Production client. The only file in Fable that talks to StoreKit's
/// transaction machinery.
struct LiveStoreClient: StoreClient {
    func currentEntitlements() async -> [EntitlementRecord] {
        var records: [EntitlementRecord] = []
        for await result in Transaction.currentEntitlements {
            // Unverified entitlements are ignored outright: a signature we
            // cannot check is not a purchase we honour.
            guard case .verified(let transaction) = result else { continue }
            records.append(EntitlementRecord(transaction))
        }
        return records
    }

    var updates: AsyncStream<StoreUpdate> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        continuation.yield(StoreUpdate(
                            record: EntitlementRecord(transaction),
                            finish: { await transaction.finish() }
                        ))
                    } else {
                        // Unverified: refresh-worthy, nothing to finish.
                        continuation.yield(StoreUpdate(record: nil, finish: {}))
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    func isEligibleForIntroOffer(productID: String, loaded: Product?) async -> Bool {
        let product: Product?
        if let loaded, loaded.id == productID {
            product = loaded
        } else {
            product = try? await Product.products(for: [productID]).first
        }
        guard let subscription = product?.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    func purchase(productID: String, loaded: Product?) async throws -> ClientPurchaseResult {
        // Prefer the product the paywall already displays; re-resolve only
        // when the button somehow outlived a catalog wipe.
        let product: Product
        if let loaded, loaded.id == productID {
            product = loaded
        } else if let fetched = try await Product.products(for: [productID]).first {
            product = fetched
        } else {
            throw SubscriptionError.productUnavailable
        }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                return .successUnverified
            }
            // Deliberately NOT finished here: the store grants access from
            // the record first, then calls finish (Apple's order).
            return .successVerified(
                EntitlementRecord(transaction),
                finish: { await transaction.finish() }
            )
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }
}
