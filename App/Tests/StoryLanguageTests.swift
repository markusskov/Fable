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
        // Danish and German are not story languages yet (sprint pending).
        #expect(StoryLanguage.preferred(from: ["da-DK", "de-DE"]) == .english)
        #expect(StoryLanguage.preferred(from: []) == .english)
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

    // MARK: - Curated fallback across languages

    @Test func emptyNorwegianShelfFallsBackToEnglishTemplates() async throws {
        let engine = CuratedStoryEngine()
        let norwegian = try await engine.makeStory(for: norwegianRequest, seed: 42)
        var englishRequest = norwegianRequest
        englishRequest.language = .english
        let english = try await engine.makeStory(for: englishRequest, seed: 42)
        // Same seed, same story — the empty nb shelf changes nothing but honesty.
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
