import Foundation
import FoundationModels

/// On-device generation via Apple's Foundation Models. Contract: returns a
/// safety-checked story or throws — callers (StoryProvider) handle fallback.
struct ModelStoryEngine: StoryEngine {
    static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
        guard Self.isAvailable else { throw StoryEngineError.unavailable }

        let session = LanguageModelSession(instructions: Self.instructions(for: request))
        let response = try await session.respond(
            to: Self.prompt(for: request),
            generating: GeneratedStory.self
        )
        let content = StoryContent(
            title: response.content.title,
            pages: response.content.pages,
            moral: response.content.moral
        )
        guard ContentSafetyCheck.isAcceptable(content, for: request) else {
            throw StoryEngineError.generationFailed
        }
        return content
    }

    // MARK: - Prompt building (deterministic, unit-tested)

    static func instructions(for request: StoryRequest) -> String {
        """
        You are Fable, a gentle bedtime storyteller for young children. A parent \
        reads your story aloud as the very last thing before their child sleeps.

        Rules that always apply:
        - The story is calm, kind, and reassuring from the first line to the last. \
        Mild, cozy adventure is welcome; danger, peril, villains, fighting, \
        scary imagery, sadness without comfort, and loud excitement are not.
        - \(vocabularyGuidance(for: request.ageBand))
        - The story slows down as it goes: the final two pages wind toward rest, \
        and the last page ends with the child snug and sleepy, told goodnight by name.
        - No brand names, no pop-culture characters, no morals about obedience. \
        Warmth over lessons; if there is a takeaway, it is gentle.
        - Never address the reader or mention that this is a story being told.
        """
    }

    static func prompt(for request: StoryRequest) -> String {
        """
        Write tonight's bedtime story.

        The hero: \(request.childName), who is \(ageDescription(for: request.ageBand)).
        Their loyal companion in the story: \(request.companionOrDefault).
        Something cozy that should appear and bring comfort: \(request.comfortObjectOrDefault).
        Tonight's mood: \(themeDescription(for: request.theme)).
        """
    }

    private static func vocabularyGuidance(for ageBand: AgeBand) -> String {
        switch ageBand {
        case .toddler:
            "Use very simple words and short sentences a two-to-three-year-old follows. Repetition and soft sounds are lovely."
        case .little:
            "Use simple, vivid language a four-to-six-year-old follows easily, with a few delightful words worth wondering about."
        case .big:
            "Use rich but comfortable language for a seven-to-nine-year-old, with a touch of wit and wonder."
        }
    }

    private static func ageDescription(for ageBand: AgeBand) -> String {
        switch ageBand {
        case .toddler: "two or three years old"
        case .little: "between four and six years old"
        case .big: "between seven and nine years old"
        }
    }

    private static func themeDescription(for theme: StoryTheme) -> String {
        switch theme {
        case .adventure: "a small, cozy adventure close to home"
        case .animals: "gentle animals, wild or beloved"
        case .magic: "soft everyday magic, the kind that glows"
        case .space: "the moon, the stars, and the quiet night sky"
        case .ocean: "the sea, its shores, and its friendly creatures"
        case .friendship: "friendship, helping, and being helped"
        }
    }
}
