import Foundation

/// Episode framing for curated series continuations (external review
/// 2026-07-24, finding #5). The curated engine cannot write a bespoke next
/// episode the way the model can, so it is honest about what it IS: a new
/// tale in the same adventure. The framing prepends one "previously on"
/// opening page, in the language of the story actually served, quoting the
/// most recent episode's recap when that recap can be spliced safely.
///
/// The recap is dropped (never the story) when it could break the gate the
/// framed story must still pass: an exclamation mark would spend the calm
/// budget, a denied word in the SERVED language can arrive via a device
/// language switch between episodes, and an overlong recap would burst the
/// age band's page bounds. The frame without a recap still reads as a
/// continuation, which is the honesty floor.
enum CuratedSeriesFraming {
    static func framed(_ content: StoryContent, for request: StoryRequest) -> StoryContent {
        guard let series = request.series, series.episodeNumber > 1 else { return content }
        // The gate allows at most 12 pages; a template that already fills
        // the book keeps its pages rather than lose the story to the frame.
        guard content.pages.count < 12 else { return content }

        let language = content.language
        let strippedName = StoryRequest.bracesStripped(request.childName)
        let hero = strippedName.isEmpty
            ? ContentSafetyCheck.safeGenericName(for: language)
            : strippedName

        let bounds = ContentSafetyCheck.pageLengthBounds(for: request.ageBand)
        var opening = openingPage(language: language, hero: hero, recap: nil)
        if let recap = spliceableRecap(from: series.previously, servedLanguage: language) {
            let withRecap = openingPage(language: language, hero: hero, recap: recap)
            if bounds.contains(withRecap.count) { opening = withRecap }
        }
        // A degenerate hero name could still push the plain frame outside the
        // band; serving the story unframed beats failing the gate into the
        // English emergency story mid-series.
        guard bounds.contains(opening.count) else { return content }

        var framed = content
        framed.pages.insert(opening, at: 0)
        return framed
    }

    /// The newest recap, if it can be spliced into a page of the served
    /// language without endangering the gate. Recaps were gated when their
    /// own episode was accepted, but that was under the language THEY were
    /// written in; the check here re-vets against tonight's language.
    static func spliceableRecap(
        from previously: [String],
        servedLanguage: StoryLanguage
    ) -> String? {
        guard var recap = previously.last?.trimmingCharacters(in: .whitespacesAndNewlines),
              !recap.isEmpty,
              !recap.contains("!"),
              !ContentSafetyCheck.containsDeniedWord(recap, language: servedLanguage)
        else { return nil }
        if let last = recap.last, !".?…»\u{201D}'\"".contains(last) {
            recap += "."
        }
        return recap
    }

    /// One opening page per language, hand-written to each shelf's grammar
    /// discipline (no case-governed slot positions, no contracting
    /// prepositions before the name, gender-neutral address to the child).
    /// The recap arrives as a complete sentence and is quoted after a
    /// question, so both narrative recaps and legacy moral-recaps read
    /// naturally. No dashes (owner copy style).
    private static func openingPage(
        language: StoryLanguage,
        hero: String,
        recap: String?
    ) -> String {
        switch language {
        case .english:
            if let recap {
                "Tonight, \(hero)'s adventure goes on. Remember how it went last time? \(recap) And now, soft and slow, the next part of the story begins."
            } else {
                "Tonight, \(hero)'s adventure goes on, right where it left off. Snuggle in close, because the next part of the story is about to begin, soft and slow."
            }
        case .norwegianBokmal:
            if let recap {
                "I kveld fortsetter eventyret til \(hero). Husker du hvordan det gikk sist? \(recap) Og nå begynner neste del av fortellingen, rolig og stille."
            } else {
                "I kveld fortsetter eventyret til \(hero), akkurat der det slapp sist. Kryp godt inntil, for nå begynner neste del av fortellingen, rolig og stille."
            }
        case .german:
            if let recap {
                "Heute Abend geht das Abenteuer von \(hero) weiter. Weißt du noch, wie es beim letzten Mal war? \(recap) Und nun beginnt, ganz ruhig und leise, das nächste Stück der Geschichte."
            } else {
                "Heute Abend geht das Abenteuer von \(hero) weiter, genau dort, wo es aufgehört hat. Kuschel dich gut ein, denn nun beginnt, ganz ruhig und leise, das nächste Stück der Geschichte."
            }
        case .spanish:
            if let recap {
                "Esta noche continúa la aventura de \(hero). ¿Te acuerdas de cómo fue la última vez? \(recap) Y ahora, despacito y en voz bajita, empieza la siguiente parte del cuento."
            } else {
                "Esta noche continúa la aventura de \(hero), justo donde se quedó. Acurrúcate bien, porque ahora, despacito y en voz bajita, empieza la siguiente parte del cuento."
            }
        case .french:
            if let recap {
                "Ce soir, \(hero) repart à l'aventure, là où l'histoire s'était arrêtée. Tu te souviens de la dernière fois ? \(recap) Et maintenant, tout doucement, la suite de l'histoire commence."
            } else {
                "Ce soir, \(hero) repart à l'aventure, là où l'histoire s'était arrêtée. Blottis-toi bien, car la suite de l'histoire commence maintenant, tout doucement."
            }
        case .italian:
            if let recap {
                "Stasera l'avventura di \(hero) continua. Ti ricordi com'è andata l'ultima volta? \(recap) E adesso, piano piano, comincia la parte nuova della storia."
            } else {
                "Stasera l'avventura di \(hero) continua, proprio da dove si era fermata. Accoccolati bene, perché adesso, piano piano, comincia la parte nuova della storia."
            }
        case .portugueseBrazilian:
            if let recap {
                "Hoje à noite, a aventura de \(hero) continua. Você lembra como foi da última vez? \(recap) E agora, devagarinho, começa a parte nova da história."
            } else {
                "Hoje à noite, a aventura de \(hero) continua, bem de onde parou. Chega mais pertinho, porque agora, devagarinho, começa a parte nova da história."
            }
        }
    }
}
