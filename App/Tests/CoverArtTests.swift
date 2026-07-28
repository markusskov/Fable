import Foundation
import SwiftData
import Testing
@testable import Fable

// MARK: - Prompt vocabulary

struct CoverArtPromptTests {
    /// The whole prompt space is app-controlled editorial content (ADR
    /// 0004): every theme has reviewed scenes, none of them empty, none
    /// carrying template braces that could read as a slot to fill.
    @Test(arguments: StoryTheme.allCases)
    func everyThemeHasReviewedSceneVariants(theme: StoryTheme) {
        let variants = CoverArtPrompt.variants(for: theme)
        #expect(variants.count >= 2)
        for scene in variants {
            #expect(!scene.trimmingCharacters(in: .whitespaces).isEmpty)
            #expect(!scene.contains("{") && !scene.contains("}"))
        }
    }

    /// Every served prompt is one of the reviewed scenes plus the shared
    /// style contract — including its "no words or letters" line, the only
    /// guard against the generator painting ungated text into the image.
    @Test(arguments: StoryTheme.allCases)
    func servedPromptsAreASceneVariantPlusTheStyleContract(theme: StoryTheme) {
        for _ in 0..<20 {
            let prompt = CoverArtPrompt.prompt(for: theme)
            #expect(CoverArtPrompt.variants(for: theme).contains { prompt.hasPrefix($0) })
            #expect(prompt.hasSuffix("\(CoverArtPrompt.styleSuffix)."))
            #expect(prompt.contains("no words or letters"))
        }
    }

    /// `.externalProvider` is backed by a third-party service. A cover
    /// generated off-device would break the privacy promise outright, so
    /// its absence from the style list is pinned, not assumed.
    @Test func theExternalProviderStyleIsNeverUsed() {
        #expect(!PlaygroundCoverArtEngine.preferredStyles.contains(.externalProvider))
        #expect(!PlaygroundCoverArtEngine.preferredStyles.isEmpty)
    }
}

// MARK: - Studio rules

@MainActor
struct CoverArtStudioTests {
    /// Returns the CONTAINER, not just its context: a context whose
    /// container has been released takes the test host down with it.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeStory() -> Story {
        Story(
            telling: StoryProvider.TellResult(
                content: StoryContent(
                    title: "A Story",
                    pages: ["Once upon a time.", "Goodnight, Nova."],
                    moral: "Rest is good.",
                    language: .english
                ),
                engine: .curated,
                heroName: "Nova"
            ),
            theme: .ocean
        )
    }

    /// Bounded wait for the studio's outcome counter, so a regression fails
    /// the test instead of hanging CI forever.
    private func waitForPaints(_ count: Int, in studio: CoverArtStudio) async -> Bool {
        for _ in 0..<100_000 {
            if studio.paintsFinished >= count { return true }
            await Task.yield()
        }
        return studio.paintsFinished >= count
    }

    private struct FixedCoverEngine: CoverArtEngine {
        var data: Data?
        func makeCover(for theme: StoryTheme) async throws -> Data {
            guard let data else { throw CoverArtEngineError.unavailable }
            return data
        }
    }

    /// Parks until opened, and counts how many paints were asked for.
    private actor Gate {
        private var waiters: [CheckedContinuation<Void, Never>] = []
        private var isOpen = false
        private(set) var entries = 0

        func wait() async {
            entries += 1
            guard !isOpen else { return }
            await withCheckedContinuation { waiters.append($0) }
        }

        func open() {
            isOpen = true
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }

        @discardableResult
        func waitUntilEntered(bound: Int = 100_000) async -> Bool {
            for _ in 0..<bound {
                if entries > 0 { return true }
                await Task.yield()
            }
            return entries > 0
        }
    }

    private struct GatedCoverEngine: CoverArtEngine {
        let gate: Gate
        var data: Data? = Data([0xAB])
        func makeCover(for theme: StoryTheme) async throws -> Data {
            await gate.wait()
            guard let data else { throw CoverArtEngineError.unavailable }
            return data
        }
    }

    @Test func aFinishedPaintAttachesTheCoverAndSaves() async throws {
        let container = try makeContainer()
        let health = PersistenceHealth()
        let story = makeStory()
        container.mainContext.insert(story)
        try container.mainContext.save()

        let studio = CoverArtStudio(engine: FixedCoverEngine(data: Data([0x01, 0x02])))
        studio.illustrate(story, in: container.mainContext, health: health)
        #expect(await waitForPaints(1, in: studio))

        #expect(story.coverArt == Data([0x01, 0x02]))
        #expect(!container.mainContext.hasChanges, "the cover was attached but never saved")
        #expect(health.lastFailure == nil)
    }

    @Test func aFailedPaintLeavesTheStoryUntouchedAndTellsNoOne() async throws {
        let container = try makeContainer()
        let health = PersistenceHealth()
        let story = makeStory()
        container.mainContext.insert(story)
        try container.mainContext.save()

        let studio = CoverArtStudio(engine: FixedCoverEngine(data: nil))
        studio.illustrate(story, in: container.mainContext, health: health)
        #expect(await waitForPaints(1, in: studio))

        #expect(story.coverArt == nil)
        #expect(health.lastFailure == nil, "a missing cover is not a fault anyone hears about")
    }

    @Test func aStoryDeletedMidPaintIsNeverTouched() async throws {
        let container = try makeContainer()
        let story = makeStory()
        container.mainContext.insert(story)
        try container.mainContext.save()

        let gate = Gate()
        let studio = CoverArtStudio(engine: GatedCoverEngine(gate: gate))
        studio.illustrate(story, in: container.mainContext, health: nil)
        #expect(await gate.waitUntilEntered())

        container.mainContext.delete(story)
        try container.mainContext.save()

        await gate.open()
        #expect(await waitForPaints(1, in: studio))

        #expect(!container.mainContext.hasChanges, "a deleted story was written to")
        let survivors = try container.mainContext.fetch(FetchDescriptor<Story>())
        #expect(survivors.isEmpty, "the cover paint resurrected a deleted story")
    }

    @Test func anExistingCoverIsNotRepainted() async throws {
        let container = try makeContainer()
        let story = makeStory()
        story.coverArt = Data([0xFF])
        container.mainContext.insert(story)
        try container.mainContext.save()

        let gate = Gate()
        let studio = CoverArtStudio(engine: GatedCoverEngine(gate: gate))
        studio.illustrate(story, in: container.mainContext, health: nil)

        await gate.open()
        // No paint was started, so nothing to wait for: the request must
        // have returned synchronously without engaging the engine.
        #expect(await gate.entries == 0)
        #expect(studio.paintsFinished == 0)
        #expect(story.coverArt == Data([0xFF]))
    }

    /// One visual identity per adventure: an episode takes its series'
    /// earliest painted cover instead of rolling a near-identical scene of
    /// its own (owner feedback 2026-07-28).
    @Test func anEpisodeInheritsItsSeriesCoverWithoutPainting() async throws {
        let container = try makeContainer()
        let first = makeStory()
        first.coverArt = Data([0x11])
        first.episodeNumber = 1
        let second = makeStory()
        second.episodeNumber = 2
        let series = StorySeries(title: "The Lighthouse", theme: .ocean, childName: "Nova")
        container.mainContext.insert(series)
        container.mainContext.insert(first)
        container.mainContext.insert(second)
        first.series = series
        second.series = series
        try container.mainContext.save()

        let gate = Gate()
        let studio = CoverArtStudio(engine: GatedCoverEngine(gate: gate))
        studio.illustrate(second, in: container.mainContext, health: nil)

        // Inheritance is synchronous: no paint started, engine untouched.
        #expect(second.coverArt == Data([0x11]))
        #expect(await gate.entries == 0)
        #expect(!container.mainContext.hasChanges, "the inherited cover was not saved")
    }

    /// The first episode of a line has nothing to inherit and paints its
    /// own cover like any story.
    @Test func theFirstEpisodeOfASeriesPaintsItsOwnCover() async throws {
        let container = try makeContainer()
        let story = makeStory()
        story.episodeNumber = 1
        let series = StorySeries(title: "The Lighthouse", theme: .ocean, childName: "Nova")
        container.mainContext.insert(series)
        container.mainContext.insert(story)
        story.series = series
        try container.mainContext.save()

        let studio = CoverArtStudio(engine: FixedCoverEngine(data: Data([0x22])))
        studio.illustrate(story, in: container.mainContext, health: nil)
        #expect(await waitForPaints(1, in: studio))
        #expect(story.coverArt == Data([0x22]))
    }

    @Test func aSecondRequestWhileOneIsInTheAirIsIgnored() async throws {
        let container = try makeContainer()
        let story = makeStory()
        container.mainContext.insert(story)
        try container.mainContext.save()

        let gate = Gate()
        let studio = CoverArtStudio(engine: GatedCoverEngine(gate: gate))
        studio.illustrate(story, in: container.mainContext, health: nil)
        studio.illustrate(story, in: container.mainContext, health: nil)
        #expect(await gate.waitUntilEntered())

        await gate.open()
        #expect(await waitForPaints(1, in: studio))

        #expect(await gate.entries == 1, "one story bought two paints")
        #expect(studio.paintsFinished == 1)
        #expect(story.coverArt != nil)
    }
}
