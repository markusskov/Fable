import Foundation

/// The shipped story library. Grows over time; templates are permanent
/// editorial assets (seasonal collections will build on this format).
enum TemplateLibrary {
    static let all: [StoryTemplate] = [lanternPath, sleepyVoyage, littleLostFriend]

    /// Curated shelves by story language. A shelf stays empty until its
    /// templates exist as real editorial work; the engine falls back to
    /// English rather than serve machine-translated prose.
    ///
    /// The Norwegian shelf is an editorial retelling of the English one, not
    /// a literal translation: same arcs and slots, prose written to sound
    /// like a Norwegian parent telling the story. Norwegian typography rule:
    /// no dashes in story prose (owner copy style) — clauses join with
    /// commas and periods instead. Pool phrases are chosen so every slot
    /// agrees grammatically at every call site ({treasure} entries are all
    /// common-gender so «den» can refer to them).
    static let byLanguage: [StoryLanguage: [StoryTemplate]] = [
        .english: all,
        .norwegianBokmal: [lanternPathNb, sleepyVoyageNb, littleLostFriendNb],
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

    // MARK: - Lyktestien (nb · adventure · magic)

    static let lanternPathNb = StoryTemplate(
        id: "lantern-path-nb",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} og lyktestien",
            "Natten ildfluene kom til {name}",
            "{name} og den lille lysstien",
        ],
        pages: [
            "En kveld, akkurat da himmelen fikk samme farge som blåbær, fikk {name} øye på et bitte lite lys som blafret utenfor vinduet. Så ett til. Og enda ett. Ildfluer! Og det så ut som om de ventet på noen.",
            "{name} listet seg ut sammen med {companion}, med {comfort} trygt i armene. Ildfluene laget en lysende sti, som et bånd av bitte små lykter, og stien buktet seg bort mot {setting}.",
            "Stien var myk under føttene til {name}, og natten var lun og vennlig. Et sted langt borte hørtes {sound}, en søvnig, mild lyd, som om hele verden gjespet.",
            "Ved enden av lyktestien, gjemt under en moserot, fant de den: {treasure}. Den lyste svakt, som om den hadde ventet lenge, lenge på å bli funnet.",
            "«Den har falt ned fra himmelen», hvisket {companion}. «Den lengter nok hjem.» {name} løftet den opp, forsiktig, forsiktig. Den var varm, som et lite hjerte som banket.",
            "Så løftet {name} den høyt, høyere, så høyt som armer kan nå. Og ildfluene samlet seg under den og bar den opp, opp, opp, helt til den la seg til rette på himmelen, akkurat der den hørte hjemme.",
            "Himmelen blunket takk. Ildfluene bukket med de små lysene sine. Og {name} kjente seg med ett riktig søvnig, på den gode måten, slik man blir etter en dag full av undere.",
            "Hjemme igjen krøp {name} under dyna med {comfort}, og {companion} la seg tett inntil. Utenfor ble én ildflue igjen ved vinduet og holdt vakt. God natt, {name}. I natt smiler himmelen til deg.",
        ],
        settings: [
            "den gamle hageporten",
            "den hviskende bjørkeskogen",
            "engen bak haugen",
            "den lille bekken med de blanke steinene",
        ],
        sounds: [
            "uhu",
            "sj-sj-sjjj",
            "prrrl",
        ],
        treasures: [
            "en bitte liten stjerne",
            "en månestråle i et syltetøyglass",
            "en sølvbjelle som bare ringer for snille hjerter",
        ],
        moralVariants: [
            "Snille hender finner veien hjem, og det gjør det de bærer på også.",
            "Selv små hjelpere kan lyse opp en hel himmel.",
        ]
    )

    // MARK: - Den søvnige seilasen (nb · space · ocean)

    static let sleepyVoyageNb = StoryTemplate(
        id: "sleepy-voyage-nb",
        themes: [.space, .ocean],
        titleVariants: [
            "{name} og den søvnige seilasen",
            "Båten av månelys",
            "{name} og de nynnende stjernene",
        ],
        pages: [
            "Da huset ble stille og lysene ble dempet, gjorde sengen til {name} noe senger nesten aldri gjør: Den løftet seg, ganske forsiktig, og ble til en liten båt.",
            "Båten gled ut av vinduet og inn i det myke mørket, som var vennlig og lunt, som å bli tullet godt inn av hele himmelen. Forrest i båten satt {companion}, og {comfort} ble den fineste puten.",
            "De seilte forbi {setting}, der alt allerede sov. Bølgene, eller var det kanskje skyer, vugget båten sakte. Én... to... én... to...",
            "En familie av stjerner kom ut for å se dem seile forbi. Den aller minste stjernen nynnet {sound}, den melodien stjerner synger når det er på tide å hvile. {name} nynnet med, helt stille.",
            "«Se», hvisket {companion}. Der fremme, i et mykt lys, fløt {treasure}. Den kom nærmere, nikket høflig, og ble med dem videre, som en gammel venn som kjente veien.",
            "Båten vugget. Stjernene nynnet. Øyelokkene til {name} ble tunge, og enda tyngre, på den aller fineste måten, som tepper laget av varm stillhet.",
            "Sakte, sakte snudde den lille båten hjemover, gled ned gjennom det myke mørket, inn gjennom vinduet igjen, og landet, dump, ganske forsiktig, akkurat der en seng skal stå.",
            "Og der lå {name}, godt inntullet, med {comfort} like ved, mens {companion} allerede drømte. Seilasen ventet der igjen i morgen kveld. Sov godt nå, lille seiler. Stjernene nynner for deg, {name}.",
        ],
        settings: [
            "det sovende fyrtårnet",
            "øya med den putemyke sanden",
            "vika der hvalene drømmer",
            "havnen med de små papirbåtene",
        ],
        sounds: [
            "so-ro-so-ro",
            "lu-lu-lu",
            "mmm-hmm-mmm",
        ],
        treasures: [
            "en lyktefisk med sitt eget lille nattlys",
            "en liten sky formet som en katt",
            "månens egen robåt",
        ],
        moralVariants: [
            "Det stille mørket er en venn som bærer oss varsomt til morgenen.",
            "Søvnen er en seilas, og alle som sover er tapre små seilere.",
        ]
    )

    // MARK: - Den lille bortkomne vennen (nb · animals · friendship)

    static let littleLostFriendNb = StoryTemplate(
        id: "little-lost-friend-nb",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} og den lille bortkomne vennen",
            "Den aller minste gjesten",
            "Da {name} fulgte den lille hjem",
        ],
        pages: [
            "Rett før leggetid hørte {name} den aller minste lyden i verden fra trappen utenfor: {sound}. {name} og {companion} tittet forsiktig ut.",
            "Der, ikke større enn en tekopp, satt et lite vesen med store, runde øyne. Det hadde gått seg bort. Hjemmet lå helt borte ved {setting}, og kvelden ble dypere og dypere.",
            "«Bare rolig», sa {name} med den milde stemmen man bruker til veldig små ting. «Vi følger deg hjem.» {name} tok med {comfort}, for alt kjennes litt modigere med {comfort}.",
            "Den lille fikk ri på ryggen til {companion} og holdt seg godt fast. Underveis snufset den litt, så {name} fortalte om {treasure}. Da ble de runde øynene enda rundere av undring, og den glemte helt at den hadde vært lei seg.",
            "Forbi {setting} gikk de, skritt for myke skritt. Kveldsluften luktet gress og stjerner. Den lille begynte å nynne {sound}, men gladere nå, slik man nynner når man er på vei hjem.",
            "Og der var det: en bitte liten dør under en bitte liten haug, med varmt lys innenfor og en familie av små som vinket. Den minste gjesten klemte tommelen til {name}, og det var den største klemmen den fikk til.",
            "«Takk», pep den, «for at du fulgte meg helt hjem.» Og den ga {name} en gave: en bitte liten kiling på nesetippen med værhårene sine. Slikt er en stor ære blant små vesener.",
            "{name} og {companion} ruslet hjem under den snille, gamle månen og gjespet hele veien. Og da {name} krøp opp i sengen med {comfort}, kjentes natten vennlig og full av små, glade hjem. God natt, {name}.",
        ],
        settings: [
            "bjørnebærhekken",
            "de tre runde steinene",
            "den store eika med den skjeve grenen",
            "det høye gresset der sirissene synger",
        ],
        sounds: [
            "pip-pip",
            "piip",
            "mjau",
        ],
        treasures: [
            "den mykeste mosesengen i hele skogen",
            "et spiskammer fullt av honningbær",
            "et nattlys laget av en innfanget solstråle",
        ],
        moralVariants: [
            "Å følge noen hjem er den varmeste måten å avslutte en dag på.",
            "Ingen snillhet er liten når du selv er liten.",
        ]
    )
}
