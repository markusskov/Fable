import Foundation

/// When Fable may ask for an App Store rating. Calm edition (roadmap,
/// Milestone 6): only after a delight moment — closing the storybook on a
/// RE-READ, because a family that comes back to an old story is a family
/// the ritual is working for — and never during first-run, generation, or
/// a first reading. Pure rules over plain values, so every cap is
/// unit-testable; the system's own 3-per-year cap applies on top.
enum ReviewPromptGate {
    /// A story counts as re-read when it is at least this old: tonight's
    /// fresh story is part of the telling, not a return to a favorite.
    static let rereadAge: TimeInterval = 24 * 60 * 60
    /// The library must feel lived-in before Fable asks anything of anyone.
    static let minimumStoriesTold = 5
    /// At most one ask per two months, and never twice for one version.
    static let quietPeriod: TimeInterval = 60 * 24 * 60 * 60

    static func shouldAsk(
        closingStoryCreatedAt storyCreatedAt: Date,
        storiesTold: Int,
        lastAsked: Date?,
        lastAskedVersion: String?,
        currentVersion: String,
        now: Date = .now
    ) -> Bool {
        guard now.timeIntervalSince(storyCreatedAt) >= rereadAge else { return false }
        guard storiesTold >= minimumStoriesTold else { return false }
        if lastAskedVersion == currentVersion { return false }
        if let lastAsked, now.timeIntervalSince(lastAsked) < quietPeriod { return false }
        return true
    }
}
