import Testing
@testable import Fable

/// The German curated shelf is editorial product, not test fixture — every
/// rendered combination is held to the same bar as the English and Norwegian
/// shelves, plus the German-specific rules: the de safety vocabulary, no
/// dashes in story prose (owner copy style), and case discipline at slot
/// sites (checked structurally here, editorially at review time).
struct GermanShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Emil",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno der Hund",
            comfortObject: "die gelbe Decke",
            language: .german
        )
    }

    @Test func theShelfIsStockedAndServesGerman() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .german)
        #expect(story.pages.joined().contains("Emil"))
    }

    /// Every combination the seeded RNG can produce must pass the exact gate
    /// model stories are held to — in German, so the last page needs a German
    /// wind-down and no denied word from either vocabulary. All age bands,
    /// because the toddler page-length band is the tightest.
    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesTheGermanGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .german)
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

    @Test func everyThemeHasAMatchingGermanTemplate() {
        let shelf = TemplateLibrary.byLanguage[.german] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No de template covers \(theme) — theme preference would quietly vanish for German children"
            )
        }
    }

    @Test func blankOptionalFieldsGetGermanDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("ein kleiner mutiger Fuchs"))
        // Defaults are spliced mid-sentence only, so the lowercase article
        // must appear as-is — a sentence-initial splice site would need
        // "Eine", which the shelf deliberately never does.
        #expect(fullText.contains("eine weiche, warme Decke"))
    }

    /// Owner copy style: no dashes in customer-facing German prose. Clauses
    /// join with commas and periods; hyphens inside words and sound-words
    /// ("sch-sch-schhh") are fine.
    @Test func germanProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.german] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in de copy: \(text)")
                #expect(!text.contains("–"), "En dash in de copy: \(text)")
            }
        }
    }

    /// German case discipline: every {setting} pool entry is baked in the
    /// dative, so every splice site must govern the dative. The structural
    /// tell is that no template page puts a nominative-governing frame
    /// around {setting} — and defaults spliced for {companion}/{comfort}
    /// stay nominative, which the gate test above exercises via blank fields.
    @Test func settingSitesGovernTheDative() {
        let shelf = TemplateLibrary.byLanguage[.german] ?? []
        // Each occurrence of {setting} must directly follow a dative-
        // governing preposition (zu, an, hinter, bei, von).
        let dativeFrames = ["zu {setting}", "an {setting}", "hinter {setting}", "bei {setting}", "von {setting}"]
        for template in shelf {
            for page in template.pages where page.contains("{setting}") {
                #expect(
                    dativeFrames.contains { page.lowercased().contains($0) },
                    "{setting} outside a dative frame: \(page)"
                )
            }
        }
    }

    @Test func themePreferenceHoldsOnTheGermanShelf() async throws {
        // Only one de template covers .space; every German space story must
        // come from it.
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("kleines Boot") == true)
        }
    }
}
