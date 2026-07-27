// Redraws a PNG onto opaque black and writes it back without an alpha
// channel. App Store screenshots may not contain transparency, and `sips`
// has no way to drop it (2026-07-26 App Review audit).
//
// Usage: swift scripts/FlattenAlpha.swift <file.png> [more.png ...]
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func flatten(_ path: String) -> Bool {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        FileHandle.standardError.write(Data("could not read \(path)\n".utf8))
        return false
    }
    guard let context = CGContext(
        data: nil,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        // noneSkipLast: three colour channels, no alpha stored at all.
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    ) else {
        FileHandle.standardError.write(Data("could not create context for \(path)\n".utf8))
        return false
    }
    // Black, so any transparent edge matches Fable's night background rather
    // than flashing white.
    context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    guard let flattened = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil
          ) else {
        FileHandle.standardError.write(Data("could not write \(path)\n".utf8))
        return false
    }
    CGImageDestinationAddImage(destination, flattened, nil)
    return CGImageDestinationFinalize(destination)
}

var ok = true
for path in CommandLine.arguments.dropFirst() where !flatten(path) { ok = false }
exit(ok ? 0 : 1)
