import Foundation
import SwiftData
import Testing
@testable import Fable

@MainActor
struct StorySeriesTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: config
        )
    }

    private func content(title: String, recap: String = "") -> StoryContent {
        StoryContent(
            title: title,
            pages: ["Page one of the tale.", "Page two.", "Page three.", "Goodnight, Nova."],
            moral: "Gentle nights make gentle days.",
            recap: recap
        )
    }

    private func story(
        title: String,
        recap: String = "",
        theme: StoryTheme,
        engine: StoryEngineKind
    ) -> Story {
        Story(
            telling: StoryProvider.TellResult(
                content: content(title: title, recap: recap),
                engine: engine,
                heroName: "Nova"
            ),
            theme: theme
        )
    }

    @Test func episodesStayOrderedAndNumbered() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let series = StorySeries(title: "Nova and the Fox", theme: .adventure, childName: "Nova")
        context.insert(series)
        #expect(series.nextEpisodeNumber == 1)

        // Insert episodes out of order; ordering must come from numbers.
        for number in [2, 1, 3] {
            let story = story(
                title: "Episode \(number)",
                recap: "Recap \(number).",
                theme: .adventure,
                engine: .model
            )
            story.episodeNumber = number
            story.series = series
            context.insert(story)
        }
        #expect(series.orderedEpisodes.map(\.episodeNumber) == [1, 2, 3])
        #expect(series.nextEpisodeNumber == 4)
        #expect(series.recentRecaps(limit: 2) == ["Recap 2.", "Recap 3."])
    }

    /// Finding #3 of the 2026-07-24 external review: the episode number a
    /// commit stamps must be re-read from the series at commit time, not the
    /// tap-time snapshot baked into the prompt — an episode that landed while
    /// this one was being written must not be duplicated.
    @Test func commitTimeEpisodeNumberSkipsPastAConcurrentlyLandedEpisode() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let series = StorySeries(title: "Nova and the Fox", theme: .adventure, childName: "Nova")
        context.insert(series)

        // Tap time: the prompt is told this will be episode 1.
        let promptNumber = series.nextEpisodeNumber
        #expect(promptNumber == 1)

        // While writing, another write commits episode 1.
        let landed = story(title: "Landed first", theme: .adventure, engine: .model)
        landed.episodeNumber = series.nextEpisodeNumber
        landed.series = series
        context.insert(landed)

        // Commit re-reads: this story becomes episode 2, never a second 1.
        let finished = story(title: "Finished second", theme: .adventure, engine: .model)
        finished.episodeNumber = series.nextEpisodeNumber
        finished.series = series
        context.insert(finished)

        #expect(finished.episodeNumber == 2)
        #expect(series.orderedEpisodes.map(\.episodeNumber) == [1, 2])
    }

    @Test func recapFallsBackToTheMoral() {
        let authored = story(
            title: "With recap",
            recap: "Nova found the lantern.",
            theme: .magic,
            engine: .model
        )
        #expect(authored.recap == "Nova found the lantern.")

        let curated = story(
            title: "No recap",
            theme: .magic,
            engine: .curated
        )
        #expect(curated.recap == "Gentle nights make gentle days.")
    }
}
