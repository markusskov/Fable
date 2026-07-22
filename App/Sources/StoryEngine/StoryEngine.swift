import Foundation

/// Everything an engine needs to write tonight's story. Plain data, Sendable.
struct StoryRequest: Sendable, Equatable {
    var childName: String
    var ageBand: AgeBand
    var theme: StoryTheme
    var companion: String
    var comfortObject: String

    /// Trimmed, display-ready companion with a sensible default.
    var companionOrDefault: String {
        let trimmed = companion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "a small brave fox" : trimmed
    }

    var comfortObjectOrDefault: String {
        let trimmed = comfortObject.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "a soft warm blanket" : trimmed
    }
}

/// The output of any story engine: pure content, ready to persist or display.
struct StoryContent: Sendable, Equatable {
    var title: String
    var pages: [String]
    var moral: String
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
