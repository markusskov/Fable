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

    // Localized for the UI only — story engines and prompts key off the case
    // itself, never these strings.
    var displayName: String {
        switch self {
        case .adventure: String(localized: "Adventure")
        case .animals: String(localized: "Animals")
        case .magic: String(localized: "Magic")
        case .space: String(localized: "Space")
        case .ocean: String(localized: "Ocean")
        case .friendship: String(localized: "Friends")
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
        case .toddler: String(localized: "2–3 years")
        case .little: String(localized: "4–6 years")
        case .big: String(localized: "7–9 years")
        }
    }
}
