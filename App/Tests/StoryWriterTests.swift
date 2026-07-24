import Foundation
import Testing
@testable import Fable

/// The generation task lifecycle (2026-07-24 external review, finding #3):
/// a write is owned by the screen that started it, can be abandoned when
/// the family moves to another child, and delivers exactly one outcome —
/// so the meter claim is refunded or converted, never leaked, and a stale
/// profile's reader is never pushed over the active one.
@MainActor
struct StoryWriterTests {
    /// Gate-passing English content, so the finished path is deterministic
    /// instead of depending on the test host's Apple Intelligence.
    private struct GoodEngine: StoryEngine {
        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            StoryContent(
                title: "The Gentle Evening",
                pages: [
                    "Once upon a time, \(request.childName) spent a long and lovely day playing in the sunshine with \(request.companionOrDefault), and now the sky was turning gold.",
                    "Together they walked home slowly, watching the first star appear, talking softly about all the small wonderful things they had seen.",
                    "At home, \(request.childName) washed up, put on the coziest pajamas, and snuggled deep under the covers with \(request.comfortObjectOrDefault) held close.",
                    "The moon peeked in to say goodnight. Sleep well, \(request.childName), and have the sweetest dreams until morning comes.",
                ],
                moral: "A gentle day deserves a gentle night.",
                language: .english
            )
        }
    }

    /// Suspends until cancelled — the shape of a model call mid-generation.
    private struct NeverFinishingEngine: StoryEngine {
        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            try await Task.sleep(for: .seconds(60))
            throw StoryEngineError.generationFailed
        }
    }

    private var request: StoryRequest {
        StoryRequest(
            childName: "Nova",
            ageBand: .little,
            theme: .adventure,
            companion: "",
            comfortObject: ""
        )
    }

    @Test func aFinishedWriteDeliversItsStoryExactlyOnce() async {
        let writer = StoryWriter()
        let provider = StoryProvider(model: GoodEngine(), curated: GoodEngine())
        var outcomes: [StoryWriter.Outcome] = []
        await withCheckedContinuation { done in
            writer.write(request, using: provider, pacing: .zero) { outcome in
                outcomes.append(outcome)
                done.resume()
            }
            #expect(writer.isWriting)
        }
        #expect(outcomes.count == 1)
        guard case .finished(let result) = outcomes.first else {
            Issue.record("expected a finished outcome")
            return
        }
        #expect(result.engine == .model)
        #expect(!writer.isWriting)
    }

    @Test func anAbandonedWriteReportsAbandonedNotFinished() async {
        let writer = StoryWriter()
        let provider = StoryProvider(
            model: NeverFinishingEngine(),
            curated: NeverFinishingEngine()
        )
        var outcomes: [StoryWriter.Outcome] = []
        await withCheckedContinuation { done in
            writer.write(request, using: provider, pacing: .zero) { outcome in
                outcomes.append(outcome)
                done.resume()
            }
            // Let the write reach its engine suspension, then abandon it —
            // the profile-switch shape. Abandoning before it even starts
            // must produce the same outcome, so ordering is not load-bearing.
            Task {
                await Task.yield()
                writer.abandon()
            }
        }
        #expect(outcomes.count == 1)
        guard case .abandoned = outcomes.first else {
            Issue.record("an abandoned write must never deliver .finished")
            return
        }
        #expect(!writer.isWriting)
    }

    @Test func aRacingSecondWriteCannotProduceASecondOutcome() async {
        let writer = StoryWriter()
        let provider = StoryProvider(
            model: NeverFinishingEngine(),
            curated: NeverFinishingEngine()
        )
        var firstOutcomes: [StoryWriter.Outcome] = []
        var secondDelivered = false
        await withCheckedContinuation { done in
            writer.write(request, using: provider, pacing: .zero) { outcome in
                firstOutcomes.append(outcome)
                done.resume()
            }
            writer.write(request, using: provider, pacing: .zero) { _ in
                secondDelivered = true
            }
            writer.abandon()
        }
        // Give a wrongly-started second task every chance to surface.
        await Task.yield()
        await Task.yield()
        #expect(firstOutcomes.count == 1)
        #expect(!secondDelivered, "a refused write must deliver nothing")
    }

    @Test func aWriteServesOnlyTheProfileStillOnScreen() {
        let child = UUID()
        #expect(TonightView.writeServesActiveProfile(
            activeProfileUUID: child.uuidString, profile: child
        ))
        // Empty stored id means "the fallback first profile" — this screen's.
        #expect(TonightView.writeServesActiveProfile(
            activeProfileUUID: "", profile: child
        ))
        #expect(!TonightView.writeServesActiveProfile(
            activeProfileUUID: UUID().uuidString, profile: child
        ))
    }
}
