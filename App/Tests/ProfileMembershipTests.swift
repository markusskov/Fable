import Foundation
import SwiftData
import Testing
@testable import Fable

@MainActor
struct ProfileMembershipTests {
    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: config
        )
    }

    private func story(named title: String) -> Story {
        Story(
            content: StoryContent(
                title: title,
                pages: ["One.", "Two.", "Three.", "Goodnight."],
                moral: "Rest well."
            ),
            theme: .animals,
            childName: "Nova",
            engine: .curated
        )
    }

    @Test func storiesBelongToTheirChildAndLegacyStoriesToEveryone() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let nova = ChildProfile(name: "Nova", ageBand: .little)
        let astrid = ChildProfile(name: "Astrid", ageBand: .big)
        context.insert(nova)
        context.insert(astrid)

        let novasStory = story(named: "Nova's Tale")
        novasStory.profile = nova
        let legacyStory = story(named: "Old Tale") // pre-profiles, no owner
        context.insert(novasStory)
        context.insert(legacyStory)

        #expect(novasStory.belongs(to: nova))
        #expect(!novasStory.belongs(to: astrid))
        #expect(legacyStory.belongs(to: nova))
        #expect(legacyStory.belongs(to: astrid))
    }

    @Test func seriesBelongToTheirChildAndLegacySeriesToEveryone() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let nova = ChildProfile(name: "Nova", ageBand: .little)
        let astrid = ChildProfile(name: "Astrid", ageBand: .big)
        context.insert(nova)
        context.insert(astrid)

        let novasSeries = StorySeries(title: "Nova and the Fox", theme: .adventure, childName: "Nova")
        novasSeries.profileUUID = nova.uuid
        let legacySeries = StorySeries(title: "Old Adventure", theme: .magic, childName: "Nova")
        context.insert(novasSeries)
        context.insert(legacySeries)

        #expect(novasSeries.belongs(to: nova))
        #expect(!novasSeries.belongs(to: astrid))
        #expect(legacySeries.belongs(to: nova))
        #expect(legacySeries.belongs(to: astrid))
    }

    @Test func profilesKeepDistinctStableIdentity() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let nova = ChildProfile(name: "Nova", ageBand: .little)
        let astrid = ChildProfile(name: "Astrid", ageBand: .big)
        context.insert(nova)
        context.insert(astrid)
        #expect(nova.uuid != astrid.uuid)
        #expect(UUID(uuidString: nova.uuid.uuidString) == nova.uuid)
    }
}
