import SwiftUI
import SwiftData

@main
struct FableApp: App {
    @State private var subscriptions = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environment(subscriptions)
                // Entitlements resolve in the background; nothing in the story
                // flow waits on the store.
                .task { subscriptions.start() }
        }
        .modelContainer(for: [ChildProfile.self, Story.self, StorySeries.self])
    }
}
