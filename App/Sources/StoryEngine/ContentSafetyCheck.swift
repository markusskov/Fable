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

    static func deniedWords(for language: StoryLanguage) -> [String] {
        switch language {
        case .english: englishDeniedWords
        case .norwegianBokmal: englishDeniedWords + norwegianDeniedWords
        case .german:
            englishDeniedWords.filter { !englishGermanFalseFriends.contains($0) }
                + germanDeniedWords
        case .spanish: englishDeniedWords + spanishDeniedWords
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

    static func sleepSignals(for language: StoryLanguage) -> [String] {
        switch language {
        case .english: englishSleepSignals
        case .norwegianBokmal: norwegianSleepSignals
        case .german: germanSleepSignals
        case .spanish: spanishSleepSignals
        }
    }

    private static func firstDeniedWord(in text: String, language: StoryLanguage) -> String? {
        deniedWords(for: language).first { containsWord($0, in: text) }
    }

    private static func containsSleepSignal(_ text: String, language: StoryLanguage) -> Bool {
        sleepSignals(for: language).contains { containsWord($0, in: text) }
    }

    private static func containsWord(_ word: String, in text: String) -> Bool {
        let pattern = "\\b\(NSRegularExpression.escapedPattern(for: word))\\b"
        return text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
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

        // Calm: an excited story announces itself in punctuation.
        let fullText = ([content.title, content.moral] + content.pages).joined(separator: "\n")
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
