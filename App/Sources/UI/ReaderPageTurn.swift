import Foundation

/// Pure page-turn arithmetic, kept out of `ReaderView` so it stays testable.
///
/// Tap-to-turn mirrors physical books and e-readers: the left edge goes back,
/// everywhere else goes forward. The back zone is deliberately narrow so a
/// sleepy parent tapping anywhere comfortable always moves the story along.
enum ReaderPageTurn {
    /// Fraction of the page width (from the leading edge) that turns back.
    static let backZoneFraction: Double = 0.3

    /// The page a tap at `locationX` should land on. Clamped to valid pages,
    /// so tapping forward on the last page (or back on the first) is a no-op.
    static func destination(
        tappingAt locationX: Double,
        pageWidth: Double,
        currentPage: Int,
        totalPages: Int
    ) -> Int {
        guard totalPages > 0, pageWidth > 0 else { return currentPage }
        let goingBack = locationX < pageWidth * backZoneFraction
        let target = goingBack ? currentPage - 1 : currentPage + 1
        return min(max(target, 0), totalPages - 1)
    }
}
