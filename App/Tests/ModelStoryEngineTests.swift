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

    @Test func repaginationDoesNotRescueAShortPageMidStory() {
        // Mid-story pacing is the model's job; the gate must still reject it.
        let story = content(pages: [fullPage, fullPage, "Astrid feels happy.", fullPage, fullPage])
        let result = ModelStoryEngine.repaginated(story, for: request)
        #expect(result.pages == story.pages)
        #expect(!ContentSafetyCheck.isAcceptable(result, for: request))
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
    /// this asserts. Six attempts at the measured ~55% pass rate put a
    /// spurious failure below 1%; a genuine prompt or gate regression pins
    /// it near certainty. Every rejection is logged with the rule that
    /// fired and the offending text, so a red run is directly actionable.
    @Test(
        .enabled(if: ModelStoryEngine.isAvailable, "Requires Apple Intelligence"),
        .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "Model assets absent on CI runners")
    )
    func generatesAnAcceptableStoryWithinAFewAttempts() async throws {
        let engine = ModelStoryEngine()
        var rejections: [String] = []
        for (attempt, theme) in StoryTheme.allCases.enumerated() {
            var themed = request
            themed.theme = theme
            let content = ModelStoryEngine.repaginated(
                try await engine.rawStory(for: themed),
                for: themed
            )
            guard let rejection = ContentSafetyCheck.rejection(of: content, for: themed) else {
                #expect(content.pages.count >= 4)
                return // One acceptable story is the contract.
            }
            rejections.append("attempt \(attempt + 1) (\(theme)): \(rejection)")
            print("[generation] rejected — \(rejection)")
            print("[generation] title: \(content.title)")
            print("[generation] pages: \(content.pages.joined(separator: "\n  | "))")
        }
        Issue.record(
            """
            No acceptable story in \(StoryTheme.allCases.count) attempts — at the \
            measured pass rate this is a regression, not noise. Rejections:
            \(rejections.joined(separator: "\n"))
            """
        )
    }
}
