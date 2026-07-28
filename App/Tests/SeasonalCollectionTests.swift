import Foundation
import Synchronization
import Testing
@testable import Fable

struct SeasonalCollectionTests {
    private let engine = CuratedStoryEngine()

    private func date(month: Int, day: Int = 15) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = month
        components.day = day
        return Calendar(identifier: .gregorian).date(from: components)!
    }

    private func request(
        language: StoryLanguage,
        ageBand: AgeBand = .little,
        collectionID: String? = "summer-nights"
    ) -> StoryRequest {
        var request = StoryRequest(
            childName: "Nova",
            ageBand: ageBand,
            theme: .adventure,
            companion: "",
            comfortObject: "",
            language: language
        )
        request.collectionID = collectionID
        return request
    }

    // MARK: - Season windows (ADR 0005)

    @Test func summerFollowsTheHemisphere() {
        let north = Locale.Region("NO")
        let south = Locale.Region("BR")
        let calendar = Calendar(identifier: .gregorian)

        let julyNorth = SeasonalCollections.active(on: date(month: 7), calendar: calendar, region: north)
        #expect(julyNorth.contains { $0.id == "summer-nights" })
        let julySouth = SeasonalCollections.active(on: date(month: 7), calendar: calendar, region: south)
        #expect(!julySouth.contains { $0.id == "summer-nights" },
                "July is winter in Brazil; the summer card would be a season out of place")

        let januarySouth = SeasonalCollections.active(on: date(month: 1), calendar: calendar, region: south)
        #expect(januarySouth.contains { $0.id == "summer-nights" })
        let januaryNorth = SeasonalCollections.active(on: date(month: 1), calendar: calendar, region: north)
        #expect(!januaryNorth.contains { $0.id == "summer-nights" })
    }

    @Test func theWindowEdgesAreExactMonths() {
        let calendar = Calendar(identifier: .gregorian)
        let north = Locale.Region("DE")
        for month in [6, 7, 8] {
            #expect(SeasonalCollections.active(on: date(month: month), calendar: calendar, region: north)
                .contains { $0.id == "summer-nights" })
        }
        for month in [5, 9, 12] {
            #expect(!SeasonalCollections.active(on: date(month: month), calendar: calendar, region: north)
                .contains { $0.id == "summer-nights" })
        }
    }

    /// No region is treated as northern — the majority answer, and a
    /// cosmetic miss at worst.
    @Test func aMissingRegionFallsBackToTheNorthernWindow() {
        #expect(!SeasonalCollections.isSouthernHemisphere(nil))
        let calendar = Calendar(identifier: .gregorian)
        #expect(SeasonalCollections.active(on: date(month: 7), calendar: calendar, region: nil)
            .contains { $0.id == "summer-nights" })
    }

    // MARK: - Editorial parity

    /// Every collection ships every shelf language at once — a premium
    /// feature that speaks English to a German family is broken merchandise
    /// (ADR 0005). Enforced here, not by review vigilance.
    @Test func everyCollectionCarriesEveryShelfLanguage() {
        let shelfLanguages = Set(TemplateLibrary.byLanguage.keys)
        for collection in SeasonalCollections.all {
            #expect(Set(collection.templatesByLanguage.keys) == shelfLanguages,
                    "collection \(collection.id) is missing languages")
        }
    }

    @Test func collectionTemplatesStayOffTheStandingShelves() {
        let shelfTemplateIDs = Set(TemplateLibrary.byLanguage.values.flatMap { $0 }.map(\.id))
        for collection in SeasonalCollections.all {
            for template in collection.templatesByLanguage.values {
                #expect(!shelfTemplateIDs.contains(template.id))
            }
        }
    }

    @Test func collectionIDsAreUnique() {
        let ids = SeasonalCollections.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    // MARK: - Engine routing

    @Test func acollectionRequestForcesTheCollectionTemplate() async throws {
        let story = try await engine.makeStory(for: request(language: .norwegianBokmal), seed: 7)
        #expect(story.language == .norwegianBokmal)
        #expect(story.pages.joined().contains("sommer"),
                "expected the Norwegian summer template, got a shelf story")
        #expect(story.pages.joined().contains("Nova"))
    }

    @Test func theSameSeedTellsTheSameCollectionStory() async throws {
        let first = try await engine.makeStory(for: request(language: .english), seed: 42)
        let second = try await engine.makeStory(for: request(language: .english), seed: 42)
        #expect(first == second)
    }

    /// Unknown ids degrade to the normal shelf: never break bedtime
    /// outranks merchandising.
    @Test func anUnknownCollectionIDFallsBackToTheShelf() async throws {
        let story = try await engine.makeStory(
            for: request(language: .english, collectionID: "winter-tales-2031"),
            seed: 3
        )
        #expect(ContentSafetyCheck.isAcceptable(story, for: request(language: .english)))
        #expect(!story.pages.joined().contains("longest evening"),
                "an unknown id must not serve a collection template")
    }

    /// Collection stories are curated-only (ADR 0005): the premium promise
    /// is editorial quality, so the model must never be consulted.
    @Test func theProviderNeverConsultsTheModelForACollectionStory() async throws {
        let spy = SpyEngine()
        let provider = StoryProvider(model: spy, curated: engine)
        let result = await provider.makeStory(for: request(language: .english))
        #expect(spy.calls == 0, "a collection story rolled the model dice")
        #expect(result.engine == .curated)
        #expect(result.content.pages.joined().contains("summer"))

        _ = await provider.makeStory(for: request(language: .english, collectionID: nil))
        #expect(spy.calls == 1, "ordinary requests must still try the model first")
    }

    private final class SpyEngine: StoryEngine, Sendable {
        private let counter = Mutex(0)
        var calls: Int { counter.withLock { $0 } }
        func makeStory(for request: StoryRequest, seed: UInt64) async throws -> StoryContent {
            counter.withLock { $0 += 1 }
            throw StoryEngineError.unavailable
        }
    }

    // MARK: - The full gate, every language, every band

    /// Every combination the seeded RNG can produce must pass the exact
    /// gate model stories are held to, in the language served — the same
    /// bar as the standing shelves.
    @Test(arguments: StoryLanguage.allCases, AgeBand.allCases)
    func everyRenderedSummerStoryPassesTheGate(language: StoryLanguage, ageBand: AgeBand) async throws {
        for seed in 0..<25 {
            let request = request(language: language, ageBand: ageBand)
            let story = try await engine.makeStory(for: request, seed: UInt64(seed))
            #expect(story.language == language)
            let rejection = ContentSafetyCheck.rejection(of: story, for: request)
            #expect(rejection == nil,
                    "\(language) seed \(seed) band \(ageBand): \(String(describing: rejection))")
        }
    }
}
