import Foundation

/// Post-generation gate: model output is never displayed unchecked (CLAUDE.md
/// guardrail). Curated templates are pre-vetted editorially and skip this in
/// production, but tests hold them to the same bar.
///
/// Second iteration: age-banded structural heuristics, a calm-tone check, and
/// a denylist with explicit inflections. Rejection is cheap — the caller falls
/// back silently to the curated engine — so every rule errs strict.
enum ContentSafetyCheck {
    /// Why a story was rejected. Never shown to a child or parent — this
    /// exists so tests and prompt tuning can see which rule fired instead of
    /// a bare false.
    enum Rejection: Equatable, CustomStringConvertible {
        case pageCount(Int)
        case badTitle
        case badMoral
        case pageLength(pageIndex: Int, count: Int, allowed: ClosedRange<Int>)
        case tooExcited(exclamationCount: Int)
        case childMissingFromLastPage
        case endingNotSleepy
        case deniedWord(String)

        var description: String {
            switch self {
            case .pageCount(let count):
                "page count \(count) outside 4...12"
            case .badTitle:
                "title empty or over 80 characters"
            case .badMoral:
                "moral empty or over 200 characters"
            case .pageLength(let index, let count, let allowed):
                "page \(index + 1) is \(count) characters, allowed \(allowed)"
            case .tooExcited(let count):
                "\(count) exclamation marks, allowed 3"
            case .childMissingFromLastPage:
                "last page does not mention the child by name"
            case .endingNotSleepy:
                "last page has no wind-down signal (goodnight, sleep, …)"
            case .deniedWord(let word):
                "denied word \"\(word)\""
            }
        }
    }

    /// Words that have no place in a bedtime story for small children.
    /// Matched case-insensitively on word boundaries, so each inflection that
    /// matters is listed explicitly ("monster" does not catch "monsters").
    private static let deniedWords: [String] = [
        // Violence and harm.
        "blood", "bloody", "kill", "killed", "kills", "die", "died", "dies",
        "dead", "death", "gun", "guns", "knife", "knives", "weapon", "weapons",
        "war", "wars", "fight", "fights", "fighting", "fought", "punch",
        "punched", "hurt", "hurts", "attack", "attacks", "attacked", "shoot",
        "shot", "bomb", "bombs", "sword", "swords", "hate", "hated", "hates",
        // Fear and dread — even reassurances ("nothing to be scared of")
        // put the idea in a sleepy head, and a compliant story never needs them.
        "terrify", "terrified", "terrifying", "terror", "horror", "horrors",
        "nightmare", "nightmares", "scream", "screamed", "screams", "screaming",
        "scary", "scared", "afraid", "frighten", "frightened", "frightening",
        "monster", "monsters", "ghost", "ghosts", "zombie", "zombies",
        "demon", "demons", "witch", "witches", "evil", "danger", "dangerous",
        "haunted", "creepy", "spooky",
        // Unkindness.
        "stupid", "dumb", "shut up", "idiot", "ugly",
    ]

    /// A bedtime story ends going to sleep, not mid-adventure. The last page
    /// must carry at least one of these (word-boundary matched, explicit
    /// inflections, same policy as the denylist). The prompt demands a
    /// "Goodnight, <name>" ending; this is the gate that makes it stick —
    /// review 2026-07-22 observed a passing story that ended "continued to
    /// explore and discover new places".
    private static let sleepSignals: [String] = [
        "goodnight", "good night", "sleep", "sleeps", "sleepy", "asleep",
        "sleeping", "dream", "dreams", "dreaming", "rest", "rests", "resting",
        "rested", "snug", "snuggle", "snuggled", "snuggles", "yawn", "yawned",
        "yawns", "drift", "drifted", "drifts", "lullaby", "hush", "hushed",
        "tucked in", "eyes closed", "closed their eyes",
    ]

    private static func firstDeniedWord(in text: String) -> String? {
        deniedWords.first { containsWord($0, in: text) }
    }

    private static func containsSleepSignal(_ text: String) -> Bool {
        sleepSignals.contains { containsWord($0, in: text) }
    }

    private static func containsWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// A page short enough to be a single tossed-off sentence isn't a bedtime
    /// scene; one too long can't be read calmly. Younger listeners get shorter
    /// pages on both ends. Internal so the model engine's repagination pass
    /// works to the same thresholds it will be judged by.
    static func pageLengthBounds(for ageBand: AgeBand) -> ClosedRange<Int> {
        switch ageBand {
        case .toddler: 40...400
        case .little: 50...550
        case .big: 60...700
        }
    }

    static func isAcceptable(_ content: StoryContent, for request: StoryRequest) -> Bool {
        rejection(of: content, for: request) == nil
    }

    /// The first rule the story breaks, or nil when it is safe to show.
    static func rejection(of content: StoryContent, for request: StoryRequest) -> Rejection? {
        // Structure: a real story arc with full, readable pages.
        guard (4...12).contains(content.pages.count) else {
            return .pageCount(content.pages.count)
        }
        let trimmedTitle = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 80 else { return .badTitle }
        let trimmedMoral = content.moral.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMoral.isEmpty, trimmedMoral.count <= 200 else { return .badMoral }
        let bounds = pageLengthBounds(for: request.ageBand)
        for (index, page) in content.pages.enumerated() {
            let trimmed = page.trimmingCharacters(in: .whitespacesAndNewlines)
            guard bounds.contains(trimmed.count) else {
                return .pageLength(pageIndex: index, count: trimmed.count, allowed: bounds)
            }
        }

        // Calm: an excited story announces itself in punctuation.
        let fullText = ([content.title, content.moral] + content.pages).joined(separator: "\n")
        let exclamations = fullText.count(where: { $0 == "!" })
        guard exclamations <= 3 else { return .tooExcited(exclamationCount: exclamations) }

        // The child must be the hero of their own story, and the story must
        // end with them — the last page says goodnight by name and actually
        // winds down toward sleep.
        let name = request.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastPage = content.pages.last {
            if !name.isEmpty, !lastPage.localizedCaseInsensitiveContains(name) {
                return .childMissingFromLastPage
            }
            if !containsSleepSignal(lastPage) {
                return .endingNotSleepy
            }
        }

        // Nothing frightening or unkind, anywhere in the text.
        if let word = firstDeniedWord(in: fullText) { return .deniedWord(word) }
        return nil
    }
}
