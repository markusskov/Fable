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
    @AppStorage("activeProfileUUID") private var activeProfileUUID = ""
    @Query private var stories: [Story]
    @Query(sort: \StorySeries.createdAt, order: .reverse) private var series: [StorySeries]
    @Query(sort: \ChildProfile.createdAt) private var profiles: [ChildProfile]
    @State private var selectedTheme: StoryTheme = .adventure
    @State private var isWriting = false
    @State private var isShowingPaywall = false
    @State private var isAddingChild = false
    @ScaledMetric(relativeTo: .title) private var themeEmojiSize = 30

    private let provider = StoryProvider()

    /// Fable+ is unlimited; the free tier runs on the meter.
    private var allowance: StoryMeter.Allowance {
        StoryMeter.allowance(storyDates: stories.map(\.createdAt))
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
                    Text("Time for a story,\n\(profile.name)")
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

                let childSeries = series.filter { $0.belongs(to: profile) }
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
                            if isWriting {
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
                    .disabled(isWriting)

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
            return String(localized: "\(remaining) starter stories left — then one free story a week")
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
                        Label(child.name, systemImage: "checkmark")
                    } else {
                        Text(child.name)
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
                Text(profile.name)
                    .font(.subheadline.weight(.medium))
            }
        }
        .accessibilityLabel("Switch child. \(profile.name) is active.")
    }

    private func seriesCard(_ adventure: StorySeries) -> some View {
        Button {
            guard !isWriting else { return }
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
        isWriting = true
        let theme = adventure?.theme ?? selectedTheme
        var request = StoryRequest(
            childName: profile.name,
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
        Task {
            // A brief pause makes the moment feel authored, and keeps the UX
            // consistent once on-device model generation (which takes seconds)
            // becomes the primary engine.
            async let pause: Void? = try? await Task.sleep(for: .seconds(0.8))
            let result = await provider.makeStory(for: request)
            _ = await pause

            let story = Story(
                content: result.content,
                theme: theme,
                childName: profile.name,
                engine: result.engine
            )
            if let adventure {
                story.episodeNumber = adventure.nextEpisodeNumber
                story.series = adventure
            }
            story.profile = profile
            modelContext.insert(story)
            path.append(story)
            isWriting = false
        }
    }
}
