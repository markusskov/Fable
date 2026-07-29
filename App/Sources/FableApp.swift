import SwiftUI
import SwiftData

@main
struct FableApp: App {
    @State private var subscriptions = SubscriptionStore()
    @State private var reservations = StoryReservations()
    @State private var persistence = PersistenceHealth()
    // App-scoped so a cover can finish painting across profile switches and
    // navigation; it holds no per-screen state.
    @State private var coverArt = FableApp.makeCoverArtStudio()

    private static func makeCoverArtStudio() -> CoverArtStudio {
        #if DEBUG
        if StubCoverArtEngine.isRequested {
            return CoverArtStudio(engine: StubCoverArtEngine())
        }
        #endif
        return CoverArtStudio()
    }
    @Environment(\.scenePhase) private var scenePhase

    /// Marketing-capture chrome removal: `-fable-clean-chrome` hides the
    /// status bar so screenshot frames start from clean pixels (owner
    /// request 2026-07-29). DEBUG-only, like the other capture flags.
    private static var hidesStatusBar: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-fable-clean-chrome")
        #else
        false
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .statusBarHidden(Self.hidesStatusBar)
                .preferredColorScheme(.dark)
                .environment(subscriptions)
                .environment(reservations)
                .environment(persistence)
                .environment(coverArt)
                // Entitlements resolve in the background; nothing in the story
                // flow waits on the store.
                .task { subscriptions.start() }
                // Coming back to the foreground re-reads entitlements (a
                // subscription can lapse, renew, or be approved while Fable
                // is backgrounded) and retries a failed catalog load, so an
                // offline first launch is not sticky until restart.
                .onChange(of: scenePhase) { _, phase in
                    // Synchronously, in the callback itself: a resumed render
                    // can otherwise happen before the Task below runs and
                    // show a cached "free week" (round eleven, P2). Every
                    // phase change counts, so leaving the app already casts
                    // the doubt that returning resolves.
                    subscriptions.invalidateIntroEligibility()
                    if phase == .active {
                        Task { await subscriptions.refreshOnReturn() }
                    }
                }
        }
        .modelContainer(for: [ChildProfile.self, Story.self, StorySeries.self])
    }
}
