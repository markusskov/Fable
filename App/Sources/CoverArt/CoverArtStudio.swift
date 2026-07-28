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
        let id = story.persistentModelID
        guard !inFlight.contains(id) else { return }
        inFlight.insert(id)
        let theme = story.theme
        Task {
            let data = try? await engine.makeCover(for: theme)
            finish(id, attaching: data, to: story, in: context, health: health)
        }
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
