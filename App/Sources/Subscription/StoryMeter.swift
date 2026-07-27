import Foundation

/// The free tier's story budget: three starter stories to fall in love with,
/// then one fresh story a week, forever. Reading the library is never metered,
/// and Fable+ bypasses this entirely (callers check the subscription first).
///
/// Pure date arithmetic over the family's story history — no clocks, no
/// storage — so every rule is unit-testable.
enum StoryMeter {
    static let starterStories = 3
    /// A fixed 604800 seconds, deliberately, rather than a calendar week.
    /// A calendar week would hold the unlock at the same wall-clock time
    /// across a daylight-saving change; a fixed interval instead shifts it
    /// by an hour twice a year. The trade is a timezone-independent rule
    /// that behaves identically for a family that travels, and an hour of
    /// drift that lands nowhere near bedtime for anyone whose stories are
    /// told in the evening. Revisit only if real usage says otherwise.
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
        guard let mostRecent = storyDates.max() else {
            return .starter(remaining: starterStories)
        }
        // Clamped to now, because a story cannot have been told in the
        // future. A device whose clock ran ahead (a manual change, a bad
        // NTP sync, a restored backup) stamps stories with future dates,
        // and measuring the week from one of those locks the family out
        // until that date arrives: potentially months, with no way to
        // explain it and nothing they can do. Clamping treats such a story
        // as told just now, so the longest possible wait stays one week.
        // Future stories still COUNT toward the starter allowance, so
        // moving the clock forward can never mint extra credits.
        let newest = min(mostRecent, now)
        let nextStoryDate = newest.addingTimeInterval(refillInterval)
        return now >= nextStoryDate ? .weeklyReady : .waiting(nextStoryDate: nextStoryDate)
    }
}
