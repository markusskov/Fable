import Testing
@testable import Fable

/// The Brazilian Portuguese curated shelf is editorial product — held to the
/// same bar as every other shelf, plus the pt-specific rules: the pt safety
/// vocabulary, no dashes in story prose (owner copy style), and contraction
/// discipline at {setting} sites (a/de/em/por contract with articles, so
/// only "até" or transitive frames are legal).
struct PortugueseShelfTests {
    private let engine = CuratedStoryEngine()

    private func request(
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little
    ) -> StoryRequest {
        StoryRequest(
            childName: "Alice",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno, o cachorro",
            comfortObject: "a cobertinha amarela",
            language: .portugueseBrazilian
        )
    }

    @Test func theShelfIsStockedAndServesPortuguese() async throws {
        let story = try await engine.makeStory(for: request(), seed: 1)
        #expect(story.language == .portugueseBrazilian)
        #expect(story.pages.joined().contains("Alice"))
    }

    @Test(arguments: StoryTheme.allCases, AgeBand.allCases)
    func everyRenderedStoryPassesThePortugueseGate(theme: StoryTheme, ageBand: AgeBand) async throws {
        for seed: UInt64 in 0..<25 {
            let req = request(theme: theme, ageBand: ageBand)
            let story = try await engine.makeStory(for: req, seed: seed)
            #expect(story.language == .portugueseBrazilian)
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

    @Test func everyThemeHasAMatchingPortugueseTemplate() {
        let shelf = TemplateLibrary.byLanguage[.portugueseBrazilian] ?? []
        for theme in StoryTheme.allCases {
            #expect(
                shelf.contains { $0.themes.contains(theme) },
                "No pt template covers \(theme) — theme preference would quietly vanish for Brazilian children"
            )
        }
    }

    @Test func blankOptionalFieldsGetPortugueseDefaults() async throws {
        var blank = request(theme: .animals)
        blank.companion = "  "
        blank.comfortObject = ""
        let story = try await engine.makeStory(for: blank, seed: 5)
        let fullText = story.pages.joined()
        #expect(fullText.contains("uma raposinha corajosa"))
        #expect(fullText.contains("uma cobertinha macia e quentinha"))
    }

    /// Owner copy style: no dashes in customer-facing Portuguese prose.
    @Test func portugueseProseUsesNoDashes() {
        let shelf = TemplateLibrary.byLanguage[.portugueseBrazilian] ?? []
        for template in shelf {
            let strings = template.titleVariants + template.pages
                + template.settings + template.sounds
                + template.treasures + template.moralVariants
                + template.recapVariants
            for text in strings {
                #expect(!text.contains("—"), "Em dash in pt copy: \(text)")
                #expect(!text.contains("–"), "En dash in pt copy: \(text)")
            }
        }
    }

    /// Portuguese contraction discipline: {setting} pool entries carry their
    /// own article, so splice sites may only use "até" (never contracts) or
    /// a transitive frame ("cruzaram/cruzando/se cruzava {setting}").
    @Test func settingSitesNeverForceContractions() {
        let shelf = TemplateLibrary.byLanguage[.portugueseBrazilian] ?? []
        let safeFrames = ["até {setting}", "cruzaram {setting}", "cruzando {setting}", "cruzava {setting}"]
        for template in shelf {
            for page in template.pages where page.contains("{setting}") {
                #expect(
                    safeFrames.contains { page.lowercased().contains($0) },
                    "{setting} outside a contraction-safe frame: \(page)"
                )
                // Leading space: "cruzava {setting}" must not match "a {setting}".
                for bad in [" a {setting}", " de {setting}", " em {setting}", " por {setting}"] {
                    #expect(!page.lowercased().contains(bad), "contraction-forcing frame: \(page)")
                }
            }
        }
    }

    @Test func themePreferenceHoldsOnThePortugueseShelf() async throws {
        for seed: UInt64 in 0..<10 {
            let story = try await engine.makeStory(for: request(theme: .space), seed: seed)
            #expect(story.pages.first?.contains("barquinho") == true)
        }
    }
}
