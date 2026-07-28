import Foundation
import SwiftData
import Observation

/// Paints covers for committed stories, strictly after bedtime is served:
/// the reader is already showing the story when a cover is requested, and
/// nothing in the story flow waits on — or hears about — this object.
/// Success attaches the image and saves quietly; every failure leaves the
/// story exactly as it was, on its emoji emblem (ADR 0004).
@MainActor
@Observable
final class CoverArtStudio {
    private let engine: any CoverArtEngine
    /// Paints that have fully concluded, attached or not. Observable so a
    /// test can wait for an outcome to actually land instead of yielding
    /// and hoping (the StoryWriter.droppedOutcomes pattern).
    private(set) var paintsFinished = 0
    /// Stories being painted right now. Single-flight per story: a second
    /// request while one is in the air would just spend battery on an image
    /// that loses the race to attach.
    @ObservationIgnored private var inFlight: Set<PersistentIdentifier> = []

    init(engine: any CoverArtEngine = PlaygroundCoverArtEngine()) {
        self.engine = engine
    }

    /// Requests a cover for a story that already has none. One attempt, no
    /// retries — cover art is garnish, and background generation is
    /// expensive. Callers never learn the outcome.
    func illustrate(_ story: Story, in context: ModelContext, health: PersistenceHealth?) {
        guard story.coverArt == nil, !story.isDeleted else { return }
        // An episode inherits its series' cover: one visual identity per
        // adventure, like a book series sharing a jacket. Freshly painted
        // episode covers rolled a near-identical scene anyway, because
        // prompts are theme-keyed by design (owner feedback 2026-07-28;
        // story-aware prompts are ruled out by ADR 0004). Inherited from
        // the earliest painted episode so the identity never drifts.
        if let inherited = Self.seriesCover(for: story) {
            story.coverArt = inherited
            Persistence.save(context, whileDoing: "saving a story's cover art", health: health)
            return
        }
        let id = story.persistentModelID
        guard !inFlight.contains(id) else { return }
        inFlight.insert(id)
        let theme = story.theme
        Task {
            let data = try? await engine.makeCover(for: theme)
            finish(id, attaching: data, to: story, in: context, health: health)
        }
    }

    /// The cover of the earliest-numbered episode that has one, or nil for
    /// a story outside any series (or the first of its line).
    private static func seriesCover(for story: Story) -> Data? {
        guard let episodes = story.series?.episodes else { return nil }
        return episodes
            .filter { $0.coverArt != nil }
            .min { ($0.episodeNumber ?? 0, $0.createdAt) < ($1.episodeNumber ?? 0, $1.createdAt) }?
            .coverArt
    }

    private func finish(
        _ id: PersistentIdentifier,
        attaching data: Data?,
        to story: Story,
        in context: ModelContext,
        health: PersistenceHealth?
    ) {
        inFlight.remove(id)
        defer { paintsFinished += 1 }
        // The family may have deleted the story while the paint dried; a
        // cover must never resurrect or touch a deleted row.
        guard let data, !story.isDeleted else { return }
        story.coverArt = data
        Persistence.save(context, whileDoing: "saving a story's cover art", health: health)
    }
}
