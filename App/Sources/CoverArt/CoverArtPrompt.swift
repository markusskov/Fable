import Foundation

/// The entire vocabulary an image prompt can be built from. Keyed by the
/// closed `StoryTheme` enum and nothing else — no parent-typed field and no
/// model-written prose ever reaches an image prompt, because pixels cannot
/// be run through `ContentSafetyCheck` afterwards (ADR 0004). The compiler
/// holds this line: there is no way to hand this type a string.
enum CoverArtPrompt {
    /// Every scene a theme's cover can show. Reviewed editorial content,
    /// like the curated shelves; a new theme fails to compile without one.
    static func variants(for theme: StoryTheme) -> [String] {
        switch theme {
        case .adventure:
            [
                "A winding path through gentle rolling hills at dusk, a tiny lantern glowing far ahead",
                "A rolled-up treasure map and a small backpack resting under a big quiet tree at night",
                "A little rowboat tied at a calm riverbank under early evening stars",
            ]
        case .animals:
            [
                "A small sleepy fox curled up in a mossy forest clearing under moonlight",
                "A family of rabbits settling into a warm burrow lit by fireflies",
                "An owl perched on a branch watching over a quiet meadow at night",
            ]
        case .magic:
            [
                "A tiny cottage with softly glowing windows and gentle sparkles drifting in the night air",
                "A sleeping garden where flowers give off a faint starry shimmer",
                "A cozy wizard's bookshelf with a small candle and a dozing cat",
            ]
        case .space:
            [
                "A crescent moon and soft stars over sleeping rooftops",
                "A friendly little rocket ship parked on a grassy hill under the night sky",
                "Gentle planets drifting like mobiles above a quiet nursery window",
            ]
        case .ocean:
            [
                "A calm moonlit sea with a small lighthouse glowing warmly on the shore",
                "A sleepy whale drifting through soft blue water among tiny stars of plankton",
                "A quiet tide pool reflecting the moon, with a small starfish resting",
            ]
        case .friendship:
            [
                "Two teddy bears sharing a blanket on a windowsill under the moon",
                "A small campfire glowing warmly with two empty cozy chairs side by side",
                "Two paper boats floating together on a calm pond at dusk",
            ]
        }
    }

    /// The style contract every cover shares, appended to each scene: calm,
    /// storybook, and wordless — generated text inside an image is the one
    /// way letters could reach a child without passing any gate.
    static let styleSuffix =
        "Warm, calm children's storybook cover, soft cozy nighttime colors, gentle and dreamy, no words or letters"

    /// A finished prompt for tonight's cover. Which variant is served does
    /// not matter for safety — every one is reviewed — so plain randomness
    /// is fine and keeps covers from feeling stamped from one plate.
    static func prompt(for theme: StoryTheme) -> String {
        let scene = variants(for: theme).randomElement() ?? variants(for: theme)[0]
        return "\(scene). \(styleSuffix)."
    }
}
