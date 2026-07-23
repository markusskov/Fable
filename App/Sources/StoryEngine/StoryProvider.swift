import Foundation

/// The single entry point the UI uses to get a story. Encodes the product
/// guardrail "never break bedtime": this method cannot fail.
///
/// Prefers on-device model generation when available, giving it two
/// attempts before falling back silently to the curated engine: the
/// 2026-07-23 per-language yield measurement put single-attempt pass
/// rates at 4–7 of 8 (ending discipline, not content), so one retry
/// lifts most-requests-get-a-model-story from ~60% to ~85%+ per
/// language at the cost of a few extra seconds only on the failure
/// path. Unavailability skips the retry — a second try can't help.
struct StoryProvider: Sendable {
    static let modelAttempts = 2

    private let curated = CuratedStoryEngine()
    private let model = ModelStoryEngine()

    func makeStory(for request: StoryRequest) async -> (content: StoryContent, engine: StoryEngineKind) {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        for _ in 0..<Self.modelAttempts {
            do {
                let content = try await model.makeStory(for: request, seed: seed)
                return (content, .model)
            } catch StoryEngineError.unavailable {
                break
            } catch {
                continue
            }
        }
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
