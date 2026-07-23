import Testing
@testable import Fable

/// The French curated shelf is editorial product, not test fixture — every
/// rendered combination is held to the same bar as the other shelves, plus
/// the French-specific rules: the fr safety vocabulary, no dashes in story
/// prose (owner copy style), and contraction discipline at {setting} sites
/// ("à/de {setting}" would demand au/du and read broken).
struct FrenchShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Chloé",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno le chien",
            comfortObject: "la couverture jaune",
            language: .french
        )
    }

    @Test func theShelfIsStockedAndServesFrench() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .french)
        #expect(story.pages.joined().contains("Chloé"))
    }

    /// Every combination the seeded RNG can produce must pass the exact gate
    /// model stories are held to — in French, so the last page needs a French
    /// wind-down and no denied word from either vocabulary. All age bands,
    /// because the toddler page-length band is the tightest.
    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesTheFrenchGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .french)
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

    @Test func everyThemeHasAMatchingFrenchTemplate() {
        let shelf = TemplateLibrary.byLanguage[.french] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No fr template covers \(theme) — theme preference would quietly vanish for French children"
            )
        }
    }

    @Test func blankOptionalFieldsGetFrenchDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("un petit renard courageux"))
        #expect(fullText.contains("une petite couverture douce et chaude"))
    }

    /// Owner copy style: no dashes in customer-facing French prose. Clauses
    /// join with commas and periods; hyphens inside words and sound-words
    /// ("hou-hou", "tais-toi") are fine.
    @Test func frenchProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.french] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in fr copy: \(text)")
                #expect(!text.contains("–"), "En dash in fr copy: \(text)")
            }
        }
    }

    /// French contraction discipline: {setting} pool entries carry their own
    /// article, so splice sites may only use prepositions that never
    /// contract — "à {setting}" or "de {setting}" would demand au/du.
    @Test func settingSitesNeverForceContractions() {
        let shelf = TemplateLibrary.byLanguage[.french] ?? []
        let safeFrames = ["vers {setting}", "devant {setting}", "passé {setting}", "derrière {setting}"]
        for template in shelf {
            for page in template.pages where page.contains("{setting}") {
                #expect(
                    safeFrames.contains { page.lowercased().contains($0) },
                    "{setting} outside a contraction-safe frame: \(page)"
                )
                #expect(!page.contains("à {setting}"), "à + article would contract: \(page)")
                #expect(!page.contains("de {setting}"), "de + article would contract: \(page)")
            }
        }
    }

    @Test func themePreferenceHoldsOnTheFrenchShelf() async throws {
        // Only one fr template covers .space; every French space story must
        // come from it.
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("petit bateau") == true)
        }
    }
}
