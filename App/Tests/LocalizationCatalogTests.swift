import Foundation
import Testing

/// Guards `App/Resources/Localizable.xcstrings` as data. The catalog compiles
/// into per-locale tables at build time, so a missing or malformed translation
/// never fails the build — English just leaks through (or a bad format
/// specifier garbles a line) at runtime. These tests turn that into a red
/// test instead, which is what keeps the language sprint honest as locales
/// are added: append each new code to `requiredLanguages` in the same PR
/// that adds its translations.
///
/// The catalog is read straight from the repo via `#filePath` — adding it to
/// the test bundle's resources would hand it to the xcstrings compiler, which
/// replaces the raw JSON these tests need.
struct LocalizationCatalogTests {
    /// Every language the app promises a complete UI translation for.
    private static let requiredLanguages = ["nb", "de", "es"]

    /// CLDR plural categories a variation must cover for the languages above
    /// (English, Norwegian, German, and Spanish all use one/other for the
    /// cardinal counts the app can show; Spanish's "many" only starts at a
    /// million, far beyond any meter or trial length).
    private static let requiredPluralCategories: Set<String> = ["one", "other"]

    private let sourceLanguage: String
    /// key → entry dictionary, as raw JSON.
    private let strings: [String: [String: Any]]

    init() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // App/Tests
            .deletingLastPathComponent()  // App
            .appendingPathComponent("Resources/Localizable.xcstrings")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let root = try #require(json as? [String: Any])
        sourceLanguage = try #require(root["sourceLanguage"] as? String)
        strings = try #require(root["strings"] as? [String: [String: Any]])
    }

    /// Keys that opted out of translation (decorative emoji, empty labels).
    private func isTranslatable(_ entry: [String: Any]) -> Bool {
        entry["shouldTranslate"] as? Bool ?? true
    }

    private func localizations(_ entry: [String: Any]) -> [String: [String: Any]] {
        entry["localizations"] as? [String: [String: Any]] ?? [:]
    }

    /// All concrete values of one localization: the plain value, or every
    /// plural variant, tagged with its category (nil for plain values).
    private func values(of localization: [String: Any]) -> [(category: String?, value: String)] {
        if let unit = localization["stringUnit"] as? [String: Any],
           let value = unit["value"] as? String {
            return [(nil, value)]
        }
        guard let variations = localization["variations"] as? [String: Any],
              let plural = variations["plural"] as? [String: [String: Any]]
        else { return [] }
        return plural.compactMap { category, variant in
            guard let unit = variant["stringUnit"] as? [String: Any],
                  let value = unit["value"] as? String
            else { return nil }
            return (category, value)
        }
    }

    /// C-style format specifiers in order of appearance, `%%` excluded.
    private func specifiers(in string: String) -> [String] {
        let pattern = /%(?:\d+\$)?(?:lld|ld|d|@|f|s)/
        return string.matches(of: pattern).map { String($0.output) }
    }

    @Test func sourceLanguageIsEnglish() {
        #expect(sourceLanguage == "en")
    }

    @Test func everyKeyCarriesEveryRequiredLanguage() {
        for (key, entry) in strings where isTranslatable(entry) {
            let locs = localizations(entry)
            for language in Self.requiredLanguages {
                let translated = locs[language].map { !values(of: $0).isEmpty } ?? false
                #expect(translated, "\"\(key)\" has no \(language) translation")
            }
        }
    }

    @Test func pluralVariationsCoverEveryRequiredCategory() {
        for (key, entry) in strings {
            for (language, localization) in localizations(entry) {
                guard localization["variations"] != nil else { continue }
                let categories = Set(values(of: localization).compactMap(\.category))
                let missing = Self.requiredPluralCategories.subtracting(categories).sorted()
                #expect(
                    missing.isEmpty,
                    "\"\(key)\" (\(language)) is missing plural categories: \(missing)"
                )
            }
        }
    }

    /// A translation whose specifiers diverge from its key would garble (or
    /// crash) the formatted string at runtime. The "one" plural variant may
    /// drop the number ("1 uke gratis"); everything else must match exactly.
    @Test func formatSpecifiersMatchTheirKey() {
        for (key, entry) in strings where isTranslatable(entry) {
            let expected = specifiers(in: key)
            for (language, localization) in localizations(entry) {
                for (category, value) in values(of: localization) {
                    let found = specifiers(in: value)
                    if category == "one" {
                        #expect(
                            found.count <= expected.count &&
                                found.allSatisfy(expected.contains),
                            "\"\(key)\" (\(language), one) has specifiers \(found), key has \(expected)"
                        )
                    } else {
                        let variant = category.map { ", \($0)" } ?? ""
                        #expect(
                            found == expected,
                            "\"\(key)\" (\(language)\(variant)) has specifiers \(found), key has \(expected)"
                        )
                    }
                }
            }
        }
    }
}
