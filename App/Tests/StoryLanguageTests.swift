import Foundation
import Testing
@testable import Fable

/// The story-language plumbing: how a device's languages resolve to a story
/// language, how model support is judged, and how the safety gate and the
/// curated fallback behave across languages.
struct StoryLanguageTests {
    // MARK: - Resolution from device languages

    @Test func firstSupportedPreferredLanguageWins() {
        #expect(StoryLanguage.preferred(from: ["nb-NO", "en-US"]) == .norwegianBokmal)
        #expect(StoryLanguage.preferred(from: ["en-GB", "nb-NO"]) == .english)
    }

    @Test func norwegianMacrolanguageCountsAsBokmal() {
        #expect(StoryLanguage.preferred(from: ["no"]) == .norwegianBokmal)
    }

    @Test func unsupportedLanguagesFallThroughToEnglish() {
        // Danish is not a story language yet (sprint pending).
        #expect(StoryLanguage.preferred(from: ["da-DK", "sv-SE"]) == .english)
        #expect(StoryLanguage.preferred(from: []) == .english)
    }

    @Test func germanDevicesGetGermanStories() {
        #expect(StoryLanguage.preferred(from: ["de-DE", "en-US"]) == .german)
        #expect(StoryLanguage.preferred(from: ["de-AT"]) == .german)
        #expect(StoryLanguage.preferred(from: ["de-CH"]) == .german)
    }

    @Test func frenchDevicesGetFrenchStories() {
        #expect(StoryLanguage.preferred(from: ["fr-FR", "en-US"]) == .french)
        #expect(StoryLanguage.preferred(from: ["fr-CA"]) == .french)
        #expect(StoryLanguage.preferred(from: ["fr-BE"]) == .french)
    }

    @Test func italianDevicesGetItalianStories() {
        #expect(StoryLanguage.preferred(from: ["it-IT", "en-US"]) == .italian)
        #expect(StoryLanguage.preferred(from: ["it-CH"]) == .italian)
    }

    @Test func portugueseDevicesGetBrazilianStories() {
        #expect(StoryLanguage.preferred(from: ["pt-BR", "en-US"]) == .portugueseBrazilian)
        // European Portuguese devices get the pt shelf too, until pt-PT
        // earns its own edition.
        #expect(StoryLanguage.preferred(from: ["pt-PT"]) == .portugueseBrazilian)
    }

    @Test func spanishDevicesGetSpanishStories() {
        #expect(StoryLanguage.preferred(from: ["es-ES", "en-US"]) == .spanish)
        // Language-code matching serves every Spanish region, not just Spain.
        #expect(StoryLanguage.preferred(from: ["es-MX"]) == .spanish)
        #expect(StoryLanguage.preferred(from: ["es-419"]) == .spanish)
    }

    // MARK: - Model language support (pure matching; the live set varies by device)

    @Test func modelSupportMatchesOnLanguageCode() {
        let englishOnly: Set<Locale.Language> = [.init(identifier: "en-US")]
        #expect(ModelStoryEngine.supports(.english, among: englishOnly))
        #expect(!ModelStoryEngine.supports(.norwegianBokmal, among: englishOnly))

        let withNorwegian: Set<Locale.Language> = [
            .init(identifier: "en-US"), .init(identifier: "nb-Latn"),
        ]
        #expect(ModelStoryEngine.supports(.norwegianBokmal, among: withNorwegian))
        // Some systems report the macrolanguage code.
        #expect(ModelStoryEngine.supports(.norwegianBokmal, among: [.init(identifier: "no")]))
    }

    // MARK: - Instructions

    private var norwegianRequest: StoryRequest {
        StoryRequest(
            childName: "Astrid",
            ageBand: .little,
            theme: .animals,
            companion: "Luna katten",
            comfortObject: "det gule teppet",
            language: .norwegianBokmal
        )
    }

    @Test func norwegianInstructionsDemandBokmalAndANorwegianGoodnight() {
        let instructions = ModelStoryEngine.instructions(for: norwegianRequest)
        #expect(instructions.contains("Norwegian bokmål"))
        #expect(instructions.contains("never use phrasing that reads like translated English") ||
            instructions.contains("Never use phrasing that reads like translated English"))
        #expect(instructions.contains("God natt, Astrid."))
        // The always-on framing survives in every language.
        #expect(instructions.contains("calm, kind, and reassuring"))
    }

    @Test func englishInstructionsCarryNoLanguageRule() {
        var request = norwegianRequest
        request.language = .english
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(!instructions.contains("bokmål"))
        #expect(instructions.contains("Goodnight, Astrid."))
    }

    // MARK: - Safety gate in Norwegian

    /// A complete, calm bokmål story that should pass every rule.
    private var norwegianStory: StoryContent {
        StoryContent(
            title: "Astrid og stjernestien",
            pages: [
                "En kveld, akkurat da himmelen ble myk og blå som et teppe, satt Astrid ved vinduet og så på de første stjernene som våknet der ute.",
                "Sammen med Luna katten listet Astrid seg ut i hagen, hvor gresset var lunt og luften luktet av sommer og stille kvelder.",
                "De fulgte en liten sti av månelys helt ned til epletreet, og der satt de lenge og hørte på vinden som sang sin egen lille sang.",
                "Så krøp Astrid under dyna med det gule teppet, og Luna la seg tett inntil. Snart sovnet de begge to. God natt, Astrid.",
            ],
            moral: "De fineste kveldene er de helt stille.",
            language: .norwegianBokmal
        )
    }

    @Test func aCalmNorwegianStoryPassesTheGate() {
        #expect(ContentSafetyCheck.rejection(of: norwegianStory, for: norwegianRequest) == nil)
    }

    @Test func aNorwegianStoryMustWindDownInNorwegian() {
        // An English goodnight on a bokmål last page means the model broke
        // language; the gate must not accept English sleep signals here.
        var story = norwegianStory
        story.pages[story.pages.count - 1] =
            "Luna la seg tett inntil det gule teppet, og alt ble helt stille rundt Astrid. Goodnight, Astrid."
        #expect(ContentSafetyCheck.rejection(of: story, for: norwegianRequest) == .endingNotSleepy)
    }

    @Test func norwegianDeniedWordsAreCaught() {
        var story = norwegianStory
        story.pages[1] =
            "Sammen med Luna katten listet Astrid seg ut i hagen, selv om hun hadde hatt et mareritt natten før, og luften var stille."
        #expect(ContentSafetyCheck.rejection(of: story, for: norwegianRequest) == .deniedWord("mareritt"))
    }

    @Test func englishDeniedWordsAreCaughtInsideANorwegianStory() {
        var story = norwegianStory
        story.pages[2] =
            "De fulgte en liten sti av månelys, og Luna hvisket noe om en ghost som visst bodde bak epletreet i den gamle hagen."
        #expect(ContentSafetyCheck.rejection(of: story, for: norwegianRequest) == .deniedWord("ghost"))
    }

    @Test func norwegianHomonymsOfHarmlessWordsPass() {
        // "dør" (door) is deliberately not on the denylist even though it is
        // also "dies" — a door in a story must not torpedo it.
        var story = norwegianStory
        story.pages[2] =
            "Ved enden av stien sto en gammel grønn dør i muren, og bak den lå en liten hage der alle blomstene allerede hadde lagt seg for kvelden."
        #expect(ContentSafetyCheck.rejection(of: story, for: norwegianRequest) == nil)
    }

    // MARK: - Safety gate in German

    private var germanRequest: StoryRequest {
        StoryRequest(
            childName: "Emil",
            ageBand: .little,
            theme: .animals,
            companion: "Bruno der Hund",
            comfortObject: "die gelbe Decke",
            language: .german
        )
    }

    /// A complete, calm German story that should pass every rule. It leans
    /// on "die" and "war" on purpose — see the false-friend test below.
    private var germanStory: StoryContent {
        StoryContent(
            title: "Emil und der Abendstern",
            pages: [
                "Es war ein stiller Abend, und der Himmel über dem Garten wurde langsam dunkelblau, während Emil am Fenster saß und den ersten Sternen beim Aufwachen zusah.",
                "Zusammen mit Bruno dem Hund schlich Emil hinaus in den Garten, wo das Gras noch warm war und die Luft nach Sommer und leisen Abenden roch.",
                "Sie folgten einer kleinen Spur aus Mondlicht bis zum Apfelbaum, und dort saßen sie lange und lauschten dem Wind, der sein eigenes leises Lied sang.",
                "Dann kroch Emil unter die gelbe Decke, und Bruno rollte sich dicht daneben zusammen. Bald schliefen beide. Gute Nacht, Emil.",
            ],
            moral: "Die schönsten Abende sind die ganz stillen.",
            language: .german
        )
    }

    @Test func aCalmGermanStoryPassesTheGate() {
        #expect(ContentSafetyCheck.rejection(of: germanStory, for: germanRequest) == nil)
    }

    /// The English denylist contains "die", "dies", and "war" — the German
    /// article, "this", and "was". The union must exempt exactly those
    /// three, or every German sentence ever written would be rejected.
    @Test func englishFalseFriendsDoNotPoisonGermanStories() {
        let denied = ContentSafetyCheck.deniedWords(for: .german)
        #expect(!denied.contains("die"))
        #expect(!denied.contains("dies"))
        #expect(!denied.contains("war"))
        // The German words for those concepts hold the line instead.
        #expect(denied.contains("sterben"))
        #expect(denied.contains("Krieg"))
        // And the rest of the English list still applies.
        #expect(denied.contains("ghost"))
        #expect(denied.contains("monster"))
    }

    @Test func aGermanStoryMustWindDownInGerman() {
        var story = germanStory
        story.pages[story.pages.count - 1] =
            "Bruno rollte sich neben der gelben Decke zusammen, und alles wurde ganz still um Emil herum. Goodnight, Emil."
        #expect(ContentSafetyCheck.rejection(of: story, for: germanRequest) == .endingNotSleepy)
    }

    @Test func germanDeniedWordsAreCaught() {
        var story = germanStory
        story.pages[1] =
            "Zusammen mit Bruno dem Hund schlich Emil hinaus in den Garten, obwohl er in der Nacht davor einen Albtraum gehabt hatte, und die Luft roch nach Sommer."
        #expect(ContentSafetyCheck.rejection(of: story, for: germanRequest) == .deniedWord("Albtraum"))
    }

    @Test func englishDeniedWordsAreCaughtInsideAGermanStory() {
        var story = germanStory
        story.pages[2] =
            "Sie folgten einer kleinen Spur aus Mondlicht, und Bruno flüsterte etwas über einen ghost, der angeblich hinter dem Apfelbaum wohnte."
        #expect(ContentSafetyCheck.rejection(of: story, for: germanRequest) == .deniedWord("ghost"))
    }

    @Test func germanInstructionsDemandGermanAndAGermanGoodnight() {
        var request = germanRequest
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(instructions.contains("written in German"))
        #expect(instructions.contains("Gute Nacht, Emil."))
        #expect(instructions.contains("calm, kind, and reassuring"))
        request.language = .english
        #expect(!ModelStoryEngine.instructions(for: request).contains("written in German"))
    }

    // MARK: - Safety gate in Spanish

    private var spanishRequest: StoryRequest {
        StoryRequest(
            childName: "Lucía",
            ageBand: .little,
            theme: .animals,
            companion: "Bruno el perro",
            comfortObject: "la manta amarilla",
            language: .spanish
        )
    }

    /// A complete, calm Spanish story that should pass every rule.
    private var spanishStory: StoryContent {
        StoryContent(
            title: "Lucía y el lucero de la tarde",
            pages: [
                "Era una tarde tranquila, y el cielo sobre el jardín se iba volviendo azul oscuro mientras Lucía miraba por la ventana cómo despertaban las primeras estrellas.",
                "Junto con Bruno el perro, Lucía salió de puntillas al jardín, donde la hierba seguía tibia y el aire olía a verano y a tardes silenciosas.",
                "Siguieron un caminito de luz de luna hasta el manzano, y allí se quedaron un buen rato escuchando al viento, que cantaba su propia canción bajita.",
                "Después Lucía se metió bajo la manta amarilla, y Bruno se acurrucó a su lado. Pronto se durmieron los dos. Buenas noches, Lucía.",
            ],
            moral: "Las tardes más bonitas son las más tranquilas.",
            language: .spanish
        )
    }

    @Test func aCalmSpanishStoryPassesTheGate() {
        #expect(ContentSafetyCheck.rejection(of: spanishStory, for: spanishRequest) == nil)
    }

    /// Unlike German ("die", "dies", "war"), the English denylist contains
    /// no everyday Spanish word — checked word by word when the vocabulary
    /// landed — so the union applies unfiltered.
    @Test func theFullEnglishDenylistAppliesToSpanish() {
        let denied = ContentSafetyCheck.deniedWords(for: .spanish)
        #expect(denied.contains("die"))
        #expect(denied.contains("war"))
        #expect(denied.contains("ghost"))
        #expect(denied.contains("monster"))
        // And the Spanish words hold their own line.
        #expect(denied.contains("guerra"))
        #expect(denied.contains("monstruo"))
    }

    @Test func aSpanishStoryMustWindDownInSpanish() {
        var story = spanishStory
        story.pages[story.pages.count - 1] =
            "Bruno se tumbó junto a la manta amarilla, y todo quedó en silencio alrededor de Lucía. Goodnight, Lucía."
        #expect(ContentSafetyCheck.rejection(of: story, for: spanishRequest) == .endingNotSleepy)
    }

    @Test func spanishDeniedWordsAreCaught() {
        var story = spanishStory
        story.pages[1] =
            "Junto con Bruno el perro, Lucía salió de puntillas al jardín, aunque la noche anterior había tenido una pesadilla, y el aire olía a verano."
        #expect(ContentSafetyCheck.rejection(of: story, for: spanishRequest) == .deniedWord("pesadilla"))
    }

    @Test func englishDeniedWordsAreCaughtInsideASpanishStory() {
        var story = spanishStory
        story.pages[2] =
            "Siguieron un caminito de luz de luna, y Bruno susurró algo sobre un ghost que al parecer vivía detrás del manzano."
        #expect(ContentSafetyCheck.rejection(of: story, for: spanishRequest) == .deniedWord("ghost"))
    }

    @Test func spanishHomonymsOfHarmfulWordsPass() {
        // "de golpe" (suddenly) and "una mata" (a bush) are everyday cozy
        // prose; the denylist deliberately carries the verb inflections
        // ("golpear", "matar") instead of these homonym forms.
        var story = spanishStory
        story.pages[2] =
            "De golpe, el viento se quedó quieto junto a una mata de lavanda, y el jardín entero pareció escuchar la canción bajita de la noche."
        #expect(ContentSafetyCheck.rejection(of: story, for: spanishRequest) == nil)
    }

    @Test func spanishInstructionsDemandSpanishAndASpanishGoodnight() {
        var request = spanishRequest
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(instructions.contains("written in Spanish"))
        #expect(instructions.contains("Buenas noches, Lucía."))
        #expect(instructions.contains("calm, kind, and reassuring"))
        request.language = .english
        #expect(!ModelStoryEngine.instructions(for: request).contains("written in Spanish"))
    }

    // MARK: - Curated fallback across languages

    @Test func anEmptyShelfFallsBackToEnglishTemplates() async throws {
        // Simulates a future sprint language whose shelf has no editorial
        // work yet (the shipped nb shelf is stocked; see NorwegianShelfTests).
        let engine = CuratedStoryEngine(libraries: [
            .english: TemplateLibrary.all,
            .norwegianBokmal: [],
        ])
        let norwegian = try await engine.makeStory(for: norwegianRequest, seed: 42)
        var englishRequest = norwegianRequest
        englishRequest.language = .english
        let english = try await engine.makeStory(for: englishRequest, seed: 42)
        // Same seed, same story — the empty shelf changes nothing but honesty.
        #expect(norwegian == english)
        #expect(norwegian.language == .english)
    }

    @Test func aStockedShelfServesItsOwnLanguage() async throws {
        let nbTemplate = StoryTemplate(
            id: "nb-proof",
            themes: [.animals],
            titleVariants: ["{name} og den lille reven"],
            pages: [
                "En kveld fant {name} og {companion} en liten rev som hadde gått seg bort i {setting}, og de fulgte den hjem i det siste gylne lyset.",
                "Reven takket dem med et blikk så varmt som {comfort}, og et sted langt borte hørtes {sound}, mykt som en pute.",
                "På veien hjem fant de {treasure}, og {name} bar den forsiktig hele veien, mens kvelden ble blåere og blåere rundt dem.",
                "Hjemme igjen krøp {name} under dyna med {comfort}, og {companion} la seg tett inntil. Snart sovnet de. God natt, {name}.",
            ],
            settings: ["den gamle hagen"],
            sounds: ["en myk uglesang"],
            treasures: ["en blank liten stein"],
            moralVariants: ["Den som følger noen hjem, finner alltid veien selv."]
        )
        let engine = CuratedStoryEngine(libraries: [
            .english: TemplateLibrary.all,
            .norwegianBokmal: [nbTemplate],
        ])
        let story = try await engine.makeStory(for: norwegianRequest, seed: 7)
        #expect(story.language == .norwegianBokmal)
        #expect(story.pages.joined().contains("Astrid"))
        // The rendered Norwegian story satisfies the gate it will be held to.
        #expect(ContentSafetyCheck.rejection(of: story, for: norwegianRequest) == nil)
    }
}

// MARK: - French

struct FrenchLanguageGateTests {
    private var request: StoryRequest {
        StoryRequest(
            childName: "Chloé",
            ageBand: .little,
            theme: .adventure,
            companion: "Bruno le chien",
            comfortObject: "la couverture jaune",
            language: .french
        )
    }

    private func story(lastPage: String, language: StoryLanguage = .french) -> StoryContent {
        StoryContent(
            title: "Chloé et la prairie du soir",
            pages: [
                "Chloé entra dans la prairie silencieuse avec Bruno, juste quand les lucioles se réveillaient.",
                "Les lucioles clignotaient bonjour, une par une, et les herbes hautes se balançaient doucement.",
                "Ensemble, ils trouvèrent le coin de mousse le plus doux et regardèrent les étoiles s'allumer.",
                lastPage,
            ],
            moral: "Les soirées douces font les belles nuits.",
            language: language
        )
    }

    @Test func aCalmFrenchStoryPassesTheGate() {
        let content = story(lastPage: "Chloé bâilla, se blottit contre Bruno et s'endormit. Bonne nuit, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func aFrenchStoryMustWindDownInFrench() {
        // An English goodnight on a French last page means the model broke
        // language mid-story; that story never reaches a child.
        let content = story(lastPage: "Chloé se blottit tout contre Bruno. Goodnight and sleep tight, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
        // "se blottit" is a genuine French wind-down, so this passes; strip
        // it and only the English signal remains, which must not count.
        let english = story(lastPage: "Chloé regarda les étoiles avec Bruno. Goodnight, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: english, for: request) == .endingNotSleepy)
    }

    @Test func frenchDeniedWordsAreCaught() {
        let content = story(lastPage: "Chloé eut très peur du grand bois sombre, puis se blottit et s'endormit. Bonne nuit, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("peur"))
    }

    @Test func englishDeniedWordsAreCaughtInsideAFrenchStory() {
        let content = story(lastPage: "Un monster passa au loin, mais Chloé s'endormit vite. Bonne nuit, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("monster"))
    }

    @Test func frenchHomonymsOfHarmfulWordsPass() {
        // "bête" is the standard cozy word for a little creature, "nulle
        // part" is plain "nowhere", and hearts beat with "battre" — none of
        // these may trip the denylist.
        let content = story(lastPage: "La petite bête ne trouvait sa maison nulle part, alors son cœur battait doucement contre Chloé, et elles s'endormirent ensemble. Bonne nuit, Chloé.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func frenchInstructionsDemandFrenchAndAFrenchGoodnight() {
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(instructions.contains("written in French"))
        #expect(instructions.contains("\"tu\""))
        #expect(instructions.contains("Bonne nuit, Chloé."))
    }
}


// MARK: - Italian

struct ItalianLanguageGateTests {
    private var request: StoryRequest {
        StoryRequest(
            childName: "Sofia",
            ageBand: .little,
            theme: .adventure,
            companion: "Bruno il cane",
            comfortObject: "la copertina gialla",
            language: .italian
        )
    }

    private func story(lastPage: String) -> StoryContent {
        StoryContent(
            title: "Sofia e il prato della sera",
            pages: [
                "Sofia entrò nel prato silenzioso con Bruno, proprio mentre le lucciole si svegliavano.",
                "Le lucciole salutavano a intermittenza, una alla volta, e le erbe alte ondeggiavano piano.",
                "Insieme trovarono l'angolo di muschio più morbido e guardarono le stelle accendersi.",
                lastPage,
            ],
            moral: "Le serate dolci fanno le notti belle.",
            language: .italian
        )
    }

    @Test func aCalmItalianStoryPassesTheGate() {
        let content = story(lastPage: "Sofia sbadigliò, si rannicchiò accanto a Bruno e si addormentò. Buonanotte, Sofia.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func anItalianStoryMustWindDownInItalian() {
        let english = story(lastPage: "Sofia guardò le stelle con Bruno. Goodnight, Sofia.")
        #expect(ContentSafetyCheck.rejection(of: english, for: request) == .endingNotSleepy)
    }

    @Test func italianDeniedWordsAreCaught() {
        let content = story(lastPage: "Sofia ebbe tanta paura del bosco scuro, poi si addormentò. Buonanotte, Sofia.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("paura"))
    }

    @Test func englishDeniedWordsAreCaughtInsideAnItalianStory() {
        let content = story(lastPage: "Un monster passò lontano, ma Sofia si addormentò presto. Buonanotte, Sofia.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("monster"))
    }

    @Test func italianHomonymsOfHarmfulWordsPass() {
        // "un brutto sogno che finisce bene" and "non è cattivo" are
        // everyday mild Italian; malvagio holds the wickedness line.
        let content = story(lastPage: "Il piccolo riccio non era cattivo, e dopo un brutto sogno finito bene si addormentò accanto a Sofia. Buonanotte, Sofia.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func italianInstructionsDemandItalianAndAnItalianGoodnight() {
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(instructions.contains("written in Italian"))
        #expect(instructions.contains("Buonanotte, Sofia."))
    }
}


// MARK: - Brazilian Portuguese

struct PortugueseLanguageGateTests {
    private var request: StoryRequest {
        StoryRequest(
            childName: "Alice",
            ageBand: .little,
            theme: .adventure,
            companion: "Bruno, o cachorro",
            comfortObject: "a cobertinha amarela",
            language: .portugueseBrazilian
        )
    }

    private func story(lastPage: String) -> StoryContent {
        StoryContent(
            title: "Alice e o campo da noite",
            pages: [
                "Alice entrou no campo silencioso com Bruno, bem na hora em que os vagalumes acordavam.",
                "Os vagalumes piscavam um oi, um de cada vez, e o capim alto balançava devagarinho.",
                "Juntos, encontraram o cantinho de musgo mais macio e viram as estrelas se acenderem.",
                lastPage,
            ],
            moral: "Noites mansas nascem de finais gentis.",
            language: .portugueseBrazilian
        )
    }

    @Test func aCalmPortugueseStoryPassesTheGate() {
        let content = story(lastPage: "Alice bocejou, se aconchegou no Bruno e adormeceu. Boa noite, Alice.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func aPortugueseStoryMustWindDownInPortuguese() {
        let english = story(lastPage: "Alice olhou as estrelas com Bruno. Goodnight, Alice.")
        #expect(ContentSafetyCheck.rejection(of: english, for: request) == .endingNotSleepy)
    }

    @Test func portugueseDeniedWordsAreCaught() {
        let content = story(lastPage: "Alice sentiu muito medo do bosque escuro, depois adormeceu. Boa noite, Alice.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("medo"))
    }

    @Test func englishDeniedWordsAreCaughtInsideAPortugueseStory() {
        let content = story(lastPage: "Um monster passou bem longe, mas Alice adormeceu rapidinho. Boa noite, Alice.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == .deniedWord("monster"))
    }

    @Test func portugueseHomonymsOfHarmfulWordsPass() {
        // "pela mata" is a walk in the woods, "o burro" is the donkey, and
        // "atirou a bolinha" is throwing a ball — none may trip the list.
        let content = story(lastPage: "O burro simpático atirou a bolinha pela mata uma última vez, e depois todos se aconchegaram com Alice e adormeceram. Boa noite, Alice.")
        #expect(ContentSafetyCheck.rejection(of: content, for: request) == nil)
    }

    @Test func portugueseInstructionsDemandPortugueseAndAPortugueseGoodnight() {
        let instructions = ModelStoryEngine.instructions(for: request)
        #expect(instructions.contains("written in Brazilian Portuguese"))
        #expect(instructions.contains("Boa noite, Alice."))
    }
}
