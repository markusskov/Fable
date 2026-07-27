import Foundation
import Testing
@testable import Fable

struct StoryMeterTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var day: TimeInterval { 24 * 60 * 60 }

    @Test func aNewFamilyHasThreeStarterStories() {
        #expect(StoryMeter.allowance(storyDates: [], now: now) == .starter(remaining: 3))
    }

    @Test func starterCreditsCountDown() {
        let one = [now.addingTimeInterval(-2)]
        #expect(StoryMeter.allowance(storyDates: one, now: now) == .starter(remaining: 2))
        let two = one + [now.addingTimeInterval(-1)]
        #expect(StoryMeter.allowance(storyDates: two, now: now) == .starter(remaining: 1))
    }

    @Test func fourthStoryTheSameNightMustWait() {
        let starters = (1...3).map { now.addingTimeInterval(-Double($0)) }
        let allowance = StoryMeter.allowance(storyDates: starters, now: now)
        #expect(allowance == .waiting(nextStoryDate: starters[0].addingTimeInterval(StoryMeter.refillInterval)))
        #expect(!allowance.isAllowed)
    }

    @Test func weeklyStoryUnlocksSevenDaysAfterTheNewest() {
        let dates = [
            now.addingTimeInterval(-30 * day),
            now.addingTimeInterval(-20 * day),
            now.addingTimeInterval(-8 * day),
        ]
        #expect(StoryMeter.allowance(storyDates: dates, now: now) == .weeklyReady)
    }

    @Test func refillMeasuresFromTheNewestStoryRegardlessOfOrder() {
        // Shuffled input, newest is 3 days ago → waiting 4 more days.
        let newest = now.addingTimeInterval(-3 * day)
        let dates = [now.addingTimeInterval(-40 * day), newest, now.addingTimeInterval(-10 * day)]
        let expected = StoryMeter.Allowance.waiting(nextStoryDate: newest.addingTimeInterval(7 * day))
        #expect(StoryMeter.allowance(storyDates: dates.shuffled(), now: now) == expected)
    }

    @Test func unlockIsExactAtTheBoundary() {
        let newest = now.addingTimeInterval(-7 * day)
        let dates = [now.addingTimeInterval(-9 * day), now.addingTimeInterval(-8 * day), newest]
        #expect(StoryMeter.allowance(storyDates: dates, now: now) == .weeklyReady)
        let justBefore = newest.addingTimeInterval(7 * day - 1)
        #expect(StoryMeter.allowance(storyDates: dates, now: justBefore)
            == .waiting(nextStoryDate: newest.addingTimeInterval(7 * day)))
    }

    // MARK: - Clock jumps (roadmap finding #8)

    /// A device whose clock ran ahead stamps stories with future dates. The
    /// week must be measured from now, not from that date, or the family is
    /// locked out until it arrives: potentially months, with nothing they
    /// can do about it and no way to explain it.
    @Test func afutureDatedStoryDoesNotLockTheFamilyOut() {
        let history = [
            now.addingTimeInterval(-10 * 86_400),
            now.addingTimeInterval(-9 * 86_400),
            // Told while the clock was three months ahead.
            now.addingTimeInterval(90 * 86_400),
        ]
        guard case .waiting(let next) = StoryMeter.allowance(storyDates: history, now: now) else {
            Issue.record("expected the meter to be waiting, not open")
            return
        }
        #expect(next <= now.addingTimeInterval(StoryMeter.refillInterval),
                "a future-dated story pushed the next free story months out")
    }

    /// The forgiveness must not become a loophole: a future story still
    /// spends a starter credit, so winding the clock forward cannot mint
    /// extra stories.
    @Test func afutureDatedStoryStillSpendsItsStarterCredit() {
        let history = (1...3).map { now.addingTimeInterval(Double($0) * 86_400) }
        let allowance = StoryMeter.allowance(storyDates: history, now: now)
        #expect(!allowance.isAllowed, "future-dated stories minted free credits")
    }

    /// And an ordinary history is untouched by the clamp.
    @Test func anOrdinaryHistoryIsUnaffectedByTheClamp() {
        let history = [
            now.addingTimeInterval(-20 * 86_400),
            now.addingTimeInterval(-14 * 86_400),
            now.addingTimeInterval(-2 * 86_400),
        ]
        guard case .waiting(let next) = StoryMeter.allowance(storyDates: history, now: now) else {
            Issue.record("expected to be waiting five days after the newest story")
            return
        }
        #expect(next == now.addingTimeInterval(5 * 86_400))
    }
}
