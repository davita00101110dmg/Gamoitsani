//
//  ScoringTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Scoring")
struct ScoringTests {

    /// Every scoring path, exhaustively. v1 computed these in three places that disagreed.
    @Test("points for every outcome", arguments: [
        (PlayOutcome.correct, false, 1),
        (PlayOutcome.skipped, false, -1),
        (PlayOutcome.correct, true, 3),
        (PlayOutcome.skipped, true, -3),
    ])
    func points(outcome: PlayOutcome, isSuper: Bool, expected: Int) {
        #expect(Scoring.points(for: outcome, isSuperWord: isSuper) == expected)
    }

    /// v1's GameMode.skipPenalty declared classic as 0 while classic skips actually cost
    /// -1, so the property was wrong and only ever read for arcade. Set-skip is a distinct
    /// concept: only arcade has a set to abandon.
    @Test("set-skip penalty applies to arcade only", arguments: [
        (GameMode.classic, 0),
        (GameMode.arcade, -2),
    ])
    func setSkip(mode: GameMode, expected: Int) {
        #expect(Scoring.setSkipPenalty(for: mode) == expected)
    }

    @Test("words on screen per mode", arguments: [
        (GameMode.classic, 1),
        (GameMode.arcade, 5),
    ])
    func wordsPerSet(mode: GameMode, expected: Int) {
        #expect(mode.wordsPerSet == expected)
    }

    @Test("a skip cancels the streak but a super word does not double-count")
    func streakAndSuper() {
        let now = Date()
        var team = Team(name: "A")

        team.record(.correct, isSuperWord: false, at: now)
        team.record(.correct, isSuperWord: true, at: now)
        #expect(team.score == 4)
        #expect(team.currentStreak == 2)
        #expect(team.bestStreak == 2)
        #expect(team.superWordsGuessed == 1)

        team.record(.skipped, isSuperWord: false, at: now)
        #expect(team.score == 3)
        #expect(team.currentStreak == 0)
        #expect(team.bestStreak == 2, "best streak must survive a skip")
        #expect(team.wordsSkipped == 1)
    }

    /// v1 reported 0.0s in classic because startGuessing was never called there, and in
    /// arcade recorded exactly one interval per turn. Time is injected here.
    @Test("guess time is measured from when the word appeared")
    func guessTiming() {
        let start = Date()
        var team = Team(name: "A")

        team.beginGuessing(at: start)
        team.record(.correct, isSuperWord: false, at: start.addingTimeInterval(4))
        team.beginGuessing(at: start.addingTimeInterval(4))
        team.record(.correct, isSuperWord: false, at: start.addingTimeInterval(10))

        #expect(team.totalGuessTime == 10)
        #expect(team.averageGuessTime == 5)
    }

    @Test("average guess time is zero, not NaN, before anything is guessed")
    func averageGuessTimeIsSafe() {
        #expect(Team(name: "A").averageGuessTime == 0)
    }
}
