import FoundationModels

/// Guided-generation schema for on-device story output. The framework
/// constrains decoding to this shape, so we never parse free-form text.
@Generable
struct GeneratedStory {
    @Guide(description: "A short, warm story title of at most eight words. No quotation marks.")
    var title: String

    @Guide(description: "The story told in 6 to 9 pages. Each page, including the final one, is a complete calm scene of 2 to 5 soothing sentences — never a single short sentence alone — that a parent reads aloud slowly in about half a minute. The final page ends by saying goodnight to the child by name. No exclamation marks.", .count(6...9))
    var pages: [String]

    @Guide(description: "One gentle closing sentence with the story's warm takeaway, phrased for a child.")
    var moral: String
}
