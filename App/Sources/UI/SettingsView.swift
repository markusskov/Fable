import SwiftUI
import SwiftData
import StoreKit

/// The one place a parent goes when they want to change something: who the
/// stories are for, what Fable+ costs, where the legal pages live, and an
/// honest word about how the stories are made. Grew out of the About sheet
/// when external review finding #6 asked for profile management and a home
/// for subscription management.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(PersistenceHealth.self) private var persistence
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""

    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @Query private var stories: [Story]
    @Query private var series: [StorySeries]

    @State private var editingProfile: ChildProfile?
    @State private var profilePendingDeletion: ChildProfile?
    @State private var isAddingChild = false
    @State private var isManagingSubscription = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                if persistence.lastFailure != nil { storageWarning }
                children
                subscription
                howStoriesAreMade
                links
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 32)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
        .presentationDragIndicator(.visible)
        .accessibilityIdentifier("settings.root")
        .sheet(item: $editingProfile) { profile in
            ProfileSetupView(editing: profile)
        }
        .sheet(isPresented: $isAddingChild) {
            ProfileSetupView(isAddingAnotherChild: true)
        }
        .manageSubscriptionsSheet(isPresented: $isManagingSubscription)
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { profilePendingDeletion != nil },
                set: { if !$0 { profilePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { confirmDeletion() }
            Button("Keep", role: .cancel) { profilePendingDeletion = nil }
        } message: {
            Text(deletionMessage)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🌙")
                .font(.system(size: 40))
                .accessibilityHidden(true)
            Text(verbatim: "Fable")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
            Text("Bedtime stories, written on this device. Fable never sends or collects your family's data.")
                .font(.subheadline)
                .foregroundStyle(FableTheme.creamDim)
            Text(verbatim: Self.versionLine)
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
        }
    }

    /// The quiet half of "error surfacing": bedtime never sees an alert, but a
    /// parent who comes looking is told the truth.
    private var storageWarning: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Some changes couldn't be saved", systemImage: "exclamationmark.triangle")
                .font(.callout.weight(.medium))
                .foregroundStyle(FableTheme.gold)
            Text("Your device may be out of storage. Freeing some space and reopening Fable usually fixes it.")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var children: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Children")
            ForEach(profiles) { profile in
                childRow(profile)
            }
            Button {
                if subscriptions.isSubscribed || profiles.isEmpty {
                    isAddingChild = true
                }
            } label: {
                Label(
                    subscriptions.isSubscribed ? "Add a child" : "Add a child (Fable+)",
                    systemImage: "plus"
                )
                .font(.callout)
                .foregroundStyle(subscriptions.isSubscribed ? FableTheme.gold : FableTheme.creamDim)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(!subscriptions.isSubscribed && !profiles.isEmpty)
        }
    }

    private func childRow(_ profile: ChildProfile) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(ContentSafetyCheck.displayName(for: profile.name))
                    .font(.system(.body, design: .serif, weight: .medium))
                    .foregroundStyle(FableTheme.cream)
                Text(profile.ageBand.displayName)
                    .font(.caption)
                    .foregroundStyle(FableTheme.creamDim)
            }
            Spacer()
            Button("Change") { editingProfile = profile }
                .font(.footnote.weight(.medium))
                .foregroundStyle(FableTheme.gold)
                .buttonStyle(.plain)
            Button {
                profilePendingDeletion = profile
            } label: {
                Image(systemName: "trash")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.creamDim)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete \(ContentSafetyCheck.displayName(for: profile.name))")
        }
        .padding(16)
        .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
    }

    private var subscription: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Fable+")
            VStack(alignment: .leading, spacing: 10) {
                Text(subscriptions.isSubscribed
                     ? "Fable+ is active. Thank you for supporting a small, quiet app."
                     : "The free tier is yours forever: one new story every week.")
                    .font(.callout)
                    .foregroundStyle(FableTheme.cream)
                Button("Manage subscription") { isManagingSubscription = true }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(FableTheme.gold)
                    .buttonStyle(.plain)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Transparency the roadmap asked for: families should know that some
    /// nights the story is written by the on-device model and some nights it
    /// comes from the hand-written shelf, and that neither ever leaves.
    private var howStoriesAreMade: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("How stories are made")
            Text("Fable writes on your device, using Apple Intelligence when it is available. When it is not, a hand-written story from Fable's own shelf steps in, so bedtime never waits. Every story is checked for calm, gentle language before you see it, and nothing is ever sent anywhere.")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private var links: some View {
        VStack(spacing: 12) {
            linkRow("questionmark.circle", "Support", destination: FableLinks.support)
            linkRow("hand.raised", "Privacy Policy", destination: FableLinks.privacyPolicy)
            linkRow("doc.text", "Terms of Use", destination: FableLinks.termsOfUse)
        }
    }

    // MARK: - Deletion

    private var deletionTitle: LocalizedStringKey {
        guard let profilePendingDeletion else { return "Delete this child?" }
        return "Delete \(ContentSafetyCheck.displayName(for: profilePendingDeletion.name))?"
    }

    /// Says exactly what is lost. A child's stories are deleted with them
    /// rather than quietly handed to a sibling.
    private var deletionMessage: String {
        guard let profile = profilePendingDeletion else { return "" }
        let impact = ProfileDeletion.impact(ofDeleting: profile, stories: stories, series: series)
        let name = ContentSafetyCheck.displayName(for: profile.name)
        // Three plain sentences rather than one with a plural substitution:
        // every language Fable ships has a simple one/other split, and the
        // single-story case was ungrammatical in English too ("Emma's 1
        // stories"). Also: the count and the name swap places in German and
        // the Romance languages, which positional arguments handle.
        switch impact.storyCount {
        case 0:
            return String(localized: "\(name) has no stories yet. This can't be undone.")
        case 1:
            return String(localized: "\(name)'s story will be deleted too. This can't be undone.")
        default:
            return String(localized: "\(name)'s \(impact.storyCount) stories will be deleted too. This can't be undone.")
        }
    }

    private func confirmDeletion() {
        guard let profile = profilePendingDeletion else { return }
        profilePendingDeletion = nil
        let successor = ProfileDeletion.successor(to: profile, among: profiles)
        ProfileDeletion.delete(profile, series: series, from: modelContext)
        // Point the app at whoever remains BEFORE saving, so a relaunch mid
        // way through can never land on a deleted child.
        activeProfileUUID = successor?.uuid.uuidString ?? ""
        Persistence.save(modelContext, whileDoing: "deleting this child", health: persistence)
        if successor == nil { dismiss() }
    }

    // MARK: - Chrome

    private func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(FableTheme.creamDim)
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
