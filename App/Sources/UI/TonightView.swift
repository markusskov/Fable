import SwiftUI
import SwiftData

/// The nightly ritual: pick a mood, get tonight's story.
struct TonightView: View {
    let profile: ChildProfile

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var selectedTheme: StoryTheme = .adventure
    @State private var isWriting = false
    @State private var presentedStory: Story?
    @ScaledMetric(relativeTo: .title) private var themeEmojiSize = 30

    private let provider = StoryProvider()

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

                Button(action: tellStory) {
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
            }
            .padding(.horizontal, 24)
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .fableBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    LibraryView(profile: profile)
                } label: {
                    Image(systemName: "books.vertical")
                }
            }
        }
        .navigationDestination(item: $presentedStory) { story in
            ReaderView(story: story)
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
        .animation(.snappy(duration: 0.2), value: selectedTheme)
    }

    private func tellStory() {
        isWriting = true
        let request = StoryRequest(
            childName: profile.name,
            ageBand: profile.ageBand,
            theme: selectedTheme,
            companion: profile.companion,
            comfortObject: profile.comfortObject
        )
        Task {
            // A brief pause makes the moment feel authored, and keeps the UX
            // consistent once on-device model generation (which takes seconds)
            // becomes the primary engine.
            async let pause: Void? = try? await Task.sleep(for: .seconds(0.8))
            let result = await provider.makeStory(for: request)
            _ = await pause

            let story = Story(
                content: result.content,
                theme: selectedTheme,
                childName: profile.name,
                engine: result.engine
            )
            modelContext.insert(story)
            presentedStory = story
            isWriting = false
        }
    }
}
