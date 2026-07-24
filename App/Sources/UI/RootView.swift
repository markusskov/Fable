import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
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
                ReaderView(story: story)
            }
        }
        .tint(FableTheme.gold)
        .task { repairLegacyProfiles() }
    }

    /// Profiles persisted before the profile form validated input
    /// (TestFlight builds before PR #34) can hold values today's form
    /// would refuse, and the greeting/profile menu show these fields raw.
    /// One pass on launch makes storage itself safe; profiles created
    /// through the current form are untouched by construction.
    private func repairLegacyProfiles() {
        for profile in profiles {
            let name = ContentSafetyCheck.storableName(from: profile.name)
            if profile.name != name { profile.name = name }
            let companion = ContentSafetyCheck.storableProfileField(from: profile.companion)
            if profile.companion != companion { profile.companion = companion }
            let comfort = ContentSafetyCheck.storableProfileField(from: profile.comfortObject)
            if profile.comfortObject != comfort { profile.comfortObject = comfort }
        }
    }
}
