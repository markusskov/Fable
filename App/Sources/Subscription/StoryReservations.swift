import Foundation
import Observation

/// Household-wide ledger of stories that are being written right now but not
/// yet persisted. The free-tier meter must count these: TonightView checks
/// the allowance, then generates for a second or two, and only then inserts
/// the consuming Story. Without a reservation, switching profiles during
/// that window rebuilds the view and lets the same weekly credit be spent
/// again (2026-07-24 external money-path review, P1).
///
/// Lives at the app root, above any per-profile view, precisely so a profile
/// switch cannot reset it. In-memory only: if the process dies mid-write no
/// story was persisted, so no credit was spent and nothing needs repair.
@MainActor
@Observable
final class StoryReservations {
    /// An opaque claim: identity, not date equality, is what a release
    /// targets — two claims made in the same instant must be separable.
    struct Claim: Equatable {
        let id: UUID
        let date: Date
    }

    private(set) var claims: [Claim] = []

    /// What the meter counts alongside persisted story dates.
    var dates: [Date] { claims.map(\.date) }

    /// Claims a slot against the meter before generation begins. The check
    /// and the claim happen synchronously on the main actor — no suspension
    /// between them — which is what makes the reservation race-free.
    func reserve(now: Date = .now) -> Claim {
        let claim = Claim(id: UUID(), date: now)
        claims.append(claim)
        return claim
    }

    /// Releases a claim once the story row is persisted (the meter counts
    /// the row itself from then on) or if generation is abandoned.
    /// Releasing twice is harmless: only this claim's identity is removed.
    func release(_ claim: Claim) {
        claims.removeAll { $0.id == claim.id }
    }
}
