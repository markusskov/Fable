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
    /// The language the prose is actually written in, stamped from the
    /// gated content. Empty for rows persisted before the stamp existed —
    /// which is why the legacy repair sweep cannot vocabulary-scan old
    /// bodies (scanning German prose with English words flags "die"/"war").
    var languageRaw: String = ""
    /// Set when this story is an episode of a continuing adventure.
    var series: StorySeries?
    var episodeNumber: Int?
    /// The child this story was told for. Optional for pre-profiles stories,
    /// which are treated as belonging to every child.
    var profile: ChildProfile?

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
        self.languageRaw = content.language.rawValue
    }

    /// The one way UI persists a provider result: the hero identity travels
    /// with the content it was written for. Round two reached the reader
    /// chrome because a call site paired gated content with the RAW profile
    /// name; round three noted the fix lived only at that call site. This
    /// initializer removes the choice.
    convenience init(telling result: StoryProvider.TellResult, theme: StoryTheme) {
        self.init(content: result.content, theme: theme,
                  childName: result.heroName, engine: result.engine)
    }
}

extension Story {
    /// Pre-profiles stories (nil profile) belong to every child.
    func belongs(to profile: ChildProfile) -> Bool {
        self.profile == nil || self.profile?.uuid == profile.uuid
    }
}

extension StorySeries {
    func belongs(to profile: ChildProfile) -> Bool {
        profileUUID == nil || profileUUID == profile.uuid
    }
}

/// Which producer wrote a story. Shown honestly in settings, never in the reader.
enum StoryEngineKind: String, Codable, Sendable {
    case curated
    case model
    /// The deterministic personalized fallback (curated + emergency were
    /// indistinguishable before the 2026-07-24 round-two review).
    case emergency
    /// The input-free floor: safe by construction, not personalized.
    case floor
}
