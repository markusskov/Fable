import Foundation

/// The places Fable links out to. One list, used by the paywall footer and
/// Settings, so the app can never disagree with itself about where its legal
/// pages live. Terms is Apple's standard EULA (we set no custom EULA in App
/// Store Connect).
enum FableLinks {
    static let privacyPolicy = URL(string: "https://markusskov.github.io/Fable/privacy.html")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://markusskov.github.io/Fable/")!
}
