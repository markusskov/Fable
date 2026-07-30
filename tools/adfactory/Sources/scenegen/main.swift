// Route B scene generator: Apple's on-device ImageCreator painting the
// emotional layer for ad creatives — illustrated, free, and thematically
// native to a storybook brand. Route A (Nano Banana/Gemini) plugs into
// the same compositing spec if the owner provisions a key.
//
// Usage: swift run --package-path tools/adfactory scenegen <out-dir>

import Foundation
import ImagePlayground
import AppKit

let scenes: [(id: String, prompt: String)] = [
    ("hero", "A small child tucked in bed at night, wide eyed and delighted, a parent silhouette beside the bed reading from a softly glowing phone, warm golden light in a dark cozy bedroom, warm storybook illustration, cozy nighttime blues and deep violet with golden light, soft and calm"),
    ("privacy", "A phone lying face down on a wooden nightstand beside a peacefully sleeping child, moonlight through a window, deep blue night bedroom at rest, warm storybook illustration, cozy nighttime blues and deep violet with golden light, soft and calm"),
    ("fatigue", "A tall worn stack of well loved children's picture books on a nightstand under a small warm lamp, dark cozy bedroom at night, warm storybook illustration, cozy nighttime blues and deep violet with golden light, soft and calm"),
]

let outDir = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "out/scenes")
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

let creator: ImageCreator
do {
    creator = try await ImageCreator()
} catch {
    print("ImageCreator init failed: \(error)")
    exit(2)
}
let style = creator.availableStyles.first { $0 == .illustration } ?? creator.availableStyles.first!
print("style: \(style)")

for scene in scenes {
    let images = creator.images(for: [.text(scene.prompt)], style: style, limit: 1)
    do {
    for try await created in images {
        let rep = NSBitmapImageRep(cgImage: created.cgImage)
        guard let png = rep.representation(using: .png, properties: [:]) else { continue }
        let url = outDir.appendingPathComponent("\(scene.id).png")
        try png.write(to: url)
        print("\(scene.id) -> \(url.path)")
        break
    }
    } catch {
        print("\(scene.id) FAILED: \(error)")
    }
}
