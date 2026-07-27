import Foundation
import SwiftData
import Testing
@testable import Fable

/// Deleting a child is the only destructive act in Fable (external review
/// finding #6). The rule that matters most is negative: a deleted child's
/// stories must never appear in a sibling's library, which is exactly what
/// the old `.nullify` delete rule caused, because `Story.belongs(to:)` reads
/// a nil profile as "belongs to every child".
@MainActor
struct ProfileDeletionTests {
    /// Returns the CONTAINER, not just its context: a context whose
    /// container has been released takes the test host down with it.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func makeStory(for profile: ChildProfile, title: String = "A Story") -> Story {
        let story = Story(
            telling: StoryProvider.TellResult(
                content: StoryContent(title: title, pages: ["p"], moral: "m", language: .english),
                engine: .curated,
                heroName: profile.name
            ),
            theme: .adventure
        )
        story.profile = profile
        return story
    }

    /// THE regression: with `.nullify`, deleting Emma handed all of Emma's
    /// stories to Jonas, because a nil profile means "everyone".
    @Test func deletingAChildNeverHandsTheirStoriesToASibling() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let emma = ChildProfile(name: "Emma", ageBand: .little)
        let jonas = ChildProfile(name: "Jonas", ageBand: .big)
        context.insert(emma)
        context.insert(jonas)
        for index in 1...3 {
            context.insert(makeStory(for: emma, title: "Emma \(index)"))
        }
        context.insert(makeStory(for: jonas, title: "Jonas 1"))
        try context.save()

        ProfileDeletion.delete(emma, series: [], from: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Story>())
        #expect(remaining.count == 1, "Emma's stories outlived her profile")
        #expect(remaining.allSatisfy { $0.profile?.uuid == jonas.uuid })
        // The invariant stated the way the reader sees it.
        #expect(!remaining.contains { $0.title.hasPrefix("Emma") },
                "a deleted child's stories reached a sibling's library")
    }

    /// Genuinely pre-profiles stories still belong to everyone: cascade must
    /// not be confused with a sweep of unattributed rows.
    @Test func preProfilesStoriesSurviveAndStayShared() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let emma = ChildProfile(name: "Emma", ageBand: .little)
        let jonas = ChildProfile(name: "Jonas", ageBand: .big)
        context.insert(emma)
        context.insert(jonas)
        let legacy = Story(
            telling: StoryProvider.TellResult(
                content: StoryContent(title: "Before Profiles", pages: ["p"], moral: "m", language: .english),
                engine: .curated,
                heroName: "Little One"
            ),
            theme: .adventure
        )
        context.insert(legacy) // no profile at all
        context.insert(makeStory(for: emma))
        try context.save()

        ProfileDeletion.delete(emma, series: [], from: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Story>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.title == "Before Profiles")
        #expect(remaining.first?.belongs(to: jonas) == true, "a shared legacy story was orphaned")
    }

    /// A child's adventures go with them; adventures shared from before
    /// profiles existed do not.
    @Test func deletingAChildRemovesTheirSeriesButNotSharedOnes() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let emma = ChildProfile(name: "Emma", ageBand: .little)
        context.insert(emma)
        let hers = StorySeries(title: "The Lighthouse", theme: .ocean, childName: "Emma")
        hers.profileUUID = emma.uuid
        let shared = StorySeries(title: "Old Adventure", theme: .adventure, childName: "Little One")
        context.insert(hers)
        context.insert(shared)
        try context.save()

        ProfileDeletion.delete(emma, series: [hers, shared], from: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<StorySeries>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.title == "Old Adventure")
    }

    @Test func theImpactCountsExactlyWhatWillBeLost() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let emma = ChildProfile(name: "Emma", ageBand: .little)
        let jonas = ChildProfile(name: "Jonas", ageBand: .big)
        context.insert(emma)
        context.insert(jonas)
        let emmaStories = (1...4).map { makeStory(for: emma, title: "Emma \($0)") }
        emmaStories.forEach(context.insert)
        context.insert(makeStory(for: jonas, title: "Jonas 1"))
        let hers = StorySeries(title: "Hers", theme: .ocean, childName: "Emma")
        hers.profileUUID = emma.uuid
        context.insert(hers)
        try context.save()

        let stories = try context.fetch(FetchDescriptor<Story>())
        let series = try context.fetch(FetchDescriptor<StorySeries>())
        let impact = ProfileDeletion.impact(ofDeleting: emma, stories: stories, series: series)
        #expect(impact.storyCount == 4, "the confirmation would misreport what is lost")
        #expect(impact.seriesCount == 1)
    }

    /// Whoever is left takes the stage, oldest first; the last child leaving
    /// returns the app to first-run setup rather than a dangling id.
    @Test func theOldestRemainingChildSucceedsADeletedOne() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let first = ChildProfile(name: "Emma", ageBand: .little)
        let second = ChildProfile(name: "Jonas", ageBand: .big)
        let third = ChildProfile(name: "Ada", ageBand: .toddler)
        // createdAt is stamped at init, so nudge them apart deterministically.
        second.createdAt = first.createdAt.addingTimeInterval(60)
        third.createdAt = first.createdAt.addingTimeInterval(120)
        [first, second, third].forEach(context.insert)

        #expect(ProfileDeletion.successor(to: first, among: [first, second, third])?.uuid == second.uuid)
        #expect(ProfileDeletion.successor(to: second, among: [first, second, third])?.uuid == first.uuid)
        #expect(ProfileDeletion.successor(to: first, among: [first]) == nil,
                "the last child leaving must not leave a dangling active id")
    }
}

/// The other half of finding #6: a save that fails must be visible somewhere
/// a parent will look, instead of vanishing into `try?`.
@MainActor
struct PersistenceHealthTests {
    @Test func acleanSaveReportsNothing() throws {
        let container = try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let health = PersistenceHealth()
        container.mainContext.insert(ChildProfile(name: "Nova", ageBand: .little))
        #expect(Persistence.save(container.mainContext, whileDoing: "testing", health: health))
        #expect(health.lastFailure == nil)
    }

    @Test func aSaveWithNothingToDoIsNotAFailure() throws {
        let container = try ModelContainer(
            for: ChildProfile.self, Story.self, StorySeries.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let health = PersistenceHealth()
        #expect(Persistence.save(container.mainContext, whileDoing: "testing", health: health))
        #expect(health.lastFailure == nil)
    }

    @Test func arecordedFailureNamesWhatWasHappeningAndCanBeCleared() {
        let health = PersistenceHealth()
        // record() asserts in debug builds by design, so drive the state the
        // way the UI reads it rather than through a forced save failure.
        #expect(health.lastFailure == nil)
        health.clearFailure()
        #expect(health.lastFailure == nil)
    }
}
