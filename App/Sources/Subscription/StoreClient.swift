import Foundation
import StoreKit

/// The app-owned boundary to the App Store (2026-07-24 external money-path
/// review): everything `SubscriptionStore` needs from StoreKit, expressed in
/// plain values so entitlement lifecycle transitions — grace period, refund
/// mid-refresh, Ask-to-Buy approval, offline — can be forced deterministically
/// in tests. Product objects for the paywall stay outside this boundary: they
/// cannot be constructed in tests and carry no lifecycle logic.
protocol StoreClient: Sendable {
    /// The verified entitlement facts StoreKit can currently vouch for.
    /// Membership here is Apple's access decision (it includes billing
    /// grace); callers must not re-filter by date.
    func currentEntitlements() async -> [EntitlementRecord]
    /// Emits whenever entitlements may have changed: renewal, refund,
    /// Ask-to-Buy approval, a purchase on another device. Elements carry
    /// nothing — the store re-reads entitlements on each signal.
    var updates: AsyncStream<Void> { get }
    /// "Restore purchases" — asks the App Store to sync this device.
    func sync() async throws
    /// Runs the purchase flow for a product and reports what the App Store
    /// said, in plain values — so pending, cancellation, and verification
    /// failure are forceable in tests (2026-07-24 review round two: the
    /// previous seam left every purchase path environment-dependent).
    func purchase(productID: String) async throws -> ClientPurchaseResult
}

enum ClientPurchaseResult: Equatable {
    /// Verified and finished; entitlements now reflect it.
    case successVerified
    /// The App Store accepted the purchase but could not vouch for the
    /// transaction's signature.
    case successUnverified
    /// Ask to Buy: a parent must approve; the outcome arrives later
    /// through `updates`.
    case pending
    case cancelled
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
            records.append(
                EntitlementRecord(
                    productID: transaction.productID,
                    expirationDate: transaction.expirationDate,
                    revocationDate: transaction.revocationDate,
                    isUpgraded: transaction.isUpgraded
                )
            )
        }
        return records
    }

    var updates: AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    // Finish verified transactions here so renewals and
                    // Ask-to-Buy approvals do not redeliver forever; then
                    // signal regardless — even an unverified update is a
                    // reason to re-read entitlements.
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func sync() async throws {
        try await AppStore.sync()
    }

    func purchase(productID: String) async throws -> ClientPurchaseResult {
        // Re-resolve rather than borrowing the paywall's display list:
        // Product is not Sendable-constructible across the boundary, and
        // StoreKit caches this lookup.
        guard let product = try await Product.products(for: [productID]).first else {
            throw SubscriptionError.productUnavailable
        }
        switch try await product.purchase() {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                return .successUnverified
            }
            await transaction.finish()
            return .successVerified
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }
}
