import Foundation
import SwiftData

/// A finished story in the library. Engine-agnostic: producers create
/// `StoryContent`, the app persists it here.
@Model
final class Story {
    var title: String
    var pages: [String]
    var moral: String
    var themeRaw: String
    var childName: String
    var engineRaw: String
    var isFavorite: Bool
    var createdAt: Date
    /// One narrator's sentence of what happened, used as "previously on"
    /// context when a series continues. Empty for pre-series stories.
    var recap: String = ""
    /// Set when this story is an episode of a continuing adventure.
    var series: StorySeries?
    var episodeNumber: Int?

    var theme: StoryTheme {
        get { StoryTheme(rawValue: themeRaw) ?? .adventure }
        set { themeRaw = newValue.rawValue }
    }

    var engine: StoryEngineKind {
        get { StoryEngineKind(rawValue: engineRaw) ?? .curated }
        set { engineRaw = newValue.rawValue }
    }

    init(content: StoryContent, theme: StoryTheme, childName: String, engine: StoryEngineKind) {
        self.title = content.title
        self.pages = content.pages
        self.moral = content.moral
        self.themeRaw = theme.rawValue
        self.childName = childName
        self.engineRaw = engine.rawValue
        self.isFavorite = false
        self.createdAt = .now
        // Engines that can't author a recap (curated templates) leave it
        // empty; the moral is an honest one-line stand-in for "previously on".
        self.recap = content.recap.isEmpty ? content.moral : content.recap
    }
}

/// Which producer wrote a story. Shown honestly in settings, never in the reader.
enum StoryEngineKind: String, Codable, Sendable {
    case curated
    case model
}
