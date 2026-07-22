import Foundation

/// The single entry point the UI uses to get a story. Encodes the product
/// guardrail "never break bedtime": this method cannot fail.
///
/// Milestone 1 will add `ModelStoryEngine` (FoundationModels) as the preferred
/// engine when available; the curated engine remains the silent fallback.
struct StoryProvider: Sendable {
    private let curated = CuratedStoryEngine()

    func makeStory(for request: StoryRequest) async -> (content: StoryContent, engine: StoryEngineKind) {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        if let content = try? await curated.makeStory(for: request, seed: seed) {
            return (content, .curated)
        }
        // Unreachable with a valid library, but bedtime gets a story no matter what.
        return (Self.emergencyStory(for: request), .curated)
    }

    private static func emergencyStory(for request: StoryRequest) -> StoryContent {
        StoryContent(
            title: "Goodnight, \(request.childName)",
            pages: [
                "Once there was a wonderful child named \(request.childName), who had done so many things today that even the moon was impressed.",
                "\"Time to rest,\" said the moon, tucking a silver blanket of light over the whole town.",
                "So \(request.childName) snuggled in close with \(request.comfortObjectOrDefault), took one deep cozy breath, and let the day drift off like a little boat.",
                "Goodnight, \(request.childName). Tomorrow is already on its way, full of new stories.",
            ],
            moral: "Every day ends softly when you let it."
        )
    }
}
