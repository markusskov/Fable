import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @Query private var stories: [Story]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var path = NavigationPath()

    /// The child whose stories are on screen. Falls back to the first
    /// profile when the stored id is stale (deleted profile, fresh install).
    private var activeProfile: ChildProfile? {
        profiles.first { $0.uuid.uuidString == activeProfileUUID } ?? profiles.first
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let profile = activeProfile {
                    TonightView(profile: profile, path: $path)
                        .id(profile.uuid) // rebuild state when switching children
                        .transition(.opacity)
                } else {
                    ProfileSetupView()
                        .transition(.opacity)
                }
            }
            // A gentle crossfade when setup hands over to Tonight (and when
            // switching children) — the hard cut read as a glitch on first run.
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.4), value: activeProfile?.uuid)
            // The single Story destination for the whole stack. Declaring it
            // once at the root is load-bearing: a second declaration deeper
            // in the stack (e.g. in LibraryView) is silently ignored by
            // SwiftUI and breaks value-based navigation entirely.
            .navigationDestination(for: Story.self) { story in
                if story.isReaderSafe {
                    ReaderView(story: story)
                } else {
                    ContentUnavailableView(
                        "Story unavailable",
                        systemImage: "book.closed",
                        description: Text("This older story can't be opened safely.")
                    )
                    .fableBackground()
                }
            }
        }
        .tint(FableTheme.gold)
        .task { repairLegacyProfiles() }
    }

    /// Rows persisted before the input boundary existed (TestFlight builds
    /// before PR #34) can hold values today's form would refuse, and the
    /// chrome (greeting, profile menu, reader dedication) shows these fields
    /// raw. One pass on launch makes storage itself safe; rows written by
    /// the current code are untouched by construction. Re-running every
    /// launch with the CURRENT device language also covers language drift
    /// after storage. Story rows without a language stamp predate the all-path
    /// gate; they remain in the store but reader/series surfaces quarantine
    /// them rather than guessing their language or deleting family data.
    private func repairLegacyProfiles() {
        var changed = false
        for profile in profiles {
            let name = ContentSafetyCheck.storableName(from: profile.name)
            if profile.name != name {
                profile.name = name
                changed = true
            }
            let companion = ContentSafetyCheck.storableProfileField(from: profile.companion)
            if profile.companion != companion {
                profile.companion = companion
                changed = true
            }
            let comfort = ContentSafetyCheck.storableProfileField(from: profile.comfortObject)
            if profile.comfortObject != comfort {
                profile.comfortObject = comfort
                changed = true
            }
        }
        for story in stories {
            let language = story.contentLanguage ?? .deviceDefault
            let name = ContentSafetyCheck.storableName(from: story.childName, language: language)
            if story.childName != name {
                story.childName = name
                changed = true
            }
        }
        if changed {
            do {
                try modelContext.save()
            } catch {
                assertionFailure("Could not persist safety repair: \(error)")
            }
        }
    }
}
