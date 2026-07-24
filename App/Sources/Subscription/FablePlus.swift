import Foundation

/// The Fable+ subscription catalog and the pure rules around it.
///
/// Deliberately free of StoreKit types so the entitlement logic — the part
/// that decides whether a family paid — is unit-testable without a store.
/// `SubscriptionStore` owns everything that actually talks to StoreKit.
enum FablePlus {
    /// Must match `subscriptionGroupID` in `App/StoreKit/Fable.storekit` and,
    /// later, the subscription group in App Store Connect.
    static let subscriptionGroupID = "21654001"

    /// The two ways to subscribe. Raw values are the App Store product IDs.
    ///
    /// Yes, "monthlyy"/"annualy" — the original IDs were created and deleted
    /// in App Store Connect on 2026-07-23, and deleted product IDs can never
    /// be reused. These are the live IDs; do NOT "fix" the spelling.
    enum Plan: String, CaseIterable, Sendable, Identifiable {
        case monthly = "com.markusskov.fable.plus.monthlyy"
        case annual = "com.markusskov.fable.plus.annualy"

        var id: String { rawValue }
        var productID: String { rawValue }

        var displayName: String {
            switch self {
            case .monthly: String(localized: "Monthly")
            case .annual: String(localized: "Yearly")
            }
        }

        /// Suffix for a price label: "3,99 € / month".
        var cadence: String {
            switch self {
            case .monthly: String(localized: "month")
            case .annual: String(localized: "year")
            }
        }

        /// Months covered by one charge — used for monthly-equivalent pricing.
        var monthsPerPeriod: Decimal {
            switch self {
            case .monthly: 1
            case .annual: 12
            }
        }

        /// Presentation order on the paywall: yearly first, it is the better deal.
        var sortOrder: Int {
            switch self {
            case .annual: 0
            case .monthly: 1
            }
        }
    }

    static var productIDs: [String] { Plan.allCases.map(\.productID) }

    static func plan(forProductID id: String) -> Plan? { Plan(rawValue: id) }

    /// Whole-percent saving of the yearly plan against twelve monthly charges.
    /// Returns nil when there is nothing honest to claim — we never advertise
    /// a discount that rounds to zero, or a negative one.
    static func yearlySavingPercent(monthlyPrice: Decimal, yearlyPrice: Decimal) -> Int? {
        let twelveMonths = monthlyPrice * 12
        guard twelveMonths > 0, yearlyPrice > 0, yearlyPrice < twelveMonths else { return nil }
        // Rounded down to a whole percent before converting: NSDecimalNumber's
        // intValue returns 0 for the many-digit decimals division produces.
        var fraction = (twelveMonths - yearlyPrice) / twelveMonths * 100
        var whole = Decimal()
        NSDecimalRound(&whole, &fraction, 0, .down)
        let percent = (whole as NSDecimalNumber).intValue
        return percent > 0 ? percent : nil
    }

    /// Price per month for any plan, so both options can be compared on the
    /// same axis. Rounded to two decimals, half-up, like a shelf price.
    static func monthlyEquivalent(of price: Decimal, plan: Plan) -> Decimal {
        var perMonth = price / plan.monthsPerPeriod
        var rounded = Decimal()
        NSDecimalRound(&rounded, &perMonth, 2, .plain)
        return rounded
    }
}

/// What the app believes about the current family's access.
enum SubscriptionStatus: Sendable, Equatable {
    /// Before the first entitlement check finishes. Treated as *not* subscribed
    /// for gating, but the UI can avoid flashing a paywall while it resolves.
    case unknown
    case free
    case subscribed(FablePlus.Plan)

    var isSubscribed: Bool {
        if case .subscribed = self { return true }
        return false
    }

    var plan: FablePlus.Plan? {
        if case .subscribed(let plan) = self { return plan }
        return nil
    }
}

/// The few facts we need from a verified StoreKit transaction, lifted into a
/// plain value so status derivation can be tested exhaustively.
struct EntitlementRecord: Sendable, Equatable {
    var productID: String
    var expirationDate: Date?
    var revocationDate: Date?
    /// StoreKit marks the superseded transaction when a plan is switched.
    var isUpgraded: Bool

    init(productID: String, expirationDate: Date? = nil, revocationDate: Date? = nil, isUpgraded: Bool = false) {
        self.productID = productID
        self.expirationDate = expirationDate
        self.revocationDate = revocationDate
        self.isUpgraded = isUpgraded
    }
}

extension SubscriptionStatus {
    /// Derives access from the verified entitlements StoreKit reports.
    ///
    /// An empty set means free — StoreKit only returns entitlements it can
    /// vouch for, so "nothing" is a real answer, not a missing one.
    ///
    /// Membership in `currentEntitlements` IS the access decision. Apple
    /// includes subscriptions in billing grace there even though the last
    /// transaction's expiration date is already past, so re-checking the
    /// date locally locks out exactly the paying families Apple is trying
    /// to keep (2026-07-24 external money-path review, P1). Staleness is
    /// handled by refreshing on foreground and on `Transaction.updates`,
    /// not by second-guessing the platform's answer.
    static func derive(from records: [EntitlementRecord]) -> SubscriptionStatus {
        let active = records.filter { record in
            record.revocationDate == nil && !record.isUpgraded
        }
        // If a family somehow holds both (plan switch mid-period), the yearly
        // plan wins — it is the one with the longer remaining runway.
        let plans = active.compactMap { FablePlus.plan(forProductID: $0.productID) }
        guard let best = plans.min(by: { $0.sortOrder < $1.sortOrder }) else { return .free }
        return .subscribed(best)
    }
}
