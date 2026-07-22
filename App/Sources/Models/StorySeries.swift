import Foundation
import SwiftData

/// A continuing adventure: the same hero and companion, one new episode at a
/// time. Fable+ feature — creation and continuation are gated in the UI.
@Model
final class StorySeries {
    var title: String
    var themeRaw: String
    var childName: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Story.series)
    var episodes: [Story]

    var theme: StoryTheme {
        get { StoryTheme(rawValue: themeRaw) ?? .adventure }
        set { themeRaw = newValue.rawValue }
    }

    init(title: String, theme: StoryTheme, childName: String) {
        self.title = title
        self.themeRaw = theme.rawValue
        self.childName = childName
        self.createdAt = .now
        self.episodes = []
    }

    /// Episodes in story order. The relationship array is unordered storage.
    var orderedEpisodes: [Story] {
        episodes.sorted { $0.episodeNumber ?? 0 < $1.episodeNumber ?? 0 }
    }

    var nextEpisodeNumber: Int {
        (orderedEpisodes.last?.episodeNumber ?? 0) + 1
    }

    /// The "previously on" material for the next episode: the most recent
    /// recaps, oldest first, capped so prompts stay small.
    func recentRecaps(limit: Int = 3) -> [String] {
        orderedEpisodes.suffix(limit).map(\.recap).filter { !$0.isEmpty }
    }
}
