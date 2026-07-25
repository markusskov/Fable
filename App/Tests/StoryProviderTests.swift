import Testing
@testable import Fable

/// The product contract behind "never break bedtime": whatever the model
/// engine does — unavailable, refused, rejected by the safety gate — the
/// provider hands back a story a parent can read tonight.
struct StoryProviderTests {
    @Test(arguments: StoryTheme.allCases)
    func aStoryAlwaysComesBack(theme: StoryTheme) async {
        let provider = StoryProvider()
        let request = StoryRequest(
            childName: "Astrid",
            ageBand: .little,
            theme: theme,
            companion: "Luna the cat",
            comfortObject: "the yellow blanket"
        )
        let result = await provider.makeStory(for: request)
        #expect(!result.content.title.isEmpty)
        #expect(result.content.pages.count >= 4)
        #expect(result.content.pages.last?.localizedCaseInsensitiveContains("Astrid") == true)
    }
}

/// The two cancellation guards added in rounds five and six. Neither was
/// pinned by the writer-level tests: one checked an exit count before the
/// abandoned task had conclusively landed, and the post-loop guard was never
/// reached by that timing at all (round seven, test verdict).
@MainActor
struct StoryProviderCancellationTests {
    /// Counts calls and fails immediately, WITHOUT throwing CancellationError
    /// — the uncooperative shape the guards exist for.
    private actor CountingFailingEngine: StoryEngine {
        private(set) var calls = 0
        private let error: any Error

        init(error: any Error = StoryEngineError.generationFailed) { self.error = error }

        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            calls += 1
            throw error
        }
    }

    /// Cancels the calling task on its first call, then fails as `unavailable`
    /// so the model loop BREAKS — the only route to the post-loop guard.
    private actor SelfCancellingUnavailableEngine: StoryEngine {
        private(set) var calls = 0

        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            calls += 1
            withUnsafeCurrentTask { $0?.cancel() }
            throw StoryEngineError.unavailable
        }
    }

    private var request: StoryRequest {
        StoryRequest(childName: "Nova", ageBand: .little, theme: .adventure,
                     companion: "", comfortObject: "")
    }

    /// Guard one: a write cancelled before it starts spends nothing at all.
    @Test func acancelledWriteNeverCallsAnEngine() async {
        let model = CountingFailingEngine()
        let curated = CountingFailingEngine()
        let provider = StoryProvider(model: model, curated: curated)
        let task = Task { await provider.makeStory(for: request) }
        task.cancel()
        let result = await task.value
        #expect(result.engine == .floor)
        #expect(await model.calls == 0, "a cancelled write still called the model engine")
        #expect(await curated.calls == 0, "a cancelled write still rendered a curated story")
    }

    /// Guard two: when the model engine reports unavailable and the task is
    /// already cancelled, the provider stops instead of rendering a curated
    /// story nobody will read.
    @Test func acancelledWriteStopsAtTheModelBreakInsteadOfRenderingCurated() async {
        let model = SelfCancellingUnavailableEngine()
        let curated = CountingFailingEngine()
        let provider = StoryProvider(model: model, curated: curated)
        let result = await Task { await provider.makeStory(for: request) }.value
        #expect(result.engine == .floor)
        #expect(await model.calls == 1, "unavailable must not be retried")
        #expect(await curated.calls == 0, "a cancelled write still rendered a curated story")
    }

    /// And the guard is not overeager: an uncancelled write that hits the
    /// same unavailable break still gets its curated story.
    @Test func anUncancelledWriteStillFallsBackToCuratedOnUnavailable() async {
        let model = CountingFailingEngine(error: StoryEngineError.unavailable)
        let curated = CountingFailingEngine()
        let provider = StoryProvider(model: model, curated: curated)
        let result = await provider.makeStory(for: request)
        #expect(await model.calls == 1)
        #expect(await curated.calls == 1, "the curated shelf was skipped for a live write")
        #expect(result.engine == .emergency)
    }
}
