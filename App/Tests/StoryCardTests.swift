import Foundation
import Testing
import UIKit
@testable import Fable

@MainActor
struct StoryCardTests {
    private func content(pages: [String], coverArt: Data? = nil) -> StoryCardView.Content {
        .init(
            title: "Nova and the Longest Evening",
            childName: "Nova",
            pages: pages,
            moral: "Even the brightest days need a goodnight.",
            themeEmoji: "🗺️",
            coverArt: coverArt
        )
    }

    private let onePage = ["Once there was a wonderful child named Nova, and the evening was long and golden."]

    @Test func rendersAtTheExportWidth() {
        let image = StoryCardRenderer.render(content(pages: onePage))
        let unwrapped = try! #require(image)
        #expect(unwrapped.size.width * unwrapped.scale == StoryCardView.width * 2,
                "the card must export at exactly 2x the layout width")
    }

    @Test func aLongerStoryMakesATallerCardNeverAClippedOne() {
        let short = StoryCardRenderer.render(content(pages: onePage))
        let long = StoryCardRenderer.render(content(
            pages: Array(repeating: onePage[0] + " " + onePage[0], count: 8)
        ))
        let shortCard = try! #require(short)
        let longCard = try! #require(long)
        #expect(longCard.size.height > shortCard.size.height * 2)
    }

    @Test func aCoverRendersAndAnEmojiFallbackRendersToo() {
        // A tiny real PNG, so UIImage(data:) succeeds inside the card.
        let pixel = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).pngData { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
        #expect(StoryCardRenderer.render(content(pages: onePage, coverArt: pixel)) != nil)
        #expect(StoryCardRenderer.render(content(pages: onePage, coverArt: nil)) != nil)
    }
}
