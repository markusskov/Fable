import Foundation
import Observation

/// Owns one in-flight story write from tap to outcome. The 2026-07-24
/// external review (finding #3) flagged the fire-and-forget Task behind the
/// Tell-Story button: nothing owned it, nothing could cancel it, and it
/// steered navigation whenever it finished — even over a different child's
/// screen. This object is that ownership: the screen that starts a write
/// holds its writer, can abandon it, and receives exactly one outcome on
/// the main actor.
@MainActor
@Observable
final class StoryWriter {
    enum Outcome {
        /// The story is ready. The caller decides whether it may still be
        /// committed and shown — the family may have moved on by now.
        case finished(StoryProvider.TellResult)
        /// The write was abandoned before it finished. No story exists;
        /// the caller refunds whatever it reserved.
        case abandoned
    }

    private(set) var isWriting = false
    /// Outcomes that arrived for a write nobody is waiting for any more.
    /// Observable so a test can wait for a straggler to actually land
    /// instead of yielding and hoping (round six, test verdict).
    private(set) var droppedOutcomes = 0
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var deliver: (@MainActor (Outcome) -> Void)?
    /// Identity of the write the stored `deliver` belongs to, so a straggler
    /// task from an abandoned write can never deliver its stale story into a
    /// newer write's closure.
    @ObservationIgnored private var writeID = UUID()

    /// Starts writing. Callers must check `isWriting` before reserving a
    /// meter claim for this write; the guard here is a backstop so a racing
    /// second call can never produce a second outcome, not a path that
    /// manages the caller's claim.
    func write(
        _ request: StoryRequest,
        using provider: StoryProvider,
        pacing: Duration = .seconds(0.8),
        deliver: @escaping @MainActor (Outcome) -> Void
    ) {
        guard !isWriting else { return }
        isWriting = true
        self.deliver = deliver
        let id = UUID()
        writeID = id
        task = Task {
            // The pause keeps the moment feeling authored even when the
            // curated engine answers instantly; abandonment cuts it short.
            async let pause: Void? = try? await Task.sleep(for: pacing)
            let result = await provider.makeStory(for: request)
            _ = await pause
            conclude(id, with: Task.isCancelled ? .abandoned : .finished(result))
        }
    }

    /// Abandons the in-flight write, if any. The `.abandoned` outcome is
    /// delivered IMMEDIATELY — not when the engine deigns to notice the
    /// cancellation. An engine that ignores cancellation must not hold the
    /// family's meter claim hostage (2026-07-24 review round three); its
    /// eventual result finds a concluded write and is dropped.
    func abandon() {
        task?.cancel()
        conclude(writeID, with: .abandoned)
    }

    /// Delivers exactly once per write: whichever of task-completion or
    /// abandon() gets here first wins, and only for the write it belongs to.
    private func conclude(_ id: UUID, with outcome: Outcome) {
        guard id == writeID, let deliver else {
            droppedOutcomes += 1
            return
        }
        self.deliver = nil
        isWriting = false
        task = nil
        deliver(outcome)
    }
}
