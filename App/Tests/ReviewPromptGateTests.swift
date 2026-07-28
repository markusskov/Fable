import Foundation
import Testing
@testable import Fable

struct ReviewPromptGateTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var twoDaysAgo: Date { now.addingTimeInterval(-2 * 86_400) }

    /// The one moment Fable may ask: an old favorite, a lived-in library,
    /// nothing asked recently, nothing asked this version.
    @Test func aRereadCloseInALivedInLibraryMayAsk() {
        #expect(ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: twoDaysAgo, storiesTold: 8,
            lastAsked: nil, lastAskedVersion: nil,
            currentVersion: "1.1", now: now
        ))
    }

    /// Tonight's fresh story is part of the telling, not a return to a
    /// favorite — closing it never asks, no matter how ripe everything
    /// else is.
    @Test func aFirstReadingNeverAsks() {
        #expect(!ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: now.addingTimeInterval(-60), storiesTold: 50,
            lastAsked: nil, lastAskedVersion: nil,
            currentVersion: "1.1", now: now
        ))
    }

    @Test func aYoungLibraryNeverAsks() {
        #expect(!ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: twoDaysAgo,
            storiesTold: ReviewPromptGate.minimumStoriesTold - 1,
            lastAsked: nil, lastAskedVersion: nil,
            currentVersion: "1.1", now: now
        ))
    }

    @Test func oneAskPerVersionEver() {
        #expect(!ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: twoDaysAgo, storiesTold: 20,
            lastAsked: now.addingTimeInterval(-365 * 86_400), lastAskedVersion: "1.1",
            currentVersion: "1.1", now: now
        ))
    }

    @Test func theQuietPeriodHoldsAcrossVersions() {
        // A new version does not reopen the door early: 60 quiet days
        // outrank the version change.
        #expect(!ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: twoDaysAgo, storiesTold: 20,
            lastAsked: now.addingTimeInterval(-10 * 86_400), lastAskedVersion: "1.0",
            currentVersion: "1.1", now: now
        ))
        // Both satisfied — quiet period passed AND a new version — asks.
        #expect(ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: twoDaysAgo, storiesTold: 20,
            lastAsked: now.addingTimeInterval(-ReviewPromptGate.quietPeriod), lastAskedVersion: "1.0",
            currentVersion: "1.1", now: now
        ))
    }

    @Test func theRereadBoundaryIsExact() {
        #expect(ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: now.addingTimeInterval(-ReviewPromptGate.rereadAge),
            storiesTold: 10,
            lastAsked: nil, lastAskedVersion: nil,
            currentVersion: "1.1", now: now
        ))
        #expect(!ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: now.addingTimeInterval(-ReviewPromptGate.rereadAge + 1),
            storiesTold: 10,
            lastAsked: nil, lastAskedVersion: nil,
            currentVersion: "1.1", now: now
        ))
    }
}
