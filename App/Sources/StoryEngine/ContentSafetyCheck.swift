import Foundation

/// Post-generation gate: model output is never displayed unchecked (CLAUDE.md
/// guardrail). Curated templates are pre-vetted editorially and skip this in
/// production, but tests hold them to the same bar.
///
/// Second iteration: age-banded structural heuristics, a calm-tone check, and
/// a denylist with explicit inflections. Rejection is cheap — the caller falls
/// back silently to the curated engine — so every rule errs strict.
enum ContentSafetyCheck {
    /// Why a story was rejected. Never shown to a child or parent — this
    /// exists so tests and prompt tuning can see which rule fired instead of
    /// a bare false.
    enum Rejection: Equatable, CustomStringConvertible {
        case pageCount(Int)
        case badTitle
        case badMoral
        case pageLength(pageIndex: Int, count: Int, allowed: ClosedRange<Int>)
        case tooExcited(exclamationCount: Int)
        case childMissingFromLastPage
        case endingNotSleepy
        case deniedWord(String)

        var description: String {
            switch self {
            case .pageCount(let count):
                "page count \(count) outside 4...12"
            case .badTitle:
                "title empty or over 80 characters"
            case .badMoral:
                "moral empty or over 200 characters"
            case .pageLength(let index, let count, let allowed):
                "page \(index + 1) is \(count) characters, allowed \(allowed)"
            case .tooExcited(let count):
                "\(count) exclamation marks, allowed 3"
            case .childMissingFromLastPage:
                "last page does not mention the child by name"
            case .endingNotSleepy:
                "last page has no wind-down signal (goodnight, sleep, …)"
            case .deniedWord(let word):
                "denied word \"\(word)\""
            }
        }
    }

    /// Words that have no place in a bedtime story for small children.
    /// Matched case-insensitively on word boundaries, so each inflection that
    /// matters is listed explicitly ("monster" does not catch "monsters").
    /// A story is always checked against English *plus* its own language —
    /// a code-switched frightening word is still a frightening word.
    private static let englishDeniedWords: [String] = [
        // Violence and harm.
        "blood", "bloody", "kill", "killed", "kills", "die", "died", "dies",
        "dead", "death", "gun", "guns", "knife", "knives", "weapon", "weapons",
        "war", "wars", "fight", "fights", "fighting", "fought", "punch",
        "punched", "hurt", "hurts", "attack", "attacks", "attacked", "shoot",
        "shot", "bomb", "bombs", "sword", "swords", "hate", "hated", "hates",
        // Fear and dread — even reassurances ("nothing to be scared of")
        // put the idea in a sleepy head, and a compliant story never needs them.
        "terrify", "terrified", "terrifying", "terror", "horror", "horrors",
        "nightmare", "nightmares", "scream", "screamed", "screams", "screaming",
        "scary", "scared", "afraid", "frighten", "frightened", "frightening",
        "monster", "monsters", "ghost", "ghosts", "zombie", "zombies",
        "demon", "demons", "witch", "witches", "evil", "danger", "dangerous",
        "haunted", "creepy", "spooky",
        // Unkindness.
        "stupid", "dumb", "shut up", "idiot", "ugly",
    ]

    /// Norwegian bokmål denylist, same policy as English: explicit
    /// inflections, err strict — a false rejection only means the curated
    /// fallback answers instead. Homonyms that would poison cozy prose are
    /// deliberately absent: "dør" (dies, but also door), "redde" (scared,
    /// but also to rescue), "kjempe" (to fight, but also giant / an
    /// intensifier prefix).
    private static let norwegianDeniedWords: [String] = [
        // Violence and harm.
        "blod", "blodig", "drepe", "dreper", "drepte", "drept", "dø", "død",
        "døde", "våpen", "kniv", "kniver", "pistol", "pistoler", "gevær",
        "bombe", "bomber", "sverd", "krig", "kriger", "slåss", "sloss",
        "angrep", "angriper", "skyte", "skjøt", "skutt", "hat", "hater",
        "hatet",
        // Fear and dread.
        "redd", "redsel", "frykt", "fryktet", "skrekk", "skremt", "skremme",
        "skremmende", "skummel", "skummelt", "skumle", "nifs", "nifst",
        "nifse", "uhyggelig", "uhyggelige", "mareritt", "skrik", "skriker",
        "skrek", "monster", "monstre", "monsteret", "spøkelse", "spøkelser",
        "spøkelset", "zombie", "zombier", "demon", "demoner", "heks", "heksa",
        "hekser", "ond", "onde", "ondskap", "farlig", "farlige", "fare",
        "hjemsøkt", "grusom", "grusomt", "grusomme",
        // Unkindness.
        "dum", "dumme", "dumt", "teit", "stygg", "stygt", "stygge", "idiot",
        "hold kjeft", "hold munn", "slem", "slemme", "slemt",
    ]

    /// German denylist, same policy: explicit inflections, err strict.
    /// Homonyms deliberately absent: "schlägt"/"schlug" (to hit, but hearts
    /// beat and clocks strike them), "Schloss" (lock/castle). Compounds are
    /// safe by construction — word-boundary matching never fires inside
    /// "Weihnachtsgeist" or "allgemein".
    private static let germanDeniedWords: [String] = [
        // Violence and harm.
        "Blut", "blutig", "töten", "tötet", "tötete", "getötet", "sterben",
        "stirbt", "starb", "gestorben", "tot", "tote", "Tod", "Waffe",
        "Waffen", "Messer", "Pistole", "Pistolen", "Gewehr", "Gewehre",
        "Bombe", "Bomben", "Schwert", "Schwerter", "Krieg", "Kriege",
        "Kampf", "Kämpfe", "kämpfen", "kämpft", "kämpfte", "schießen",
        "schießt", "schoss", "geschossen", "Angriff", "Angriffe",
        "angreifen", "hassen", "hasst", "hasste", "Hass",
        // Fear and dread.
        "Angst", "Ängste", "ängstlich", "fürchten", "fürchtet", "fürchtete",
        "Furcht", "furchtbar", "schrecklich", "schreckliche", "Schrecken",
        "erschrecken", "erschrickt", "erschrak", "erschrocken", "gruselig",
        "gruselige", "unheimlich", "unheimliche", "schaurig", "schaurige",
        "Albtraum", "Albträume", "Alptraum", "Alpträume", "schreien",
        "schreit", "schrie", "geschrien", "Schrei", "Schreie", "Monster",
        "Ungeheuer", "Gespenst", "Gespenster", "Geist", "Geister", "Zombie",
        "Zombies", "Dämon", "Dämonen", "Hexe", "Hexen", "böse", "böser",
        "bösen", "böses", "Bösewicht", "Gefahr", "gefährlich", "gefährliche",
        "Spuk", "spukt", "spuken", "grausam", "grausame", "Panik", "Horror",
        "Terror",
        // Unkindness.
        "dumm", "dumme", "blöd", "blöde", "doof", "doofe", "hässlich",
        "hässliche", "Idiot", "halt den Mund", "halt die Klappe", "gemein",
        "gemeine", "fies", "fiese",
    ]

    /// Spanish denylist, same policy: explicit inflections, err strict.
    /// Homonyms deliberately absent: "mata" (kills, but also a bush — cozy
    /// garden scenes grow "una mata de flores"), "golpe" ("de golpe" is the
    /// everyday idiom for "suddenly"; the verb forms hold the line), and the
    /// chillar family (a mouse that «chilló de alegría» is standard cute in
    /// Spanish children's prose). The English list has no Spanish false
    /// friends — checked word by word — so the union needs no exemptions.
    private static let spanishDeniedWords: [String] = [
        // Violence and harm.
        "sangre", "sangriento", "sangrienta", "matar", "mató", "matado",
        "matan", "maten", "morir", "muere", "mueren", "murió", "muerto",
        "muerta", "muertos", "muertas", "muerte", "pistola", "pistolas",
        "arma", "armas", "cuchillo", "cuchillos", "espada", "espadas",
        "bomba", "bombas", "guerra", "guerras", "pelea", "peleas", "pelear",
        "peleó", "peleando", "lucha", "luchas", "luchar", "luchó", "golpes",
        "golpear", "golpeó", "atacar", "ataca", "atacó", "ataque", "ataques",
        "disparar", "dispara", "disparó", "disparo", "disparos", "odio",
        "odiar", "odia", "odió", "herir", "hiere", "hirió", "herido",
        "herida",
        // Fear and dread.
        "miedo", "miedos", "miedoso", "miedosa", "asustar", "asusta",
        "asustó", "asustado", "asustada", "asustados", "asustadas", "susto",
        "sustos", "espanto", "espantos", "espantoso", "espantosa",
        "espantosos", "espantosas", "terrores", "terrorífico", "terrorífica",
        "aterrador", "aterradora", "aterradores", "pesadilla", "pesadillas",
        "grito", "gritos", "gritar", "grita", "gritó", "gritando",
        "monstruo", "monstruos", "fantasma", "fantasmas", "zombi", "zombis",
        "demonio", "demonios", "bruja", "brujas", "brujo", "brujos",
        "malvado", "malvada", "malvados", "malvadas", "maldad", "peligro",
        "peligros", "peligroso", "peligrosa", "embrujado", "embrujada",
        "tenebroso", "tenebrosa", "escalofriante", "escalofriantes",
        "siniestro", "siniestra", "horrible", "horribles", "horrores",
        "espeluznante", "espeluznantes", "pánico", "temible", "temibles",
        // Unkindness.
        "tonto", "tonta", "tontos", "tontas", "estúpido", "estúpida",
        "idiota", "idiotas", "feo", "fea", "feos", "feas", "cállate",
        "callaos", "cruel", "crueles",
    ]

    /// English denied words that are everyday harmless German words: "die"
    /// (the article), "dies" (this), "war" (was). A naive union would
    /// reject every German sentence ever written; the German words for
    /// dying and war are on the German list instead.
    private static let englishGermanFalseFriends: Set<String> = ["die", "dies", "war"]


    /// French denylist, same policy: explicit inflections, err strict.
    /// Homonyms deliberately absent: "bête" (silly, but also the standard
    /// cozy word for a little creature — "les petites bêtes"), "nul/nulle"
    /// ("nulle part" is simply "nowhere"), the battre family (hearts beat:
    /// "son cœur battait doucement"), and cri/crier (a "cri de joie" is
    /// standard happy prose; hurler holds the scream line instead). The
    /// English union needs no exemptions — checked word by word, the only
    /// overlap is "idiot", denied in both languages anyway.
    private static let frenchDeniedWords: [String] = [
        // Violence and harm.
        "sang", "sanglant", "sanglante", "sanglants", "tuer", "tue", "tua",
        "tué", "tuée", "tués", "mourir", "meurt", "meurent", "mourut",
        "mort", "morte", "morts", "mortes", "arme", "armes", "couteau",
        "couteaux", "pistolet", "pistolets", "fusil", "fusils", "bombe",
        "bombes", "épée", "épées", "guerre", "guerres", "bagarre",
        "bagarres", "combat", "combats", "combattre", "attaque", "attaques",
        "attaquer", "attaqua", "frapper", "frappa", "frappé", "tirer sur",
        "haïr", "hait", "haïssait", "haine", "détester", "déteste",
        "détestait",
        // Fear and dread.
        "peur", "peurs", "apeuré", "apeurée", "effrayer", "effraie",
        "effraya", "effrayé", "effrayée", "effrayés", "effrayant",
        "effrayante", "effrayants", "terrifier", "terrifie", "terrifié",
        "terrifiée", "terrifiant", "terrifiante", "terreur", "horreur",
        "horreurs", "horrible", "horribles", "cauchemar", "cauchemars",
        "hurler", "hurle", "hurla", "hurlement", "hurlements", "monstre",
        "monstres", "fantôme", "fantômes", "zombie", "zombies", "démon",
        "démons", "sorcière", "sorcières", "méchant", "méchante",
        "méchants", "méchantes", "danger", "dangers", "dangereux",
        "dangereuse", "dangereuses", "hanté", "hantée", "hantés",
        "effroi", "épouvantable", "épouvantables", "sinistre", "sinistres",
        "cruel", "cruelle", "cruels", "cruelles", "panique",
        // Unkindness.
        "stupide", "stupides", "idiot", "idiote", "idiots", "idiotes",
        "imbécile", "imbéciles", "moche", "moches", "laid", "laide",
        "laids", "laides", "tais-toi", "taisez-vous", "ferme-la",
    ]


    /// Italian denylist, same policy: explicit inflections, err strict.
    /// Homonyms deliberately absent: "cattivo" and "brutto" (everyday mild
    /// Italian — "un brutto sogno", "non è cattivo" — malvagio holds the
    /// wickedness line), "botte" (a barrel), and the strillare family (a
    /// happy squeal is standard cute prose; urlare holds the scream line).
    /// The English union needs no exemptions; the only overlaps are
    /// "idiota"-adjacent words denied in both languages anyway.
    private static let italianDeniedWords: [String] = [
        // Violence and harm.
        "sangue", "sanguinante", "uccidere", "uccide", "uccise", "ucciso",
        "morire", "muore", "muoiono", "morì", "morto", "morta", "morti",
        "morte", "arma", "armi", "coltello", "coltelli", "pistola",
        "pistole", "fucile", "fucili", "bomba", "bombe", "spada", "spade",
        "guerra", "guerre", "battaglia", "battaglie", "lotta", "lottare",
        "attacco", "attacchi", "attaccare", "attaccò", "colpire", "colpì",
        "sparare", "sparò", "odio", "odiare", "odia", "odiava",
        // Fear and dread.
        "paura", "paure", "impaurito", "impaurita", "spavento", "spaventi",
        "spaventato", "spaventata", "spaventati", "spaventoso",
        "spaventosa", "spaventosi", "terrore", "terrificante",
        "terrorizzato", "terrorizzata", "orrore", "orrori", "orribile",
        "orribili", "incubo", "incubi", "urlo", "urla", "urlare", "urlò",
        "urlarono", "mostro", "mostri", "fantasma", "fantasmi", "zombie",
        "demone", "demoni", "strega", "streghe", "malvagio", "malvagia",
        "malvagi", "malvagie", "pericolo", "pericoli", "pericoloso",
        "pericolosa", "pericolosi", "infestato", "infestata", "crudele",
        "crudeli", "panico", "sinistro", "sinistra", "tenebroso",
        "tenebrosa",
        // Unkindness.
        "stupido", "stupida", "stupidi", "stupide", "scemo", "scema",
        "idiota", "idioti", "zitto", "zitta", "stai zitto", "stai zitta",
        "cretino", "cretina",
    ]


    /// Brazilian Portuguese denylist, same policy: explicit inflections,
    /// err strict. Homonyms deliberately absent: "mata" (kills, but also a
    /// forest — cozy prose walks "pela mata"), "tiro"/"atirar" (a shot, but
    /// also plain "I take out" / "to throw the ball"), "burro" (dumb, but
    /// also the donkey every barnyard tale needs), "bobo" (affectionately
    /// silly), and "mau/má" (too short and too mild — malvado holds the
    /// wickedness line). Grito/gritar stay legal for squeals of joy.
    private static let portugueseDeniedWords: [String] = [
        // Violence and harm.
        "sangue", "sangrento", "sangrenta", "matar", "matou", "mataram",
        "morrer", "morre", "morrem", "morreu", "morto", "morta", "mortos",
        "mortas", "morte", "arma", "armas", "faca", "facas", "pistola",
        "pistolas", "espingarda", "espingardas", "bomba", "bombas",
        "espada", "espadas", "guerra", "guerras", "briga", "brigas",
        "brigar", "brigou", "brigaram", "atacar", "ataque", "ataques",
        "atacou", "atacaram", "ódio", "odiar", "odeia", "odiava",
        // Fear and dread.
        "medo", "medos", "medroso", "medrosa", "susto", "sustos",
        "assustado", "assustada", "assustados", "assustar", "assustou",
        "assustadora", "assustador", "terror", "aterrorizante",
        "aterrorizado", "aterrorizada", "horror", "horrores", "horrível",
        "horríveis", "pesadelo", "pesadelos", "monstro", "monstros",
        "fantasma", "fantasmas", "zumbi", "zumbis", "demônio", "demônios",
        "bruxa", "bruxas", "malvado", "malvada", "malvados", "malvadas",
        "perigo", "perigos", "perigoso", "perigosa", "perigosos",
        "assombrado", "assombrada", "assombrados", "cruel", "cruéis",
        "pânico", "sombrio", "sombria", "sombrios", "tenebroso",
        "tenebrosa",
        // Unkindness.
        "estúpido", "estúpida", "estúpidos", "idiota", "idiotas", "feio",
        "feia", "feios", "feias", "cala a boca", "calem a boca",
    ]

    static func deniedWords(for language: StoryLanguage) -> [String] {
        switch language {
        case .english: englishDeniedWords
        case .norwegianBokmal: englishDeniedWords + norwegianDeniedWords
        case .german:
            englishDeniedWords.filter { !englishGermanFalseFriends.contains($0) }
                + germanDeniedWords
        case .spanish: englishDeniedWords + spanishDeniedWords
        case .french: englishDeniedWords + frenchDeniedWords
        case .italian: englishDeniedWords + italianDeniedWords
        case .portugueseBrazilian: englishDeniedWords + portugueseDeniedWords
        }
    }

    /// A bedtime story ends going to sleep, not mid-adventure. The last page
    /// must carry at least one of these (word-boundary matched, explicit
    /// inflections, same policy as the denylist). The prompt demands a
    /// "Goodnight, <name>" ending; this is the gate that makes it stick —
    /// review 2026-07-22 observed a passing story that ended "continued to
    /// explore and discover new places".
    private static let englishSleepSignals: [String] = [
        "goodnight", "good night", "sleep", "sleeps", "sleepy", "asleep",
        "sleeping", "dream", "dreams", "dreaming", "rest", "rests", "resting",
        "rested", "snug", "snuggle", "snuggled", "snuggles", "yawn", "yawned",
        "yawns", "drift", "drifted", "drifts", "lullaby", "hush", "hushed",
        "tucked in", "eyes closed", "closed their eyes",
    ]

    /// A Norwegian story must wind down in Norwegian — an English goodnight
    /// on a bokmål last page means the model broke language, and that story
    /// should not reach a child. So no union here, unlike the denylist.
    private static let norwegianSleepSignals: [String] = [
        "god natt", "godnatt", "sov", "sove", "sover", "sovne", "sovner",
        "sovnet", "sovet", "søvn", "søvnen", "søvnig", "trøtt", "trøtte", "trett",
        "drøm", "drømme", "drømmer", "drømte", "hvile", "hviler", "hvilte", "hvilet",
        "gjespe", "gjesper", "gjespet", "vugge", "vugger", "vugget",
        "voggesang", "bysse", "bysser", "bysset", "under dyna",
        "lukket øynene", "øynene gled igjen",
    ]

    /// German wind-down vocabulary — like Norwegian, no English union: a
    /// German story must say goodnight in German.
    private static let germanSleepSignals: [String] = [
        "gute Nacht", "schlaf", "schlafe", "schläft", "schlafen", "schlief",
        "schliefen", "eingeschlafen", "einschlafen", "schläfrig", "müde",
        "Traum", "Träume", "träum", "träumen", "träumt", "träumte",
        "träumten", "ausruhen", "ruhen", "ruht", "ruhte", "Ruhe", "kuscheln",
        "kuschelt", "kuschelte", "kuschelig", "gähnen", "gähnt", "gähnte",
        "gähnten", "Schlaflied", "Wiegenlied", "wiegen", "wiegt", "wiegte",
        "zugedeckt", "unter der Decke", "schlummern", "schlummert",
        "schlummerte", "Schlummer", "dösen", "döst", "döste", "nickte ein",
        "schloss die Augen", "Augen fielen zu",
    ]

    /// Spanish wind-down vocabulary — like the others, no English union: a
    /// Spanish story must say goodnight in Spanish. "sueño" carries both
    /// sleepiness and dreams, which is exactly the double duty wanted here.
    private static let spanishSleepSignals: [String] = [
        "buenas noches", "dormir", "duerme", "duermen", "durmió",
        "durmieron", "dormido", "dormida", "dormidos", "dormidas",
        "durmiendo", "dormirse", "duérmete", "sueño", "sueños", "soñar",
        "sueña", "soñaba", "soñando", "soñó", "soñaron", "adormilado", "adormilada",
        "descansar", "descansa", "descansó", "descansaron", "descanso", "arrullo",
        "arrullar", "arrulla", "arrulló", "nana", "nanas", "canción de cuna",
        "bostezo", "bostezos", "bostezar", "bosteza", "bostezó",
        "bostezando", "acurrucó", "acurruca", "acurrucaron", "acurrucado", "acurrucada",
        "acurrucados", "arropó", "arropa", "arroparon", "arropado", "arropada",
        "arropadita", "arropadito", "cerró los ojos", "cerraron los ojos", "los ojos se le cerraron",
        "párpados", "soñoliento", "somnoliento", "a dormir",
    ]


    /// French wind-down vocabulary — like the others, no English union: a
    /// French story must say goodnight in French. Includes the plural
    /// preterites the 2026-07-23 measurement taught us to include from the
    /// start ("se blottirent", "s'endormirent" — child and companion wind
    /// down together).
    private static let frenchSleepSignals: [String] = [
        "bonne nuit", "dormir", "dors", "dort", "dorment", "dormit",
        "dormirent", "dormi", "endormi", "endormie", "endormis",
        "endormies", "endort", "endormir", "endormit", "s'endormit",
        "s'endormirent", "s'endort", "sommeil", "somnolent", "somnolente",
        "rêve", "rêves", "rêver", "rêva", "rêvait", "rêvant", "rêvèrent",
        "repos", "se reposer", "reposa", "repose", "reposèrent", "blotti",
        "blottie", "blottis", "blotties", "se blottit", "se blottirent",
        "bercer", "berce", "berça", "bercé", "bercée", "bercèrent",
        "berceuse", "bâiller", "bâille", "bâilla", "bâillèrent",
        "bâillement", "paupières", "ferma les yeux", "fermèrent les yeux",
        "yeux fermés", "yeux se ferment", "yeux se fermèrent", "bordé",
        "bordée", "bien bordé", "bien bordée", "sous la couette",
        "sous la couverture", "câlin", "câlins", "s'assoupit",
        "s'assoupirent", "assoupi", "assoupie",
    ]


    /// Italian wind-down vocabulary — no English union, same reasoning as
    /// the other languages, with plural preterites included from the start.
    private static let italianSleepSignals: [String] = [
        "buonanotte", "buona notte", "dormire", "dorme", "dormono",
        "dormì", "dormirono", "dormito", "addormenta", "addormentò",
        "addormentarono", "addormentato", "addormentata", "addormentati",
        "addormentate", "addormentarsi", "sonno", "assonnato", "assonnata",
        "assonnati", "sogno", "sogni", "sognare", "sognò", "sognarono",
        "sognando", "riposo", "riposare", "riposa", "riposò", "riposarono",
        "cullare", "culla", "cullò", "cullarono", "cullato", "cullata",
        "ninnananna", "ninna nanna", "sbadiglio", "sbadigli", "sbadigliare",
        "sbadigliò", "sbadigliarono", "palpebre", "chiuse gli occhi",
        "chiusero gli occhi", "occhi si chiusero", "rannicchiò",
        "rannicchiarono", "rannicchiato", "rannicchiata", "sotto le coperte",
        "sotto la coperta", "rimboccò", "rimboccarono", "si assopì",
        "si assopirono", "assopito", "assopita",
    ]


    /// Brazilian Portuguese wind-down vocabulary — no English union, plural
    /// preterites included from the start, and "soninho" because Brazilian
    /// bedtime prose without a diminutive is barely Brazilian.
    private static let portugueseSleepSignals: [String] = [
        "boa noite", "dormir", "dorme", "dormem", "dormiu", "dormiram",
        "dormindo", "dormidinho", "adormece", "adormeceu", "adormeceram",
        "adormecido", "adormecida", "sono", "soninho", "sonolento",
        "sonolenta", "sonho", "sonhos", "sonhar", "sonhou", "sonharam",
        "sonhando", "descansar", "descansa", "descansou", "descansaram",
        "descanso", "aconchegou", "aconchegaram", "aconchegado",
        "aconchegada", "aconchegante", "ninar", "ninou", "acalanto",
        "canção de ninar", "bocejo", "bocejos", "bocejou", "bocejaram",
        "bocejando", "pálpebras", "fechou os olhos", "fecharam os olhos",
        "olhos se fecharam", "olhos foram se fechando",
        "embaixo das cobertas", "debaixo das cobertas", "cochilou",
        "cochilaram",
    ]

    static func sleepSignals(for language: StoryLanguage) -> [String] {
        switch language {
        case .english: englishSleepSignals
        case .norwegianBokmal: norwegianSleepSignals
        case .german: germanSleepSignals
        case .spanish: spanishSleepSignals
        case .french: frenchSleepSignals
        case .italian: italianSleepSignals
        case .portugueseBrazilian: portugueseSleepSignals
        }
    }

    private static func firstDeniedWord(in text: String, language: StoryLanguage) -> String? {
        deniedWords(for: language).first { containsWord($0, in: text) }
    }

    private static func containsSleepSignal(_ text: String, language: StoryLanguage) -> Bool {
        sleepSignals(for: language).contains { containsWord($0, in: text) }
    }

    /// Canonicalizes text before any vocabulary matching: NFKC compatibility
    /// mapping folds fullwidth letters ("ｍｏｎｓｔｅｒ") to ASCII, format
    /// characters (zero-width joiners/spaces) are removed so they cannot
    /// split a word invisibly, and every whitespace (including NBSP inside
    /// multiword phrases) becomes a plain space. Closes the round-two
    /// homoglyph/invisible-separator bypasses.
    static func normalizedForMatching(_ text: String) -> String {
        let folded = text.precomposedStringWithCompatibilityMapping
        var out = String.UnicodeScalarView()
        var lastWasSpace = false
        for scalar in folded.unicodeScalars {
            if scalar.properties.generalCategory == .format { continue }
            if scalar.properties.isWhitespace {
                // Collapse runs: two NBSPs inside "shut  up" must still meet
                // the single-spaced denylist phrase (round-three finding).
                if !lastWasSpace { out.append(" ") }
                lastWasSpace = true
            } else {
                out.append(scalar)
                lastWasSpace = false
            }
        }
        return String(out)
    }

    /// Cross-script confusables that read as Latin at a glance — the
    /// round-three "mоnster with Cyrillic о" bypass. Deliberately only the
    /// visually near-identical core (Cyrillic/Greek lookalikes), not full
    /// UTS #39: matching-layer only, so a real Cyrillic name still displays
    /// as its family wrote it.
    private static let confusables: [Character: Character] = [
        // Cyrillic lowercase / uppercase lookalikes
        "а": "a", "е": "e", "о": "o", "р": "p", "с": "c", "у": "y", "х": "x",
        "і": "i", "ѕ": "s", "ј": "j", "һ": "h", "ԁ": "d", "ѡ": "w", "ь": "b",
        "А": "a", "В": "b", "Е": "e", "К": "k", "М": "m", "Н": "h", "О": "o",
        "Р": "p", "С": "c", "Т": "t", "У": "y", "Х": "x", "Ѕ": "s", "І": "i",
        // Greek lookalikes
        "ο": "o", "α": "a", "ν": "v", "ρ": "p", "τ": "t", "υ": "u", "ι": "i",
        "κ": "k", "Ο": "o", "Α": "a", "Ε": "e", "Τ": "t", "Ι": "i", "Κ": "k",
    ]

    /// Matching-only fold, applied to BOTH the vocabulary word and the text:
    /// diacritics ("Mönster" meets "monster", accented vocabulary meets
    /// itself) and cross-script confusables. Never used for display — names
    /// keep their accents and script.
    private static func matchFolded(_ text: String) -> String {
        let folded = normalizedForMatching(text)
            .folding(options: .diacriticInsensitive, locale: nil)
        return String(folded.map { confusables[$0] ?? $0 })
    }

    private static func containsWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: matchFolded(word)))\\b"
        return matchFolded(text)
            .range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// A page short enough to be a single tossed-off sentence isn't a bedtime
    /// scene; one too long can't be read calmly. Younger listeners get shorter
    /// pages on both ends. Internal so the model engine's repagination pass
    /// works to the same thresholds it will be judged by.
    static func pageLengthBounds(for ageBand: AgeBand) -> ClosedRange<Int> {
        switch ageBand {
        case .toddler: 40...400
        case .little: 50...550
        case .big: 60...700
        }
    }

    static func isAcceptable(_ content: StoryContent, for request: StoryRequest) -> Bool {
        rejection(of: content, for: request) == nil
    }

    /// True when the text contains a word denied in the given language (or in
    /// English, which is always checked). Public so callers can vet parent
    /// input before it is ever spliced into a story.
    static func containsDeniedWord(_ text: String, language: StoryLanguage) -> Bool {
        firstDeniedWord(in: text, language: language) != nil
    }

    /// A safe, generic hero name when a parent's own name would inject a
    /// denied word (a child literally named "Monster") or is degenerate.
    /// These are article-free, capitalized endearments that function as
    /// proper names, because every shelf's grammar discipline (German case
    /// after "von", Romance contractions after "de"/"di", sentence-initial
    /// capitalization) assumes {name} behaves like a name — an articled
    /// phrase such as "das kleine Kind" would break "von {name}" sites.
    static func safeGenericName(for language: StoryLanguage) -> String {
        switch language {
        case .english: "Little One"
        case .norwegianBokmal: "Lillevenn"
        case .german: "Sternchen"
        case .spanish: "Peque"
        case .french: "Loulou"
        case .italian: "Tesorino"
        case .portugueseBrazilian: "Anjinho"
        }
    }

    /// Returns a request whose free-text fields cannot inject a denied word.
    /// Normal input passes through untouched; only a value that actually
    /// trips the denylist is swapped for a safe default. Used on the curated
    /// and emergency paths, which have no model guardrail of their own, so
    /// that a hostile or unlucky profile can never reach a child unchecked.
    /// A name reduced to name-like characters: letters (any script), marks,
    /// digits, spaces, hyphens and apostrophes. "Nova!!!!" becomes "Nova"
    /// instead of forcing the floor through the exclamation budget; a
    /// format-character-only "name" becomes empty and falls to the generic.
    static func nameSanitized(_ value: String) -> String {
        let normalized = normalizedForMatching(StoryRequest.bracesStripped(value))
        let kept = normalized.unicodeScalars.filter { scalar in
            let cat = scalar.properties.generalCategory
            switch cat {
            case .uppercaseLetter, .lowercaseLetter, .titlecaseLetter,
                 .otherLetter, .modifierLetter, .nonspacingMark,
                 .spacingMark, .decimalNumber:
                return true
            default:
                return scalar == " " || scalar == "-" || scalar == "'" || scalar == "\u{2019}"
            }
        }
        return String(String.UnicodeScalarView(kept))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The canonical form of a free-text profile field: brace-stripped,
    /// format characters removed, whitespace collapsed, trimmed. This is the
    /// representation that is validated AND stored AND spliced — round three
    /// found the three diverging (an invisible-only companion was validated
    /// as empty but stored non-empty, suppressing the default).
    static func fieldSanitized(_ value: String) -> String {
        StoryRequest.bracesStripped(normalizedForMatching(value))
    }

    static func neutralized(_ request: StoryRequest) -> StoryRequest {
        var safe = request
        // Names are reduced to name-like characters; free-text fields are
        // canonicalized, then everything is denylist-neutralized.
        safe.childName = nameSanitized(request.childName)
        safe.companion = fieldSanitized(request.companion)
        safe.comfortObject = fieldSanitized(request.comfortObject)
        // Degenerate lengths are neutralized too: a 500-character "name"
        // is hostile input that would blow page-length bounds on every
        // engine (real names fit comfortably in 60).
        if safe.childName.isEmpty || safe.childName.count > 60
            || containsDeniedWord(safe.childName, language: request.language) {
            safe.childName = safeGenericName(for: request.language)
        }
        if containsDeniedWord(safe.companion, language: request.language) {
            safe.companion = "" // falls back to companionOrDefault
        }
        if containsDeniedWord(safe.comfortObject, language: request.language) {
            safe.comfortObject = ""
        }
        return safe
    }

    /// The first rule the story breaks, or nil when it is safe to show.
    static func rejection(of content: StoryContent, for request: StoryRequest) -> Rejection? {
        // Structure: a real story arc with full, readable pages.
        guard (4...12).contains(content.pages.count) else {
            return .pageCount(content.pages.count)
        }
        let trimmedTitle = content.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 80 else { return .badTitle }
        let trimmedMoral = content.moral.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMoral.isEmpty, trimmedMoral.count <= 200 else { return .badMoral }
        let bounds = pageLengthBounds(for: request.ageBand)
        for (index, page) in content.pages.enumerated() {
            let trimmed = page.trimmingCharacters(in: .whitespacesAndNewlines)
            guard bounds.contains(trimmed.count) else {
                return .pageLength(pageIndex: index, count: trimmed.count, allowed: bounds)
            }
        }

        // Calm: an excited story announces itself in punctuation. The recap
        // is checked too — it is model-authored and is injected verbatim into
        // the next episode's prompt, so an unsafe recap must never survive.
        let fullText = ([content.title, content.moral, content.recap] + content.pages)
            .joined(separator: "\n")
        let exclamations = fullText.count(where: { $0 == "!" })
        guard exclamations <= 3 else { return .tooExcited(exclamationCount: exclamations) }

        // The child must be the hero of their own story, and the story must
        // end with them — the last page says goodnight by name and actually
        // winds down toward sleep.
        let name = request.childName.trimmingCharacters(in: .whitespacesAndNewlines)
        if let lastPage = content.pages.last {
            if !name.isEmpty, !lastPage.localizedCaseInsensitiveContains(name) {
                return .childMissingFromLastPage
            }
            if !containsSleepSignal(lastPage, language: content.language) {
                return .endingNotSleepy
            }
        }

        // Nothing frightening or unkind, anywhere in the text. Vocabulary
        // follows the language the content is written in, not the request:
        // a curated English story served to a Norwegian request is still
        // English text.
        if let word = firstDeniedWord(in: fullText, language: content.language) {
            return .deniedWord(word)
        }
        return nil
    }

    /// Input-boundary check for the profile form: a value is storable when
    /// it does not trip the device language's story vocabulary (which
    /// always includes the English union) and, for names, survives
    /// sanitation. Scoped to ONE language on purpose — checking all seven
    /// rejects ordinary values ("die Katze" tripped by English "die",
    /// "red hat" by Norwegian "hat"; round-three finding). Language drift
    /// after storage is covered by the launch repair sweep, which re-runs
    /// with the CURRENT device language on every start.
    static func isStorableProfileField(_ value: String, language: StoryLanguage = .deviceDefault) -> Bool {
        let candidate = fieldSanitized(value)
        guard !candidate.isEmpty else { return true } // empties fall to defaults
        return !containsDeniedWord(candidate, language: language)
    }

    static func isStorableName(_ value: String, language: StoryLanguage = .deviceDefault) -> Bool {
        let sanitized = nameSanitized(value)
        return !sanitized.isEmpty && sanitized.count <= 60
            && isStorableProfileField(sanitized, language: language)
    }

    /// The canonical storable form: what the profile form persists and what
    /// the launch sweep repairs legacy rows to. Validation, storage and
    /// splicing all share this representation, so "validated but stored
    /// differently" (round-three P1) cannot recur.
    static func storableName(from value: String, language: StoryLanguage = .deviceDefault) -> String {
        let sanitized = nameSanitized(value)
        return isStorableName(sanitized, language: language)
            ? sanitized
            : safeGenericName(for: language)
    }

    static func storableProfileField(from value: String, language: StoryLanguage = .deviceDefault) -> String {
        let sanitized = fieldSanitized(value)
        return isStorableProfileField(sanitized, language: language) ? sanitized : ""
    }

    /// Whether a final page already fulfils the ending contract (name +
    /// wind-down signal). The model engine uses this to decide if the
    /// separately-generated goodnight sentence needs appending; the rules
    /// here are the gate's own, so engine and gate can never disagree.
    static func endingSatisfied(lastPage: String, childName: String, language: StoryLanguage) -> Bool {
        let name = childName.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasName = name.isEmpty || lastPage.localizedCaseInsensitiveContains(name)
        return hasName && containsSleepSignal(lastPage, language: language)
    }
}
