import FoundationModels

/// Guided-generation schema for on-device story output. The framework
/// constrains decoding to this shape, so we never parse free-form text.
@Generable
struct GeneratedStory {
    @Guide(description: "A short, warm story title of at most eight words. No quotation marks.")
    var title: String

    @Guide(description: "The story told in 6 to 9 short pages. Each page is 2 to 4 gentle sentences that a parent reads aloud in about twenty seconds.", .count(6...9))
    var pages: [String]

    @Guide(description: "One gentle closing sentence with the story's warm takeaway, phrased for a child.")
    var moral: String
}
