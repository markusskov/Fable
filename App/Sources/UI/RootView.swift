import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let profile = profiles.first {
                    TonightView(profile: profile, path: $path)
                } else {
                    ProfileSetupView()
                }
            }
            // The single Story destination for the whole stack. Declaring it
            // once at the root is load-bearing: a second declaration deeper
            // in the stack (e.g. in LibraryView) is silently ignored by
            // SwiftUI and breaks value-based navigation entirely.
            .navigationDestination(for: Story.self) { story in
                ReaderView(story: story)
            }
        }
        .tint(FableTheme.gold)
    }
}
