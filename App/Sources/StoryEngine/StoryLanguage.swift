import Foundation

/// A language Fable can tell stories in. This is a separate axis from UI
/// localization (the String Catalog): story language drives the model's
/// instructions, the safety gate's vocabulary, and which curated shelf the
/// fallback engine reads from. A language ships here only when all three
/// can hold the line — that is the "model-language honesty" guardrail.
enum StoryLanguage: String, CaseIterable, Sendable, Codable {
    case english = "en"
    case norwegianBokmal = "nb"
    case german = "de"

    /// The language stories are told in by default: the device's first
    /// preferred language that Fable supports, English otherwise. Mirrors
    /// how iOS resolves the UI language, so the story matches the app
    /// around it.
    static var deviceDefault: StoryLanguage {
        preferred(from: Locale.preferredLanguages)
    }

    static func preferred(from identifiers: [String]) -> StoryLanguage {
        for identifier in identifiers {
            let code = Locale.Language(identifier: identifier).languageCode?.identifier ?? identifier
            if let match = allCases.first(where: { $0.matches(code: code) }) {
                return match
            }
        }
        return .english
    }

    /// Whether an ISO 639 code denotes this language. "no" (the Norwegian
    /// macrolanguage) counts as bokmål — systems report Norwegian either way.
    func matches(code: String) -> Bool {
        code == rawValue || (self == .norwegianBokmal && code == "no")
    }

    /// The rule prepended to the model's instructions for non-English
    /// stories; nil for English, whose instructions are already English —
    /// the tuned base prompt must stay byte-identical.
    var modelDirective: String? {
        switch self {
        case .english:
            nil
        case .norwegianBokmal:
            """
            The entire story — title, every page, the moral, and the recap — \
            is written in Norwegian bokmål, in the natural, warm voice of a \
            Norwegian parent telling a bedtime story. Never use phrasing that \
            reads like translated English.
            """
        case .german:
            """
            The entire story — title, every page, the moral, and the recap — \
            is written in German, in the natural, warm voice of a German \
            parent telling a bedtime story; address the child as "du". Never \
            use phrasing that reads like translated English.
            """
        }
    }

    /// The model-facing example of the last page's goodnight sentence.
    func goodnightExample(for name: String) -> String {
        switch self {
        case .english: "Goodnight, \(name)."
        case .norwegianBokmal: "God natt, \(name)."
        case .german: "Gute Nacht, \(name)."
        }
    }
}
