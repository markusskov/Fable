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
    /// One narrator's sentence of what happened, rendered with the same slot
    /// picks as the story it summarizes. This is the "previously on" material
    /// the next episode of a series builds on — without it, curated episodes
    /// fell back to the moral, which reads as a lesson, not a recap
    /// (external review 2026-07-24, finding #5). Uses the same slots and the
    /// same grammar discipline as pages.
    let recapVariants: [String]

    func render(for request: StoryRequest, rng: inout some RandomNumberGenerator) -> StoryContent {
        // Parent-typed values are brace-stripped: a child "named" {sound}
        // must never be re-substituted by a later dictionary pass (iteration
        // order is random, so the old behavior was nondeterministic), and no
        // parent input may masquerade as a template token. The name falls
        // back to a generic if brace-stripping leaves it empty, so a child
        // "named" "{}" is never nameless.
        let strippedName = StoryRequest.bracesStripped(request.childName)
        let substitutions: [String: String] = [
            "{name}": strippedName.isEmpty ? ContentSafetyCheck.safeGenericName(for: request.language) : strippedName,
            "{companion}": StoryRequest.bracesStripped(request.companionOrDefault),
            "{comfort}": StoryRequest.bracesStripped(request.comfortObjectOrDefault),
            "{setting}": settings.pick(using: &rng),
            "{sound}": sounds.pick(using: &rng),
            "{treasure}": treasures.pick(using: &rng),
        ]
        // The recap variant is picked LAST so that adding recaps did not
        // shift the title/page/moral output of any existing seed.
        var content = StoryContent(
            title: titleVariants.pick(using: &rng).applying(substitutions),
            pages: pages.map { $0.applying(substitutions) },
            moral: moralVariants.pick(using: &rng).applying(substitutions)
        )
        if !recapVariants.isEmpty {
            content.recap = recapVariants.pick(using: &rng).applying(substitutions)
        }
        return content
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
