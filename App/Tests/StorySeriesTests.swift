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

    @Test func episodesStayOrderedAndNumbered() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let series = StorySeries(title: "Nova and the Fox", theme: .adventure, childName: "Nova")
        context.insert(series)
        #expect(series.nextEpisodeNumber == 1)

        // Insert episodes out of order; ordering must come from numbers.
        for number in [2, 1, 3] {
            let story = Story(
                content: content(title: "Episode \(number)", recap: "Recap \(number)."),
                theme: .adventure,
                childName: "Nova",
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

    @Test func recapFallsBackToTheMoral() {
        let authored = Story(
            content: content(title: "With recap", recap: "Nova found the lantern."),
            theme: .magic, childName: "Nova", engine: .model
        )
        #expect(authored.recap == "Nova found the lantern.")

        let curated = Story(
            content: content(title: "No recap"),
            theme: .magic, childName: "Nova", engine: .curated
        )
        #expect(curated.recap == "Gentle nights make gentle days.")
    }
}
