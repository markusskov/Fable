import SwiftUI
import SwiftData

@main
struct FableApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [ChildProfile.self, Story.self])
    }
}
