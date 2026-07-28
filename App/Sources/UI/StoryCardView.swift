import SwiftUI
import UIKit

/// A finished story typeset as one tall, shareable image — the whole tale,
/// cover to moral, on the night background. Rendered on device and handed
/// to the system share sheet; the quiet footer is the only marketing Fable
/// does inside a family's group chat (roadmap, story cards).
struct StoryCardView: View {
    /// Plain values, not the SwiftData model: rendering must not touch a
    /// live store object off the reader's screen.
    struct Content {
        var title: String
        var childName: String
        var pages: [String]
        var moral: String
        var themeEmoji: String
        var coverArt: Data?
    }

    let content: Content
    /// Points; the exported pixel width is this × the renderer scale.
    static let width: CGFloat = 540

    var body: some View {
        VStack(spacing: 28) {
            if let cover = content.coverArt, let image = UIImage(data: cover) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 300, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .padding(.top, 44)
            } else {
                Text(content.themeEmoji)
                    .font(.system(size: 72))
                    .padding(.top, 44)
            }

            VStack(spacing: 10) {
                Text(content.title)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(FableTheme.cream)
                    .multilineTextAlignment(.center)
                Text("A story for \(content.childName)")
                    .font(.callout)
                    .foregroundStyle(FableTheme.creamDim)
            }

            ForEach(Array(content.pages.enumerated()), id: \.offset) { _, page in
                Text(page)
                    .font(.system(.title3, design: .serif))
                    .lineSpacing(6)
                    .foregroundStyle(FableTheme.cream)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 10) {
                Text("The End")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(FableTheme.gold)
                Text(content.moral)
                    .font(.system(.callout, design: .serif))
                    .italic()
                    .foregroundStyle(FableTheme.creamDim)
                    .multilineTextAlignment(.center)
                Text("Sweet dreams, \(content.childName).")
                    .font(.footnote)
                    .foregroundStyle(FableTheme.creamDim)
            }
            .padding(.top, 8)

            Label("Told with Fable", systemImage: "moon.stars")
                .font(.footnote.weight(.medium))
                .foregroundStyle(FableTheme.gold)
                .padding(.top, 20)
                .padding(.bottom, 44)
        }
        .padding(.horizontal, 40)
        .frame(width: Self.width)
        .background(FableTheme.nightSky)
    }
}

/// The system share sheet, unchanged: Messages, AirDrop, Save Image —
/// wherever the family already talks.
struct ActivityShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

@MainActor
enum StoryCardRenderer {
    /// The story as one PNG-ready image, @2x. Returns nil only if UIKit
    /// cannot produce an image at all, which the caller treats as "no
    /// share this time" — never an error at bedtime.
    static func render(_ content: StoryCardView.Content) -> UIImage? {
        let renderer = ImageRenderer(content: StoryCardView(content: content))
        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: StoryCardView.width, height: nil)
        return renderer.uiImage
    }
}
