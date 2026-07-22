import SwiftUI

/// Fable's visual language: a warm, dim, end-of-day palette.
/// Bedtime is sacred — nothing bright, nothing loud.
enum FableTheme {
    static let night = Color(red: 0.10, green: 0.11, blue: 0.22)
    static let nightDeep = Color(red: 0.05, green: 0.06, blue: 0.14)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.86)
    static let creamDim = Color(red: 0.97, green: 0.94, blue: 0.86).opacity(0.72)
    static let gold = Color(red: 0.93, green: 0.78, blue: 0.47)
    static let card = Color.white.opacity(0.07)
    // A whisper of warmth for the reader: night shading into candlelit plum.
    static let ember = Color(red: 0.13, green: 0.08, blue: 0.15)

    static var nightSky: LinearGradient {
        LinearGradient(
            colors: [night, nightDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var readerSky: LinearGradient {
        LinearGradient(
            colors: [night, nightDeep, ember],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Soft candle-glow halo used behind the title-page emblem.
    static var titleGlow: RadialGradient {
        RadialGradient(
            colors: [gold.opacity(0.18), .clear],
            center: .center,
            startRadius: 0,
            endRadius: 130
        )
    }
}

extension View {
    /// Full-bleed night background used by every screen.
    func fableBackground() -> some View {
        background(FableTheme.nightSky.ignoresSafeArea())
    }

    /// The reader's slightly warmer take on the night background.
    func readerBackground() -> some View {
        background(FableTheme.readerSky.ignoresSafeArea())
    }
}
