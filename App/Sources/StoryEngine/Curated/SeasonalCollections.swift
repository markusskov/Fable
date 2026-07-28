import Foundation

/// A premium curated shelf that is only in season part of the year.
/// Collections are editorial assets like the standing shelves: every one
/// ships all seven languages at once (enforced by test), and a collection
/// story is told by the curated engine only — the premium promise is
/// editorial quality, never a model roll (ADR 0005).
struct SeasonalCollection: Identifiable, Sendable {
    let id: String
    /// Shown on the Tonight card next to the localized collection name.
    let emoji: String
    /// The theme a collection story is filed under, so library and reader
    /// emblems stay meaningful. Explicit rather than derived from the
    /// template's theme SET, whose ordering is arbitrary.
    let theme: StoryTheme
    /// Months (1–12) the collection is in season, per hemisphere. Sets, not
    /// ranges: southern summer spans the year boundary (Dec–Feb).
    let northernMonths: Set<Int>
    let southernMonths: Set<Int>
    let templatesByLanguage: [StoryLanguage: StoryTemplate]

    func isInSeason(month: Int, southernHemisphere: Bool) -> Bool {
        (southernHemisphere ? southernMonths : northernMonths).contains(month)
    }
}

enum SeasonalCollections {
    static let all: [SeasonalCollection] = [summerNights]

    static func collection(withID id: String) -> SeasonalCollection? {
        all.first { $0.id == id }
    }

    /// Collections in season right now, by the device's local calendar and
    /// region. Region stands in for hemisphere (ADR 0005): it is data the
    /// OS already exposes, needs no permission, and a wrong region costs a
    /// family nothing but seeing the card in the wrong months.
    static func active(
        on date: Date = .now,
        calendar: Calendar = .current,
        region: Locale.Region? = Locale.current.region
    ) -> [SeasonalCollection] {
        let month = calendar.component(.month, from: date)
        let southern = isSouthernHemisphere(region)
        return all.filter { $0.isInSeason(month: month, southernHemisphere: southern) }
    }

    /// Regions whose temperate seasons are southern. Deliberately omits
    /// equatorial regions (ID, KE, EC …) where "summer" is not a season a
    /// bedtime story would name; they follow the northern window, which is
    /// as right as any single answer can be. Extend as evidence arrives.
    static let southernRegions: Set<String> = [
        "AU", "NZ", "PG", "FJ", "SB", "VU", "NC", "PF", "WS", "TO", "TV", "CK", "NU",
        "AR", "BO", "BR", "CL", "PY", "PE", "UY",
        "ZA", "NA", "BW", "ZW", "MZ", "MG", "LS", "SZ", "MW", "ZM", "AO",
    ]

    static func isSouthernHemisphere(_ region: Locale.Region?) -> Bool {
        guard let region else { return false }
        return southernRegions.contains(region.identifier)
    }
}
