//
//  HighlightsTests.swift
//  GamoitsaniCaptureTests
//

import Foundation
import Testing
@testable import GamoitsaniCapture

@Suite("Highlights")
struct HighlightsTests {

    private let policy = HighlightPolicy()

    /// A turn where `word` was on screen from `start` until it was guessed at `end`.
    private func turn(
        length: TimeInterval,
        _ answers: [(word: String, start: TimeInterval, end: TimeInterval, outcome: RecordingOutcome)]
    ) -> RecordingTimeline {
        var timeline = RecordingTimeline(teamName: "Blue")
        for answer in answers {
            timeline.wordShown(answer.word, at: answer.start)
            timeline.wordAnswered(answer.word, outcome: answer.outcome, at: answer.end)
        }
        timeline.finish(at: length)
        return timeline
    }

    @Test("a word that hung there and was then guessed is kept")
    func struggle() {
        let timeline = turn(length: 45, [("ბალახი", 0, 20, .correct)])
        let reel = policy.highlights(from: [timeline])

        let first = try! #require(reel.first)
        #expect(first.kind == .struggle)
        #expect(first.words == ["ბალახი"])
        // The run-up, not the whole twenty seconds of silence.
        #expect(first.start == 20 - policy.leadIn)
        #expect(first.end == 20 + policy.tail)
    }

    @Test("a quick guess is not a struggle")
    func quickIsNotStruggle() {
        let timeline = turn(length: 45, [("ბალახი", 0, 2, .correct)])
        #expect(!policy.highlights(from: [timeline]).contains { $0.kind == .struggle })
    }

    @Test("a guess as the clock runs out is kept")
    func buzzerBeater() {
        let timeline = turn(length: 30, [("მთვარე", 25, 29, .correct)])
        let reel = policy.highlights(from: [timeline])
        #expect(reel.contains { $0.kind == .buzzerBeater })
    }

    @Test("three in a few seconds is kept")
    func streak() {
        let timeline = turn(length: 45, [
            ("ა", 0, 10, .correct),
            ("ბ", 10, 12, .correct),
            ("გ", 12, 14, .correct)
        ])
        let reel = policy.highlights(from: [timeline])
        let streak = try! #require(reel.first { $0.kind == .streak || $0.words.count > 1 })
        #expect(streak.words.count >= 2)
    }

    @Test("three slow ones are not a streak")
    func slowIsNotStreak() {
        let timeline = turn(length: 60, [
            ("ა", 0, 10, .correct),
            ("ბ", 10, 25, .correct),
            ("გ", 25, 40, .correct)
        ])
        #expect(!policy.highlights(from: [timeline]).contains { $0.kind == .streak })
    }

    @Test("skipped and unanswered words are never highlights")
    func onlyCorrect() {
        let timeline = turn(length: 45, [
            ("ა", 0, 20, .skipped),
            ("ბ", 20, 44, .unanswered)
        ])
        let reel = policy.highlights(from: [timeline])
        // Only the fallback, which exists so a reel is never empty.
        #expect(reel.allSatisfy { $0.kind == .fallback })
    }

    /// A buzzer-beater is very often also a struggle. Cutting the same seconds twice makes
    /// the reel stutter.
    @Test("two rules on the same guess produce one slice")
    func overlapsMerge() {
        let timeline = turn(length: 30, [("ბალახი", 5, 28, .correct)])
        let reel = policy.highlights(from: [timeline])
        #expect(reel.count == 1)
        #expect(reel[0].kind == .buzzerBeater, "the better reason wins")
    }

    @Test("slices never run past the end of their turn")
    func clamped() {
        let timeline = turn(length: 30, [("ა", 0, 29.8, .correct)])
        for highlight in policy.highlights(from: [timeline]) {
            #expect(highlight.start >= 0)
            #expect(highlight.end <= 30)
        }
    }

    @Test("the reel stays inside its length and count caps")
    func caps() {
        let timelines = (0..<8).map { _ in
            turn(length: 45, [("ა", 0, 20, .correct), ("ბ", 20, 40, .correct)])
        }
        let reel = policy.highlights(from: timelines)

        #expect(reel.count <= policy.maximumCount)
        #expect(reel.reduce(0) { $0 + $1.duration } <= policy.maximumTotal)
    }

    @Test("the reel plays in the order the game happened")
    func chronological() {
        let timelines = (0..<3).map { _ in turn(length: 45, [("ა", 0, 20, .correct)]) }
        let reel = policy.highlights(from: timelines)

        for (earlier, later) in zip(reel, reel.dropFirst()) {
            #expect(
                (earlier.turnIndex, earlier.start) < (later.turnIndex, later.start),
                "a reel is a replay, not a ranking"
            )
        }
    }

    /// Better an eight second reel than none.
    @Test("a game where nothing stood out still produces something")
    func neverEmpty() {
        let timelines = [turn(length: 20, [("ა", 0, 19, .skipped)])]
        #expect(!policy.highlights(from: timelines).isEmpty)
    }

    @Test("a game with no footage produces nothing")
    func noTurns() {
        #expect(policy.highlights(from: []).isEmpty)
    }

    @Test("an unfinished turn is ignored")
    func unfinishedTurn() {
        var timeline = RecordingTimeline(teamName: "Blue")
        timeline.wordShown("ა", at: 0)
        #expect(policy.highlights(from: [timeline]).isEmpty)
    }
}
