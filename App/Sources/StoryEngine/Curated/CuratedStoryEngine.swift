import Foundation

/// Deterministic template-based engine. Same request + same seed → same story.
/// Always succeeds as long as the library is non-empty (enforced at init).
struct CuratedStoryEngine: StoryEngine {
    private let library: [StoryTemplate]

    init(library: [StoryTemplate] = TemplateLibrary.all) {
        precondition(!library.isEmpty, "CuratedStoryEngine requires a non-empty library")
        self.library = library
    }

    func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
        var rng = SeededRandom(seed: seed)
        let matching = library.filter { $0.themes.contains(request.theme) }
        let template = (matching.isEmpty ? library : matching).pick(using: &rng)
        return template.render(for: request, rng: &rng)
    }
}
