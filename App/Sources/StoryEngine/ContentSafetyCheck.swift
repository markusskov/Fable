import Foundation

/// Post-generation gate: model output is never displayed unchecked (CLAUDE.md
/// guardrail). Curated templates are pre-vetted editorially and skip this in
/// production, but tests hold them to the same bar.
///
/// Second iteration: age-banded structural heuristics, a calm-tone check, and
/// a denylist with explicit inflections. Rejection is cheap — the caller falls
/// back silently to the curated engine — so every rule errs strict.
enum ContentSafetyCheck {
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

    private static func containsDeniedWord(_ text: String) -> Bool {
        deniedWords.contains { word in
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    /// A page short enough to be a single tossed-off sentence isn't a bedtime
    /// scene; one too long can't be read calmly. Younger listeners get shorter
    /// pages on both ends.
    private static func pageLengthBounds(for ageBand: AgeBand) -> ClosedRange<Int> {
        switch ageBand {
        case .toddler: 40...400
        case .little: 50...550
        case .big: 60...700
        }
    }

    static func isAcceptable(_ content: StoryContent, for request: StoryRequest) -> Bool {
        // Structure: a real story arc with full, readable pages.
        guard (4...12).contains(content.pages.count) else { return false }
        let trimmedTitle = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 80 else { return false }
        let trimmedMoral = content.moral.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMoral.isEmpty, trimmedMoral.count <= 200 else { return false }
        let bounds = pageLengthBounds(for: request.ageBand)
        for page in content.pages {
            let trimmed = page.trimmingCharacters(in: .whitespacesAndNewlines)
            guard bounds.contains(trimmed.count) else { return false }
        }

        // Calm: an excited story announces itself in punctuation.
        let fullText = ([content.title, content.moral] + content.pages).joined(separator: "\n")
        guard fullText.count(where: { $0 == "!" }) <= 3 else { return false }

        // The child must be the hero of their own story, and the story must
        // end with them — the last page says goodnight by name.
        let name = request.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            guard let lastPage = content.pages.last,
                  lastPage.localizedCaseInsensitiveContains(name)
            else { return false }
        }

        // Nothing frightening or unkind, anywhere in the text.
        return !containsDeniedWord(fullText)
    }
}
