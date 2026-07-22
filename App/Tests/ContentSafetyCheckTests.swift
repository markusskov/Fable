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
                "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
                "The fireflies blinked hello, one by one, and the tall grass swayed a sleepy hello too.",
                "Together they found the softest patch of moss and watched the stars come out overhead.",
                "Nova yawned, snuggled close to Bruno, and drifted off to sleep. Goodnight, Nova.",
            ],
            moral: moral
        )
    }

    @Test func acceptsAGentleStory() {
        #expect(ContentSafetyCheck.isAcceptable(story(), for: request))
    }

    @Test func curatedEngineOutputAlwaysPasses() async throws {
        // The editorial bar and the safety gate must agree — every curated
        // story, for every theme and age band, must pass the same check
        // applied to the model.
        let engine = CuratedStoryEngine()
        for ageBand in AgeBand.allCases {
            for theme in StoryTheme.allCases {
                var variant = request
                variant.ageBand = ageBand
                variant.theme = theme
                for seed: UInt64 in 0..<10 {
                    let content = try await engine.makeStory(for: variant, seed: seed)
                    #expect(
                        ContentSafetyCheck.isAcceptable(content, for: variant),
                        "Curated story failed safety check: \(content.title) [\(theme), \(ageBand)]"
                    )
                }
            }
        }
    }

    @Test(arguments: [
        "There was blood on the old stones, dark and strange in the pale light.",
        "The monster under the bridge wanted to KILL all the little lights.",
        "It was a horror to behold, and everyone hid away from it very quickly.",
        "Don't be stupid, said the owl, ruffling its feathers at the little mouse.",
        "A nightmare crept closer and closer through the tangled trees that night.",
        "Two small ghosts drifted past the window, whispering to each other softly.",
        "The path ahead looked dangerous, and the wind felt cold and unfriendly.",
        "Nova felt afraid of the deep shadows gathering under the old fir trees.",
        "There was nothing to be scared of in the wood, Bruno promised quietly.",
    ])
    func rejectsDeniedWords(page: String) {
        let content = story(pages: [
            "Nova walked into the whispering wood with Bruno close beside the whole way.",
            page,
            "Then Nova and Bruno turned around and walked all the long way back home.",
            "Nova crawled into bed and closed both sleepy eyes. Goodnight, Nova.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func deniedWordsMatchWholeWordsOnly() {
        // "skill", "candied", "warm" contain denied substrings but are innocent.
        let content = story(pages: [
            "Nova showed great skill with the kite as the evening breeze grew softer.",
            "They shared candied apples by the warm fire and watched the embers glow.",
            "The evening was calm and sweet, and the crickets sang their slowest song.",
            "Nova hugged the blanket and smiled into sleep. Goodnight, Nova.",
        ])
        #expect(ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func rejectsAnExcitedStory() {
        // Calm is structural: an excited story announces itself in punctuation.
        let content = story(pages: [
            "Nova raced into the meadow with Bruno! The fireflies were amazing tonight!",
            "What a night! The stars were so bright and absolutely everything sparkled!",
            "They leaped and cheered and spun around and around under the moonlight.",
            "Then Nova bounced into bed, still buzzing with it all. Goodnight, Nova!",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func allowsAnOccasionalGentleExclamation() {
        let content = story(pages: [
            "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
            "Fireflies! They blinked hello, one by one, and the tall grass swayed along.",
            "Together they found the softest patch of moss and watched the stars come out.",
            "Nova yawned, snuggled close to Bruno, and drifted off. Goodnight, Nova.",
        ])
        #expect(ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func rejectsSkimpyPages() {
        // A single tossed-off sentence is not a bedtime scene — the observed
        // model failure this heuristic exists for.
        let content = story(pages: [
            "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
            "Nova was excited.",
            "Together they found the softest patch of moss and watched the stars come out.",
            "Nova yawned, snuggled close to Bruno, and drifted off. Goodnight, Nova.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func pageLengthBoundsAdaptToAge() {
        // ~440 characters: fine for a seven-to-nine-year-old, far too much for
        // a toddler to sit through on a single page.
        let longPage = "Nova and Bruno followed the winding path past the garden gate, "
            + String(repeating: "past the sleepy sunflowers and the humming bees, ", count: 7)
            + "all the way to the soft green hill."
        let pages = [
            "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
            longPage,
            "Together they found the softest patch of moss and watched the stars come out.",
            "Nova yawned, snuggled close to Bruno, and drifted off. Goodnight, Nova.",
        ]
        var toddler = request
        toddler.ageBand = .toddler
        var big = request
        big.ageBand = .big
        #expect(!ContentSafetyCheck.isAcceptable(story(pages: pages), for: toddler))
        #expect(ContentSafetyCheck.isAcceptable(story(pages: pages), for: big))
    }

    @Test func rejectsStructuralProblems() {
        // Too few pages.
        #expect(!ContentSafetyCheck.isAcceptable(story(pages: [
            "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
            "Nova yawned, snuggled close to Bruno, and drifted off. Goodnight, Nova.",
        ]), for: request))
        // Empty page.
        #expect(!ContentSafetyCheck.isAcceptable(story(pages: [
            "Nova smiled at the moon, and the moon smiled right on back at Nova.",
            "   ",
            "The stars counted themselves softly, one and two and three and four.",
            "Nova pulled the covers up to both ears and drifted off. Goodnight, Nova.",
        ]), for: request))
        // Empty title, empty moral.
        #expect(!ContentSafetyCheck.isAcceptable(story(title: "  "), for: request))
        #expect(!ContentSafetyCheck.isAcceptable(story(moral: "  "), for: request))
        // A page far too long to read calmly at any age.
        let runOn = String(repeating: "and then Nova walked a little further ", count: 30)
        #expect(!ContentSafetyCheck.isAcceptable(story(pages: [
            "Nova set out across the garden just as the sky turned to dusk.",
            runOn,
            "At last they were home again, and the kettle sang its softest song.",
            "Nova curled up warm and cozy in the big bed. Goodnight, Nova.",
        ]), for: request))
    }

    @Test func rejectsStoryThatForgetsTheChild() {
        let content = story(pages: [
            "Somebody walked into the whispering wood as the light went low and golden.",
            "The trees were tall and kind, and the moss was soft under every step.",
            "Then they turned for home beneath the sleepy silver evening stars.",
            "Goodnight, little one, wherever your dreams may wander off to tonight.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }

    @Test func rejectsStoryWhoseEndingForgetsTheChild() {
        // The child appears earlier, but the last page must say goodnight
        // to them by name.
        let content = story(pages: [
            "Nova stepped into the quiet meadow with Bruno, just as the fireflies woke up.",
            "The fireflies blinked hello, one by one, and the tall grass swayed along.",
            "Together they found the softest patch of moss and watched the stars come out.",
            "The meadow grew quiet, and everyone was asleep. Goodnight, sweet meadow.",
        ])
        #expect(!ContentSafetyCheck.isAcceptable(content, for: request))
    }
}
