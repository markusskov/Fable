import Testing
@testable import Fable

/// The Spanish curated shelf is editorial product, not test fixture — every
/// rendered combination is held to the same bar as the other shelves, plus
/// the Spanish-specific rules: the es safety vocabulary, no dashes in story
/// prose (owner copy style), and contraction discipline at slot sites
/// (checked structurally here, editorially at review time).
struct SpanishShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Lucía",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno el perro",
            comfortObject: "la manta amarilla",
            language: .spanish
        )
    }

    @Test func theShelfIsStockedAndServesSpanish() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .spanish)
        #expect(story.pages.joined().contains("Lucía"))
    }

    /// Every combination the seeded RNG can produce must pass the exact gate
    /// model stories are held to — in Spanish, so the last page needs a
    /// Spanish wind-down and no denied word from either vocabulary. All age
    /// bands, because the toddler page-length band is the tightest.
    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesTheSpanishGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .spanish)
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

    @Test func everyThemeHasAMatchingSpanishTemplate() {
        let shelf = TemplateLibrary.byLanguage[.spanish] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No es template covers \(theme) — theme preference would quietly vanish for Spanish children"
            )
        }
    }

    @Test func blankOptionalFieldsGetSpanishDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("un pequeño zorro valiente"))
        // Defaults are spliced mid-sentence only, so the lowercase article
        // must appear as-is — a sentence-initial splice site would need
        // "Una", which the shelf deliberately never does.
        #expect(fullText.contains("una manta suave y calentita"))
    }

    /// Owner copy style: no dashes in customer-facing Spanish prose — which
    /// also rules out the traditional raya for dialogue; the shelf uses
    /// «guillemets» instead. Hyphens inside sound-words ("pío-pío") are fine.
    @Test func spanishProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.spanish] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
                + template.recapVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in es copy: \(text)")
                #expect(!text.contains("–"), "En dash in es copy: \(text)")
            }
        }
    }

    /// Spanish contraction discipline: {setting} pool entries bake their
    /// article in, so a splice site behind "a" or "de" would render "a el"/
    /// "de el" where Spanish demands "al"/"del". Every {setting} must sit
    /// directly behind a preposition that never contracts.
    @Test func settingSitesNeverForceContractions() {
        let shelf = TemplateLibrary.byLanguage[.spanish] ?? []
        let safeFrames = ["hacia {setting}", "hasta {setting}", "por {setting}", "en {setting}", "tras {setting}"]
        for template in shelf {
            for page in template.pages where page.contains("{setting}") {
                #expect(
                    safeFrames.contains { page.lowercased().contains($0) },
                    "{setting} outside a non-contracting frame: \(page)"
                )
                // Standalone "a"/"de" before the slot would contract with
                // the pool's article ("a el" → "al"); \b keeps "hacia" and
                // "tras" from matching.
                #expect(
                    page.range(of: #"\b(a|de) \{setting\}"#, options: [.regularExpression, .caseInsensitive]) == nil,
                    "contracting preposition before {setting}: \(page)"
                )
            }
        }
    }

    @Test func themePreferenceHoldsOnTheSpanishShelf() async throws {
        // Only one es template covers .space; every Spanish space story must
        // come from it.
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("barquito") == true)
        }
    }
}
