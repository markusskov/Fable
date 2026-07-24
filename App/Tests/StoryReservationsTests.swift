import Foundation
import Testing
@testable import Fable

/// The profile-switch quota bypass (2026-07-24 external money-path review,
/// P1): the meter used to be checked at tap time while the consuming Story
/// row appeared seconds later, so switching profiles during generation let
/// the same weekly credit be spent once per profile. The reservation ledger
/// closes the window: a claim counts against the meter the moment the tap
/// is accepted.
@MainActor
struct StoryReservationsTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    /// A family past its starter credits whose weekly story is ready.
    private var spentHistory: [Date] {
        [8.5, 9, 10].map { now.addingTimeInterval(-$0 * 86_400) }
    }

    @Test func theReviewsReproduction_tapSwitchTap_spendsOneCreditNotTwo() {
        let reservations = StoryReservations()
        let history = spentHistory
        #expect(StoryMeter.allowance(storyDates: history + reservations.dates, now: now) == .weeklyReady)

        // Profile A taps Tell Story: the claim is immediate and household-wide.
        let claim = reservations.reserve(now: now)

        // Mid-generation, the family switches to profile B and taps again.
        // The rebuilt view consults the same ledger: the credit is spent.
        let allowanceForB = StoryMeter.allowance(storyDates: history + reservations.dates, now: now)
        #expect(!allowanceForB.isAllowed, "profile B was allowed to double-spend the weekly credit")

        // A's story persists; the row carries the charge and the claim lifts.
        let persisted = history + [now]
        reservations.release(claim)
        #expect(reservations.dates.isEmpty)
        let after = StoryMeter.allowance(storyDates: persisted + reservations.dates, now: now)
        #expect(!after.isAllowed, "the persisted story must keep the meter spent")
    }

    @Test func starterCreditsAreClaimedOneTapAtATime() {
        let reservations = StoryReservations()
        var claims: [StoryReservations.Claim] = []
        for expected in [2, 1, 0] {
            let allowance = StoryMeter.allowance(storyDates: reservations.dates, now: now)
            #expect(allowance.isAllowed)
            claims.append(reservations.reserve(now: now))
            _ = expected
        }
        // Three in flight: the fourth tap must wait, whichever profile taps.
        let fourth = StoryMeter.allowance(storyDates: reservations.dates, now: now)
        #expect(!fourth.isAllowed)
    }

    @Test func anAbandonedClaimIsReleasedExactlyOnce() {
        let reservations = StoryReservations()
        let claim = reservations.reserve(now: now)
        let twin = reservations.reserve(now: now)
        reservations.release(claim)
        #expect(reservations.dates.count == 1)
        reservations.release(claim) // double release must not eat the twin
        #expect(reservations.dates.count == 1)
        reservations.release(twin)
        #expect(reservations.dates.isEmpty)
    }
}
