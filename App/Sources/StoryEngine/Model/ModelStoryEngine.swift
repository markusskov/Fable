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
        let content = Self.repaginated(try await rawStory(for: request), for: request)
        guard ContentSafetyCheck.isAcceptable(content, for: request) else {
            throw StoryEngineError.generationFailed
        }
        return content
    }

    /// Deterministic cleanup of the model's page breaks, applied before the
    /// safety gate. The commonest observed rejections are pagination, not
    /// content: a below-floor page somewhere in the story, or a tiny final
    /// page holding only "Goodnight, …". Any too-short page merges forward
    /// into the page after it (the last one merges backward), which never
    /// adds, removes, or reorders a word the model wrote — blank pages and a
    /// written-out "The End" excepted — and the full safety check still
    /// judges the result: pervasive skimpiness collapses the page count
    /// below 4 or pushes a merged page past the ceiling, and both still
    /// reject. (Earlier revisions refused to touch mid-story pages; measured
    /// 2026-07-22, those rejections dominated the ~50% raw pass rate, and a
    /// short fragment reads naturally as the opening of the next scene.)
    static func repaginated(_ content: StoryContent, for request: StoryRequest) -> StoryContent {
        let minLength = ContentSafetyCheck.pageLengthBounds(for: request.ageBand).lowerBound
        var pages = content.pages
            .map { Self.strippingWrittenEnd(from: $0) }
            .filter { !$0.isEmpty }
        var index = 0
        while index < pages.count, pages.count >= 2 {
            if pages[index].count < minLength, index + 1 < pages.count {
                pages[index + 1] = pages[index] + " " + pages[index + 1]
                pages.remove(at: index)
            } else {
                index += 1
            }
        }
        while pages.count >= 2, let last = pages.last, last.count < minLength {
            pages[pages.count - 2] += " " + last
            pages.removeLast()
        }
        return StoryContent(title: content.title, pages: pages, moral: content.moral)
    }

    /// The reader draws its own "The End" marker; a model that writes one
    /// anyway (observed in review 2026-07-22) would show it twice. Trailing
    /// only — mid-sentence occurrences are left for the gate/reader as-is.
    static func strippingWrittenEnd(from page: String) -> String {
        page
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing(/(?i)\s*the\s+end[.!…]*\s*$/, with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// One unchecked generation. Only `makeStory` (which gates it) and the
    /// on-device test harness (which inspects rejections) may call this —
    /// unchecked output must never reach the UI.
    func rawStory(for request: StoryRequest) async throws -> StoryContent {
        guard Self.isAvailable else { throw StoryEngineError.unavailable }

        let session = LanguageModelSession(instructions: Self.instructions(for: request))
        // Low temperature: bedtime stories want steady, predictable prose, not
        // sparkle. Observed default-temperature output drifting into excited,
        // exclamatory one-liners.
        let response = try await session.respond(
            to: Self.prompt(for: request),
            generating: GeneratedStory.self,
            options: GenerationOptions(temperature: 0.7)
        )
        return StoryContent(
            title: response.content.title,
            pages: response.content.pages,
            moral: response.content.moral
        )
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
        - Nobody in the story ever feels fear or worry, not even briefly and \
        not even to be comforted afterwards — in this story's world there is \
        simply nothing to fear. Characters feel curious, cozy, delighted, \
        sleepy, and loved.
        - The voice is hushed and unhurried, like reading by lamplight. Never \
        use exclamation marks. Nothing is sudden, loud, or thrilling; wonder \
        is quiet, and surprises are soft.
        - The story lives in the evening: it begins as the light goes low and \
        golden, and the world settles toward night as it goes. Never set it \
        on a bright morning or a sunny afternoon.
        - Every page is a complete, unhurried scene of \
        \(pageFullnessGuidance(for: request.ageBand)) — never a single quick \
        sentence. Linger on cozy details: how things feel, glow, and sound.
        - \(vocabularyGuidance(for: request.ageBand))
        - The story slows down as it goes: the final two pages wind toward rest. \
        The last page is a full page like every other — the child settles in \
        snug and sleepy, and its final sentence says goodnight to the child \
        by name, for example "Goodnight, \(request.childName)." Never put the \
        goodnight on a tiny page of its own, and never end without the \
        child's name.
        - No brand names, no pop-culture characters, no morals about obedience. \
        Warmth over lessons; if there is a takeaway, it is gentle.
        - Never address the reader or mention that this is a story being told, \
        and never write "The End" — the storybook closes itself.
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

    private static func pageFullnessGuidance(for ageBand: AgeBand) -> String {
        switch ageBand {
        case .toddler: "two or three short, soothing sentences"
        case .little: "three or four gentle sentences"
        case .big: "three to five flowing sentences"
        }
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
