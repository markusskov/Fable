import Foundation

/// The Summer Nights collection: one arc ("the longest evening" — helping
/// the midsummer sun to bed), retold in all seven languages with each
/// shelf's slot discipline. Same editorial bar as the standing shelves;
/// these templates never appear on them — they are served only through the
/// collection (ADR 0005).
extension SeasonalCollections {
    static let summerNights = SeasonalCollection(
        id: "summer-nights",
        emoji: "🌻",
        theme: .adventure,
        northernMonths: [6, 7, 8],
        southernMonths: [12, 1, 2],
        templatesByLanguage: [
            .english: longestEvening,
            .norwegianBokmal: longestEveningNb,
            .german: longestEveningDe,
            .spanish: longestEveningEs,
            .french: longestEveningFr,
            .italian: longestEveningIt,
            .portugueseBrazilian: longestEveningPt,
        ]
    )

    // MARK: - The Longest Evening (en · summer)

    static let longestEvening = StoryTemplate(
        id: "longest-evening",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} and the Longest Evening",
            "The Night the Sun Stayed Up Late",
            "{name}'s Summer Night",
        ],
        pages: [
            "It was the middle of summer, and the sun was staying up late. Long past dinner it still hung over the rooftops, golden and warm, like it had forgotten how to say goodnight. {name} watched it from the window and wondered if someone ought to help.",
            "So {name} set out with {companion}, with {comfort} tucked under one arm, into the long golden evening. The air was soft as bathwater, and the whole world smelled of warm grass and sleepy flowers.",
            "They walked to {setting}, where the light lingers longest. Somewhere in the tall grass, the evening was tuning up its little orchestra: {sound}, went the crickets, slow and cozy, the song they only play when a day has been good.",
            "\"Dear Sun,\" called {name}, in a kind voice, \"you have shone so long today. Aren't you tired?\" And the sun yawned a great golden yawn, and stretched, and sank a little lower, glad that someone had finally asked.",
            "{name} and {companion} helped gather the clouds, plumping them up like pillows, until the sun had the coziest bed in the whole sky. It slid down under the cloud blankets, lower and lower, until only its hair of golden light peeked out.",
            "And just before it fell asleep, the sun left a goodnight gift in the grass beside {name}: {treasure}. It was still warm from the long day, the way a keepsake of summer should be.",
            "Then the stars tiptoed out, one by one. They had waited so patiently for their turn. The sky turned the deep blue that only summer nights have, and the crickets played on, softer now: {sound}, {sound}, slower and slower.",
            "{name} walked home through the warm dark with {companion}, carrying the sun's gift all the way to bed. And with {comfort} close and the window open to the cricket song, summer itself tucked {name} in. Goodnight, {name}. Sleep as long as the sun.",
        ],
        settings: [
            "the little hill where the day ends",
            "the meadow of golden grass",
            "the old apple tree",
            "the warm smooth stones by the water",
        ],
        sounds: [
            "cree-cree",
            "chirr-chirr",
            "zree-zree",
        ],
        treasures: [
            "a little jar of evening gold",
            "a sun-warmed pebble shaped like a heart",
            "one last ray of sunshine, curled up like a ribbon",
        ],
        moralVariants: [
            "Even the brightest days need a goodnight.",
            "The best way to end a long day is gently.",
        ],
        recapVariants: [
            "{name} and {companion} walked out into the longest evening, helped the summer sun to bed, and carried home {treasure}.",
        ]
    )

    // MARK: - Den lengste kvelden (nb · summer)

    static let longestEveningNb = StoryTemplate(
        id: "longest-evening-nb",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} og den lengste kvelden",
            "Natten da solen ble oppe for lenge",
            "Sommernatten til {name}",
        ],
        pages: [
            "Det var midt på sommeren, og solen ble oppe altfor lenge. Lenge etter middag hang den fremdeles over hustakene, gyllen og varm, som om den hadde glemt hvordan man sier god natt. {name} så på den fra vinduet og lurte på om noen burde hjelpe den.",
            "Så gikk {name} ut sammen med {companion}, med {comfort} trygt under armen, ut i den lange, gylne kvelden. Luften var myk som badevann, og hele verden luktet varmt gress og søvnige blomster.",
            "De gikk bort til {setting}, der lyset blir værende aller lengst. Et sted i det høye gresset stemte kvelden det lille orkesteret sitt: {sound}, sang sirissene, sakte og lunt, den sangen de bare spiller når en dag har vært god.",
            "«Kjære sol», sa {name} med sin snilleste stemme, «du har skint så lenge i dag. Er du ikke trøtt nå?» Og solen gjespet et stort, gyllent gjesp, strakte seg, og sank litt lavere, glad for at noen endelig spurte.",
            "{name} og {companion} hjalp til med å samle skyene og riste dem luftige som puter, helt til solen hadde den fineste sengen på hele himmelen. Den gled ned under skyteppene, lavere og lavere, til bare det gylne håret stakk opp.",
            "Og rett før den sovnet, la solen igjen en godnattgave i gresset ved siden av {name}: {treasure}. Den var fremdeles varm etter den lange dagen, akkurat slik et sommerminne skal være.",
            "Så listet stjernene seg frem, én etter én. De hadde ventet så tålmodig på tur. Himmelen fikk den dype blåfargen som bare sommernetter har, og sirissene spilte videre, mykere nå: {sound}, {sound}, saktere og saktere.",
            "{name} ruslet hjemover gjennom det varme mørket med {companion}, og bar solens gave helt til sengs. Og med {comfort} tett inntil og vinduet åpent mot sirissangen, ble {name} tullet inn av selve sommeren. God natt, {name}. Sov like lenge som solen.",
        ],
        settings: [
            "den lille bakken der dagen tar kveld",
            "engen med det gylne gresset",
            "det gamle epletreet",
            "de varme, glatte steinene ved vannet",
        ],
        sounds: [
            "srr-srr",
            "cri-cri",
            "zirr-zirr",
        ],
        // Common gender throughout, so «den» on page six agrees.
        treasures: [
            "en liten krukke med kveldsgull",
            "en solvarm stein formet som et hjerte",
            "en siste solstråle, rullet sammen som et bånd",
        ],
        moralVariants: [
            "Selv de lyseste dagene trenger en god natt.",
            "Den fineste måten å avslutte en lang dag på er varsomt.",
        ],
        recapVariants: [
            "{name} og {companion} gikk ut i den lengste kvelden, hjalp sommersolen til sengs og bar {treasure} med seg hjem.",
        ]
    )

    // MARK: - Der längste Abend (de · summer)

    static let longestEveningDe = StoryTemplate(
        id: "longest-evening-de",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} und der längste Abend",
            "Die Nacht, in der die Sonne zu lange aufblieb",
            "Die Sommernacht von {name}",
        ],
        pages: [
            "Es war mitten im Sommer, und die Sonne blieb viel zu lange auf. Noch lange nach dem Abendessen hing sie über den Dächern, golden und warm, als hätte sie vergessen, wie man Gute Nacht sagt. {name} schaute vom Fenster aus zu und überlegte, ob ihr wohl jemand helfen sollte.",
            "Also machte sich {name} auf den Weg, {comfort} fest unter dem Arm, und {companion} kam natürlich mit, hinaus in den langen, goldenen Abend. Die Luft war weich wie Badewasser, und die ganze Welt roch nach warmem Gras und schläfrigen Blumen.",
            "Sie gingen zu {setting}, dort bleibt das Licht am allerlängsten. Irgendwo im hohen Gras stimmte der Abend sein kleines Orchester: {sound}, sangen die Grillen, langsam und behaglich, jenes Lied, das sie nur spielen, wenn ein Tag gut gewesen ist.",
            "„Liebe Sonne“, sagte {name} mit freundlicher Stimme, „du hast heute so lange geschienen. Bist du denn gar nicht müde?“ Da gähnte die Sonne ein großes, goldenes Gähnen, streckte sich und sank ein Stückchen tiefer, froh, dass endlich jemand fragte.",
            "{name} und {companion} halfen mit, die Wolken zusammenzuschieben und aufzuschütteln wie Kissen, bis die Sonne das gemütlichste Bett am ganzen Himmel hatte. Sie rutschte unter die Wolkendecken, tiefer und tiefer, bis nur noch ihr goldenes Haar herausschaute.",
            "Und kurz bevor sie einschlief, ließ die Sonne im Gras neben {name} ein Gutenachtgeschenk zurück: {treasure}. Das kleine Andenken war noch warm vom langen Tag, genau so, wie ein Sommerandenken sein soll.",
            "Dann kamen die Sterne hervor, einer nach dem anderen. Sie hatten so geduldig gewartet, bis sie an der Reihe waren. Der Himmel bekam jenes tiefe Blau, das nur Sommernächte haben, und die Grillen spielten weiter, leiser jetzt: {sound}, {sound}, immer langsamer.",
            "{name} und {companion} spazierten durch das warme Dunkel nach Hause und trugen das Geschenk der Sonne bis ins Bett. {comfort} lag ganz nah, das offene Fenster war voller Grillenlied, und der Sommer selbst deckte {name} zu. Gute Nacht, {name}. Schlaf so lang wie die Sonne.",
        ],
        // Dative baked in, as on the German shelf.
        settings: [
            "dem kleinen Hügel, auf dem der Tag zu Ende geht",
            "der Wiese mit dem goldenen Gras",
            "dem alten Apfelbaum",
            "den warmen, glatten Steinen am Wasser",
        ],
        sounds: [
            "zirp-zirp",
            "srr-srr",
            "criii",
        ],
        // Colon apposition (nominative); page six refers back only through
        // the fixed neuter epithet "das kleine Andenken".
        treasures: [
            "ein kleines Glas voll Abendgold",
            "ein sonnenwarmer Stein in Herzform",
            "ein letzter Sonnenstrahl, aufgerollt wie ein Band",
        ],
        moralVariants: [
            "Auch die hellsten Tage brauchen eine Gute Nacht.",
            "Ein langer Tag endet am schönsten ganz sanft.",
        ],
        recapVariants: [
            "{name} und {companion} gingen hinaus in den längsten Abend, halfen der Sommersonne ins Bett und trugen ein Gutenachtgeschenk nach Hause: {treasure}.",
        ]
    )

    // MARK: - La tarde más larga (es · summer)

    static let longestEveningEs = StoryTemplate(
        id: "longest-evening-es",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} y la tarde más larga",
            "La noche en que el sol se quedó despierto hasta tarde",
            "La noche de verano de {name}",
        ],
        pages: [
            "Era pleno verano, y el sol se quedaba despierto hasta tardísimo. Mucho después de la cena seguía colgado sobre los tejados, dorado y calentito, como si se le hubiera olvidado cómo se dice buenas noches. {name} lo miraba desde la ventana y pensaba que alguien debería ayudarlo.",
            "Así que {name} salió con {companion} y con {comfort}, hacia la tarde larga y dorada. El aire era suave como el agua del baño, y el mundo entero olía a hierba caliente y a flores dormilonas.",
            "Caminaron hacia {setting}, donde la luz se queda más tiempo. En algún rincón de la hierba alta, la tarde afinaba su pequeña orquesta: {sound}, cantaban los grillos, despacio y a gusto, esa canción que solo tocan cuando el día ha sido bueno.",
            "«Querido sol», dijo {name} con voz amable, «hoy has brillado muchísimo rato. ¿No estás cansado?» Y el sol soltó un bostezo grande y dorado, se estiró, y bajó un poquito más, contento de que por fin alguien se lo preguntara.",
            "{name} y {companion} ayudaron a juntar las nubes y a ahuecarlas como almohadas, hasta que el sol tuvo la cama más cómoda de todo el cielo. Se deslizó bajo las mantas de nubes, más y más abajo, hasta que solo asomaba su pelito de luz dorada.",
            "Y justo antes de dormirse, el sol dejó un regalo de buenas noches en la hierba, al lado de {name}: {treasure}. Todavía estaba calentita del día tan largo, como debe estar un recuerdo del verano.",
            "Después salieron las estrellas de puntillas, una a una. Habían esperado su turno con muchísima paciencia. El cielo se puso de ese azul hondo que solo tienen las noches de verano, y los grillos siguieron tocando, más bajito ahora: {sound}, {sound}, cada vez más despacio.",
            "{name} volvió a casa con {companion} por la oscuridad tibia, llevando el regalo del sol hasta la cama. Y con {comfort} al ladito y la ventana abierta a la canción de los grillos, el verano mismo arropó a {name}. Buenas noches, {name}. Duerme tanto como el sol.",
        ],
        // Article baked in; reached only with "hacia" (never contracts).
        settings: [
            "la colina pequeña donde termina el día",
            "el prado de hierba dorada",
            "el viejo manzano",
            "las piedras lisas y tibias junto al agua",
        ],
        sounds: [
            "cri-cri",
            "chirr-chirr",
            "zri-zri",
        ],
        // Uniformly feminine: "calentita" on page six agrees with all three.
        treasures: [
            "una jarrita llena de oro del atardecer",
            "una piedrecita tibia con forma de corazón",
            "una última rayita de sol, enroscada como una cinta",
        ],
        moralVariants: [
            "Hasta los días más luminosos necesitan unas buenas noches.",
            "La mejor manera de terminar un día largo es despacito.",
        ],
        recapVariants: [
            "{name} y {companion} salieron a la tarde más larga, ayudaron al sol de verano a acostarse y llevaron a casa {treasure}.",
        ]
    )

    // MARK: - Le plus long des soirs (fr · summer)

    static let longestEveningFr = StoryTemplate(
        id: "longest-evening-fr",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} et le plus long des soirs",
            "La nuit où le soleil resta debout trop tard",
            "La nuit d'été de {name}",
        ],
        pages: [
            "C'était le plein été, et le soleil restait debout très, très tard. Longtemps après le dîner, il flottait encore au-dessus des toits, doré et tiède, comme s'il avait oublié comment on dit bonne nuit. {name} le regardait par la fenêtre et se demandait si quelqu'un ne devrait pas l'aider.",
            "Alors {name} sortit avec {companion} et avec {comfort}, dans le long soir doré. L'air était doux comme l'eau du bain, et le monde entier sentait l'herbe chaude et les fleurs ensommeillées.",
            "Ils marchèrent vers {setting}, là où la lumière s'attarde le plus longtemps. Quelque part dans les herbes hautes, le soir accordait son petit orchestre : {sound}, chantaient les grillons, lentement, bien au chaud, la chanson qu'ils ne jouent que lorsque la journée a été belle.",
            "« Cher soleil », dit {name} d'une voix gentille, « tu as brillé si longtemps aujourd'hui. Tu n'es pas fatigué ? » Et le soleil bâilla un grand bâillement doré, s'étira, et descendit un petit peu plus bas, tout content qu'on le lui demande enfin.",
            "{name} et {companion} aidèrent à rassembler les nuages et à les tapoter comme des oreillers, jusqu'à ce que le soleil ait le lit le plus douillet de tout le ciel. Il se glissa sous les couvertures de nuages, plus bas, encore plus bas, jusqu'à ne laisser dépasser que ses cheveux de lumière dorée.",
            "Et juste avant de s'endormir, le soleil laissa un cadeau de bonne nuit dans l'herbe, à côté de {name} : {treasure}. Elle était encore tiède de la longue journée, exactement comme doit l'être un souvenir d'été.",
            "Puis les étoiles sortirent sur la pointe des pieds, une à une. Elles avaient attendu leur tour si patiemment. Le ciel prit ce bleu profond que seules connaissent les nuits d'été, et les grillons continuèrent, plus doucement maintenant : {sound}, {sound}, de plus en plus lentement.",
            "{name} rentra à la maison avec {companion} par l'obscurité tiède, emportant le cadeau du soleil jusqu'au lit. Et avec {comfort} tout près et la fenêtre ouverte sur la chanson des grillons, l'été lui-même borda {name}. Bonne nuit, {name}. Dors aussi longtemps que le soleil.",
        ],
        // Article baked in; reached only with "vers".
        settings: [
            "la petite colline où finit le jour",
            "la prairie aux herbes dorées",
            "le vieux pommier",
            "les pierres lisses et tièdes au bord de l'eau",
        ],
        sounds: [
            "cri-cri",
            "crii-crii",
            "zzi-zzi",
        ],
        // Uniformly feminine: "Elle était encore tiède" on page six.
        treasures: [
            "une petite jarre remplie d'or du soir",
            "une pierre tiède en forme de cœur",
            "une petite lueur de soleil, enroulée comme un ruban",
        ],
        moralVariants: [
            "Même les jours les plus lumineux ont besoin d'une bonne nuit.",
            "La plus belle façon de finir une longue journée, c'est tout en douceur.",
        ],
        recapVariants: [
            "{name} et {companion} sortirent dans le plus long des soirs, aidèrent le soleil d'été à se coucher et rapportèrent {treasure} à la maison.",
        ]
    )

    // MARK: - La sera più lunga (it · summer)

    static let longestEveningIt = StoryTemplate(
        id: "longest-evening-it",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} e la sera più lunga",
            "La notte in cui il sole rimase sveglio fino a tardi",
            "La notte d'estate di {name}",
        ],
        pages: [
            "Era piena estate, e il sole restava sveglio fino a tardissimo. Molto dopo cena era ancora lì, sopra i tetti, dorato e tiepido, come se avesse dimenticato come si dice buonanotte. {name} lo guardava dalla finestra e si chiedeva se qualcuno non dovesse aiutarlo.",
            "Così {name} uscì con {companion} e con {comfort}, nella lunga sera dorata. L'aria era morbida come l'acqua del bagnetto, e il mondo intero profumava di erba calda e di fiori assonnati.",
            "Camminarono verso {setting}, dove la luce si ferma più a lungo. Da qualche parte nell'erba alta, la sera accordava la sua piccola orchestra: {sound}, cantavano i grilli, piano piano, quella canzone che suonano solo quando la giornata è stata bella.",
            "«Caro sole», disse {name} con voce gentile, «oggi hai brillato così a lungo. Non sei stanco?» E il sole fece uno sbadiglio grande e dorato, si stiracchiò, e scese un pochino più giù, contento che finalmente qualcuno glielo chiedesse.",
            "{name} e {companion} aiutarono a radunare le nuvole e a sprimacciarle come cuscini, finché il sole non ebbe il letto più comodo di tutto il cielo. Scivolò sotto le coperte di nuvole, sempre più giù, finché fuori non restarono che i suoi capelli di luce dorata.",
            "E un attimo prima di addormentarsi, il sole lasciò un regalo della buonanotte nell'erba, accanto a {name}: {treasure}. Era ancora tiepida della lunga giornata, proprio come deve essere un ricordo d'estate.",
            "Poi le stelle uscirono in punta di piedi, una alla volta. Avevano aspettato il loro turno con tanta pazienza. Il cielo prese quel blu profondo che hanno solo le notti d'estate, e i grilli continuarono a suonare, più piano adesso: {sound}, {sound}, sempre più lentamente.",
            "{name} tornò a casa con {companion} attraverso il buio tiepido, portando il regalo del sole fino al letto. E con {comfort} lì accanto e la finestra aperta sulla canzone dei grilli, fu l'estate stessa a rimboccare le coperte a {name}. Buonanotte, {name}. Dormi a lungo come il sole.",
        ],
        // Article baked in; reached only with "verso".
        settings: [
            "la piccola collina dove finisce il giorno",
            "il prato dall'erba dorata",
            "il vecchio melo",
            "i sassi lisci e tiepidi in riva all'acqua",
        ],
        sounds: [
            "cri-cri",
            "crii-crii",
            "zri-zri",
        ],
        // Uniformly feminine: "Era ancora tiepida" on page six.
        treasures: [
            "una piccola giara piena d'oro della sera",
            "una pietra tiepida a forma di cuore",
            "un'ultima piccola luce di sole, arrotolata come un nastro",
        ],
        moralVariants: [
            "Anche i giorni più luminosi hanno bisogno di una buonanotte.",
            "Il modo più bello di finire una lunga giornata è farlo piano piano.",
        ],
        recapVariants: [
            "{name} e {companion} uscirono nella sera più lunga, aiutarono il sole d'estate ad addormentarsi e portarono a casa {treasure}.",
        ]
    )

    // MARK: - A tarde mais longa (pt-BR · summer)

    static let longestEveningPt = StoryTemplate(
        id: "longest-evening-pt",
        themes: [.adventure, .friendship],
        titleVariants: [
            "{name} e a tarde mais longa",
            "A noite em que o sol ficou acordado até tarde",
            "A noite de verão de {name}",
        ],
        pages: [
            "Era pleno verão, e o sol ficava acordado até tardíssimo. Muito depois do jantar, ele ainda estava ali, pendurado sobre os telhados, dourado e morninho, como se tivesse esquecido como se diz boa noite. {name} olhava da janela e pensava que alguém devia ajudar.",
            "Então {name} saiu com {companion} e com {comfort}, pela tarde comprida e dourada. O ar era macio como água de banho, e o mundo inteiro cheirava a grama quente e a flores sonolentas.",
            "Caminharam até {setting}, onde a luz fica mais tempo. Em algum canto do capim alto, a tarde afinava a sua pequena orquestra: {sound}, cantavam os grilos, devagarzinho, aquela canção que eles só tocam quando o dia foi bom.",
            "“Querido sol”, disse {name} com voz gentil, “você brilhou tanto tempo hoje. Não está cansado?” E o sol soltou um bocejo grande e dourado, se espreguiçou, e desceu um pouquinho mais, contente que alguém finalmente perguntasse.",
            "{name} e {companion} ajudaram a juntar as nuvens e a afofá-las como travesseiros, até o sol ter a cama mais gostosa do céu inteiro. Ele deslizou para debaixo das cobertas de nuvem, cada vez mais para baixo, até só aparecer o seu cabelinho de luz dourada.",
            "E bem antes de pegar no sono, o sol deixou um presente de boa noite na grama, ao lado de {name}: {treasure}. Ainda estava morninha do dia comprido, do jeitinho que uma lembrança de verão deve ser.",
            "Depois as estrelas saíram na ponta dos pés, uma de cada vez. Tinham esperado a vez delas com muita paciência. O céu ficou daquele azul fundo que só as noites de verão têm, e os grilos continuaram tocando, mais baixinho agora: {sound}, {sound}, cada vez mais devagar.",
            "{name} voltou para casa com {companion} pelo escuro morninho, levando o presente do sol até a cama. E com {comfort} bem pertinho e a janela aberta para a canção dos grilos, foi o próprio verão que ajeitou as cobertas de {name}. Boa noite, {name}. Durma tanto quanto o sol.",
        ],
        // Article baked in; reached only with "até" (never contracts).
        settings: [
            "a colininha onde o dia termina",
            "o campo de capim dourado",
            "a velha macieira",
            "as pedras lisas e mornas na beira da água",
        ],
        sounds: [
            "cri-cri",
            "crii-crii",
            "zri-zri",
        ],
        // Uniformly feminine: "Ainda estava morninha" on page six.
        treasures: [
            "uma jarrinha cheia de ouro do entardecer",
            "uma pedrinha morna em formato de coração",
            "uma última luzinha de sol, enroladinha como uma fita",
        ],
        moralVariants: [
            "Até os dias mais brilhantes precisam de uma boa noite.",
            "O jeito mais bonito de terminar um dia comprido é devagarinho.",
        ],
        recapVariants: [
            "{name} e {companion} saíram pela tarde mais longa, ajudaram o sol de verão a se deitar e levaram {treasure} para casa.",
        ]
    )
}
