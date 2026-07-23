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
}
