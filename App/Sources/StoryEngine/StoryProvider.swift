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
        // Neutralize once, at the single chokepoint, so EVERY path — model,
        // curated, emergency — is fed input that cannot inject a denied word
        // or a template brace. Normal profiles pass through untouched; only a
        // hostile one (child named "Monster", a "{}" companion) is rewritten.
        // This is the boundary the 2026-07-24 external review asked for: parent
        // values validated before they reach any generator, and every returned
        // story re-checked by the gate.
        let safe = ContentSafetyCheck.neutralized(request)
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        for _ in 0..<Self.modelAttempts {
            do {
                let content = try await model.makeStory(for: safe, seed: seed)
                return (content, .model)
            } catch StoryEngineError.unavailable {
                break
            } catch {
                continue
            }
        }

        if let content = try? await curated.makeStory(for: safe, seed: seed),
           ContentSafetyCheck.isAcceptable(content, for: safe) {
            return (content, .curated)
        }
        // The emergency story is deterministic and built from neutralized
        // values, so it is guaranteed to pass; the gate here is belt and
        // suspenders, and if it somehow fails we serve the input-free story.
        let emergency = Self.emergencyStory(for: safe)
        if ContentSafetyCheck.isAcceptable(emergency, for: safe) {
            return (emergency, .curated)
        }
        return (Self.inputFreeStory(for: safe.language), .curated)
    }

    /// Deterministic English safe story that still stars the child. Built
    /// only from a neutralized request, so its interpolated values cannot be
    /// unsafe. Marked English because its prose is English (the gate judges
    /// by the text's actual language).
    private static func emergencyStory(for request: StoryRequest) -> StoryContent {
        StoryContent(
            title: "Goodnight, \(request.childName)",
            pages: [
                "Once there was a wonderful child named \(request.childName), who had done so many things today that even the moon was impressed.",
                "\"Time to rest,\" said the moon, tucking a silver blanket of light over the whole town.",
                "So \(request.childName) snuggled in close with \(request.comfortObjectOrDefault), took one deep cozy breath, and let the day drift off like a little boat.",
                "Goodnight, \(request.childName). Tomorrow is already on its way, full of new stories.",
            ],
            moral: "Every day ends softly when you let it.",
            language: .english
        )
    }

    /// The absolute floor: a fixed, parent-input-free goodnight story that
    /// cannot contain anything unsafe because it contains no variable text at
    /// all. Only reached if even the neutralized emergency story somehow
    /// failed the gate — a state that should be impossible, but bedtime never
    /// breaks and a child never sees a rejected story.
    private static func inputFreeStory(for language: StoryLanguage) -> StoryContent {
        StoryContent(
            title: "A Quiet Goodnight",
            pages: [
                "The evening grew soft and dim, and the whole town began to yawn. Rooftops settled, windows glowed, and the streetlamps hummed their lowest, sleepiest song.",
                "The moon rose slowly over the hills, spreading a silver blanket of light across every garden, every path, and every warm little bed.",
                "One by one, the stars came out to keep watch, blinking gently, the way friends do when they are glad to see you resting.",
                "And so the night wrapped the world in quiet. Sleep now, little one. Goodnight, and sweet dreams until the morning.",
            ],
            moral: "Every day ends softly when you let it.",
            language: .english
        )
    }
}
