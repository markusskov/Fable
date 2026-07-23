import Foundation

/// Deterministic template-based engine. Same request + same seed → same story.
/// Always succeeds as long as the English library is non-empty (enforced at
/// init) — English is the universal fallback shelf.
struct CuratedStoryEngine: StoryEngine {
    private let libraries: [StoryLanguage: [StoryTemplate]]

    init(libraries: [StoryLanguage: [StoryTemplate]] = TemplateLibrary.byLanguage) {
        precondition(
            !(libraries[.english] ?? []).isEmpty,
            "CuratedStoryEngine requires a non-empty English library"
        )
        self.libraries = libraries
    }

    func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
        var rng = SeededRandom(seed: seed)
        // A language whose curated shelf is still empty gets English: a real
        // story in the wrong language beats breaking bedtime. The content is
        // stamped with the language actually served, so nothing downstream
        // mistakes it for a translation.
        let language: StoryLanguage =
            (libraries[request.language]?.isEmpty == false) ? request.language : .english
        let library = libraries[language] ?? []
        let matching = library.filter { $0.themes.contains(request.theme) }
        var rendered = (matching.isEmpty ? library : matching)
            .pick(using: &rng)
            .render(for: request, rng: &rng)
        rendered.language = language
        return rendered
    }
}
