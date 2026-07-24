import SwiftUI

/// The places Fable links out to. One list, used by the paywall footer and
/// the About sheet, so the app can never disagree with itself about where
/// its legal pages live. Terms is Apple's standard EULA (we set no custom
/// EULA in App Store Connect).
enum FableLinks {
    static let privacyPolicy = URL(string: "https://markusskov.github.io/Fable/privacy.html")!
    static let termsOfUse = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let support = URL(string: "https://markusskov.github.io/Fable/")!
}

/// The minimal about surface: what Fable is, which version, and the links
/// Apple requires to be reachable inside the app (privacy policy and terms
/// for a subscription app). Grows into a full settings screen later
/// (profile management, subscription management); until then it stays a
/// quiet single sheet. Links open in the browser; the app itself still
/// makes no network calls.
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                links
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🌙")
                .font(.system(size: 40))
                .accessibilityHidden(true)
            Text(verbatim: "Fable")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
            Text("Bedtime stories, written on this device. Nothing ever leaves it.")
                .font(.subheadline)
                .foregroundStyle(FableTheme.creamDim)
            Text(verbatim: Self.versionLine)
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
        }
    }

    private var links: some View {
        VStack(spacing: 12) {
            linkRow("questionmark.circle", "Support", destination: FableLinks.support)
            linkRow("hand.raised", "Privacy Policy", destination: FableLinks.privacyPolicy)
            linkRow("doc.text", "Terms of Use", destination: FableLinks.termsOfUse)
        }
    }

    private func linkRow(
        _ symbol: String, _ title: LocalizedStringKey, destination: URL
    ) -> some View {
        Link(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.subheadline)
                    .foregroundStyle(FableTheme.gold)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.callout)
                    .foregroundStyle(FableTheme.cream)
                Spacer()
                Image(systemName: "arrow.up.forward")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.creamDim)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    /// "Fable 1.0 (3)" — read from the bundle so release bumps flow through
    /// without touching this file. Not localized: a version is a version.
    private static var versionLine: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "Fable \(version) (\(build))"
    }
}
