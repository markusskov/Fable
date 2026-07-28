import AVFoundation

/// The real voice: a thin shell over AVSpeechSynthesizer. On-device
/// text-to-speech only — narration, like everything else, never leaves
/// the phone.
@MainActor
final class SynthesizerSpeechEngine: NSObject, SpeechEngine {
    var onUtteranceFinished: (@MainActor () -> Void)?
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, language: StoryLanguage, preferredVoiceID: String?) {
        // .playback so the story reads even with the ring switch on silent —
        // a parent who pressed play meant it; .spokenAudio pauses other
        // audio (a podcast) instead of mixing over it.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.voice(for: language, preferredVoiceID: preferredVoiceID)
        // Slower than the synthesizer's default: this is a wind-down, not a
        // screen reader. The pause after each utterance is the breath a
        // parent takes at a page turn.
        utterance.rate = 0.42
        utterance.postUtteranceDelay = 0.6
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .word)
    }

    // MARK: - Voice selection

    /// The BCP 47 tag narration asks the system for, per story language.
    /// Follows the stamped story language, never the device locale — a
    /// Norwegian story narrates in Norwegian on an English phone.
    static func speechLanguageTag(for language: StoryLanguage) -> String {
        switch language {
        case .english: "en-US"
        case .norwegianBokmal: "nb-NO"
        case .german: "de-DE"
        case .spanish: "es-ES"
        case .french: "fr-FR"
        case .italian: "it-IT"
        case .portugueseBrazilian: "pt-BR"
        }
    }

    /// A chosen voice is honored only when it can actually speak the
    /// story's language: a Personal Voice recorded in English must not
    /// mangle a Norwegian story. Pure so the rule is testable.
    static func honorsPreferredVoice(speaking voiceLanguage: String, for language: StoryLanguage) -> Bool {
        let wanted = speechLanguageTag(for: language).prefix(2)
        return voiceLanguage.prefix(2) == wanted
    }

    static func voice(for language: StoryLanguage, preferredVoiceID: String?) -> AVSpeechSynthesisVoice? {
        if let preferredVoiceID,
           let preferred = AVSpeechSynthesisVoice(identifier: preferredVoiceID),
           honorsPreferredVoice(speaking: preferred.language, for: language) {
            return preferred
        }
        // Best installed voice for the language: highest quality wins
        // (premium > enhanced > default), ties broken stably by identifier.
        // iOS preinstalls only the "compact" default voice per language;
        // the warmer enhanced/premium voices exist as free downloads under
        // Accessibility > Spoken Content > Voices, and appear here the
        // moment they are installed. Siri's own voices are not available
        // to apps at all (owner asked 2026-07-28) — the download is the
        // best any third-party app can offer.
        let tag = speechLanguageTag(for: language)
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.prefix(2) == tag.prefix(2) && !$0.voiceTraits.contains(.isNoveltyVoice) }
        let best = bestVoiceIdentifier(
            among: candidates.map { ($0.identifier, $0.quality.rawValue) }
        ).flatMap { id in candidates.first { $0.identifier == id } }
        return best ?? AVSpeechSynthesisVoice(language: tag)
    }

    /// Highest quality wins; a quality tie breaks stably to the smallest
    /// identifier so the choice never flips between launches. Pure so the
    /// ordering is testable without installed voices.
    static func bestVoiceIdentifier(among voices: [(identifier: String, quality: Int)]) -> String? {
        voices.max {
            ($0.quality, $1.identifier) < ($1.quality, $0.identifier)
        }?.identifier
    }

    /// The parent's own recorded voices, once iOS has been asked and the
    /// family said yes. Empty until authorized.
    static var personalVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.voiceTraits.contains(.isPersonalVoice) }
    }
}

extension SynthesizerSpeechEngine: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            self.onUtteranceFinished?()
        }
    }
}
