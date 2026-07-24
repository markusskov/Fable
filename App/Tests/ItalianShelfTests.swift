import Testing
@testable import Fable

/// The Italian curated shelf is editorial product, not test fixture — held to
/// the same bar as every other shelf, plus the Italian-specific rules: the it
/// safety vocabulary, no dashes in story prose (owner copy style), and
/// contraction discipline at {setting} sites (a/di/da/in/su always contract
/// with articles, so only verso/oltre or transitive frames are legal).
struct ItalianShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Sofia",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno il cane",
            comfortObject: "la copertina gialla",
            language: .italian
        )
    }

    @Test func theShelfIsStockedAndServesItalian() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .italian)
        #expect(story.pages.joined().contains("Sofia"))
    }

    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesTheItalianGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .italian)
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

    @Test func everyThemeHasAMatchingItalianTemplate() {
        let shelf = TemplateLibrary.byLanguage[.italian] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No it template covers \(theme) — theme preference would quietly vanish for Italian children"
            )
        }
    }

    @Test func blankOptionalFieldsGetItalianDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("una piccola volpe coraggiosa"))
        #expect(fullText.contains("una copertina morbida e calda"))
    }

    /// Owner copy style: no dashes in customer-facing Italian prose.
    @Test func italianProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.italian] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
                + template.recapVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in it copy: \(text)")
                #expect(!text.contains("–"), "En dash in it copy: \(text)")
            }
        }
    }

    /// Italian contraction discipline: {setting} pool entries carry their own
    /// article, so splice sites may only use "verso"/"oltre" (which never
    /// contract) or a transitive frame ("superarono {setting}").
    @Test func settingSitesNeverForceContractions() {
        let shelf = TemplateLibrary.byLanguage[.italian] ?? []
        let safeFrames = ["verso {setting}", "oltre {setting}", "superarono {setting}"]
        for template in shelf {
            for page in template.pages where page.contains("{setting}") {
                #expect(
                    safeFrames.contains { page.lowercased().contains($0) },
                    "{setting} outside a contraction-safe frame: \(page)"
                )
                for bad in ["a {setting}", "di {setting}", "da {setting}", "in {setting}", "su {setting}"] {
                    #expect(!page.lowercased().contains(bad), "contraction-forcing frame: \(page)")
                }
            }
        }
    }

    @Test func themePreferenceHoldsOnTheItalianShelf() async throws {
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("barchetta") == true)
        }
    }
}
