import Foundation
import Testing
@testable import Fable

/// The in-app legal links are an App Review requirement (3.1.2) and a legal
/// one: a typo here ships a broken privacy policy. Pin the exact URLs the
/// app promises, matching what App Store Connect and the support site say.
struct FableLinksTests {
    @Test func privacyPolicyMatchesTheLiveSite() {
        #expect(FableLinks.privacyPolicy.absoluteString == "https://markusskov.github.io/Fable/privacy.html")
    }

    @Test func supportMatchesTheLiveSite() {
        #expect(FableLinks.support.absoluteString == "https://markusskov.github.io/Fable/")
    }

    @Test func termsPointAtAppleStandardEULA() {
        #expect(FableLinks.termsOfUse.absoluteString == "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
    }

    @Test func everyLinkIsHTTPS() {
        for url in [FableLinks.privacyPolicy, FableLinks.termsOfUse, FableLinks.support] {
            #expect(url.scheme == "https")
        }
    }
}
