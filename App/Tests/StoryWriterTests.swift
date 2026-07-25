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

    /// A gate that is NOT cancellation-aware, so a write parked on it keeps
    /// running no matter what the task's cancellation flag says.
    private actor Gate {
        private var continuation: CheckedContinuation<Void, Never>?
        private var isOpen = false
        private var entryWaiters: [CheckedContinuation<Void, Never>] = []
        private(set) var entries = 0
        private(set) var exits = 0

        func wait() async {
            entries += 1
            entryWaiters.forEach { $0.resume() }
            entryWaiters.removeAll()
            defer { exits += 1 }
            guard !isOpen else { return }
            await withCheckedContinuation { continuation = $0 }
        }

        /// Suspends until a write has actually entered the gate — a real
        /// signal, so abandonment is provably mid-flight rather than
        /// scheduled and hoped for (round four, test verdict).
        func waitUntilEntered() async {
            guard entries == 0 else { return }
            await withCheckedContinuation { entryWaiters.append($0) }
        }

        func open() {
            isOpen = true
            continuation?.resume()
            continuation = nil
        }
    }

    /// Ignores cancellation entirely — a real engine, or a framework call
    /// inside one, that never checks `Task.isCancelled`. Abandoning such a
    /// write must still return the family's meter claim at once
    /// (2026-07-24 review round three, P2).
    private struct StubbornEngine: StoryEngine {
        let gate: Gate

        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            await gate.wait()
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

    /// Abandonment must not need the engine's cooperation: the outcome
    /// arrives while the engine is still parked, and the straggler result
    /// that shows up later is dropped rather than delivered twice.
    @Test func abandoningAnUncooperativeWriteStillRefundsAtOnce() async {
        let gate = Gate()
        let writer = StoryWriter()
        let provider = StoryProvider(
            model: StubbornEngine(gate: gate),
            curated: StubbornEngine(gate: gate)
        )
        var outcomes: [StoryWriter.Outcome] = []
        await withCheckedContinuation { done in
            writer.write(request, using: provider, pacing: .zero) { outcome in
                outcomes.append(outcome)
                done.resume()
            }
            Task {
                // Abandon only once the engine is provably parked.
                await gate.waitUntilEntered()
                writer.abandon()
            }
        }
        // Delivered while the engine is STILL suspended on the gate.
        #expect(await gate.exits == 0, "the engine returned before the outcome arrived")
        #expect(outcomes.count == 1)
        guard case .abandoned = outcomes.first else {
            Issue.record("an uncooperative write must still report abandoned")
            return
        }
        #expect(!writer.isWriting)

        // The engine finally returns and the whole provider chain drains:
        // two model attempts plus one curated attempt, all now instant.
        await gate.open()
        let expectedExits = StoryProvider.modelAttempts + 1
        while await gate.exits < expectedExits { await Task.yield() }
        await Task.yield()
        #expect(outcomes.count == 1, "a straggler write delivered a second outcome")
    }

    /// The scenario round four found untested: an abandoned write's result
    /// arrives AFTER a new write has started, and must not be delivered into
    /// the new write's closure. Write identity, not just cancellation, is
    /// what keeps them apart.
    @Test func astragglerFromAnAbandonedWriteCannotHijackTheNextWrite() async {
        let gate = Gate()
        let writer = StoryWriter()
        let stalled = StoryProvider(model: StubbornEngine(gate: gate), curated: StubbornEngine(gate: gate))
        let ready = StoryProvider(model: GoodEngine(), curated: GoodEngine())

        var first: [StoryWriter.Outcome] = []
        await withCheckedContinuation { done in
            writer.write(request, using: stalled, pacing: .zero) { outcome in
                first.append(outcome)
                done.resume()
            }
            Task {
                await gate.waitUntilEntered()
                writer.abandon()
            }
        }
        #expect(first.count == 1)

        // A new write starts and finishes while the first is still parked.
        var second: [StoryWriter.Outcome] = []
        await withCheckedContinuation { done in
            writer.write(request, using: ready, pacing: .zero) { outcome in
                second.append(outcome)
                done.resume()
            }
        }
        #expect(second.count == 1)
        guard case .finished = second.first else {
            Issue.record("the second write should have finished normally")
            return
        }

        // Now the abandoned write's engine returns at last.
        await gate.open()
        let expectedExits = StoryProvider.modelAttempts + 1
        while await gate.exits < expectedExits { await Task.yield() }
        await Task.yield()
        #expect(first.count == 1, "the abandoned write delivered twice")
        #expect(second.count == 1, "a straggler was delivered into the next write's closure")
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
