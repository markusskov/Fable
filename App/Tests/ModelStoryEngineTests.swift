import Foundation
import Testing
@testable import Fable

struct ModelStoryEngineTests {
    private let request = StoryRequest(
        childName: "Astrid",
        ageBand: .toddler,
        theme: .ocean,
        companion: "Luna the cat",
        comfortObject: "the yellow blanket"
    )

    @Test func promptCarriesTheWholeProfile() {
        let prompt = ModelStoryEngine.prompt(for: request)
        #expect(prompt.contains("Astrid"))
        #expect(prompt.contains("Luna the cat"))
        #expect(prompt.contains("the yellow blanket"))
        #expect(prompt.contains("two or three years old"))
        #expect(prompt.contains("the sea"))
    }

    @Test(arguments: AgeBand.allCases)
    func instructionsAdaptToAge(ageBand: AgeBand) {
        var banded = request
        banded.ageBand = ageBand
        let instructions = ModelStoryEngine.instructions(for: banded)
        let marker = switch ageBand {
        case .toddler: "two-to-three-year-old"
        case .little: "four-to-six-year-old"
        case .big: "seven-to-nine-year-old"
        }
        #expect(instructions.contains(marker))
        // Page fullness adapts to age too (the 1-sentence-page regression guard).
        let fullness = switch ageBand {
        case .toddler: "two or three short, soothing sentences"
        case .little: "three or four gentle sentences"
        case .big: "three to five flowing sentences"
        }
        #expect(instructions.contains(fullness))
        // The always-on safety and calm framing must survive any edit.
        #expect(instructions.contains("calm, kind, and reassuring"))
        #expect(instructions.contains("Never use exclamation marks"))
        #expect(instructions.contains("goodnight"))
        // Review 2026-07-22 additions: evening setting, no written "The End".
        #expect(instructions.contains("lives in the evening"))
        #expect(instructions.contains("never write \"The End\""))
    }

    @Test func seriesContextShapesThePrompt() {
        var episode = request
        episode.series = StoryRequest.SeriesContext(
            title: "Astrid and the Quiet Tide",
            episodeNumber: 3,
            previously: ["Astrid met the lantern-fish.", "The tide sang them home."]
        )
        let prompt = ModelStoryEngine.prompt(for: episode)
        #expect(prompt.contains("episode 3"))
        #expect(prompt.contains("Astrid and the Quiet Tide"))
        #expect(prompt.contains("- Astrid met the lantern-fish."))
        #expect(prompt.contains("- The tide sang them home."))
        // Recaps come oldest first, in the order given.
        let fishIndex = prompt.range(of: "lantern-fish")!.lowerBound
        let tideIndex = prompt.range(of: "tide sang")!.lowerBound
        #expect(fishIndex < tideIndex)
        // Standalone-readability demand survives.
        #expect(prompt.contains("even if earlier nights are half-forgotten"))
    }

    @Test func aPlainRequestHasNoSeriesFraming() {
        let prompt = ModelStoryEngine.prompt(for: request)
        #expect(!prompt.contains("episode"))
        #expect(!prompt.contains("continuing adventure"))
    }

    @Test func blankOptionalFieldsUseDefaultsInPrompt() {
        var blank = request
        blank.companion = " "
        blank.comfortObject = ""
        let prompt = ModelStoryEngine.prompt(for: blank)
        #expect(prompt.contains("a small brave fox"))
        #expect(prompt.contains("a soft warm blanket"))
    }

    // MARK: - Repagination (deterministic, runs everywhere)

    private func content(pages: [String]) -> StoryContent {
        StoryContent(title: "Astrid and the Quiet Tide", pages: pages, moral: "Soft nights follow gentle days.")
    }

    private let fullPage = "The waves hushed themselves against the shore while Astrid and Luna the cat watched the last gulls sail home."

    @Test func repaginationStripsAWrittenTheEnd() {
        // Review 2026-07-22: the model wrote "The End." inside the last page,
        // doubling the reader's own end marker.
        let ending = "Astrid drifted off to sleep beside Luna the cat, warm and snug. Goodnight, Astrid. The End."
        let story = content(pages: [fullPage, fullPage, fullPage, ending])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages.last == "Astrid drifted off to sleep beside Luna the cat, warm and snug. Goodnight, Astrid.")
        // A page that is nothing but "The End" disappears entirely.
        let marker = content(pages: [fullPage, fullPage, fullPage, fullPage, "The end…"])
        #expect(ModelStoryEngine.repaginated(marker, for: request).pages.count == 4)
        // Mid-page mentions are untouched — only a trailing marker is a marker.
        #expect(ModelStoryEngine.strippingWrittenEnd(from: "The end of the garden glowed softly.")
            == "The end of the garden glowed softly.")
    }

    @Test func repaginationMergesATinyGoodnightPageIntoThePreviousOne() {
        // The commonest observed rejection: the model puts the goodnight on
        // a page of its own.
        let story = content(pages: [fullPage, fullPage, fullPage, fullPage, "Goodnight, Astrid."])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages.count == 4)
        #expect(result.pages.last == fullPage + " " + "Goodnight, Astrid.")
    }

    @Test func repaginationMergesAShortOpeningPageForward() {
        let story = content(pages: ["Astrid loves the sea.", fullPage, fullPage, fullPage, fullPage])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages.count == 4)
        #expect(result.pages.first == "Astrid loves the sea." + " " + fullPage)
    }

    @Test func repaginationDropsBlankPages() {
        let story = content(pages: [fullPage, "   ", fullPage, fullPage, "", fullPage])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages == [fullPage, fullPage, fullPage, fullPage])
    }

    @Test func repaginationLeavesAGoodStoryAlone() {
        let story = content(pages: [fullPage, fullPage, fullPage, fullPage])
        #expect(ModelStoryEngine.repaginated(story, for: request).pages == story.pages)
    }

    @Test func repaginationMergesAShortMidStoryPageForward() {
        // Reversal of an earlier stance, measured 2026-07-22: below-floor
        // mid pages dominated rejections, and a short fragment reads
        // naturally as the opening of the next scene.
        let story = content(pages: [fullPage, fullPage, "Astrid feels happy.", fullPage, fullPage])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages.count == 4)
        #expect(result.pages[2] == "Astrid feels happy." + " " + fullPage)
        #expect(result.pages.joined(separator: " ") == story.pages.joined(separator: " "))
    }

    @Test func pervasiveSkimpinessStillFailsTheGate() {
        // Merging is a pagination repair, not a quality amnesty: a story of
        // nothing but fragments collapses below the 4-page floor and rejects.
        let story = content(pages: [
            "Astrid smiled.", "Luna purred.", "The sea was calm.",
            "They sailed.", "Stars came out.", "Goodnight, Astrid.",
        ])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(ContentSafetyCheck.rejection(of: result, for: request) == .pageCount(result.pages.count))
    }

    @Test func repaginationNeverLosesAWord() {
        // Merging may move page breaks, never text.
        let story = content(pages: ["Hi.", fullPage, fullPage, fullPage, fullPage, "Goodnight, Astrid.", ""])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages.joined(separator: " ") == [
            "Hi.", fullPage, fullPage, fullPage, fullPage, "Goodnight, Astrid.",
        ].joined(separator: " "))
    }

    /// Real end-to-end generation, dev machines only. CI runners report the
    /// model as available but lack the actual assets (Model Catalog error
    /// 5000), so availability alone is not a sufficient gate.
    ///
    /// Generation is nondeterministic and the safety gate is deliberately
    /// strict, so a single sample is a coin flip — measured July 2026 on
    /// this prompt: 10 of 18 samples pass, rejections almost all mid-story
    /// pacing (a page just under the length floor). What the product needs
    /// is that the pipeline yields an acceptable story within a few tries
    /// (the provider silently falls back when a try fails), so that is what
    /// this asserts. The 2026-07-22 gate additions (wind-down ending, evening
    /// setting) trimmed the raw pass rate, and one 6-attempt run was observed
    /// failing on nothing but mid-story pacing rejections — so this allows
    /// eight attempts: even at a 40% pass rate a spurious failure stays under
    /// ~2%, while a genuine prompt or gate regression still pins it near
    /// certainty. Every rejection is logged with the rule that fired and the
    /// offending text, so a red run is directly actionable.
    private static let generationAttempts = 8

    @Test(
        .enabled(if: ModelStoryEngine.isAvailable, "Requires Apple Intelligence"),
        .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "Model assets absent on CI runners")
    )
    func generatesAnAcceptableStoryWithinAFewAttempts() async throws {
        try await expectAcceptableStory(from: request)
    }

    /// Same acceptance loop in Norwegian. Runs only where the on-device
    /// model claims Norwegian support — which is exactly the gate production
    /// uses, so a red run here means Apple's claim and our safety gate
    /// disagree about nb story quality, and that is worth knowing before a
    /// Norwegian family finds out.
    @Test(
        .enabled(
            if: ModelStoryEngine.isAvailable && ModelStoryEngine.supportsLanguage(.norwegianBokmal),
            "Requires Apple Intelligence with Norwegian support"
        ),
        .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "Model assets absent on CI runners")
    )
    func generatesAnAcceptableNorwegianStoryWithinAFewAttempts() async throws {
        var norwegian = request
        norwegian.language = .norwegianBokmal
        try await expectAcceptableStory(from: norwegian)
    }

    private func expectAcceptableStory(from base: StoryRequest) async throws {
        let engine = ModelStoryEngine()
        var rejections: [String] = []
        let themes = StoryTheme.allCases
        for attempt in 0..<Self.generationAttempts {
            var themed = base
            themed.theme = themes[attempt % themes.count]
            let content = ModelStoryEngine.repaginated(
                try await engine.rawStory(for: themed),
                for: themed
            )
            guard let rejection = ContentSafetyCheck.rejection(of: content, for: themed) else {
                #expect(content.pages.count >= 4)
                return // One acceptable story is the contract.
            }
            rejections.append("attempt \(attempt + 1) (\(themed.theme)): \(rejection)")
            print("[generation] rejected — \(rejection)")
            print("[generation] title: \(content.title)")
            print("[generation] pages: \(content.pages.joined(separator: "\n  | "))")
        }
        Issue.record(
            """
            No acceptable story in \(Self.generationAttempts) attempts — at the \
            measured pass rate this is a regression, not noise. Rejections:
            \(rejections.joined(separator: "\n"))
            """
        )
    }
}
