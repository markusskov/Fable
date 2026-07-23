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
    /// German shelf discipline (German declines articles, the others don't):
    /// {companion} and {comfort} appear only where the nominative form a
    /// parent naturally types stays correct — subject positions, appositions
    /// like "{comfort} ganz nah" — never after case-governing prepositions.
    /// {setting} sites all govern the dative, and the pool entries bake the
    /// dative article in. {treasure} entries are introduced by colon
    /// apposition (nominative) and referred back to by a fixed epithet or a
    /// per-template uniform pronoun, so genders never disagree.
    /// Spanish shelf discipline (no cases, but contractions and gender):
    /// {setting} pools bake the article and sit only behind prepositions
    /// that never contract (hacia, hasta, por, en, tras) — "a {setting}" or
    /// "de {setting}" would demand "al"/"del" and read broken. {companion}
    /// and {comfort} appear as subjects, after "con", or in verbless
    /// appositions; no participle or adjective ever agrees with a slot, so
    /// whatever gender a parent types stays correct. {treasure} pools are
    /// uniformly feminine where the prose refers back with "la", or referred
    /// back by the fixed epithet "aquel visitante silencioso".
    static let byLanguage: [StoryLanguage: [StoryTemplate]] = [
        .english: all,
        .norwegianBokmal: [lanternPathNb, sleepyVoyageNb, littleLostFriendNb],
        .german: [lanternPathDe, sleepyVoyageDe, littleLostFriendDe],
        .spanish: [lanternPathEs, sleepyVoyageEs, littleLostFriendEs],
        .french: [lanternPathFr, sleepyVoyageFr, littleLostFriendFr],
        .italian: [lanternPathIt, sleepyVoyageIt, littleLostFriendIt],
        .portugueseBrazilian: [lanternPathPt, sleepyVoyagePt, littleLostFriendPt],
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

    // MARK: - Der Laternenpfad (de · adventure · magic)

    static let lanternPathDe = StoryTemplate(
        id: "lantern-path-de",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} und der Laternenpfad",
            "Die Nacht, in der die Glühwürmchen zu {name} kamen",
            "{name} und die kleinen Lichter",
        ],
        pages: [
            "Eines Abends, gerade als der Himmel die Farbe von Blaubeeren annahm, entdeckte {name} ein winziges Licht, das vor dem Fenster auf und ab tanzte. Dann noch eins. Und noch eins. Glühwürmchen! Und es sah ganz so aus, als warteten sie auf jemanden.",
            "{name} schlich leise hinaus, {comfort} fest im Arm, und {companion} kam natürlich mit. Die Glühwürmchen bildeten einen leuchtenden Pfad, wie ein Band aus winzigen Laternen, und der Pfad schlängelte sich hinüber zu {setting}.",
            "Der Weg fühlte sich ganz weich an unter den Füßen von {name}, und die Nacht war lau und freundlich. Irgendwo weit draußen machte es {sound}, ein schläfriger, sanfter Laut, so als würde die ganze Welt einmal tief gähnen.",
            "Am Ende des Laternenpfads, gut versteckt unter einer moosigen Wurzel, da lag er, still und geduldig: {treasure}. Er glomm ganz leise, als hätte er lange, lange darauf gewartet, endlich gefunden zu werden.",
            "„Er ist vom Himmel gefallen“, flüsterte {companion}. „Bestimmt hat er Heimweh.“ {name} hob ihn auf, ganz vorsichtig, ganz behutsam. Er war warm, wie ein kleines Herz, das leise klopfte.",
            "Da hob {name} ihn hoch, höher, so hoch kleine Arme eben reichen. Und die Glühwürmchen sammelten sich darunter und trugen ihn hinauf, hinauf, hinauf, bis er sich wieder an den Himmel schmiegte, genau an seinen Platz.",
            "Der Himmel funkelte ein Dankeschön. Die Glühwürmchen verneigten sich mit ihren kleinen Lichtern. Und {name} wurde auf einmal wunderbar müde, auf die gute Art, so wie nach einem Tag voller Wunder.",
            "Zu Hause kuschelte sich {name} unter die Bettdecke, {comfort} ganz nah, und {companion} rollte sich dicht daneben zusammen. Draußen blieb ein einzelnes Glühwürmchen am Fenster und hielt Wache. Gute Nacht, {name}. Der Himmel lächelt dir heute Nacht zu.",
        ],
        settings: [
            "dem alten Gartentor",
            "dem flüsternden Birkenwäldchen",
            "der Wiese hinter dem Hügel",
            "dem kleinen Bach mit den runden, glatten Steinen",
        ],
        sounds: [
            "schuhu",
            "sch-sch-schhh",
            "prrrl",
        ],
        treasures: [
            "ein kleiner gefallener Stern",
            "ein Mondstrahl in einem Marmeladenglas",
            "ein kleiner Mondkristall, der nur für freundliche Herzen leuchtet",
        ],
        moralVariants: [
            "Freundliche Hände finden den Weg nach Hause, und alles, was sie tragen, findet ihn mit.",
            "Auch kleine Helfer können einen ganzen Himmel zum Leuchten bringen.",
        ]
    )

    // MARK: - Die schläfrige Bootsfahrt (de · space · ocean)

    static let sleepyVoyageDe = StoryTemplate(
        id: "sleepy-voyage-de",
        themes: [.space, .ocean],
        titleVariants: [
            "{name} und die schläfrige Bootsfahrt",
            "Das Boot aus Mondlicht",
            "{name} und die summenden Sterne",
        ],
        pages: [
            "Als das Haus still wurde und die Lichter leise wurden, tat das Bett von {name} etwas, das Betten sonst fast nie tun: Es hob sich, ganz sachte, und wurde ein kleines Boot.",
            "Das Boot glitt aus dem Fenster hinaus in das weiche Dunkel, das freundlich und behaglich war, so als würde einen der ganze Himmel zudecken. Vorne im Boot saß {companion}, und {comfort} wurde das allerbeste Kissen.",
            "Sie segelten an {setting} vorbei, wo alles schon schlief. Die Wellen, oder waren es vielleicht Wolken, wiegten das Boot ganz langsam. Eins... zwei... eins... zwei...",
            "Eine Familie von Sternen kam heraus, um sie vorbeiziehen zu sehen. Der allerkleinste Stern summte {sound}, jene Melodie, die Sterne singen, wenn es Zeit zum Ausruhen ist. {name} summte ganz leise mit.",
            "„Schau“, flüsterte {companion}. Dort vorn, in einem weichen Licht, schwebte {treasure}. Ganz sacht kam der stille Gast näher, nickte höflich und blieb einfach bei ihnen, wie ein alter Freund, der den Weg kannte.",
            "Das Boot wiegte sich. Die Sterne summten. Die Augen von {name} wurden schwer und noch ein bisschen schwerer, auf die allerschönste Art, wie Decken aus warmer Stille.",
            "Langsam, ganz langsam drehte das kleine Boot heimwärts, glitt hinab durch das weiche Dunkel, zurück durch das Fenster, und landete, plumps, ganz sanft, genau dort, wo ein Bett stehen soll.",
            "Und da lag {name}, warm zugedeckt, {comfort} gleich daneben, während {companion} schon träumte. Die Reise würde morgen Abend wieder dort warten. Schlaf gut, {name}. Die Sterne summen für dich.",
        ],
        settings: [
            "dem schlafenden Leuchtturm",
            "der Insel mit dem kissenweichen Sand",
            "der Bucht, in der die Wale träumen",
            "dem Hafen der Papierboote",
        ],
        sounds: [
            "mmh-mmh-mmh",
            "lu-lu-lu",
            "summm",
        ],
        treasures: [
            "ein Laternenfisch mit einem eigenen kleinen Nachtlicht",
            "eine kleine Wolke, die aussah wie eine Katze",
            "das Ruderboot des Mondes",
        ],
        moralVariants: [
            "Das stille Dunkel ist ein Freund, der uns sanft bis zum Morgen trägt.",
            "Schlafen ist eine Reise, und alle, die schlafen, sind mutige kleine Reisende.",
        ]
    )

    // MARK: - Der kleine verlorene Freund (de · animals · friendship)

    static let littleLostFriendDe = StoryTemplate(
        id: "little-lost-friend-de",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} und der kleine verlorene Freund",
            "Der allerkleinste Gast",
            "Wie {name} den kleinen Gast nach Hause brachte",
        ],
        pages: [
            "Kurz vor dem Schlafengehen hörte {name} das allerkleinste Geräusch der Welt, und es kam von der Türschwelle: {sound}. {name} und {companion} schauten vorsichtig nach draußen.",
            "Dort, nicht größer als eine Teetasse, saß ein kleines Wesen mit großen, runden Augen. Es hatte sich verlaufen. Sein Zuhause lag ein ganzes Stück hinter {setting}, und der Abend wurde tiefer und tiefer.",
            "„Keine Sorge“, sagte {name} mit der sanften Stimme, die man für sehr kleine Dinge benutzt. „Wir bringen dich nach Hause.“ Und natürlich kam auch {comfort} mit, denn mit etwas Vertrautem an der Seite fühlt sich jeder Weg ein bisschen leichter an.",
            "Der kleine Gast durfte reiten, denn {companion} trug ihn gern auf dem Rücken, und er hielt sich gut fest. Unterwegs schniefte er ein bisschen, und da erzählte {name} leise, was zu Hause auf kleine Gäste wartet: {treasure}. Die runden Augen wurden noch runder vor Staunen, und alles Schniefen war vergessen.",
            "An {setting} vorbei gingen sie, Schritt für leisen Schritt. Die Abendluft roch nach Gras und Sternen. Der kleine Gast begann {sound} zu summen, aber fröhlicher jetzt, so wie man eben summt, wenn man auf dem Weg nach Hause ist.",
            "Und dann war es da: eine winzige Tür unter einem winzigen Hügel, mit warmem Licht dahinter und einer Familie aus lauter Kleinen, die winkten. Der allerkleinste Gast umarmte den Daumen von {name}, und das war die größte Umarmung, die er zustande brachte.",
            "„Danke“, piepste er, „dass ihr mich den ganzen Weg nach Hause gebracht habt.“ Und er ließ ein Geschenk da: ein winziges Schnurrhaarkitzeln auf der Nasenspitze von {name}. So etwas ist eine große Ehre unter kleinen Wesen.",
            "{name} und {companion} spazierten unter dem freundlichen alten Mond nach Hause und gähnten den ganzen Weg. Und als {name} ins Bett kroch, {comfort} ganz fest im Arm, da fühlte sich die Nacht freundlich an und voller kleiner, glücklicher Zuhause. Gute Nacht, {name}.",
        ],
        settings: [
            "der Brombeerhecke",
            "den drei runden Steinen",
            "der großen Eiche mit dem schiefen Ast",
            "dem hohen Gras, in dem die Grillen singen",
        ],
        sounds: [
            "piep-piep",
            "fiep",
            "miau",
        ],
        treasures: [
            "das weichste Moosbett im ganzen Wald",
            "eine Speisekammer voller Honigbeeren",
            "ein Nachtlicht aus einem eingefangenen Sonnenstrahl",
        ],
        moralVariants: [
            "Jemanden nach Hause zu bringen ist der wärmste Abschluss für einen Tag.",
            "Keine Freundlichkeit ist klein, wenn man selbst klein ist.",
        ]
    )

    // MARK: - El sendero de farolillos (es · adventure · magic)

    static let lanternPathEs = StoryTemplate(
        id: "lantern-path-es",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} y el sendero de farolillos",
            "La noche en que las luciérnagas vinieron a buscar a {name}",
            "{name} y las lucecitas",
        ],
        pages: [
            "Un atardecer, justo cuando el cielo se puso del color de los arándanos, {name} vio una lucecita diminuta que bailaba al otro lado de la ventana. Luego otra. Y otra más. ¡Luciérnagas! Y parecía que estaban esperando a alguien.",
            "{name} salió de puntillas con {companion}, llevando {comfort} muy cerquita. Las luciérnagas formaban un sendero brillante, como una cinta de farolillos diminutos, que serpenteaba hacia {setting}.",
            "El sendero era blandito bajo los pies de {name}, y la noche era tibia y amable. En algún lugar muy lejano se oyó {sound}, un sonido suave y dormilón, como si el mundo entero bostezara.",
            "Al final del sendero de farolillos, escondida bajo una raíz con musgo, allí estaba, quietecita y paciente: {treasure}. Brillaba muy despacito, como si llevara mucho, mucho tiempo esperando a que alguien la encontrara.",
            "«Se ha caído del cielo», susurró {companion}. «Seguro que echa de menos su casa.» {name} la levantó con muchísimo cuidado. Estaba calentita, como un corazoncito que late bajito.",
            "Entonces {name} la alzó bien alto, más alto, tan alto como llegan los brazos. Y las luciérnagas se juntaron debajo y la llevaron arriba, arriba y más arriba, hasta que se acomodó otra vez en el cielo, justo en su sitio.",
            "El cielo parpadeó para dar las gracias. Las luciérnagas hicieron una reverencia con sus lucecitas. Y de pronto {name} sintió muchísimo sueño, del bueno, como el que llega después de un día lleno de maravillas.",
            "Ya en casa, {name} se metió bajo las mantas con {comfort}, y {companion} se acurrucó muy cerca. Fuera, una luciérnaga se quedó junto a la ventana, montando guardia. Buenas noches, {name}. Esta noche el cielo te sonríe.",
        ],
        settings: [
            "el viejo portón del jardín",
            "el bosquecillo de abedules que susurran",
            "el prado detrás de la colina",
            "el arroyo de las piedras lisas",
        ],
        sounds: [
            "uu-uh",
            "chss-chss-chsss",
            "prrrl",
        ],
        treasures: [
            "una estrellita caída",
            "una lucecita de luna guardada en un tarro de cristal",
            "una campanilla de plata que solo suena para los corazones buenos",
        ],
        moralVariants: [
            "Las manos bondadosas encuentran el camino a casa, y también lo encuentra todo lo que llevan.",
            "Hasta los ayudantes más pequeños pueden iluminar el cielo entero.",
        ]
    )

    // MARK: - El viaje dormilón (es · space · ocean)

    static let sleepyVoyageEs = StoryTemplate(
        id: "sleepy-voyage-es",
        themes: [.space, .ocean],
        titleVariants: [
            "{name} y el viaje dormilón",
            "El barquito de luz de luna",
            "{name} y las estrellas que tarareaban",
        ],
        pages: [
            "Cuando la casa se quedó en silencio y las luces se volvieron suavecitas, la cama de {name} hizo algo que las camas casi nunca hacen: se levantó despacito, muy despacito, y se convirtió en un barquito.",
            "El barquito salió flotando por la ventana hacia la oscuridad blandita, que era amable y acogedora, como si el cielo entero te arropara. Delante iba {companion}, y {comfort} se convirtió en la almohada perfecta.",
            "Pasaron navegando por {setting}, donde todo dormía ya. Las olas, ¿o quizá eran nubes?, mecían el barquito despacio. Un... dos... un... dos...",
            "Una familia de estrellas salió a verlos pasar. La estrella más pequeñita tarareaba {sound}, esa melodía que cantan las estrellas cuando llega la hora de descansar. {name} tarareó con ella, muy bajito.",
            "«Mira», susurró {companion}. Allí delante, en medio de una luz suave, flotaba {treasure}. Aquel visitante silencioso se acercó despacito, saludó con mucha educación y se quedó con ellos, como un viejo amigo que conocía el camino.",
            "El barquito se mecía. Las estrellas tarareaban. Los ojos de {name} se fueron poniendo pesados, y un poquito más pesados, de la manera más bonita, como mantas hechas de silencio calentito.",
            "Despacio, muy despacio, el barquito dio la vuelta hacia casa, bajó planeando por la oscuridad blandita, entró otra vez por la ventana y aterrizó, pluf, con muchísima suavidad, justo donde debe estar una cama.",
            "Y allí estaba {name}, ya en su camita, con {comfort} al ladito, mientras {companion} ya soñaba. El viaje estaría esperando otra vez mañana por la noche. A dormir, que las estrellas tararean para ti, {name}.",
        ],
        settings: [
            "el faro dormido",
            "la isla de arena blandita como una almohada",
            "la cala donde sueñan las ballenas",
            "el puerto de los barquitos de papel",
        ],
        sounds: [
            "mmm-hmm-mmm",
            "lu-lu-lu",
            "nanita-nana",
        ],
        treasures: [
            "un pececito farol con su propia lucecita de noche",
            "una nubecita con forma de gato",
            "la barca de remos de la Luna",
        ],
        moralVariants: [
            "La oscuridad tranquila es una amiga que nos lleva con suavidad hasta la mañana.",
            "Dormir es un viaje, y quien duerme zarpa cada noche con mucha valentía.",
        ]
    )

    // MARK: - El amiguito perdido (es · animals · friendship)

    static let littleLostFriendEs = StoryTemplate(
        id: "little-lost-friend-es",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} y el amiguito perdido",
            "El invitado más pequeñito",
            "La noche en que {name} acompañó a casa al amiguito",
        ],
        pages: [
            "Justo antes de irse a la cama, {name} oyó el sonido más pequeñito del mundo, y venía de la puerta de casa: {sound}. {name} y {companion} se asomaron con mucho cuidado.",
            "Allí, no más grande que una taza de té, había un animalito de ojos grandes y redondos. Se había perdido. Su casa quedaba lejos, tras {setting}, y la noche se hacía cada vez más honda.",
            "«No te preocupes», dijo {name} con esa voz suave que se usa para las cosas muy pequeñas. «Te acompañamos a casa.» Y claro que {comfort} también vino, porque con algo querido al lado el camino se hace más fácil.",
            "El pequeño invitado pudo ir montado, porque {companion} lo llevó sobre el lomo, y él se agarró bien fuerte. Por el camino soltó algún puchero, así que {name} le contó lo que espera en casa a los invitados pequeños: {treasure}. Los ojos redondos se le pusieron aún más redondos de asombro, y las penas se le olvidaron del todo.",
            "Pasaron por {setting}, pasito a pasito, muy despacio. El aire de la noche olía a hierba y a estrellas. El pequeño invitado se puso a tararear {sound}, pero ahora más contento, como se tararea cuando por fin se va camino de casa.",
            "Y de repente allí estaba: una puerta chiquitita bajo una colina chiquitita, con una luz calentita dentro y toda una familia de pequeñines saludando. El invitado más pequeñito abrazó el pulgar de {name}, que era el abrazo más grande que sabía dar.",
            "«Gracias», dijo con su vocecita, «por acompañarme hasta casa.» Y dejó un regalo: unas cosquillas diminutas de bigotes en la punta de la nariz de {name}. Eso, entre los animalitos pequeños, es un honor muy grande.",
            "{name} y {companion} volvieron a casa paseando bajo la luna vieja y amable, bostezando todo el camino. Y cuando {name} se metió en la cama con {comfort}, la noche entera se sintió amiga y llena de casitas pequeñas y felices. Buenas noches, {name}.",
        ],
        settings: [
            "el seto de moras",
            "las tres piedras redondas",
            "el gran roble de la rama torcida",
            "la hierba alta donde cantan los grillos",
        ],
        sounds: [
            "pío-pío",
            "iiip",
            "miau",
        ],
        treasures: [
            "el lecho de musgo más blandito de todo el bosque",
            "una despensa llena de bayas de miel",
            "una lucecita de noche hecha con un rayito de sol atrapado",
        ],
        moralVariants: [
            "Acompañar a alguien a casa es la manera más bonita de terminar el día.",
            "Ninguna bondad es pequeña cuando quien la da también es pequeño.",
        ]
    )


    // MARK: - Le sentier des lanternes (fr · adventure · magic)
    //
    // French slot discipline: settings carry their own article and are only
    // ever reached with "vers" or "devant" (no à/de contractions, which
    // would demand au/du and read broken). {companion} and {comfort} appear
    // as subjects, after "avec", or in verbless appositions, so whatever
    // gender a parent types stays correct. Treasure pools that the prose
    // refers back to are uniformly feminine ("elle"); the lost-friend pool
    // is only ever mentioned, never pronouned.

    static let lanternPathFr = StoryTemplate(
        id: "lantern-path-fr",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} et le sentier des lanternes",
            "La nuit où les lucioles vinrent chercher {name}",
            "{name} et les petites lumières",
        ],
        pages: [
            "Un soir, juste au moment où le ciel prenait la couleur des myrtilles, {name} aperçut une petite lumière qui dansait derrière la fenêtre. Puis une autre. Et encore une autre. Des lucioles ! Et on aurait dit qu'elles attendaient quelqu'un.",
            "{name} sortit sur la pointe des pieds, serrant {comfort} tout contre soi, et {companion} vint aussi, bien sûr. Les lucioles dessinaient un chemin lumineux, comme un ruban de toutes petites lanternes, qui serpentait vers {setting}.",
            "Le chemin était doux sous les pieds de {name}, et la nuit était tiède et amicale. Quelque part au loin, on entendit {sound}, un son doux et ensommeillé, comme si le monde entier bâillait tout doucement.",
            "Au bout du sentier des lanternes, blottie sous une racine couverte de mousse, elle était là : {treasure}. Elle luisait faiblement, comme si elle avait attendu très, très longtemps qu'on vienne la trouver.",
            "« Elle est tombée du ciel », chuchota {companion}. « Elle doit avoir le mal du pays. » {name} la ramassa avec mille précautions. Elle était tiède, comme un petit cœur qui battait doucement.",
            "Alors {name} la souleva haut, très haut, aussi haut que peuvent monter de petits bras. Et les lucioles se rassemblèrent dessous et la portèrent, plus haut, encore plus haut, jusqu'à ce qu'elle retrouve sa place exacte dans le ciel.",
            "Le ciel scintilla pour dire merci. Les lucioles s'inclinèrent avec leurs petites lumières. Et {name} se sentit soudain merveilleusement fatigué, de la bonne fatigue, celle qui vient après une journée pleine de merveilles.",
            "De retour à la maison, {name} se glissa sous la couette, {comfort} tout près, et {companion} se roula en boule juste à côté. Dehors, une luciole resta près de la fenêtre pour veiller. Bonne nuit, {name}. Cette nuit, le ciel te sourit.",
        ],
        settings: [
            "le vieux portail du jardin",
            "le petit bois de bouleaux qui chuchotent",
            "la prairie derrière la colline",
            "le ruisseau aux pierres lisses et rondes",
        ],
        sounds: [
            "hou-hou",
            "chuuut-chuuut",
            "prrrl",
        ],
        treasures: [
            "une petite étoile tombée du ciel",
            "une lueur de lune enfermée dans un bocal",
            "une petite clochette d'argent qui ne tinte que pour les cœurs doux",
        ],
        moralVariants: [
            "Les mains douces retrouvent toujours le chemin de la maison, et ce qu'elles portent le retrouve avec elles.",
            "Même les tout petits peuvent faire briller un ciel tout entier.",
        ]
    )

    // MARK: - Le voyage ensommeillé (fr · space · ocean)

    static let sleepyVoyageFr = StoryTemplate(
        id: "sleepy-voyage-fr",
        themes: [.space, .ocean],
        titleVariants: [
            "Le voyage ensommeillé de {name}",
            "Le bateau fait de clair de lune",
            "{name} et les étoiles qui fredonnent",
        ],
        pages: [
            "Quand la maison devint toute silencieuse et que les lumières se firent toutes petites, le lit de {name} fit une chose que les lits ne font presque jamais : il se souleva, tout doucement, et devint un petit bateau.",
            "Le bateau glissa par la fenêtre et s'en alla dans la douce obscurité, qui n'avait rien d'inquiétant du tout. Elle était douillette, comme si le ciel entier vous bordait. {companion} s'installa à l'avant, et {comfort} fit un oreiller parfait.",
            "Ils voguèrent devant {setting}, où tout dormait déjà. Les vagues, à moins que ce ne soient des nuages, berçaient le bateau lentement. Une… deux… une… deux…",
            "Une famille d'étoiles sortit pour les regarder passer. La plus petite des étoiles fredonnait {sound}, la chanson que chantent les étoiles quand vient l'heure de se reposer. {name} fredonna aussi, tout bas.",
            "« Regarde », chuchota {companion}. Devant eux, brillant doucement, flottait {treasure}. Cette douce visiteuse s'approcha, salua poliment, et fit route avec eux, comme une vieille amie qui connaissait le chemin.",
            "Le bateau se balançait. Les étoiles fredonnaient. Les yeux de {name} devenaient lourds, de plus en plus lourds, de la plus agréable des façons, comme des couvertures faites de chaud silence.",
            "Lentement, lentement, le petit bateau prit le chemin du retour, glissant à travers la douce obscurité, repassant par la fenêtre, pour se poser, tout doucement, exactement là où doit se trouver un lit.",
            "Et voilà {name}, bien bordé, {comfort} tout près, {companion} déjà en train de rêver. Le voyage serait encore là demain soir. Dors maintenant, petit marin. Bonne nuit, {name}, les étoiles fredonnent pour toi.",
        ],
        settings: [
            "le phare endormi",
            "l'île au sable doux comme un oreiller",
            "la crique où rêvent les baleines",
            "le port des bateaux en papier",
        ],
        sounds: [
            "mmm-hmm-mmm",
            "lou-lou-lou",
            "hummm",
        ],
        treasures: [
            "une petite lampe-poisson au doux éclat",
            "une barque minuscule que la Lune avait prêtée",
            "une luciole de mer au ventre doré",
        ],
        moralVariants: [
            "La douce obscurité est une amie qui nous porte doucement jusqu'au matin.",
            "Dormir est un voyage, et chaque dormeur est un brave petit marin.",
        ]
    )

    // MARK: - Le petit ami perdu (fr · animals · friendship)

    static let littleLostFriendFr = StoryTemplate(
        id: "little-lost-friend-fr",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} et le petit ami perdu",
            "Le tout petit invité",
            "Le soir où {name} raccompagna le petit perdu",
        ],
        pages: [
            "Juste avant l'heure du coucher, {name} entendit le plus petit bruit du monde venir du pas de la porte : {sound}. {name} et {companion} allèrent regarder tout doucement.",
            "Là, pas plus grand qu'une tasse à thé, se tenait un petit être aux grands yeux tout ronds. Il était perdu. Sa maison se trouvait de l'autre côté, passé {setting}, et le soir devenait de plus en plus profond.",
            "« Ne t'en fais pas », dit {name} de la voix douce qu'on garde pour les toutes petites choses. « Nous allons te raccompagner. » {name} emporta {comfort}, parce que tout est plus facile avec {comfort}.",
            "Le tout petit grimpa sur le dos de {companion} et se tint bien fort. En chemin, il renifla un peu, alors {name} lui parla de {treasure}. Les yeux du petit s'arrondirent d'émerveillement, et ses soucis s'envolèrent.",
            "Ils passèrent devant {setting}, pas à pas, tout doucement. L'air du soir sentait l'herbe et les étoiles. Le tout petit se mit à fredonner {sound}, mais plus joyeusement maintenant, un fredon de retour à la maison.",
            "Et la voilà : une porte minuscule sous une colline minuscule, avec une lumière chaude à l'intérieur et une famille de tout-petits qui faisaient coucou. Le plus petit des invités serra le pouce de {name} très fort. C'était le plus grand câlin qu'il pouvait faire.",
            "« Merci », couina-t-il, « de m'avoir raccompagné jusqu'au bout. » Et il laissa un cadeau à {name} : une toute petite caresse de moustaches sur le bout du nez. C'est un très grand honneur, chez les petits êtres.",
            "{name} et {companion} rentrèrent à la maison sous la bonne vieille lune, en bâillant tout du long. Et quand {name} se glissa dans son lit avec {comfort}, la nuit semblait amicale et pleine de petites maisons heureuses. Bonne nuit, {name}.",
        ],
        settings: [
            "la haie aux mûres",
            "les trois pierres rondes",
            "le grand chêne à la branche tordue",
            "les herbes hautes où chantent les grillons",
        ],
        sounds: [
            "pip-pip",
            "couic",
            "miou",
        ],
        treasures: [
            "le lit de mousse le plus doux de toute la forêt",
            "un garde-manger rempli de baies au miel",
            "une veilleuse faite d'un rayon de soleil apprivoisé",
        ],
        moralVariants: [
            "Raccompagner quelqu'un chez lui, c'est la plus chaleureuse façon de finir la journée.",
            "Aucune gentillesse n'est petite quand on est petit.",
        ]
    )


    // MARK: - Il sentiero delle lanterne (it · adventure · magic)
    //
    // Italian slot discipline: a/di/da/in/su always contract with articles
    // (al, del, nel), so {setting} pools bake the article and appear only
    // behind "verso"/"oltre" or as the object of a transitive verb
    // ("superarono {setting}"). {companion} and {comfort} appear as
    // subjects, after "con", or in verbless appositions. Pronoun-referenced
    // treasure pools are uniformly feminine ("lei/la"); the lost-friend
    // pool is only ever mentioned, never pronouned.

    static let lanternPathIt = StoryTemplate(
        id: "lantern-path-it",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} e il sentiero delle lanterne",
            "La notte in cui le lucciole vennero a cercare {name}",
            "{name} e le piccole luci",
        ],
        pages: [
            "Una sera, proprio mentre il cielo prendeva il colore dei mirtilli, {name} notò una piccola luce che danzava fuori dalla finestra. Poi un'altra. E un'altra ancora. Le lucciole! E sembrava proprio che stessero aspettando qualcuno.",
            "{name} uscì in punta di piedi, stringendo forte {comfort}, e naturalmente venne anche {companion}. Le lucciole disegnavano un sentiero luminoso, come un nastro di piccolissime lanterne, che serpeggiava verso {setting}.",
            "Il sentiero era morbido sotto i piedi di {name}, e la notte era tiepida e gentile. Da qualche parte, lontano lontano, si sentì {sound}, un suono dolce e assonnato, come se il mondo intero stesse sbadigliando piano piano.",
            "In fondo al sentiero delle lanterne, nascosta sotto una radice coperta di muschio, eccola lì: {treasure}. Brillava piano, come se avesse aspettato tanto, tanto tempo che qualcuno venisse a trovarla.",
            "«È caduta dal cielo», sussurrò {companion}. «Deve avere tanta nostalgia di casa.» {name} la raccolse con mille attenzioni. Era tiepida, come un piccolo cuore che batteva piano.",
            "Allora {name} la sollevò in alto, sempre più in alto, in alto quanto possono arrivare due piccole braccia. E le lucciole si raccolsero lì sotto e la portarono su, su, su, finché non ritrovò il suo posto esatto nel cielo.",
            "Il cielo scintillò per dire grazie. Le lucciole si inchinarono con le loro piccole luci. E {name} si sentì all'improvviso meravigliosamente stanco, di quella stanchezza buona che viene dopo una giornata piena di meraviglie.",
            "Tornati a casa, {name} si infilò sotto le coperte, con {comfort} lì vicino, e {companion} si rannicchiò accanto. Fuori, una lucciola rimase alla finestra a fare la guardia. Buonanotte, {name}. Stanotte il cielo ti sorride.",
        ],
        settings: [
            "il vecchio cancello del giardino",
            "il boschetto di betulle che sussurrano",
            "il prato dietro la collina",
            "il ruscello dai sassi lisci e tondi",
        ],
        sounds: [
            "uh-uh",
            "sci-sci-sciii",
            "prrrl",
        ],
        treasures: [
            "una piccola stella caduta dal cielo",
            "una lucina di luna chiusa in un barattolo",
            "una campanellina d'argento che suona solo per i cuori gentili",
        ],
        moralVariants: [
            "Le mani gentili ritrovano sempre la strada di casa, e ciò che portano la ritrova con loro.",
            "Anche i piccoli aiutanti possono far brillare un cielo intero.",
        ]
    )

    // MARK: - Il viaggio assonnato (it · space · ocean)

    static let sleepyVoyageIt = StoryTemplate(
        id: "sleepy-voyage-it",
        themes: [.space, .ocean],
        titleVariants: [
            "Il viaggio assonnato di {name}",
            "La barchetta fatta di luce di luna",
            "{name} e le stelle che canticchiano",
        ],
        pages: [
            "Quando la casa diventò tutta silenziosa e le luci si fecero piccole piccole, il letto di {name} fece una cosa che i letti non fanno quasi mai: si sollevò, piano piano, e diventò una barchetta.",
            "La barchetta scivolò fuori dalla finestra, dentro il buio morbido, che non era per niente preoccupante. Era accogliente, come se tutto il cielo ti rimboccasse le coperte. {companion} si mise a prua, e {comfort} fece da cuscino perfetto.",
            "Navigarono oltre {setting}, dove tutto già dormiva. Le onde, o forse erano nuvole, cullavano la barchetta lentamente. Una… due… una… due…",
            "Una famiglia di stelle uscì a guardarli passare. La stella più piccina canticchiava {sound}, la canzone che cantano le stelle quando arriva l'ora di riposare. Anche {name} canticchiò, pianissimo.",
            "«Guarda», sussurrò {companion}. Davanti a loro, brillando piano, galleggiava {treasure}. Quella dolce visitatrice si avvicinò, salutò con garbo, e si unì al viaggio come una vecchia amica che conosceva la strada.",
            "La barchetta dondolava. Le stelle canticchiavano. Gli occhi di {name} si facevano pesanti, sempre più pesanti, nel modo più piacevole che ci sia, come coperte fatte di silenzio caldo.",
            "Lentamente, lentamente, la barchetta prese la via di casa, scivolando nel buio morbido, ripassando dalla finestra, fino a posarsi, piano piano, esattamente dove deve stare un letto.",
            "Ed ecco {name}, ben rimboccato, con {comfort} lì accanto e {companion} che già sognava. Il viaggio sarebbe stato lì anche domani sera. Dormi adesso, piccolo marinaio. Buonanotte, {name}, le stelle canticchiano per te.",
        ],
        settings: [
            "il faro addormentato",
            "l'isola dalla sabbia soffice come un cuscino",
            "la baia dove sognano le balene",
            "il porto delle barchette di carta",
        ],
        sounds: [
            "mmm-hmm-mmm",
            "lu-lu-lu",
            "hummm",
        ],
        treasures: [
            "una piccola lampada-pesce dal tenue bagliore",
            "una barchetta minuscola prestata dalla Luna",
            "una lucciola di mare dal pancino dorato",
        ],
        moralVariants: [
            "Il buio gentile è un amico che ci porta piano piano fino al mattino.",
            "Riposare è un viaggio, e chi dorme è un piccolo marinaio coraggioso.",
        ]
    )

    // MARK: - Il piccolo amico smarrito (it · animals · friendship)

    static let littleLostFriendIt = StoryTemplate(
        id: "little-lost-friend-it",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} e il piccolo amico smarrito",
            "L'ospite piccolissimo",
            "La sera in cui {name} accompagnò a casa il piccolino",
        ],
        pages: [
            "Poco prima dell'ora della nanna, {name} sentì il rumore più piccolo del mondo arrivare dalla porta di casa: {sound}. {name} e {companion} andarono a guardare piano piano.",
            "Lì, non più grande di una tazzina da tè, c'era un esserino dai grandi occhi tondi. Si era smarrito. La sua casa era dall'altra parte, oltre {setting}, e la sera si faceva sempre più profonda.",
            "«Non preoccuparti», disse {name} con la voce dolce che si usa per le cose piccoline. «Ti accompagniamo noi.» {name} portò con sé {comfort}, perché tutto riesce meglio con {comfort}.",
            "Il piccolino salì sulla schiena di {companion} e si tenne ben stretto. Per strada tirò su col nasino, allora {name} gli raccontò di {treasure}. Gli occhi del piccolino si fecero tondi di meraviglia, e i suoi pensieri volarono via.",
            "Superarono {setting}, un passo dopo l'altro, piano piano. L'aria della sera profumava di erba e di stelle. Il piccolino si mise a canticchiare {sound}, ma più allegramente adesso, un canticchiare da ritorno a casa.",
            "Ed eccola lì: una porticina sotto una collinetta, con una luce calda dentro e una famiglia di piccolini che salutava. L'ospite più piccolo strinse forte il pollice di {name}. Era l'abbraccio più grande che sapesse fare.",
            "«Grazie», squittì, «di avermi accompagnato fino a casa.» E lasciò un regalo a {name}: una piccolissima carezza di baffi sulla punta del naso. È un grandissimo onore, tra gli esserini.",
            "{name} e {companion} tornarono a casa sotto la buona vecchia luna, sbadigliando per tutta la strada. E quando {name} si infilò nel letto con {comfort}, la notte sembrava gentile e piena di piccole case felici. Buonanotte, {name}.",
        ],
        settings: [
            "la siepe delle more",
            "i tre sassi rotondi",
            "la grande quercia dal ramo storto",
            "le erbe alte dove cantano i grilli",
        ],
        sounds: [
            "pip-pip",
            "squit",
            "miao",
        ],
        treasures: [
            "il lettino di muschio più morbido di tutto il bosco",
            "una dispensa piena di bacche al miele",
            "una lucina fatta con un raggio di sole addomesticato",
        ],
        moralVariants: [
            "Accompagnare qualcuno a casa è il modo più caldo di finire la giornata.",
            "Nessuna gentilezza è piccola quando si è piccoli.",
        ]
    )


    // MARK: - A trilha das lanterninhas (pt-BR · adventure · magic)
    //
    // Portuguese slot discipline: a/de/em/por contract with articles (ao,
    // do, na, pela), so {setting} pools bake the article and appear only
    // behind "até" (which never contracts) or as the object of a transitive
    // verb ("cruzaram {setting}"). {companion} and {comfort} appear as
    // subjects, after "com", or in verbless appositions. Pronoun-referenced
    // treasure pools are uniformly feminine ("ela/a"); the lost-friend pool
    // is only ever mentioned, never pronouned. Diminutives carry the
    // Brazilian bedtime register.

    static let lanternPathPt = StoryTemplate(
        id: "lantern-path-pt",
        themes: [.adventure, .magic],
        titleVariants: [
            "{name} e a trilha das lanterninhas",
            "A noite em que os vagalumes vieram buscar {name}",
            "{name} e as luzinhas",
        ],
        pages: [
            "Uma noite, bem na hora em que o céu ficava da cor das amoras, {name} percebeu uma luzinha dançando do lado de fora da janela. Depois outra. E mais outra. Vagalumes! E parecia mesmo que eles estavam esperando alguém.",
            "{name} saiu na ponta dos pés, abraçando {comfort} bem forte, e é claro que {companion} foi junto. Os vagalumes desenhavam uma trilha iluminada, como uma fita de lanterninhas minúsculas, serpenteando até {setting}.",
            "A trilha era macia sob os pés de {name}, e a noite estava morna e amiga. Em algum lugar bem longe, ouviu-se {sound}, um som doce e sonolento, como se o mundo inteiro estivesse bocejando devagarinho.",
            "No fim da trilha das lanterninhas, escondida embaixo de uma raiz coberta de musgo, lá estava ela: {treasure}. Brilhava baixinho, como se tivesse esperado muito, muito tempo para ser encontrada.",
            "«Ela caiu do céu», sussurrou {companion}. «Deve estar com saudade de casa.» {name} pegou a luzinha com todo o cuidado do mundo. Era morna, como um coração pequenino batendo devagar.",
            "Então {name} levantou a estrelinha bem alto, cada vez mais alto, tão alto quanto dois bracinhos conseguem chegar. E os vagalumes se juntaram embaixo e a carregaram para cima, para cima, para cima, até que ela encontrou de novo o seu lugar certinho no céu.",
            "O céu cintilou um obrigado. Os vagalumes fizeram uma reverência com as suas luzinhas. E {name} sentiu de repente um cansaço maravilhoso, daquele cansaço bom que vem depois de um dia cheio de maravilhas.",
            "De volta em casa, {name} se aconchegou embaixo das cobertas, com {comfort} bem pertinho, e {companion} se enroscou logo ao lado. Lá fora, um vagalume ficou na janela, montando guarda. Boa noite, {name}. Hoje o céu sorri para você.",
        ],
        settings: [
            "o portão velho do jardim",
            "o bosquezinho de bétulas que sussurram",
            "o campo atrás da colina",
            "o riachinho das pedras lisas e redondas",
        ],
        sounds: [
            "uh-uh",
            "psiu-psiu-psiuuu",
            "prrrl",
        ],
        treasures: [
            "uma estrelinha caída do céu",
            "uma luzinha de lua guardada num vidrinho",
            "uma sinetinha de prata que só toca para corações gentis",
        ],
        moralVariants: [
            "Mãos gentis sempre encontram o caminho de casa, e o que elas carregam encontra junto.",
            "Até os ajudantes pequenininhos conseguem acender um céu inteiro.",
        ]
    )

    // MARK: - A viagem sonolenta (pt-BR · space · ocean)

    static let sleepyVoyagePt = StoryTemplate(
        id: "sleepy-voyage-pt",
        themes: [.space, .ocean],
        titleVariants: [
            "A viagem sonolenta de {name}",
            "O barquinho feito de luar",
            "{name} e as estrelas que cantarolam",
        ],
        pages: [
            "Quando a casa ficou toda silenciosa e as luzes foram ficando pequenininhas, a cama de {name} fez uma coisa que as camas quase nunca fazem: levantou voo, devagarinho, e virou um barquinho.",
            "O barquinho deslizou pela janela e entrou no escuro macio, que não tinha nada de preocupante. Era aconchegante, como se o céu inteiro estivesse ajeitando as suas cobertas. {companion} sentou na proa, e {comfort} virou o travesseiro perfeito.",
            "Velejaram cruzando {setting}, onde tudo já dormia. As ondas, ou será que eram nuvens, embalavam o barquinho devagar. Uma… duas… uma… duas…",
            "Uma família de estrelas saiu para vê-los passar. A estrelinha mais miudinha cantarolava {sound}, a canção que as estrelas cantam quando chega a hora de descansar. {name} cantarolou junto, bem baixinho.",
            "«Olha», sussurrou {companion}. Lá na frente, brilhando de mansinho, flutuava {treasure}. Aquela doce visitante chegou perto, cumprimentou com jeitinho, e seguiu viagem com eles, como uma velha amiga que conhecia o caminho.",
            "O barquinho balançava. As estrelas cantarolavam. Os olhos de {name} foram ficando pesados, cada vez mais pesados, do jeitinho mais gostoso que existe, como cobertas feitas de silêncio quente.",
            "Devagar, devagarinho, o barquinho pegou o caminho de casa, deslizando pelo escuro macio, voltando pela janela, até pousar, de mansinho, exatamente onde uma cama deve ficar.",
            "E lá estava {name}, bem coberto, com {comfort} pertinho e {companion} já sonhando. A viagem estaria ali de novo amanhã à noite. Durma agora, pequeno marinheiro. Boa noite, {name}, as estrelas cantarolam para você.",
        ],
        settings: [
            "o farol adormecido",
            "a ilha de areia fofa como travesseiro",
            "a enseada onde as baleias sonham",
            "o porto dos barquinhos de papel",
        ],
        sounds: [
            "mmm-hmm-mmm",
            "lu-lu-lu",
            "hummm",
        ],
        treasures: [
            "uma lamparina-peixe de brilho suave",
            "uma barquinha emprestada pela Lua",
            "uma estrela-do-mar sonolenta",
        ],
        moralVariants: [
            "O escuro gentil é um amigo que nos carrega devagarinho até a manhã.",
            "Descansar é uma viagem, e quem dorme é um pequeno marinheiro corajoso.",
        ]
    )

    // MARK: - O amiguinho perdido (pt-BR · animals · friendship)

    static let littleLostFriendPt = StoryTemplate(
        id: "little-lost-friend-pt",
        themes: [.animals, .friendship],
        titleVariants: [
            "{name} e o amiguinho perdido",
            "O visitante pequenininho",
            "A noite em que {name} levou o pequenino para casa",
        ],
        pages: [
            "Pouco antes da hora de dormir, {name} ouviu o barulhinho mais pequeno do mundo vindo da porta de casa: {sound}. {name} e {companion} foram espiar devagarinho.",
            "Ali, não maior que uma xícara de chá, estava um serzinho de olhos grandes e redondos. Ele tinha se perdido. A casa dele ficava do outro lado, depois que se cruzava {setting}, e a noite ia ficando cada vez mais funda.",
            "«Não se preocupe», disse {name} com a voz macia que a gente guarda para as coisas pequenininhas. «A gente leva você.» {name} levou {comfort} junto, porque tudo fica mais fácil com {comfort}.",
            "O pequenino subiu nas costas de {companion} e se segurou firme. No caminho, ele fungou um pouquinho, então {name} contou para ele sobre {treasure}. Os olhos do pequenino ficaram redondos de encanto, e as preocupações dele voaram para longe.",
            "Cruzaram {setting}, um passinho de cada vez, devagarinho. O ar da noite cheirava a grama e a estrelas. O pequenino começou a cantarolar {sound}, mas mais alegre agora, um cantarolar de quem está voltando para casa.",
            "E lá estava ela: uma portinha embaixo de uma colininha, com uma luz quentinha lá dentro e uma família de pequeninos acenando. O visitante mais pequenininho apertou o polegar de {name} com força. Era o maior abraço que ele sabia dar.",
            "«Obrigado», piou ele, «por me levar até em casa.» E deixou um presente para {name}: um carinho minúsculo de bigodinhos na ponta do nariz. Isso é uma honra enorme, entre os serzinhos.",
            "{name} e {companion} voltaram para casa embaixo da boa e velha lua, bocejando o caminho inteiro. E quando {name} se enfiou na cama com {comfort}, a noite parecia amiga e cheia de casinhas felizes. Boa noite, {name}.",
        ],
        settings: [
            "a cerca das amoras",
            "as três pedras redondas",
            "o carvalho grande do galho torto",
            "o capim alto onde cantam os grilos",
        ],
        sounds: [
            "piu-piu",
            "quic",
            "miau",
        ],
        treasures: [
            "a caminha de musgo mais macia do bosque inteiro",
            "uma despensa cheia de amoras com mel",
            "uma luzinha feita de um raio de sol amansado",
        ],
        moralVariants: [
            "Levar alguém para casa é o jeito mais quentinho de terminar o dia.",
            "Nenhuma gentileza é pequena quando a gente é pequeno.",
        ]
    )
}
