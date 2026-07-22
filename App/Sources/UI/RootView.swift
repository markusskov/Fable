import SwiftUI
import SwiftData

struct RootView: View {
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]

    var body: some View {
        NavigationStack {
            if let profile = profiles.first {
                TonightView(profile: profile)
            } else {
                ProfileSetupView()
            }
        }
        .tint(FableTheme.gold)
    }
}
