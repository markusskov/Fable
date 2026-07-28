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
        let tag = speechLanguageTag(for: language)
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.prefix(2) == tag.prefix(2) && !$0.voiceTraits.contains(.isNoveltyVoice) }
        let best = candidates.max {
            ($0.quality.rawValue, $1.identifier) < ($1.quality.rawValue, $0.identifier)
        }
        return best ?? AVSpeechSynthesisVoice(language: tag)
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
