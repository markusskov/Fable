import SwiftUI
import SwiftData
import StoreKit
import UIKit

/// The reading experience: one page at a time, generous serif type,
/// nothing on screen but the story. Swipe or tap to turn pages —
/// left edge goes back, everywhere else goes forward.
struct ReaderView: View {
    let story: Story

    @State private var pageIndex = 0
    @State private var didStartSeries = false
    /// The title-page emblem is decided once, when the reader opens: the
    /// cover if it is already painted, the emoji otherwise — and it stays
    /// put for the whole reading. A cover that finishes mid-read used to
    /// swap in over the emoji on the start screen (owner feedback
    /// 2026-07-28); now it simply greets the family on the next open.
    @State private var emblemCover: Data?
    @State private var narrator = StoryNarrator(engine: SynthesizerSpeechEngine())
    @AppStorage("narrationVoiceID") private var narrationVoiceID = ""
    @Environment(\.requestReview) private var requestReview
    @Query private var allStories: [Story]
    @AppStorage("reviewAskedAt") private var reviewAskedAt = 0.0
    @AppStorage("reviewAskedVersion") private var reviewAskedVersion = ""
    @State private var storyCard: UIImage?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.modelContext) private var modelContext
    @ScaledMetric(relativeTo: .largeTitle) private var emblemSize = 52
    @ScaledMetric(relativeTo: .title2) private var storyLineSpacing = 7

    private var totalPages: Int { story.pages.count + 1 } // + title page

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TabView(selection: $pageIndex) {
                    titlePage.tag(0)
                    ForEach(Array(story.pages.enumerated()), id: \.offset) { index, text in
                        storyPage(text, isLast: index == story.pages.count - 1)
                            .tag(index + 1)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .simultaneousGesture(tapToTurn(pageWidth: geometry.size.width))

                pageProgress
                    .padding(.bottom, 12)
            }
        }
        .readerBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                shareButton
            }
            ToolbarItem(placement: .topBarTrailing) {
                narrationButton
            }
        }
        .sheet(isPresented: Binding(
            get: { storyCard != nil },
            set: { if !$0 { storyCard = nil } }
        )) {
            if let storyCard {
                ActivityShareSheet(image: storyCard)
            }
        }
        // Bedtime pages stay up for minutes at a time; don't let the screen
        // sleep mid-story. Restored on the way out.
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            emblemCover = story.coverArt
            narrator.onPageChange = { index in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    pageIndex = index
                }
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            narrator.stop()
        }
        // A hand turning the page outranks the voice: narration follows.
        .onChange(of: pageIndex) { _, newIndex in
            narrator.pageWasTurned(to: newIndex)
        }
    }

    /// The whole story as one typeset image, handed to the family's group
    /// chat by the system share sheet. A parent control, so it lives in
    /// the toolbar, not on the end page a child is falling asleep to.
    private var shareButton: some View {
        Button {
            storyCard = StoryCardRenderer.render(.init(
                title: story.title,
                childName: story.childName,
                pages: story.pages,
                moral: story.moral,
                themeEmoji: story.theme.emoji,
                coverArt: story.coverArt
            ))
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .accessibilityLabel("Share this story")
        .accessibilityIdentifier("button.shareStory")
    }

    /// Read-aloud toggle. Quiet by design: one small symbol, no sheet, no
    /// autoplay. The voice reads from the page on screen and turns pages
    /// as it goes; stopping is instant.
    private var narrationButton: some View {
        Button {
            if narrator.isReading {
                narrator.stop()
            } else {
                narrator.startReading(
                    [story.title] + story.pages,
                    from: pageIndex,
                    language: story.contentLanguage ?? .english,
                    preferredVoiceID: narrationVoiceID.isEmpty ? nil : narrationVoiceID
                )
            }
        } label: {
            Image(systemName: narrator.isReading ? "pause.circle" : "speaker.wave.2")
        }
        .accessibilityLabel(narrator.isReading
                            ? Text("Pause reading")
                            : Text("Read aloud"))
        .accessibilityIdentifier("button.readAloud")
    }

    private func tapToTurn(pageWidth: CGFloat) -> some Gesture {
        SpatialTapGesture()
            .onEnded { tap in
                let destination = ReaderPageTurn.destination(
                    tappingAt: tap.location.x,
                    pageWidth: pageWidth,
                    currentPage: pageIndex,
                    totalPages: totalPages
                )
                guard destination != pageIndex else { return }
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    pageIndex = destination
                }
            }
    }

    private var titlePage: some View {
        VStack(spacing: 18) {
            Spacer()
            // Cover art when it was already painted at open; the emoji
            // emblem otherwise and always as the silent fallback.
            // Decorative either way — the title below carries the meaning.
            Group {
                if let cover = emblemCover, let image = UIImage(data: cover) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 216, height: 216)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.35), radius: 18, y: 8)
                } else {
                    Text(story.theme.emoji)
                        .font(.system(size: emblemSize))
                        .background(FableTheme.titleGlow.frame(width: 260, height: 260))
                }
            }
            .accessibilityHidden(true)
            Text(story.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
                .multilineTextAlignment(.center)
            if let episode = story.episodeNumber, let seriesTitle = story.series?.title {
                Text("Episode \(episode) of “\(seriesTitle)”")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.gold)
            }
            Text("A story for \(story.childName)")
                .accessibilityIdentifier("reader.titlePage")
                .font(.callout)
                .foregroundStyle(FableTheme.creamDim)
            Spacer()
            Label("Tap or swipe to begin", systemImage: "chevron.right")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
        .fableContentColumn()
    }

    private func storyPage(_ text: String, isLast: Bool) -> some View {
        ScrollView {
            VStack(spacing: 28) {
                Text(text)
                    .font(.system(.title2, design: .serif))
                    .lineSpacing(storyLineSpacing)
                    .foregroundStyle(FableTheme.cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 36)

                if isLast {
                    VStack(spacing: 10) {
                        Text("The End")
                            .accessibilityIdentifier("reader.theEnd")
                            .font(.system(.title3, design: .serif, weight: .semibold))
                            .foregroundStyle(FableTheme.gold)
                        Text(story.moral)
                            .font(.system(.callout, design: .serif))
                            .italic()
                            .foregroundStyle(FableTheme.creamDim)
                            .multilineTextAlignment(.center)
                        Text("Sweet dreams, \(story.childName).")
                            .font(.footnote)
                            .foregroundStyle(FableTheme.creamDim)
                            .padding(.top, 8)

                        seriesFooter
                            .padding(.top, 16)

                        // Owner feedback 2026-07-23: the toolbar back chevron
                        // is easy to miss at the end of a story. A quiet,
                        // explicit way out — deliberately not "read another
                        // story"; endings should end.
                        Button {
                            // The one delight moment Fable will ever ask a
                            // rating at: closing the book on a RE-READ.
                            // The gate (and the system's own caps) decide;
                            // most closes stay perfectly quiet.
                            maybeAskForReview()
                            dismiss()
                        } label: {
                            Label("Close the storybook", systemImage: "book.closed")
                                .accessibilityIdentifier("button.closeStorybook")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(FableTheme.cream)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(FableTheme.card, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
            .fableContentColumn()
        }
    }

    /// On the end page, Fable+ families can turn tonight's story into a
    /// continuing adventure — or see that it already is one. Data-only:
    /// the next episode is told from the Tonight screen, another night.
    @ViewBuilder private var seriesFooter: some View {
        if story.series != nil {
            Label("The adventure continues another night", systemImage: "books.vertical")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
        } else if subscriptions.isSubscribed {
            if didStartSeries {
                Label("Saved. Continue it from the Tonight screen", systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.gold)
            } else {
                Button {
                    startSeries()
                } label: {
                    Label("Make this a continuing adventure", systemImage: "sparkles.rectangle.stack")
                        .accessibilityIdentifier("button.makeSeries")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(FableTheme.nightDeep)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(FableTheme.gold, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func maybeAskForReview() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        guard ReviewPromptGate.shouldAsk(
            closingStoryCreatedAt: story.createdAt,
            storiesTold: allStories.count,
            lastAsked: reviewAskedAt > 0 ? Date(timeIntervalSince1970: reviewAskedAt) : nil,
            lastAskedVersion: reviewAskedVersion.isEmpty ? nil : reviewAskedVersion,
            currentVersion: version
        ) else { return }
        // Recorded BEFORE the request: the system may decline to show
        // anything, and that still spends this version's one ask — never
        // let a quiet decline turn into a retry loop.
        reviewAskedAt = Date.now.timeIntervalSince1970
        reviewAskedVersion = version
        requestReview()
    }

    private func startSeries() {
        let series = StorySeries(title: story.title, theme: story.theme, childName: story.childName)
        series.profileUUID = story.profile?.uuid
        modelContext.insert(series)
        story.episodeNumber = 1
        story.series = series
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            didStartSeries = true
        }
    }

    /// Dots at standard sizes; readable text at accessibility sizes, where
    /// 6-point dots are effectively invisible. VoiceOver treats either as one
    /// adjustable "Page x of y" element.
    @ViewBuilder private var pageProgress: some View {
        Group {
            if typeSize.isAccessibilitySize {
                Text("Page \(pageIndex + 1) of \(totalPages)")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.creamDim)
            } else {
                HStack(spacing: 6) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(index == pageIndex ? FableTheme.gold : FableTheme.cream.opacity(0.2))
                            .frame(width: 6, height: 6)
                    }
                }
                .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: pageIndex)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(pageIndex + 1) of \(totalPages)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: pageIndex = min(pageIndex + 1, totalPages - 1)
            case .decrement: pageIndex = max(pageIndex - 1, 0)
            @unknown default: break
            }
        }
    }
}
