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
    @ObservationIgnored private var task: Task<Void, Never>?

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
        task = Task {
            // The pause keeps the moment feeling authored even when the
            // curated engine answers instantly; abandonment cuts it short.
            async let pause: Void? = try? await Task.sleep(for: pacing)
            let result = await provider.makeStory(for: request)
            _ = await pause
            // No suspension between this check and delivery, so an outcome
            // can never flip after it is decided.
            let outcome: Outcome = Task.isCancelled ? .abandoned : .finished(result)
            isWriting = false
            task = nil
            deliver(outcome)
        }
    }

    /// Abandons the in-flight write, if any. The outcome still arrives (as
    /// `.abandoned`) so cleanup has exactly one place to live.
    func abandon() {
        task?.cancel()
    }
}
