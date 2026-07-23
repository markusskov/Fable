import Foundation

/// A hand-written, parameterized bedtime story. Slots (`{name}`, `{companion}`,
/// `{comfort}`) come from the child profile; pools (`{setting}`, `{sound}`,
/// `{treasure}`) are picked per-telling so repeats feel like new stories.
///
/// Editorial bar: every rendered combination must read as a finished,
/// publishable story — the curated engine is a product tier, not a stub.
struct StoryTemplate: Identifiable, Sendable {
    let id: String
    let themes: Set<StoryTheme>
    let titleVariants: [String]
    let pages: [String]
    let settings: [String]
    let sounds: [String]
    let treasures: [String]
    let moralVariants: [String]

    func render(for request: StoryRequest, rng: inout some RandomNumberGenerator) -> StoryContent {
        // Parent-typed values are brace-stripped: a child "named" {sound}
        // must never be re-substituted by a later dictionary pass (iteration
        // order is random, so the old behavior was nondeterministic), and no
        // parent input may masquerade as a template token.
        func sanitized(_ value: String) -> String {
            value.replacingOccurrences(of: "{", with: "")
                .replacingOccurrences(of: "}", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let substitutions: [String: String] = [
            "{name}": sanitized(request.childName),
            "{companion}": sanitized(request.companionOrDefault),
            "{comfort}": sanitized(request.comfortObjectOrDefault),
            "{setting}": settings.pick(using: &rng),
            "{sound}": sounds.pick(using: &rng),
            "{treasure}": treasures.pick(using: &rng),
        ]
        return StoryContent(
            title: titleVariants.pick(using: &rng).applying(substitutions),
            pages: pages.map { $0.applying(substitutions) },
            moral: moralVariants.pick(using: &rng).applying(substitutions)
        )
    }
}

extension String {
    func applying(_ substitutions: [String: String]) -> String {
        var result = self
        for (token, value) in substitutions {
            result = result.replacingOccurrences(of: token, with: value)
        }
        return result
    }
}
