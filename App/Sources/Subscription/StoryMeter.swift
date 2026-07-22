import Foundation

/// The free tier's story budget: three starter stories to fall in love with,
/// then one fresh story a week, forever. Reading the library is never metered,
/// and Fable+ bypasses this entirely (callers check the subscription first).
///
/// Pure date arithmetic over the family's story history — no clocks, no
/// storage — so every rule is unit-testable.
enum StoryMeter {
    static let starterStories = 3
    static let refillInterval: TimeInterval = 7 * 24 * 60 * 60

    /// What the free tier may do right now, given when every previous story
    /// was told (order does not matter).
    enum Allowance: Equatable {
        /// A starter credit is available; `remaining` counts this one.
        case starter(remaining: Int)
        /// Starters are spent, but the weekly story is ready.
        case weeklyReady
        /// Nothing available until `nextStoryDate`.
        case waiting(nextStoryDate: Date)

        var isAllowed: Bool {
            switch self {
            case .starter, .weeklyReady: true
            case .waiting: false
            }
        }
    }

    static func allowance(storyDates: [Date], now: Date = .now) -> Allowance {
        if storyDates.count < starterStories {
            return .starter(remaining: starterStories - storyDates.count)
        }
        // Weekly refill is measured from the most recent story: tell tonight's
        // story, and the next free one is ready this time next week.
        guard let newest = storyDates.max() else {
            return .starter(remaining: starterStories)
        }
        let nextStoryDate = newest.addingTimeInterval(refillInterval)
        return now >= nextStoryDate ? .weeklyReady : .waiting(nextStoryDate: nextStoryDate)
    }
}
