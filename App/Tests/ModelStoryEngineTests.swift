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

    /// Real end-to-end generation, dev machines only. CI runners report the
    /// model as available but lack the actual assets (Model Catalog error
    /// 5000), so availability alone is not a sufficient gate.
    @Test(
        .enabled(if: ModelStoryEngine.isAvailable, "Requires Apple Intelligence"),
        .disabled(if: ProcessInfo.processInfo.environment["CI"] != nil, "Model assets absent on CI runners")
    )
    func generatesASafeStoryOnDevice() async throws {
        let engine = ModelStoryEngine()
        let content = try await engine.makeStory(for: request, seed: 1)
        #expect(ContentSafetyCheck.isAcceptable(content, for: request))
        #expect(content.pages.count >= 4)
    }
}
