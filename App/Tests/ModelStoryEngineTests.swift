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
        // The always-on safety framing must survive any edit.
        #expect(instructions.contains("calm, kind, and reassuring"))
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

    /// Real end-to-end generation. Runs only where Apple Intelligence is
    /// available (dev machines); skips cleanly in CI.
    @Test(.enabled(if: ModelStoryEngine.isAvailable, "Requires Apple Intelligence"))
    func generatesASafeStoryOnDevice() async throws {
        let engine = ModelStoryEngine()
        let content = try await engine.makeStory(for: request, seed: 1)
        #expect(ContentSafetyCheck.isAcceptable(content, for: request))
        #expect(content.pages.count >= 4)
    }
}
