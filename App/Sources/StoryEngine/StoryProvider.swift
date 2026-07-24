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

    private let curated: any StoryEngine
    private let model: any StoryEngine
    /// Test seam: stands in for the deterministic emergency story so the
    /// floor branch (reached only when the emergency fails the gate, which
    /// no real input can cause) can be forced and asserted on. Nil in
    /// production.
    private let emergencyOverride: StoryContent?

    /// Engines are injectable so tests can force every fallback depth —
    /// including the input-free floor, which is otherwise unreachable.
    /// Production always uses the real pair.
    init(
        model: any StoryEngine = ModelStoryEngine(),
        curated: any StoryEngine = CuratedStoryEngine(),
        emergencyOverride: StoryContent? = nil
    ) {
        self.model = model
        self.curated = curated
        self.emergencyOverride = emergencyOverride
    }

    /// What the provider hands back: the story, which engine told it, and
    /// the hero identity the story was actually written for. Persistence and
    /// chrome MUST use `heroName`, never the raw profile name — the round-two
    /// review showed "A story for Monster" wrapping a neutralized body.
    struct TellResult: Sendable {
        var content: StoryContent
        var engine: StoryEngineKind
        var heroName: String
    }

    func makeStory(for request: StoryRequest) async -> TellResult {
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
                // The production model engine gates its own output, but the
                // provider's postcondition must not depend on an engine's
                // internals (round-three finding): every path re-checks here.
                guard ContentSafetyCheck.isAcceptable(content, for: safe) else { continue }
                return TellResult(content: content, engine: .model, heroName: safe.childName)
            } catch StoryEngineError.unavailable {
                break
            } catch {
                continue
            }
        }

        if let content = try? await curated.makeStory(for: safe, seed: seed),
           ContentSafetyCheck.isAcceptable(content, for: safe) {
            return TellResult(content: content, engine: .curated, heroName: safe.childName)
        }
        // The emergency story is deterministic and built from neutralized
        // values; for any name within the neutralized length bound it passes
        // the gate. The check is kept anyway — if it ever fails, the floor
        // below answers.
        let emergency = emergencyOverride ?? Self.emergencyStory(for: safe)
        if ContentSafetyCheck.isAcceptable(emergency, for: safe) {
            return TellResult(content: emergency, engine: .emergency, heroName: safe.childName)
        }
        // The floor's hero is its own "Little One" — the persisted story
        // must say so rather than dedicating a floor story to a name it
        // does not contain. The floor is a constant, so its gate acceptance
        // is proven exhaustively in tests (every age band) rather than
        // re-checked at runtime: there is nothing beneath it to fall to.
        return TellResult(
            content: Self.inputFreeStory,
            engine: .floor,
            heroName: Self.floorHeroName
        )
    }

    /// Deterministic English safe story that still stars the child. Built
    /// only from a neutralized request, so its interpolated values cannot be
    /// unsafe. Marked English because its prose is English (the gate judges
    /// by the text's actual language).
    private static func emergencyStory(for request: StoryRequest) -> StoryContent {
        // English prose gets English default slots: a Spanish comfort default
        // spliced mid-English-sentence was round-three's mixed-language
        // finding. A parent-typed comfort object still appears verbatim —
        // it is the child's own thing, whatever language names it.
        var request = request
        request.language = .english
        return StoryContent(
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

    /// The floor: ONE fixed English goodnight story whose only "variable" is
    /// the constant safe hero "Little One", woven into the last page so the
    /// story satisfies the FULL gate — the round-two review showed a
    /// name-free floor failing `.childMissingFromLastPage`. It contains no
    /// parent input, so no denied word can appear, and its page lengths sit
    /// inside every age band's bounds (proven exhaustively in tests).
    /// English by decision, not omission: the floor lies beneath a curated
    /// shelf that already exists in all seven languages, so it is reached
    /// only when that library is broken — and "never break bedtime" then
    /// outranks language purity. Round three rightly flagged the earlier
    /// signature for taking a language it ignored.
    static let floorHeroName = "Little One"

    static let inputFreeStory = StoryContent(
        title: "A Quiet Goodnight",
        pages: [
            "The evening grew soft and dim, and the whole town began to yawn. Rooftops settled, windows glowed, and the streetlamps hummed their lowest, sleepiest song.",
            "The moon rose slowly over the hills, spreading a silver blanket of light across every garden, every path, and every warm little bed.",
            "One by one, the stars came out to keep watch, blinking gently, the way friends do when they are glad to see you resting.",
            "And so the night wrapped the world in quiet. Sleep now, \(floorHeroName). Goodnight, and sweet dreams until the morning.",
        ],
        moral: "Every day ends softly when you let it.",
        language: .english
    )
}
