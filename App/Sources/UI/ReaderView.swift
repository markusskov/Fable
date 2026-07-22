import SwiftUI
import UIKit

/// The reading experience: one page at a time, generous serif type,
/// nothing on screen but the story. Swipe or tap to turn pages —
/// left edge goes back, everywhere else goes forward.
struct ReaderView: View {
    let story: Story

    @State private var pageIndex = 0
    @Environment(\.dynamicTypeSize) private var typeSize
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
        // Bedtime pages stay up for minutes at a time; don't let the screen
        // sleep mid-story. Restored on the way out.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
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
                withAnimation(.easeInOut(duration: 0.35)) {
                    pageIndex = destination
                }
            }
    }

    private var titlePage: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(story.theme.emoji)
                .font(.system(size: emblemSize))
                .background(FableTheme.titleGlow.frame(width: 260, height: 260))
                .accessibilityHidden(true)
            Text(story.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
                .multilineTextAlignment(.center)
            Text("A story for \(story.childName)")
                .font(.callout)
                .foregroundStyle(FableTheme.creamDim)
            Spacer()
            Label("Tap or swipe to begin", systemImage: "chevron.right")
                .font(.footnote)
                .foregroundStyle(FableTheme.creamDim)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, 32)
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
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
                .animation(.snappy(duration: 0.2), value: pageIndex)
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
