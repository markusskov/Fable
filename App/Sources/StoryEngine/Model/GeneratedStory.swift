import FoundationModels

/// Guided-generation schema for on-device story output. The framework
/// constrains decoding to this shape, so we never parse free-form text.
@Generable
struct GeneratedStory {
    @Guide(description: "A short, warm story title of at most eight words. No quotation marks.")
    var title: String

    @Guide(description: "The story told in 6 to 9 pages. Each page, including the final one, is a complete calm scene of at least two full sentences — around 40 to 80 words, never one short sentence alone — that a parent reads aloud slowly in about half a minute. The final page ends by saying goodnight to the child by name. No exclamation marks.", .count(6...9))
    var pages: [String]

    @Guide(description: "One gentle closing sentence with the story's warm takeaway, phrased for a child.")
    var moral: String

    @Guide(description: "One short narrator's sentence that could remind the child tomorrow night what happened in this story, mentioning the most memorable thing. Past tense, warm, no spoilers of feelings — just what happened.")
    var recap: String
}
