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

        /// Suspends until a write has actually entered the gate, or gives
        /// up. A real condition, so abandonment is provably mid-flight —
        /// and bounded, so a regression in entry fails the test instead of
        /// hanging CI forever (round nine).
        @discardableResult
        func waitUntilEntered(bound: Int = 100_000) async -> Bool {
            for _ in 0..<bound {
                if entries > 0 { return true }
                await Task.yield()
            }
            return entries > 0
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

    /// Drains a gate to an exact expected number of engine exits. Bounded,
    /// so a wrong expectation fails the test instead of hanging it.
    private func drain(_ gate: Gate, to expected: Int, _ what: String) async {
        for _ in 0..<10_000 {
            if await gate.exits >= expected { break }
            await Task.yield()
        }
        #expect(await gate.exits == expected, "\(what): expected \(expected) engine exits")
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

    @Test(.timeLimit(.minutes(1)))
    func anAbandonedWriteReportsAbandonedNotFinished() async {
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
    @Test(.timeLimit(.minutes(1)))
    func abandoningAnUncooperativeWriteStillRefundsAtOnce() async {
        let gate = Gate()
        let writer = StoryWriter()
        let provider = StoryProvider(
            model: StubbornEngine(gate: gate),
            curated: StubbornEngine(gate: gate)
        )
        var outcomes: [StoryWriter.Outcome] = []
        writer.write(request, using: provider, pacing: .zero) { outcomes.append($0) }

        // No callback continuation to strand: abandon() delivers
        // synchronously, so entry can be REQUIRED and a failure to park
        // fails the test instead of leaving a continuation unresumed
        // (round ten).
        let entered = await gate.waitUntilEntered()
        #expect(entered, "the engine never parked, so abandonment proves nothing")
        if entered { writer.abandon() }

        #expect(await gate.exits == 0, "the engine returned before the outcome arrived")
        #expect(outcomes.count == 1)
        if case .abandoned = outcomes.first {} else {
            Issue.record("an uncooperative write must still report abandoned")
        }
        #expect(!writer.isWriting)

        // The engine finally returns; its result must go nowhere.
        await gate.open()
        // Only the already in-flight call completes: the provider now
        // checks cancellation before each attempt, so no second one starts.
        await drain(gate, to: 1, "abandoned chain")
        for _ in 0..<10_000 where writer.droppedOutcomes == 0 { await Task.yield() }
        #expect(outcomes.count == 1, "a straggler write delivered a second outcome")
    }

    /// The scenario round four flagged and round five sharpened: an
    /// abandoned write's result must not disturb a replacement write that is
    /// STILL RUNNING. Finishing the replacement first would prove nothing.
    @Test(.timeLimit(.minutes(1)))
    func astragglerCannotDisturbAStillRunningReplacementWrite() async {
        let abandonedGate = Gate()
        let replacementGate = Gate()
        let writer = StoryWriter()

        var first: [StoryWriter.Outcome] = []
        writer.write(
            request,
            using: StoryProvider(
                model: StubbornEngine(gate: abandonedGate),
                curated: StubbornEngine(gate: abandonedGate)
            ),
            pacing: .zero
        ) { first.append($0) }
        let enteredFirst = await abandonedGate.waitUntilEntered()
        #expect(enteredFirst, "the first write never reached its engine")
        if enteredFirst { writer.abandon() }
        #expect(first.count == 1)

        // The replacement starts and parks: it is in flight, not finished.
        var second: [StoryWriter.Outcome] = []
        writer.write(
            request,
            using: StoryProvider(
                model: StubbornEngine(gate: replacementGate),
                curated: StubbornEngine(gate: replacementGate)
            ),
            pacing: .zero
        ) { outcome in
            second.append(outcome)
        }
        #expect(await replacementGate.waitUntilEntered(), "the replacement never reached its engine")
        #expect(writer.isWriting, "the replacement write should still be running")

        // The abandoned write's engine finally returns, mid-replacement.
        await abandonedGate.open()
        await drain(abandonedGate, to: 1, "abandoned chain")
        // Wait for the straggler to actually LAND and be dropped: yielding
        // and hoping proved nothing (round six, test verdict).
        for _ in 0..<10_000 where writer.droppedOutcomes == 0 { await Task.yield() }
        #expect(writer.droppedOutcomes == 1, "the straggler never arrived, so nothing was proved")
        #expect(first.count == 1, "the abandoned write delivered twice")
        #expect(second.isEmpty, "a straggler was delivered into a running write's closure")
        #expect(writer.isWriting, "a straggler ended the replacement write")

        // The replacement then finishes on its own terms.
        await replacementGate.open()
        await drain(replacementGate, to: StoryProvider.modelAttempts + 1, "live chain")
        for _ in 0..<10_000 where second.isEmpty { await Task.yield() }
        #expect(second.count == 1)
        // The CASE matters: without the writeID guard a stale .abandoned
        // could take this slot and a count-only assertion would pass.
        guard case .finished = second.first else {
            Issue.record("the replacement write received the straggler's outcome")
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

    /// The weak capture round seven added, actually observed: an abandoned
    /// writer must not be kept alive by an engine that never returns.
    @Test(.timeLimit(.minutes(1)))
    func anAbandonedWriterDeallocatesWhileItsEngineIsStillParked() async {
        let gate = Gate()
        weak var weakWriter: StoryWriter?
        var parked = false

        await {
            let writer = StoryWriter()
            weakWriter = writer
            writer.write(
                request,
                using: StoryProvider(
                    model: StubbornEngine(gate: gate),
                    curated: StubbornEngine(gate: gate)
                ),
                pacing: .zero
            ) { _ in }
            // REQUIRE the park: zero entries also yields zero exits, so
            // without this the test could pass having never parked an
            // engine at all (round ten).
            parked = await gate.waitUntilEntered()
            if parked { writer.abandon() }
        }()

        #expect(parked, "no engine ever parked, so nothing about retention is proved")
        #expect(await gate.exits == 0, "the engine returned before the writer was dropped")
        for _ in 0..<10_000 where weakWriter != nil { await Task.yield() }
        #expect(weakWriter == nil, "an abandoned writer was retained by its parked engine")

        await gate.open()
        await drain(gate, to: 1, "orphaned chain")
    }
}
