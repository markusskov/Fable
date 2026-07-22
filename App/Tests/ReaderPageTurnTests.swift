import Testing
@testable import Fable

struct ReaderPageTurnTests {
    private let width = 400.0
    private let total = 6

    @Test("Tap on the right side advances")
    func tapForward() {
        let next = ReaderPageTurn.destination(
            tappingAt: 300, pageWidth: width, currentPage: 2, totalPages: total
        )
        #expect(next == 3)
    }

    @Test("Tap on the left edge goes back")
    func tapBack() {
        let next = ReaderPageTurn.destination(
            tappingAt: 40, pageWidth: width, currentPage: 2, totalPages: total
        )
        #expect(next == 1)
    }

    @Test("Back zone boundary is exclusive at 30% of width")
    func backZoneBoundary() {
        let atBoundary = ReaderPageTurn.destination(
            tappingAt: width * ReaderPageTurn.backZoneFraction,
            pageWidth: width, currentPage: 2, totalPages: total
        )
        #expect(atBoundary == 3)

        let justInside = ReaderPageTurn.destination(
            tappingAt: width * ReaderPageTurn.backZoneFraction - 1,
            pageWidth: width, currentPage: 2, totalPages: total
        )
        #expect(justInside == 1)
    }

    @Test("Forward on the last page stays put")
    func clampedAtEnd() {
        let next = ReaderPageTurn.destination(
            tappingAt: 300, pageWidth: width, currentPage: total - 1, totalPages: total
        )
        #expect(next == total - 1)
    }

    @Test("Back on the first page stays put")
    func clampedAtStart() {
        let next = ReaderPageTurn.destination(
            tappingAt: 10, pageWidth: width, currentPage: 0, totalPages: total
        )
        #expect(next == 0)
    }

    @Test("Degenerate geometry never moves the page")
    func degenerateInputs() {
        #expect(ReaderPageTurn.destination(tappingAt: 10, pageWidth: 0, currentPage: 1, totalPages: total) == 1)
        #expect(ReaderPageTurn.destination(tappingAt: 10, pageWidth: width, currentPage: 0, totalPages: 0) == 0)
    }
}
