import Testing
@testable import Fable

struct CuratedStoryEngineTests {
    private let engine = CuratedStoryEngine()

    private func request(theme: StoryTheme = .adventure) -> StoryRequest {
        StoryRequest(
            childName: "Nova",
            ageBand: .little,
            theme: theme,
            companion: "Bruno the dog",
            comfortObject: "the yellow blanket"
        )
    }

    @Test func sameSeedProducesIdenticalStory() async throws {
        let a = try await engine.makeStory(for: request(), seed: 1234)
        let b = try await engine.makeStory(for: request(), seed: 1234)
        #expect(a == b)
    }

    @Test func differentSeedsProduceVariation() async throws {
        var distinctTitlesAndBodies = Set<String>()
        for seed: UInt64 in 0..<20 {
            let story = try await engine.makeStory(for: request(), seed: seed)
            distinctTitlesAndBodies.insert(story.title + story.pages.joined())
        }
        #expect(distinctTitlesAndBodies.count > 1)
    }

    @Test(arguments: StoryTheme.allCases)
    func everyThemeRendersCompletely(theme: StoryTheme) async throws {
        for seed: UInt64 in 0..<25 {
            let story = try await engine.makeStory(for: request(theme: theme), seed: seed)

            #expect(!story.title.isEmpty)
            #expect(!story.moral.isEmpty)
            #expect(story.pages.count >= 4, "A bedtime story needs a real arc")

            // No leftover template tokens anywhere.
            for text in [story.title, story.moral] + story.pages {
                #expect(!text.contains("{"), "Unrendered token in: \(text)")
                #expect(!text.contains("}"), "Unrendered token in: \(text)")
            }

            // The child is the hero: their name must appear in the story body.
            #expect(story.pages.joined().contains("Nova"))
        }
    }

    @Test func personalizationFlowsThrough() async throws {
        let story = try await engine.makeStory(for: request(theme: .animals), seed: 99)
        let fullText = story.pages.joined()
        #expect(fullText.contains("Bruno the dog"))
        #expect(fullText.contains("the yellow blanket"))
    }

    @Test func blankOptionalFieldsGetGracefulDefaults() async throws {
        var blankRequest = request()
        blankRequest.companion = "   "
        blankRequest.comfortObject = ""
        let story = try await engine.makeStory(for: blankRequest, seed: 5)
        let fullText = story.pages.joined()
        #expect(!fullText.contains("{"))
        #expect(fullText.contains("Nova"))
    }

    @Test func matchingTemplateIsPreferredForTheme() async throws {
        // The space/ocean template is the only one covering .space, so every
        // space story must come from it (recognizable by its fixed structure).
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("little boat") == true)
        }
    }

    @Test func titleVariantsOnlyUseProfileTokens() {
        // Pool values ({setting}, {sound}, {treasure}) carry their own
        // articles ("a small cloud…"), which reads badly mid-title.
        // Regression guard for the "Sails the Quiet a small cloud" bug.
        for template in TemplateLibrary.all {
            for title in template.titleVariants {
                #expect(!title.contains("{setting}"))
                #expect(!title.contains("{sound}"))
                #expect(!title.contains("{treasure}"))
            }
        }
    }

    @Test func providerNeverFails() async {
        let provider = StoryProvider()
        let result = await provider.makeStory(for: request())
        #expect(!result.content.pages.isEmpty)
        #expect(result.engine == .curated)
    }
}
