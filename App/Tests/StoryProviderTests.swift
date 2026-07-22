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
