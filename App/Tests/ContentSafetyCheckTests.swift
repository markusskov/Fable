import Testing
@testable import Fable

struct ContentSafetyCheckTests {
    private let request = StoryRequest(
        childName: "Nova",
        ageBand: .little,
        theme: .adventure,
        companion: "Bruno",
        comfortObject: "blanket"
    )

    private func story(
        title: String = "Nova and the Quiet Meadow",
        pages: [String]? = nil,
        moral: String = "Kindness makes every evening softer."
    ) -> StoryContent {
        StoryContent(
            title: title,
            pages: pages ?? [
                "Nova stepped into the quiet meadow with Bruno.",
                "The fireflies blinked hello, one by one.",
                "Together they found the softest patch of moss.",
                "Nova yawned, snuggled close, and drifted off to sleep. Goodnight, Nova.",
            ],
            moral: moral
        )
    }

    @Test func acceptsAGentleStory() {
        #expect(ContentSafetyCheck.isAcceptable(story(), for: request))
    }

    @Test func curatedEngineOutputAlwaysPasses() async throws {
        // The editorial bar and the safety gate must agree — every curated
        // story for every theme must pass the same check applied to the model.
        let engine = CuratedStoryEngine()
        for theme in StoryTheme.allCases {
            var themedRequest = request
            themedRequest.theme = theme
            for seed: UInt64 in 0..<15 {
                let content = try await engine.makeStory(for: themedRequest, seed: seed)
                #expect(
                    ContentSafetyCheck.isAcceptable(content, for: themedRequest),
                    "Curated story failed safety check: \(content.title) [\(theme)]"
                )
            }
        }
    }

    @Test(arguments: [
        "There was blood on the ground.",
        "The monster wanted to KILL the lights.",
        "It was a horror to behold.",
        "Don't be stupid, said the owl.",
        "A nightmare crept closer.",
    ])
    func rejectsDeniedWords(page: String) {
        let content = story(pages: [
            "Nova walked into the wood.",
            page,
            "Then Nova went home.",
            "Goodnight, Nova.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func deniedWordsMatchWholeWordsOnly() {
        // "skill", "candied", "warm" contain denied substrings but are innocent.
        let content = story(pages: [
            "Nova showed great skill with the kite.",
            "They shared candied apples by the warm fire.",
            "The evening was calm and sweet.",
            "Goodnight, Nova.",
        ])
        #expect(ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func rejectsStructuralProblems() {
        // Too few pages.
        #expect(!ContentSafetyCheck.isAcceptable(story(pages: ["One.", "Two."]), for: request))
        // Empty page.
        #expect(!ContentSafetyCheck.isAcceptable(
            story(pages: ["Nova smiled.", "   ", "More.", "Goodnight, Nova."]), for: request))
        // Empty title.
        #expect(!ContentSafetyCheck.isAcceptable(story(title: "  "), for: request))
        // A page far too long to read calmly.
        let runOn = String(repeating: "and then Nova walked a little further ", count: 30)
        #expect(!ContentSafetyCheck.isAcceptable(
            story(pages: ["Nova set out.", runOn, "Home again.", "Goodnight, Nova."]), for: request))
    }

    @Test func rejectsStoryThatForgetsTheChild() {
        let content = story(pages: [
            "Somebody walked into the wood.",
            "The trees were tall.",
            "Then they went home.",
            "Goodnight, little one.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }
}
