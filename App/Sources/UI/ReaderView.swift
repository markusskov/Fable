import SwiftUI

/// The reading experience: one page at a time, generous serif type,
/// nothing on screen but the story.
struct ReaderView: View {
    let story: Story

    @State private var pageIndex = 0

    private var totalPages: Int { story.pages.count + 1 } // + title page

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $pageIndex) {
                titlePage.tag(0)
                ForEach(Array(story.pages.enumerated()), id: \.offset) { index, text in
                    storyPage(text, isLast: index == story.pages.count - 1)
                        .tag(index + 1)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            pageDots
                .padding(.bottom, 12)
        }
        .fableBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var titlePage: some View {
        VStack(spacing: 18) {
            Spacer()
            Text(story.theme.emoji)
                .font(.system(size: 52))
            Text(story.title)
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(FableTheme.cream)
                .multilineTextAlignment(.center)
            Text("A story for \(story.childName)")
                .font(.callout)
                .foregroundStyle(FableTheme.creamDim)
            Spacer()
            Label("Swipe to begin", systemImage: "chevron.right")
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
                    .lineSpacing(7)
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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var pageDots: some View {
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
