import Foundation

/// The shipped story library. Grows over time; templates are permanent
/// editorial assets (seasonal collections will build on this format).
enum TemplateLibrary {
    static let all: [StoryTemplate] = [lanternPath, sleepyVoyage, littleLostFriend]

    /// Curated shelves by story language. A shelf stays empty until its
    /// templates exist as real editorial work — Norwegian awaits the
    /// owner-reviewed translation (roadmap: Milestone 4); the engine falls
    /// back to English rather than serve machine-translated prose.
    static let byLanguage: [StoryLanguage: [StoryTemplate]] = [
        .english: all,
        .norwegianBokmal: [],
    ]

    // MARK: - The Lantern Path (adventure · magic)

    static let lanternPath = StoryTemplate(
        id: "lantern-path",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} and the Lantern Path",
            "The Night the Fireflies Came for {name}",
            "{name}'s Lantern Adventure",
        ],
        pages: [
            "One evening, just as the sky turned the color of blueberries, {name} noticed a tiny light bobbing outside the window. Then another. And another. Fireflies! And they seemed to be waiting.",
            "{name} tiptoed outside with {companion}, holding {comfort} close. The fireflies made a glowing path, like a ribbon of little lanterns, winding toward {setting}.",
            "The path was soft under {name}'s feet, and the night was warm and friendly. Somewhere far away, something went {sound} — a sleepy, gentle sound, like the world yawning.",
            "At the end of the lantern path, tucked under a mossy root, they found it: {treasure}. It glowed faintly, like it had been waiting a very long time to be found.",
            "\"It fell from the sky,\" whispered {companion}. \"It must be terribly homesick.\" {name} picked it up ever so carefully. It was warm, like a little heartbeat.",
            "So {name} lifted it high, higher, as high as arms can reach — and the fireflies gathered underneath and carried it up, up, up, until it settled back into the sky right where it belonged.",
            "The sky twinkled a thank-you. The fireflies bowed their little lights. And {name} suddenly felt very, very sleepy — the good kind of sleepy, like after a day full of wonders.",
            "Back home, {name} snuggled under the covers with {comfort}, and {companion} curled up close. Outside, one firefly stayed by the window, keeping watch. Goodnight, {name}. The sky is smiling at you tonight.",
        ],
        settings: [
            "the old garden gate",
            "the whispering birch wood",
            "the meadow behind the hill",
            "the little stream with the smooth stones",
        ],
        sounds: [
            "hoo-hoo",
            "sh-sh-shhh",
            "prrrrl",
        ],
        treasures: [
            "a small fallen star",
            "a moonbeam in a jar",
            "a silver bell that only rings for kind hearts",
        ],
        moralVariants: [
            "Kind hands find their way home, and so do the things they carry.",
            "Even small helpers can light up the whole sky.",
        ]
    )

    // MARK: - The Sleepy Voyage (space · ocean)

    static let sleepyVoyage = StoryTemplate(
        id: "sleepy-voyage",
        themes: [.space, .ocean],
        titleVariants: [
            "{name}'s Sleepy Voyage",
            "The Boat Made of Moonlight",
            "{name} and the Humming Stars",
        ],
        pages: [
            "When the house grew quiet and the lights grew low, {name}'s bed did something beds almost never do: it lifted, ever so gently, and became a little boat.",
            "The boat drifted out the window and into the soft dark, which was friendly and cozy, like being tucked in by the whole sky. {companion} sat at the front, and {comfort} made the perfect pillow.",
            "They sailed past {setting}, where everything was already asleep. The waves — or were they clouds? — rocked the boat slowly. One... two... one... two...",
            "A family of stars came out to watch them pass. The littlest star hummed {sound}, which is the tune stars sing when it is time to rest. {name} hummed along, very quietly.",
            "\"Look,\" whispered {companion}. Ahead, glowing softly, floated {treasure}. It drifted close, dipped politely, and joined them like an old friend who knew the way.",
            "The boat rocked. The stars hummed. {name}'s eyes grew heavy, and heavier, in the nicest possible way — like blankets made of warm quiet.",
            "Slowly, slowly, the little boat turned for home, gliding down through the soft dark, back through the window, and settled — bump — ever so gently, right where a bed should be.",
            "And there was {name}, tucked in snug, {comfort} close by, {companion} already dreaming. The voyage would be there again tomorrow night. Sleep now, little sailor. The stars are humming for you.",
        ],
        settings: [
            "the sleeping lighthouse",
            "the island of pillow-soft sand",
            "the cove where whales dream",
            "the harbor of paper boats",
        ],
        sounds: [
            "mmm-hmm-mmm",
            "loo-loo-loo",
            "hummm",
        ],
        treasures: [
            "a lantern-fish with a nightlight glow",
            "a small cloud shaped like a cat",
            "the Moon's own rowboat",
        ],
        moralVariants: [
            "The quiet dark is a friend who carries us gently to morning.",
            "Rest is a voyage, and every sleeper is a brave sailor.",
        ]
    )

    // MARK: - The Little Lost Friend (animals · friendship)

    static let littleLostFriend = StoryTemplate(
        id: "little-lost-friend",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} and the Little Lost Friend",
            "The Smallest Guest",
            "How {name} Walked the Little One Home",
        ],
        pages: [
            "Just before bedtime, {name} heard the smallest sound in the world coming from the doorstep: {sound}. {name} and {companion} peeked outside.",
            "There, no bigger than a teacup, sat a little creature with big round eyes. It was lost. Its home was all the way past {setting}, and the evening was getting deeper.",
            "\"Don't worry,\" said {name}, in the gentle voice used for very small things. \"We'll walk you home.\" {name} brought {comfort} along, because everything is braver with {comfort}.",
            "The little one rode on {companion}'s back, holding on tight. Along the way it sniffled, so {name} told it about {treasure} — and the little one's eyes went wide with wonder, and it forgot all about its worries.",
            "Past {setting} they went, step by soft step. The evening air smelled like grass and stars. The little one began to hum {sound}, but happier now — a going-home sort of hum.",
            "And there it was: a tiny door under a tiny hill, with a warm light inside and a family of little ones waving. The smallest guest hugged {name}'s thumb — which was the biggest hug it could manage.",
            "\"Thank you,\" it squeaked, \"for walking me all the way.\" And it left {name} a gift: one perfect, tiny whisker-tickle on the nose. That is a great honor, among little creatures.",
            "{name} and {companion} walked home under the kind old moon, yawning the whole way. And when {name} climbed into bed with {comfort}, the night felt friendly and full of small, happy homes. Goodnight, {name}.",
        ],
        settings: [
            "the blackberry hedge",
            "the three round stones",
            "the big oak with the crooked branch",
            "the tall grass where the crickets sing",
        ],
        sounds: [
            "peep-peep",
            "squeak",
            "mew",
        ],
        treasures: [
            "the softest moss bed in the whole wood",
            "a pantry full of honeyberries",
            "a nightlight made from a captured sunbeam",
        ],
        moralVariants: [
            "Helping someone home is the warmest way to end a day.",
            "No kindness is small when you are small.",
        ]
    )
}
