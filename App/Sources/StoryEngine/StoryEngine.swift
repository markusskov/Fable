import Foundation

/// Everything an engine needs to write tonight's story. Plain data, Sendable.
struct StoryRequest: Sendable, Equatable {
    var childName: String
    var ageBand: AgeBand
    var theme: StoryTheme
    var companion: String
    var comfortObject: String
    /// The language tonight's story should be told in. Engines that cannot
    /// honor it do the honest thing: the model engine refuses (falling back
    /// silently), the curated engine serves its English shelf.
    var language: StoryLanguage = .english
    /// Present when tonight's story continues an adventure (Fable+).
    var series: SeriesContext?

    /// What an engine needs to continue a series: pure data lifted from the
    /// `StorySeries` model so engines stay free of SwiftData.
    struct SeriesContext: Sendable, Equatable {
        var title: String
        var episodeNumber: Int
        /// Recent episode recaps, oldest first.
        var previously: [String]
    }

    /// Trimmed, display-ready companion with a sensible default. Defaults
    /// follow the story language: they are spliced into story prose, and
    /// "a small brave fox" mid-sentence would break a bokmål page.
    var companionOrDefault: String {
        let trimmed = companion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else { return trimmed }
        return switch language {
        case .english: "a small brave fox"
        case .norwegianBokmal: "en liten modig rev"
        // Nominative — German templates only splice {companion} into
        // subject positions, so any case-marked parent input stays correct.
        case .german: "ein kleiner mutiger Fuchs"
        case .spanish: "un pequeño zorro valiente"
        case .french: "un petit renard courageux"
        }
    }

    var comfortObjectOrDefault: String {
        let trimmed = comfortObject.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty else { return trimmed }
        return switch language {
        case .english: "a soft warm blanket"
        case .norwegianBokmal: "et mykt og varmt teppe"
        // Feminine, so nominative and accusative splice sites both read
        // correctly ("eine" is both cases).
        case .german: "eine weiche, warme Decke"
        case .spanish: "una manta suave y calentita"
        case .french: "une petite couverture douce et chaude"
        }
    }
}

/// The output of any story engine: pure content, ready to persist or display.
struct StoryContent: Sendable, Equatable {
    var title: String
    var pages: [String]
    var moral: String
    /// One narrator's sentence for tomorrow's "previously on". Engines that
    /// cannot author one leave it empty; callers fall back to the moral.
    var recap: String = ""
    /// The language the text is actually written in — stamped by the engine
    /// that produced it, which may differ from the request's language when a
    /// fallback crossed languages. The safety gate judges by this, not by
    /// what was asked for.
    var language: StoryLanguage = .english
}

enum StoryEngineError: Error {
    case unavailable
    case generationFailed
}

/// A producer of stories. Implementations must be side-effect free:
/// same request + same entropy in, same story out.
protocol StoryEngine: Sendable {
    func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent
}
