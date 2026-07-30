// Fable's ad factory: deterministic static creatives for the discovery
// campaign. Brand compliance by construction — the palette, type, and
// layouts are code, so there is no style drift to QA away (the video's
// vision-model police step exists because generative images wander; ours
// cannot). Angle × layout × format is the volume knob.
//
// Usage, from the repo root:
//   swift run --package-path tools/adfactory adfactory [out-dir]
// Inputs: docs/appstore/screenshots/clean/en/*.png and the angle table
// below (source of truth for copy: docs/launch/ad-angles.md).

import SwiftUI
import AppKit

// MARK: - Brand (mirrors App/Sources/UI/Theme.swift + the owner's ad frames)

enum Brand {
    static let night = Color(red: 0.10, green: 0.11, blue: 0.22)
    static let nightDeep = Color(red: 0.05, green: 0.06, blue: 0.14)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.86)
    static let gold = Color(red: 0.93, green: 0.78, blue: 0.47)
    // The owner's night-violet ad direction.
    static let violet = Color(red: 0.42, green: 0.18, blue: 0.72)
    static let violetDeep = Color(red: 0.16, green: 0.07, blue: 0.32)
    static let highlight = Color(red: 0.78, green: 0.65, blue: 0.99)

    static var sky: LinearGradient {
        LinearGradient(colors: [violet, violetDeep, nightDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Angles (copy source of truth: docs/launch/ad-angles.md)

struct Angle {
    let id: String
    let headline: [String]      // words; one gets the highlight color
    let highlightIndex: Int
    let primary: String
    let screenshot: String      // file in the clean/en set
}

let angles: [Angle] = [
    Angle(id: "privacy", headline: ["Made", "on", "your", "phone.", "Kept", "on", "your", "phone."],
          highlightIndex: 4,
          primary: "No account. No ads. No analytics. Privacy label: Data Not Collected.",
          screenshot: "05-setup.png"),
    Angle(id: "hero", headline: ["Tonight's", "story", "stars", "your", "child."],
          highlightIndex: 3,
          primary: "Their name, their sidekick, their cozy blanket. A brand-new story every night.",
          screenshot: "01-reader-title.png"),
    Angle(id: "calm", headline: ["The", "app", "that", "ends", "with", "eyes", "closed."],
          highlightIndex: 5,
          primary: "No streaks. No badges. No notifications. Just a story that lands in sleep.",
          screenshot: "04-reader-end.png"),
    Angle(id: "voice", headline: ["Your", "voice,", "reading.", "Even", "far", "away."],
          highlightIndex: 0,
          primary: "Fable can read tonight's story in your own voice. Recorded on your phone, never uploaded.",
          screenshot: "03-reader-page.png"),
    Angle(id: "struggle", headline: ["Bedtime,", "finally", "calm."],
          highlightIndex: 1,
          primary: "The last fifteen minutes of the day, turned into the calmest.",
          screenshot: "03-reader-page.png"),
    Angle(id: "fresh", headline: ["A", "new", "story", "every", "single", "night."],
          highlightIndex: 1,
          primary: "Tonight a sea voyage, tomorrow a lantern path. Same hero: yours.",
          screenshot: "02-tonight.png"),
    Angle(id: "airplane", headline: ["On-device", "AI.", "Airplane", "mode", "approved."],
          highlightIndex: 0,
          primary: "Stories are written ON the phone. No connection, no cloud, no waiting.",
          screenshot: "02-tonight.png"),
    Angle(id: "series", headline: ["Every", "night,", "a", "new", "chapter."],
          highlightIndex: 4,
          primary: "Last night's story doesn't have to end. Fable continues the adventure.",
          screenshot: "02-tonight.png"),
]

// MARK: - Formats

struct AdFormat {
    let name: String
    let size: CGSize
}

let formats: [AdFormat] = [
    AdFormat(name: "square", size: CGSize(width: 1080, height: 1080)),
    AdFormat(name: "feed", size: CGSize(width: 1080, height: 1350)),
    AdFormat(name: "story", size: CGSize(width: 1080, height: 1920)),
]

// MARK: - Layout

struct AdView: View {
    let angle: Angle
    let format: AdFormat
    let screenshot: NSImage?

    private var scale: CGFloat { format.size.width / 1080 }
    private var isTall: Bool { format.size.height / format.size.width > 1.4 }

    var body: some View {
        ZStack {
            Brand.sky
            VStack(spacing: 36 * scale) {
                headline
                    .padding(.top, 84 * scale)
                    .padding(.horizontal, 72 * scale)
                if let screenshot {
                    device(screenshot)
                }
                Spacer(minLength: 0)
                footer
                    .padding(.bottom, 64 * scale)
            }
        }
        .frame(width: format.size.width, height: format.size.height)
    }

    private var headline: some View {
        // One highlighted word, the owner's ad-frame typography.
        Text(attributedHeadline)
            .font(.system(size: (isTall ? 104 : 88) * scale, weight: .bold, design: .rounded))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
    }

    private var attributedHeadline: AttributedString {
        var result = AttributedString()
        for (index, word) in angle.headline.enumerated() {
            var part = AttributedString(word + (index < angle.headline.count - 1 ? " " : ""))
            part.foregroundColor = index == angle.highlightIndex ? Brand.highlight : .white
            result += part
        }
        return result
    }

    private func device(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: format.size.width * (isTall ? 0.62 : 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 56 * scale))
            .overlay(RoundedRectangle(cornerRadius: 56 * scale)
                .stroke(Brand.highlight.opacity(0.7), lineWidth: 8 * scale))
            .shadow(color: .black.opacity(0.5), radius: 40 * scale, y: 20 * scale)
    }

    private var footer: some View {
        VStack(spacing: 14 * scale) {
            Text(angle.primary)
                .font(.system(size: 34 * scale, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 90 * scale)
            Text("🌙 Fable Bedtime · On the App Store")
                .font(.system(size: 30 * scale, weight: .semibold))
                .foregroundStyle(Brand.gold)
        }
    }
}

// MARK: - Render

@MainActor
func render() throws {
    let arguments = CommandLine.arguments
    let outDir = URL(fileURLWithPath: arguments.count > 1 ? arguments[1] : "out/ads")
    let shotsDir = URL(fileURLWithPath: "docs/appstore/screenshots/clean/en")
    try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

    var manifest: [String] = []
    for angle in angles {
        let shot = NSImage(contentsOf: shotsDir.appendingPathComponent(angle.screenshot))
        for format in formats {
            let view = AdView(angle: angle, format: format, screenshot: shot)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let rep = NSBitmapImageRep(data: tiff),
                  let png = rep.representation(using: .png, properties: [:]) else {
                print("render failed: \(angle.id)-\(format.name)")
                continue
            }
            let name = "\(angle.id)-\(format.name).png"
            try png.write(to: outDir.appendingPathComponent(name))
            manifest.append(name)
        }
    }
    print("\(manifest.count) creatives -> \(outDir.path)")
    for name in manifest { print("  \(name)") }
}

try await MainActor.run { try render() }
