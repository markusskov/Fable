import Foundation
import ImagePlayground
import UIKit

/// Produces one cover image for a theme, or throws. Injectable for the same
/// reason the story engines are: the real generator cannot run in CI, and
/// the studio's rules deserve deterministic tests.
protocol CoverArtEngine: Sendable {
    func makeCover(for theme: StoryTheme) async throws -> Data
}

enum CoverArtEngineError: Error {
    case unavailable
}

/// The real engine, a thin shell over ImagePlayground's `ImageCreator`.
/// Every failure collapses to a throw; the studio treats all of them as
/// "no cover tonight" and no one is told (ADR 0004).
struct PlaygroundCoverArtEngine: CoverArtEngine {
    /// On-device styles only, softest first. `.externalProvider` is a style
    /// backed by a third-party service and must NEVER appear here: a cover
    /// generated off-device would break the privacy promise outright.
    static let preferredStyles: [ImagePlaygroundStyle] = [.illustration, .animation, .sketch]

    func makeCover(for theme: StoryTheme) async throws -> Data {
        let creator: ImageCreator
        do {
            creator = try await ImageCreator()
        } catch {
            // notSupported, unavailable, or anything the framework adds
            // later: identical consequence, so one case is honest.
            throw CoverArtEngineError.unavailable
        }
        // Ours preferred-first, and only ever from OUR list: a style the
        // creator offers that we have not vetted (today: externalProvider)
        // must not be picked just because it exists.
        guard let style = Self.preferredStyles.first(where: creator.availableStyles.contains) else {
            throw CoverArtEngineError.unavailable
        }
        let images = creator.images(
            for: [.text(CoverArtPrompt.prompt(for: theme))],
            style: style,
            limit: 1
        )
        for try await created in images {
            if let data = Self.encoded(created.cgImage) {
                return data
            }
        }
        throw CoverArtEngineError.unavailable
    }

    /// HEIC when the hardware encodes it (every device that can run the
    /// generator), JPEG as a belt-and-braces fallback. Covers persist per
    /// story, so size matters more than a lossless format.
    private static func encoded(_ image: CGImage) -> Data? {
        let uiImage = UIImage(cgImage: image)
        return uiImage.heicData() ?? uiImage.jpegData(compressionQuality: 0.85)
    }
}

#if DEBUG
/// Simulator stand-in for UI checks: Apple Intelligence is often unenrolled
/// there, so the real engine throws and the cover branch of the reader and
/// library can never be SEEN. Launch with `-fable-debug-cover-stub`
/// (`simctl launch <udid> com.markusskov.fable -fable-debug-cover-stub`)
/// to paint a flat moonlit placeholder instead. DEBUG-only, like
/// `-fable-debug-plus`.
struct StubCoverArtEngine: CoverArtEngine {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-fable-debug-cover-stub")
    }

    func makeCover(for theme: StoryTheme) async throws -> Data {
        let size = CGSize(width: 512, height: 512)
        let image = UIGraphicsImageRenderer(size: size).image { context in
            UIColor(red: 0.13, green: 0.15, blue: 0.32, alpha: 1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor(red: 0.94, green: 0.80, blue: 0.54, alpha: 1).setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 176, y: 140, width: 160, height: 160))
            let label = theme.emoji as NSString
            label.draw(at: CGPoint(x: 226, y: 330),
                       withAttributes: [.font: UIFont.systemFont(ofSize: 64)])
        }
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw CoverArtEngineError.unavailable
        }
        return data
    }
}
#endif
