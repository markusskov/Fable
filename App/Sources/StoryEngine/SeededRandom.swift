import Foundation

/// SplitMix64 — tiny, fast, and deterministic across platforms.
/// Used so curated stories are reproducible in tests (seed in → story out)
/// while feeling fresh in production (seed from system entropy).
struct SeededRandom: RandomNumberGenerator, Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension Array {
    /// Deterministic pick under the caller's generator. Fatal on empty input —
    /// template pools are compile-time data and must never be empty.
    func pick(using rng: inout some RandomNumberGenerator) -> Element {
        precondition(!isEmpty, "pick(using:) called on an empty pool")
        return self[Int(rng.next() % UInt64(count))]
    }
}
