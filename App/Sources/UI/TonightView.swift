import SwiftUI
import SwiftData

/// The nightly ritual: pick a mood, get tonight's story.
struct TonightView: View {
    let profile: ChildProfile
    /// The enclosing stack's path; finished stories are pushed onto it.
    @Binding var path: NavigationPath

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(StoryReservations.self) private var reservations
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""
    @Query private var stories: [Story]
    @Query(sort: \StorySeries.createdAt, order: .reverse) private var series: [StorySeries]
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @State private var selectedTheme: StoryTheme = .adventure
    @State private var writer = StoryWriter()
    @State private var isShowingPaywall = false
    @State private var isAddingChild = false
    @State private var isShowingAbout = false
    @ScaledMetric(relativeTo: .title) private var themeEmojiSize = 30

    private let provider = StoryProvider()

    private func displayName(for profile: ChildProfile) -> String {
        // Memoized: the raw storableName scan walks the whole vocabulary
        // with fresh regexes, and this view re-renders on every theme tap.
        // Uncached it cost 1-2 seconds of visible lag per selection
        // (owner-reported, 2026-07-24).
        ContentSafetyCheck.displayName(for: profile.name)
    }

    /// Fable+ is unlimited; the free tier runs on the meter. Stories being
    /// written right now count too — a reservation is a spent credit even
    /// before its row lands in the store.
    private var allowance: StoryMeter.Allowance {
        StoryMeter.allowance(storyDates: stories.map(\.createdAt) + reservations.dates)
    }

    // Three columns of theme cards, two once type grows into accessibility
    // sizes so labels keep room to breathe instead of truncating.
    private var columns: [GridItem] {
        let count = typeSize.isAccessibilitySize ? 2 : 3
        return Array(repeating: GridItem(.flexible()), count: count)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Good evening")
                        .font(.subheadline)
                        .foregroundStyle(FableTheme.creamDim)
                    Text("Time for a story,\n\(displayName(for: profile))")
                        .font(.system(.largeTitle, design: .serif, weight: .semibold))
                        .foregroundStyle(FableTheme.cream)
                }
                .padding(.top, 12)

                VStack(alignment: .leading, spacing: 12) {
                    Text("What should tonight feel like?")
                        .font(.subheadline)
                        .foregroundStyle(FableTheme.creamDim)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(StoryTheme.allCases) { theme in
                            themeCard(theme)
                        }
                    }
                }

                let childSeries = series.filter {
                    $0.belongs(to: profile) && !$0.isSafetyQuarantined
                }
                if subscriptions.isSubscribed, !childSeries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or continue an adventure")
                            .font(.subheadline)
                            .foregroundStyle(FableTheme.creamDim)
                        ForEach(childSeries) { adventure in
                            seriesCard(adventure)
                        }
                    }
                }

                VStack(spacing: 10) {
                    Button(action: tellStoryTapped) {
                        HStack(spacing: 8) {
                            if writer.isWriting {
                                ProgressView().tint(FableTheme.nightDeep)
                                Text("Writing tonight's story…")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Tell tonight's story")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(FableTheme.nightDeep)
                    .disabled(writer.isWriting)

                    if let caption = meterCaption {
                        Text(caption)
                            .font(.caption)
                            .foregroundStyle(FableTheme.creamDim)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
        // This screen's identity IS the profile (RootView re-ids on switch),
        // so disappearing while another child is active means the family
        // moved on: abandon the write. Being covered by the reader or the
        // library is not a switch and must not abandon it.
        .onDisappear {
            if !writeServesActiveProfile { writer.abandon() }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                profileMenu
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    LibraryView(profile: profile, path: $path)
                } label: {
                    Image(systemName: "books.vertical")
                }
                // Icon-only control; without this VoiceOver reads the raw
                // symbol name.
                .accessibilityLabel("Storybook")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About Fable")
            }
        }
        .sheet(isPresented: $isShowingAbout) {
            AboutView()
        }
        .sheet(isPresented: $isAddingChild) {
            ProfileSetupView(isAddingAnotherChild: true)
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(nextFreeStoryDate: waitingUntil)
        }
    }

    /// The date the meter unlocks, when it is the thing in the way.
    private var waitingUntil: Date? {
        if case .waiting(let date) = allowance { return date }
        return nil
    }

    /// One honest line about where the free tier stands. Subscribers and
    /// mid-starter families with plenty left see nothing — quiet by default.
    private var meterCaption: String? {
        guard !subscriptions.isSubscribed else { return nil }
        switch allowance {
        case .starter(let remaining) where remaining < StoryMeter.starterStories:
            // Singular/plural lives in the string catalog's plural variations.
            return String(localized: "\(remaining) starter stories left, then one free story a week")
        case .starter:
            return nil
        case .weeklyReady:
            return String(localized: "Your free story of the week is ready")
        case .waiting(let date):
            return String(localized: "Next free story \(date.formatted(.relative(presentation: .named)))")
        }
    }

    private func themeCard(_ theme: StoryTheme) -> some View {
        let isSelected = theme == selectedTheme
        return Button {
            selectedTheme = theme
        } label: {
            VStack(spacing: 6) {
                Text(theme.emoji)
                    .font(.system(size: themeEmojiSize))
                    .accessibilityHidden(true)
                Text(theme.displayName)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(isSelected ? FableTheme.nightDeep : FableTheme.cream)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected ? AnyShapeStyle(FableTheme.gold) : AnyShapeStyle(FableTheme.card),
                in: RoundedRectangle(cornerRadius: 16)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: selectedTheme)
    }

    /// Switch children, or bring a new one into the family (Fable+ beyond
    /// the first child; the free tier has one hero).
    private var profileMenu: some View {
        Menu {
            ForEach(profiles) { child in
                Button {
                    activeProfileUUID = child.uuid.uuidString
                } label: {
                    if child.uuid == profile.uuid {
                        Label(displayName(for: child), systemImage: "checkmark")
                    } else {
                        Text(displayName(for: child))
                    }
                }
            }
            Divider()
            Button {
                if subscriptions.isSubscribed {
                    isAddingChild = true
                } else {
                    isShowingPaywall = true
                }
            } label: {
                Label("Add a child", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.circle")
                Text(displayName(for: profile))
                    .font(.subheadline.weight(.medium))
            }
        }
        .accessibilityLabel("Switch child. \(displayName(for: profile)) is active.")
    }

    private func seriesCard(_ adventure: StorySeries) -> some View {
        Button {
            // Authorize the ACTION, not just the card's existence: a
            // revocation can land before SwiftUI removes the row
            // (2026-07-24 review round two).
            guard subscriptions.isSubscribed else {
                isShowingPaywall = true
                return
            }
            tellStory(continuing: adventure)
        } label: {
            HStack(spacing: 12) {
                Text(adventure.theme.emoji)
                    .font(.title3)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(adventure.title)
                        .font(.system(.callout, design: .serif, weight: .medium))
                        .foregroundStyle(FableTheme.cream)
                        .lineLimit(1)
                    Text("Episode \(adventure.nextEpisodeNumber) tonight")
                        .font(.caption)
                        .foregroundStyle(FableTheme.creamDim)
                }
                Spacer()
                Image(systemName: "arrow.right.circle")
                    .foregroundStyle(FableTheme.gold)
            }
            .padding(14)
            .background(FableTheme.card, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func tellStoryTapped() {
        if subscriptions.isSubscribed || allowance.isAllowed {
            tellStory(continuing: nil)
        } else {
            isShowingPaywall = true
        }
    }

    private func tellStory(continuing adventure: StorySeries?) {
        guard !writer.isWriting else { return }
        // Claim the meter slot NOW, synchronously with the allowance check
        // and before any suspension. The household-wide reservation is what
        // stops the same weekly credit being spent once per profile
        // (2026-07-24 money-path review, P1).
        let reservation = reservations.reserve()
        let theme = adventure?.theme ?? selectedTheme
        var request = StoryRequest(
            childName: displayName(for: profile),
            ageBand: profile.ageBand,
            theme: theme,
            companion: profile.companion,
            comfortObject: profile.comfortObject,
            language: .deviceDefault
        )
        if let adventure {
            request.series = StoryRequest.SeriesContext(
                title: adventure.title,
                episodeNumber: adventure.nextEpisodeNumber,
                previously: adventure.recentRecaps()
            )
        }
        writer.write(request, using: provider) { outcome in
            // Abandoned, or the family switched children in the race window
            // before onDisappear could abandon it: refund the claim and tell
            // no one. A story nobody read must not eat a weekly credit.
            guard case .finished(let result) = outcome, writeServesActiveProfile else {
                reservations.release(reservation)
                return
            }
            // Story(telling:) pairs the content with the hero it was written
            // for (round-two P1: raw profile names reached the reader chrome
            // around a neutralized body). For every normal profile that hero
            // IS profile.name; they diverge only when neutralization stepped in.
            let story = Story(telling: result, theme: theme)
            if let adventure {
                // Re-read, not the tap-time snapshot: an episode that landed
                // while this one was being written must not be duplicated
                // (2026-07-24 review, finding #3). The prompt's number is
                // advisory; this one orders the shelf.
                story.episodeNumber = adventure.nextEpisodeNumber
                story.series = adventure
            }
            story.profile = profile
            modelContext.insert(story)
            // Save explicitly BEFORE releasing: the claim hands off to the
            // persisted row, so the row must actually be persisted first
            // (2026-07-24 review round two). If the save throws, autosave
            // will land the insert moments later; either way exactly one of
            // claim-or-row holds the charge at every instant.
            try? modelContext.save()
            // The persisted row carries the meter charge from here on.
            reservations.release(reservation)
            path.append(story)
        }
    }

    /// Whether a story finishing now is still for the child on screen.
    /// An empty stored id means "the fallback first profile", which is this
    /// screen's profile by construction (RootView resolves it that way).
    /// Reads UserDefaults directly, not the @AppStorage wrapper: the deliver
    /// closure can run after this view instance was torn down by a profile
    /// switch, and a torn-down wrapper is not guaranteed to report the live
    /// value — the one moment this guard must not be wrong.
    private var writeServesActiveProfile: Bool {
        Self.writeServesActiveProfile(
            activeProfileUUID: UserDefaults.standard.string(forKey: "activeProfileUUID") ?? "",
            profile: profile.uuid
        )
    }

    static func writeServesActiveProfile(activeProfileUUID: String, profile: UUID) -> Bool {
        activeProfileUUID.isEmpty || activeProfileUUID == profile.uuidString
    }
}
