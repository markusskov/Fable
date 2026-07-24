import Testing
@testable import Fable

/// Curated series continuity (external review 2026-07-24, finding #5): a
/// series continuation served by the curated engine must read as an episode,
/// not as an unrelated tale wearing an "Episode N" label — and every framed
/// combination must still pass the exact gate the provider holds it to.
struct CuratedSeriesContinuityTests {
    private let engine = CuratedStoryEngine()

    private func request(
        language: StoryLanguage = .english,
        theme: StoryTheme = .adventure,
        ageBand: AgeBand = .little,
        episode: Int = 2,
        previously: [String] = ["Nova and Bruno the dog walked a very small lost friend all the way home, past the blackberry hedge."]
    ) -> StoryRequest {
        var request = StoryRequest(
            childName: "Nova",
            ageBand: ageBand,
            theme: theme,
            companion: "Bruno the dog",
            comfortObject: "the yellow blanket",
            language: language
        )
        request.series = StoryRequest.SeriesContext(
            title: "Nova and the Little Lost Friend",
            episodeNumber: episode,
            previously: previously
        )
        return request
    }

    // MARK: - Framing

    @Test func aContinuationOpensWithThePreviousRecap() async throws {
        let story = try await engine.makeStory(for: request(), seed: 7)
        let opening = try #require(story.pages.first)
        #expect(opening.contains("Nova's adventure goes on"))
        #expect(opening.contains("walked a very small lost friend"))
    }

    @Test func aFirstEpisodeIsNotFramed() async throws {
        let unrelated = try await engine.makeStory(
            for: request(episode: 1, previously: []),
            seed: 7
        )
        var plain = request()
        plain.series = nil
        let standalone = try await engine.makeStory(for: plain, seed: 7)
        #expect(unrelated == standalone)
    }

    @Test func framingAddsExactlyOnePage() async throws {
        var plain = request()
        plain.series = nil
        let standalone = try await engine.makeStory(for: plain, seed: 11)
        let episode = try await engine.makeStory(for: request(), seed: 11)
        #expect(episode.pages.count == standalone.pages.count + 1)
        #expect(Array(episode.pages.dropFirst()) == standalone.pages)
        #expect(episode.title == standalone.title)
    }

    @Test func sameSeedProducesIdenticalEpisode() async throws {
        let a = try await engine.makeStory(for: request(), seed: 1234)
        let b = try await engine.makeStory(for: request(), seed: 1234)
        #expect(a == b)
    }

    // MARK: - The frame never endangers the gate

    /// Every language × theme × age band × seed: the framed episode passes
    /// the full gate, exactly like the shelf sweeps do for standalone
    /// stories. The recap here is a rendered curated recap, the common case.
    @Test(arguments: StoryLanguage.allCases, AgeBand.allCases)
    func everyFramedEpisodePassesTheGate(language: StoryLanguage, ageBand: AgeBand) async throws {
        for theme in StoryTheme.allCases {
            for seed: UInt64 in 0..<10 {
                // Yesterday's episode, from the same shelf, provides the recap.
                var first = request(language: language, theme: theme, ageBand: ageBand)
                first.series = nil
                let previous = try await engine.makeStory(for: first, seed: seed &+ 999)
                #expect(!previous.recap.isEmpty, "curated stories must author a recap now")

                let req = request(
                    language: language,
                    theme: theme,
                    ageBand: ageBand,
                    previously: [previous.recap]
                )
                let episode = try await engine.makeStory(for: req, seed: seed)
                #expect(
                    ContentSafetyCheck.rejection(of: episode, for: req) == nil,
                    "\(language) \(theme) \(ageBand) seed \(seed): \(ContentSafetyCheck.rejection(of: episode, for: req)?.description ?? "")"
                )
                // The opening page really is a frame, and no token leaked.
                let opening = try #require(episode.pages.first)
                #expect(opening.contains("Nova"))
                for text in [episode.title, episode.moral, episode.recap] + episode.pages {
                    #expect(!text.contains("{"), "Unrendered token in: \(text)")
                    #expect(!text.contains("}"), "Unrendered token in: \(text)")
                }
            }
        }
    }

    // MARK: - Recap vetting

    @Test func anExcitedRecapIsDroppedNotSpliced() {
        let recap = CuratedSeriesFraming.spliceableRecap(
            from: ["Nova found a star!"],
            servedLanguage: .english
        )
        #expect(recap == nil)
    }

    @Test func aRecapWithAServedLanguageDeniedWordIsDropped() {
        // "hat" is harmless English but a denied word in Norwegian (hate).
        // This is the device-language-switch path: an English episode's recap
        // must not be spliced into a Norwegian page it would poison.
        let recap = CuratedSeriesFraming.spliceableRecap(
            from: ["Nova wore a red hat on the way home."],
            servedLanguage: .norwegianBokmal
        )
        #expect(recap == nil)
        #expect(CuratedSeriesFraming.spliceableRecap(
            from: ["Nova wore a red hat on the way home."],
            servedLanguage: .english
        ) != nil)
    }

    @Test func aMissingRecapStillGetsAContinuationFrame() async throws {
        let story = try await engine.makeStory(
            for: request(previously: []),
            seed: 3
        )
        let opening = try #require(story.pages.first)
        #expect(opening.contains("right where it left off"))
        let req = request(previously: [])
        #expect(ContentSafetyCheck.rejection(of: story, for: req) == nil)
    }

    @Test func anOverlongRecapFallsBackToThePlainFrame() async throws {
        let endless = String(repeating: "The friends walked and walked under the quiet moon. ", count: 20)
        let req = request(ageBand: .toddler, previously: [endless])
        let story = try await engine.makeStory(for: req, seed: 3)
        let opening = try #require(story.pages.first)
        #expect(opening.contains("right where it left off"))
        #expect(ContentSafetyCheck.rejection(of: story, for: req) == nil)
    }

    @Test func aRecapWithoutTerminalPunctuationGetsAPeriod() {
        let recap = CuratedSeriesFraming.spliceableRecap(
            from: ["Nova sailed past the sleeping lighthouse"],
            servedLanguage: .english
        )
        #expect(recap == "Nova sailed past the sleeping lighthouse.")
    }

    // MARK: - Curated recaps are real recaps

    /// Every shelf's rendered recap mentions the child: it is "previously
    /// on" material for the NEXT episode's prompt and frame, and a recap
    /// about nobody reads wrong in both places.
    @Test(arguments: StoryLanguage.allCases)
    func renderedRecapsStarTheChildAndStayCalm(language: StoryLanguage) async throws {
        for theme in StoryTheme.allCases {
            for seed: UInt64 in 0..<10 {
                var req = request(language: language, theme: theme)
                req.series = nil
                let story = try await engine.makeStory(for: req, seed: seed)
                #expect(!story.recap.isEmpty)
                #expect(story.recap.contains("Nova"))
                #expect(!story.recap.contains("!"))
                #expect(!story.recap.contains("{") && !story.recap.contains("}"))
                #expect(!ContentSafetyCheck.containsDeniedWord(story.recap, language: story.language))
            }
        }
    }
}
