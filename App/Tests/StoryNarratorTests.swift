import Foundation
import Testing
@testable import Fable

@MainActor
struct StoryNarratorTests {
    private final class FakeSpeechEngine: SpeechEngine {
        var onUtteranceFinished: (@MainActor () -> Void)?
        private(set) var spoken: [(text: String, language: StoryLanguage, voiceID: String?)] = []
        private(set) var stops = 0

        func speak(_ text: String, language: StoryLanguage, preferredVoiceID: String?) {
            spoken.append((text, language, preferredVoiceID))
        }

        func stop() { stops += 1 }

        func finishCurrent() { onUtteranceFinished?() }
    }

    private let pages = ["A Title", "Page one.", "Page two."]

    @Test func readsFromTheCurrentPageAndTurnsAsItGoes() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        var turns: [Int] = []
        var finishes = 0
        narrator.onPageChange = { turns.append($0) }
        narrator.onFinished = { finishes += 1 }

        narrator.startReading(pages, from: 0, language: .norwegianBokmal)
        #expect(narrator.isReading)
        #expect(engine.spoken.map(\.text) == ["A Title"])
        #expect(engine.spoken.last?.language == .norwegianBokmal)

        engine.finishCurrent()
        engine.finishCurrent()
        #expect(engine.spoken.map(\.text) == pages)
        #expect(turns == [1, 2])

        engine.finishCurrent()
        #expect(!narrator.isReading)
        #expect(finishes == 1)
        // Endings end: a straggling callback must not restart the voice.
        engine.finishCurrent()
        #expect(engine.spoken.count == 3)
        #expect(finishes == 1)
    }

    @Test func stopIsInstantAndStragglersAreIgnored() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        narrator.startReading(pages, from: 1, language: .english)
        narrator.stop()

        #expect(!narrator.isReading)
        #expect(engine.stops == 1)
        engine.finishCurrent()
        #expect(engine.spoken.count == 1, "a stopped narration spoke again")
    }

    @Test func aHandTurningThePageOutranksTheVoice() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        var turns: [Int] = []
        narrator.onPageChange = { turns.append($0) }

        narrator.startReading(pages, from: 0, language: .english)
        narrator.pageWasTurned(to: 2)
        #expect(engine.spoken.map(\.text) == ["A Title", "Page two."])
        #expect(engine.stops == 1)
        // The hand already turned the page; narration must not turn it again.
        #expect(turns.isEmpty)

        // Turning to the page already being read changes nothing.
        narrator.pageWasTurned(to: 2)
        #expect(engine.spoken.count == 2)
    }

    @Test func turnsWhileIdleAreJustTurns() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        narrator.pageWasTurned(to: 1)
        #expect(engine.spoken.isEmpty)
        #expect(engine.stops == 0)
    }

    @Test func aRestartAfterStopBeginsAtTheRequestedPage() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        narrator.startReading(pages, from: 0, language: .english)
        narrator.stop()
        narrator.startReading(pages, from: 2, language: .english, preferredVoiceID: "voice.mum")
        #expect(engine.spoken.last?.text == "Page two.")
        #expect(engine.spoken.last?.voiceID == "voice.mum")
    }

    @Test func anOutOfRangeStartIsClampedNotCrashed() {
        let engine = FakeSpeechEngine()
        let narrator = StoryNarrator(engine: engine)
        narrator.startReading(pages, from: 99, language: .english)
        #expect(engine.spoken.last?.text == "Page two.")
        narrator.stop()
        narrator.startReading(pages, from: -3, language: .english)
        #expect(engine.spoken.last?.text == "A Title")
    }
}

// MARK: - Voice selection rules

@MainActor
struct NarrationVoiceTests {
    /// Narration follows the STAMPED story language, never the device
    /// locale — the same honesty rule as the shelves.
    @Test(arguments: StoryLanguage.allCases)
    func everyStoryLanguageHasASpeechTag(language: StoryLanguage) {
        let tag = SynthesizerSpeechEngine.speechLanguageTag(for: language)
        #expect(tag.count >= 5 && tag.contains("-"))
        #expect(tag.prefix(2) == language.rawValue.prefix(2))
    }

    /// A chosen voice only speaks languages it actually has: an English
    /// Personal Voice must not mangle a Norwegian story.
    @Test func aPreferredVoiceIsHonoredOnlyInItsOwnLanguage() {
        #expect(SynthesizerSpeechEngine.honorsPreferredVoice(speaking: "en-US", for: .english))
        #expect(SynthesizerSpeechEngine.honorsPreferredVoice(speaking: "en-GB", for: .english))
        #expect(!SynthesizerSpeechEngine.honorsPreferredVoice(speaking: "en-US", for: .norwegianBokmal))
        #expect(SynthesizerSpeechEngine.honorsPreferredVoice(speaking: "pt-BR", for: .portugueseBrazilian))
        #expect(!SynthesizerSpeechEngine.honorsPreferredVoice(speaking: "nb-NO", for: .german))
    }
}
