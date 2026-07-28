import Foundation
import Observation

/// Speaks one text and reports back when it finishes. Injectable for the
/// same reason the story and cover engines are: AVSpeechSynthesizer cannot
/// be driven deterministically in CI, and the page-advance rules deserve
/// real tests.
@MainActor
protocol SpeechEngine: AnyObject {
    var onUtteranceFinished: (@MainActor () -> Void)? { get set }
    func speak(_ text: String, language: StoryLanguage, preferredVoiceID: String?)
    func stop()
}

/// Reads a story aloud, one page at a time, turning pages as it goes.
/// Bedtime rules: nothing autoplays, pausing is instant, and when the last
/// page has been read the narration simply ends — endings should end.
@MainActor
@Observable
final class StoryNarrator {
    /// The texts being read, index-aligned with the reader's pages
    /// (0 is the title page, which narrates the story's title).
    private var texts: [String] = []
    private var language: StoryLanguage = .english
    private var preferredVoiceID: String?
    private(set) var isReading = false
    /// The page currently being spoken, valid while `isReading`.
    private(set) var currentIndex = 0

    /// The reader turns its page when narration moves on.
    var onPageChange: (@MainActor (Int) -> Void)?
    /// Fired once when the story has been read to the end.
    var onFinished: (@MainActor () -> Void)?

    private let engine: any SpeechEngine

    init(engine: any SpeechEngine) {
        self.engine = engine
        engine.onUtteranceFinished = { [weak self] in self?.utteranceFinished() }
    }

    /// Begins reading at the given page.
    func startReading(
        _ texts: [String],
        from index: Int,
        language: StoryLanguage,
        preferredVoiceID: String? = nil
    ) {
        guard !texts.isEmpty else { return }
        self.texts = texts
        self.language = language
        self.preferredVoiceID = preferredVoiceID
        currentIndex = min(max(index, 0), texts.count - 1)
        isReading = true
        speakCurrent()
    }

    /// Stops reading where it is. Deliberately a stop, not a pause-resume:
    /// resuming a bedtime story mid-sentence minutes later is jarring, and
    /// play simply starts the current page again.
    func stop() {
        guard isReading else { return }
        isReading = false
        engine.stop()
    }

    /// A hand turned the page while the voice was reading: follow the hand
    /// and continue from the new page. When idle, a turn is just a turn.
    func pageWasTurned(to index: Int) {
        guard isReading, index != currentIndex, texts.indices.contains(index) else { return }
        currentIndex = index
        engine.stop()
        speakCurrent()
    }

    private func speakCurrent() {
        engine.speak(texts[currentIndex], language: language, preferredVoiceID: preferredVoiceID)
    }

    private func utteranceFinished() {
        // A straggler from a stopped read must not restart the voice.
        guard isReading else { return }
        let next = currentIndex + 1
        guard texts.indices.contains(next) else {
            isReading = false
            onFinished?()
            return
        }
        currentIndex = next
        onPageChange?(next)
        speakCurrent()
    }
}
