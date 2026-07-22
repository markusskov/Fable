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
}
