import Foundation

/// The mood a child picks for tonight's story.
enum StoryTheme: String, Codable, CaseIterable, Identifiable, Sendable {
    case adventure
    case animals
    case magic
    case space
    case ocean
    case friendship

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .adventure: "Adventure"
        case .animals: "Animals"
        case .magic: "Magic"
        case .space: "Space"
        case .ocean: "Ocean"
        case .friendship: "Friends"
        }
    }

    var emoji: String {
        switch self {
        case .adventure: "🗺️"
        case .animals: "🦊"
        case .magic: "✨"
        case .space: "🌙"
        case .ocean: "🐚"
        case .friendship: "🧸"
        }
    }
}

/// Coarse age bands drive vocabulary, story length, and content guardrails.
enum AgeBand: String, Codable, CaseIterable, Identifiable, Sendable {
    case toddler   // ~2–3
    case little    // ~4–6
    case big       // ~7–9

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .toddler: "2–3 years"
        case .little: "4–6 years"
        case .big: "7–9 years"
        }
    }
}
