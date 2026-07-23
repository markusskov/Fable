import Testing
@testable import Fable

/// The Norwegian curated shelf is editorial product, not test fixture — these
/// tests hold every rendered bokmål combination to the same bar as the
/// English shelf, plus the Norwegian-specific rules (nb safety vocabulary,
/// no dashes in story prose per owner copy style).
struct NorwegianShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Astrid",
            ageBand: ageBand,
            theme: theme,
            companion: "Luna katten",
            comfortObject: "det gule teppet",
            language: .norwegianBokmal
        )
    }

    @Test func theShelfIsStockedAndServesNorwegian() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .norwegianBokmal)
        #expect(story.pages.joined().contains("Astrid"))
    }

    /// Every combination the seeded RNG can produce must pass the exact gate
    /// model stories are held to — in Norwegian, so the last page needs a
    /// bokmål wind-down and no denied word from either vocabulary. All age
    /// bands, because the toddler page-length band is the tightest.
    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesTheNorwegianGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .norwegianBokmal)
            #expect(
                ContentSafetyCheck.rejection(of: story, for: req) == nil,
                "seed \(seed): \(ContentSafetyCheck.rejection(of: story, for: req)?.description ?? "")"
            )
            for text in [story.title, story.moral] + story.pages {
                #expect(!text.contains("{"), "Unrendered token in: \(text)")
                #expect(!text.contains("}"), "Unrendered token in: \(text)")
            }
        }
    }

    @Test func everyThemeHasAMatchingNorwegianTemplate() {
        let shelf = TemplateLibrary.byLanguage[.norwegianBokmal] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No nb template covers \(theme) — theme preference would quietly vanish for Norwegian children"
            )
        }
    }

    @Test func blankOptionalFieldsGetNorwegianDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("en liten modig rev"))
        #expect(fullText.contains("et mykt og varmt teppe"))
    }

    /// Owner copy style: no dashes in customer-facing Norwegian prose.
    /// Clauses join with commas and periods; hyphens inside words
    /// (sound-words like "sj-sj-sjjj") are fine.
    @Test func norwegianProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.norwegianBokmal] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in nb copy: \(text)")
                #expect(!text.contains("–"), "En dash in nb copy: \(text)")
            }
        }
    }

    @Test func themePreferenceHoldsOnTheNorwegianShelf() async throws {
        // Only one nb template covers .space; every Norwegian space story
        // must come from it.
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("liten båt") == true)
        }
    }
}
