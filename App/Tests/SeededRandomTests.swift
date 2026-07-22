import Testing
@testable import Fable

struct SeededRandomTests {
    @Test func sameSeedProducesSameSequence() {
        var a = SeededRandom(seed: 42)
        var b = SeededRandom(seed: 42)
        for _ in 0..<100 {
            #expect(a.next() == b.next())
        }
    }

    @Test func differentSeedsDiverge() {
        var a = SeededRandom(seed: 1)
        var b = SeededRandom(seed: 2)
        let aValues = (0..<10).map { _ in a.next() }
        let bValues = (0..<10).map { _ in b.next() }
        #expect(aValues != bValues)
    }

    @Test func pickIsDeterministicAndInBounds() {
        let pool = ["a", "b", "c", "d", "e"]
        var rng1 = SeededRandom(seed: 7)
        var rng2 = SeededRandom(seed: 7)
        for _ in 0..<50 {
            let p1 = pool.pick(using: &rng1)
            let p2 = pool.pick(using: &rng2)
            #expect(p1 == p2)
            #expect(pool.contains(p1))
        }
    }
}
