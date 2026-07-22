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

    static var nightSky: LinearGradient {
        LinearGradient(
            colors: [night, nightDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    /// Full-bleed night background used by every screen.
    func fableBackground() -> some View {
        background(FableTheme.nightSky.ignoresSafeArea())
    }
}
