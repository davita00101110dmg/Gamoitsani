//
//  RecordingTimelineTests.swift
//  GamoitsaniCaptureTests
//

import Foundation
import Testing
@testable import GamoitsaniCapture

@Suite("Recording timeline")
struct RecordingTimelineTests {

    @Test("a classic turn has one word on screen at a time")
    func classicIsSequential() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ბალახი", at: 0)
        timeline.wordAnswered("ბალახი", outcome: .correct, at: 4.2)
        timeline.wordShown("მთვარე", at: 4.2)

        #expect(timeline.entries(at: 2).map(\.word) == ["ბალახი"])
        // The half-open interval: the answered word must not linger into the frame where
        // its replacement appears, or the overlay shows two cards.
        #expect(timeline.entries(at: 4.2).map(\.word) == ["მთვარე"])
    }

    @Test("arcade has five words live at once")
    func arcadeIsConcurrent() {
        var timeline = RecordingTimeline(teamName: "Red")
        for word in ["ა", "ბ", "გ", "დ", "ე"] {
            timeline.wordShown(word, at: 0)
        }
        #expect(timeline.entries(at: 1).count == 5)

        timeline.wordAnswered("გ", outcome: .correct, at: 2)
        #expect(timeline.entries(at: 3).map(\.word) == ["ა", "ბ", "დ", "ე"])
    }

    @Test("the clock running out closes everything still on the table")
    func finishClosesOpenEntries() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.wordShown("ბ", at: 0)
        timeline.wordAnswered("ა", outcome: .correct, at: 5)
        timeline.finish(at: 30)

        #expect(timeline.entries.allSatisfy { !$0.isOpen })
        #expect(timeline.entries.first { $0.word == "ბ" }?.outcome == .unanswered)
        #expect(timeline.duration == 30)
    }

    @Test("nothing is recorded after the turn ends")
    func finishedTimelineIsClosed() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.finish(at: 10)

        timeline.wordShown("ბ", at: 11)
        timeline.wordAnswered("ა", outcome: .skipped, at: 12)

        #expect(timeline.entries.count == 1)
        #expect(timeline.entries[0].outcome == .unanswered, "a late answer must not rewrite it")
        #expect(timeline.duration == 10)
    }

    /// Undo exists in the game, so it has to exist here — otherwise a word taken back by
    /// mistake still scores on the overlay.
    @Test("undo reopens the word and takes back its score")
    func undoReopens() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.wordAnswered("ა", outcome: .correct, at: 3)
        #expect(timeline.correctCount == 1)

        timeline.undoAnswer("ა")
        #expect(timeline.correctCount == 0)
        #expect(timeline.entries(at: 5).map(\.word) == ["ა"], "it is back on screen")
    }

    @Test("the same word twice in a turn closes the right one")
    func repeatedWord() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.wordAnswered("ა", outcome: .correct, at: 2)
        timeline.wordShown("ა", at: 6)
        timeline.wordAnswered("ა", outcome: .skipped, at: 8)

        #expect(timeline.entries.count == 2)
        #expect(timeline.entries[0].outcome == .correct)
        #expect(timeline.entries[1].outcome == .skipped)
    }

    /// The clip's clock and the game's clock are started from different places.
    @Test("an answer arriving before its own word cannot make a negative interval")
    func noNegativeDurations() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 5)
        timeline.wordAnswered("ა", outcome: .correct, at: 4)

        #expect(timeline.entries[0].duration == 0)
        #expect(timeline.entries[0].end == 5)
    }

    @Test("a word answered instantly is still shown for a frame")
    func zeroLengthEntryIsVisible() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 3)
        timeline.wordAnswered("ა", outcome: .correct, at: 3)

        #expect(timeline.entries(at: 3).map(\.word) == ["ა"], "otherwise it never renders")
    }

    @Test("counts follow the outcomes")
    func counts() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        timeline.wordAnswered("ა", outcome: .correct, at: 1)
        timeline.wordShown("ბ", at: 1)
        timeline.wordAnswered("ბ", outcome: .skipped, at: 2)
        timeline.wordShown("გ", at: 2)
        timeline.finish(at: 30)

        #expect(timeline.correctCount == 1)
        #expect(timeline.skippedCount == 1)
    }

    /// It is handed between the recorder and the exporter, so it has to survive the trip.
    @Test("a timeline round-trips")
    func codable() throws {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ბალახი", at: 0)
        timeline.wordAnswered("ბალახი", outcome: .correct, at: 4.2)
        timeline.finish(at: 30)

        let data = try JSONEncoder().encode(timeline)
        #expect(try JSONDecoder().decode(RecordingTimeline.self, from: data) == timeline)
    }
}
