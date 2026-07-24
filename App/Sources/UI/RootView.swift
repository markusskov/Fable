import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @Query private var stories: [Story]
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

    /// Rows persisted before the input boundary existed (TestFlight builds
    /// before PR #34) can hold values today's form would refuse, and the
    /// chrome (greeting, profile menu, reader dedication) shows these fields
    /// raw. One pass on launch makes storage itself safe; rows written by
    /// the current code are untouched by construction. Re-running every
    /// launch with the CURRENT device language also covers language drift
    /// after storage. Story BODIES are deliberately out of scope: legacy
    /// rows carry no language stamp, and a cross-language vocabulary scan
    /// would flag ordinary German "die"/"war" — the false-friend trap.
    /// Bodies were gated at creation; the residual risk is confined to
    /// pre-#34 installs, which are TestFlight-only.
    private func repairLegacyProfiles() {
        for profile in profiles {
            let name = ContentSafetyCheck.storableName(from: profile.name)
            if profile.name != name { profile.name = name }
            let companion = ContentSafetyCheck.storableProfileField(from: profile.companion)
            if profile.companion != companion { profile.companion = companion }
            let comfort = ContentSafetyCheck.storableProfileField(from: profile.comfortObject)
            if profile.comfortObject != comfort { profile.comfortObject = comfort }
        }
        for story in stories {
            let name = ContentSafetyCheck.storableName(from: story.childName)
            if story.childName != name { story.childName = name }
        }
    }
}
