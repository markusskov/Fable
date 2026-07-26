import Foundation
import SwiftData

/// Deleting a child is the one destructive act in Fable, so its rules live in
/// one tested place rather than inside a view (external review finding #6).
///
/// Two things must be true afterwards: the child's stories must never become
/// visible to their siblings, and no orphan adventures may linger. Stories
/// cascade with the profile; series are attached by UUID rather than by a
/// relationship, so they are removed explicitly here.
enum ProfileDeletion {
    /// What a parent is about to lose, so the confirmation can say it plainly.
    struct Impact: Equatable {
        var storyCount: Int
        var seriesCount: Int
    }

    static func impact(
        ofDeleting profile: ChildProfile,
        stories: [Story],
        series: [StorySeries]
    ) -> Impact {
        Impact(
            storyCount: stories.count { $0.profile?.uuid == profile.uuid },
            seriesCount: series.count { $0.profileUUID == profile.uuid }
        )
    }

    /// The profile id that should be active once `profile` is gone: the oldest
    /// remaining child, or nil when the family has none left (which returns
    /// the app to first-run setup).
    static func successor(
        to profile: ChildProfile,
        among profiles: [ChildProfile]
    ) -> ChildProfile? {
        profiles
            .filter { $0.uuid != profile.uuid }
            .min { $0.createdAt < $1.createdAt }
    }

    /// Removes the child, their stories (by cascade), and their adventures.
    /// Series with no profile are pre-profiles data shared by everyone and
    /// are deliberately left alone.
    static func delete(
        _ profile: ChildProfile,
        series: [StorySeries],
        from context: ModelContext
    ) {
        for adventure in series where adventure.profileUUID == profile.uuid {
            context.delete(adventure)
        }
        context.delete(profile)
    }
}
