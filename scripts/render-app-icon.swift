#!/usr/bin/env swift
// Renders the Fable app icon (1024x1024 PNG) with CoreGraphics.
// Deterministic, code-reviewed brand asset — no design tooling required:
//   swift scripts/render-app-icon.swift App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
// Brand language mirrors App/Sources/UI/Theme.swift: night sky into candlelit
// plum, gold moonlight, quiet sparkles.

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let size = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon1024.png"

guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create drawing context")
}

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: r, green: g, blue: b, alpha: a)
}

// Theme.swift constants, lifted verbatim.
let night = color(0.10, 0.11, 0.22)
let nightDeep = color(0.05, 0.06, 0.14)
let ember = color(0.13, 0.08, 0.15)
let gold = color(0.93, 0.78, 0.47)
let goldDeep = color(0.85, 0.66, 0.35)

let canvas = CGRect(x: 0, y: 0, width: size, height: size)

/// The full-bleed sky, drawable repeatedly so shapes can "carve" by
/// re-painting it inside a clip (used for the crescent).
func drawSky(in ctx: CGContext) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [night, nightDeep, ember] as CFArray,
        locations: [0.0, 0.62, 1.0]
    )!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: canvas.midX, y: canvas.maxY),
        end: CGPoint(x: canvas.midX, y: canvas.minY),
        options: []
    )
}

drawSky(in: context)

// Soft moon glow — a radial halo behind the crescent, like the reader's
// title-page glow. Repainted inside the crescent's carve so the carved
// disc matches its surroundings exactly.
let moonCenter = CGPoint(x: 512, y: 560)
func drawGlow(in ctx: CGContext) {
    let glow = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: [color(0.93, 0.78, 0.47, 0.22), color(0.93, 0.78, 0.47, 0.0)] as CFArray,
        locations: [0.0, 1.0]
    )!
    ctx.drawRadialGradient(
        glow,
        startCenter: moonCenter, startRadius: 0,
        endCenter: moonCenter, endRadius: 430,
        options: []
    )
}
drawGlow(in: context)

// The crescent: a gold disc, with the sky re-painted inside an offset disc.
let moonRadius: CGFloat = 258
let moonRect = CGRect(
    x: moonCenter.x - moonRadius, y: moonCenter.y - moonRadius,
    width: moonRadius * 2, height: moonRadius * 2
)
let moonFill = CGGradient(
    colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
    colors: [gold, goldDeep] as CFArray,
    locations: [0.0, 1.0]
)!
context.saveGState()
context.addEllipse(in: moonRect)
context.clip()
context.drawLinearGradient(
    moonFill,
    start: CGPoint(x: moonRect.midX, y: moonRect.maxY),
    end: CGPoint(x: moonRect.midX, y: moonRect.minY),
    options: []
)
context.restoreGState()

let biteOffset = CGPoint(x: moonCenter.x + 118, y: moonCenter.y + 86)
let biteRadius: CGFloat = 224
context.saveGState()
context.addEllipse(in: CGRect(
    x: biteOffset.x - biteRadius, y: biteOffset.y - biteRadius,
    width: biteRadius * 2, height: biteRadius * 2
))
context.clip()
drawSky(in: context)
drawGlow(in: context)
context.restoreGState()

// Quiet four-point sparkles, echoing the app's ✨ moments.
func drawSparkle(in ctx: CGContext, at center: CGPoint, radius: CGFloat, alpha: CGFloat) {
    let waist = radius * 0.18
    let path = CGMutablePath()
    path.move(to: CGPoint(x: center.x, y: center.y + radius))
    path.addQuadCurve(
        to: CGPoint(x: center.x + radius, y: center.y),
        control: CGPoint(x: center.x + waist, y: center.y + waist)
    )
    path.addQuadCurve(
        to: CGPoint(x: center.x, y: center.y - radius),
        control: CGPoint(x: center.x + waist, y: center.y - waist)
    )
    path.addQuadCurve(
        to: CGPoint(x: center.x - radius, y: center.y),
        control: CGPoint(x: center.x - waist, y: center.y - waist)
    )
    path.addQuadCurve(
        to: CGPoint(x: center.x, y: center.y + radius),
        control: CGPoint(x: center.x - waist, y: center.y + waist)
    )
    path.closeSubpath()
    ctx.saveGState()
    ctx.addPath(path)
    ctx.setFillColor(color(0.93, 0.78, 0.47, alpha))
    ctx.fillPath()
    ctx.restoreGState()
}

drawSparkle(in: context, at: CGPoint(x: 268, y: 792), radius: 54, alpha: 0.95)
drawSparkle(in: context, at: CGPoint(x: 780, y: 826), radius: 34, alpha: 0.7)
drawSparkle(in: context, at: CGPoint(x: 214, y: 470), radius: 26, alpha: 0.55)
drawSparkle(in: context, at: CGPoint(x: 812, y: 360), radius: 22, alpha: 0.45)

// Sleeping hills at the foot of the icon — the world already resting.
func drawHill(in ctx: CGContext, centerX: CGFloat, top: CGFloat, radius: CGFloat, fill: CGColor) {
    ctx.saveGState()
    ctx.addEllipse(in: CGRect(
        x: centerX - radius, y: top - radius * 2,
        width: radius * 2, height: radius * 2
    ))
    ctx.setFillColor(fill)
    ctx.fillPath()
    ctx.restoreGState()
}

drawHill(in: context, centerX: 220, top: 190, radius: 560, fill: color(0.085, 0.09, 0.19))
drawHill(in: context, centerX: 850, top: 150, radius: 620, fill: color(0.065, 0.07, 0.16))

guard let image = context.makeImage() else { fatalError("Could not render image") }
let url = URL(fileURLWithPath: outputPath) as CFURL
guard let destination = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil) else {
    fatalError("Could not create image destination")
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else { fatalError("Could not write PNG") }
print("Wrote \(outputPath)")
