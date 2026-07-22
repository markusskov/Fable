import Foundation

/// Post-generation gate: model output is never displayed unchecked (CLAUDE.md
/// guardrail). Curated templates are pre-vetted editorially and skip this.
///
/// First iteration: structural sanity + a conservative denylist. The roadmap
/// has a follow-up item to deepen this (age heuristics, richer patterns).
enum ContentSafetyCheck {
    /// Words that have no place in a bedtime story for small children.
    /// Matched case-insensitively on word boundaries.
    private static let deniedWords: [String] = [
        "blood", "bloody", "kill", "killed", "die", "died", "dead", "death",
        "gun", "knife", "weapon", "war", "fight", "punch", "hate",
        "terrify", "terrified", "horror", "nightmare", "scream", "screamed",
        "stupid", "dumb", "shut up",
    ]

    private static func containsDeniedWord(_ text: String) -> Bool {
        deniedWords.contains { word in
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
            return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }

    static func isAcceptable(_ content: StoryContent, for request: StoryRequest) -> Bool {
        // Structure: a real story arc, pages short enough to read aloud calmly.
        guard (4...12).contains(content.pages.count) else { return false }
        let trimmedTitle = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 80 else { return false }
        for page in content.pages {
            let trimmed = page.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, trimmed.count <= 700 else { return false }
        }

        // The child must be the hero of their own story.
        let name = request.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard name.isEmpty || content.pages.joined().localizedCaseInsensitiveContains(name) else {
            return false
        }

        // Nothing frightening or unkind, anywhere in the text.
        let fullText = ([content.title, content.moral] + content.pages).joined(separator: "\n")
        return !containsDeniedWord(fullText)
    }
}
