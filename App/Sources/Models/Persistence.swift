import Foundation
import SwiftData
import Observation

/// Whether the last write to disk actually landed.
///
/// SwiftData's autosave hides failures, and `try?` at a call site hides them
/// twice. Fable cannot put an alert in front of a child at bedtime, so
/// failures are recorded here instead and surfaced quietly in Settings — the
/// one place a parent goes when something seems wrong (external review
/// finding #6: "explicit persistence with error surfacing").
@MainActor
@Observable
final class PersistenceHealth {
    /// The most recent failure, or nil when everything has saved cleanly.
    private(set) var lastFailure: Failure?

    struct Failure: Equatable {
        /// What the app was doing, in words a parent can act on.
        var whileDoing: String
        var date: Date
    }

    func record(_ error: any Error, whileDoing: String) {
        lastFailure = Failure(whileDoing: whileDoing, date: .now)
        // The message itself is developer-facing; the parent sees `whileDoing`.
        assertionFailure("Persistence failure while \(whileDoing): \(error)")
    }

    func clearFailure() {
        lastFailure = nil
    }
}

enum Persistence {
    /// Saves, and says whether it worked. Callers decide what a failure means
    /// for them: the story flow keeps going (bedtime is never broken by a
    /// storage fault), while profile edits report it, because a parent who
    /// just renamed their child needs to know the rename did not stick.
    @MainActor
    @discardableResult
    static func save(
        _ context: ModelContext,
        whileDoing: String,
        health: PersistenceHealth?
    ) -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            health?.record(error, whileDoing: whileDoing)
            return false
        }
    }
}
