//
//  PlayScoringTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("Scoring in play")
struct PlayScoringTests {

    @Test("a guessed word scores one and a skipped word costs one")
    func guessedAndSkipped() throws {
        var (runner, clock) = Fixture.runner()
        runner.startTurn()
        for outcome: PlayOutcome in [.correct, .correct, .skipped, .correct] {
            clock.advance(by: 3)
            runner.answerNext(outcome)
        }
        let team = try #require(runner.currentTeam)
        #expect(team.score == 2)
        #expect(team.wordsGuessed == 3)
        #expect(team.wordsSkipped == 1)
        #expect(team.bestStreak == 2)
        #expect(team.currentStreak == 1, "the skip broke the streak")
    }

    @Test("a score can go below zero")
    func negativeScore() {
        var (runner, clock) = Fixture.runner()
        runner.playTurn([.skipped, .skipped, .skipped], clock: clock)
        #expect(runner.state.teams[0].score == -3)
    }

    @Test("only the team playing scores")
    func onlyTheCurrentTeamScores() {
        var (runner, clock) = Fixture.runner(teams: 3)
        runner.playTurn([.correct, .correct], clock: clock)
        runner.playTurn([.correct, .skipped, .skipped], clock: clock)
        #expect(runner.state.teams.map(\.score) == [2, -1, 0])
    }

    @Test("skipping an arcade set costs two and deals five fresh words")
    func arcadeSetSkip() throws {
        var (runner, _) = Fixture.runner(mode: .arcade)
        runner.startTurn()
        runner.answerNext(.correct)
        let oldSet = Set(runner.state.turnWords.map(\.id))

        let skipped = runner.send(.skipSet)
        #expect(skipped)
        let team = try #require(runner.currentTeam)
        #expect(team.score == -1)
        #expect(team.setsSkipped == 1)
        #expect(team.currentStreak == 0)
        #expect(runner.wordsInPlay.count == 5)
        #expect(oldSet.isDisjoint(with: runner.state.turnWords.map(\.id)))
    }

    @Test("classic has no set to skip")
    func classicCannotSkipASet() {
        var (runner, _) = Fixture.runner(mode: .classic)
        runner.startTurn()
        let skipped = runner.send(.skipSet)
        #expect(skipped == false)
        #expect(runner.lastRejection == .notAvailableInMode(.classic))
        #expect(runner.currentTeam?.score == 0)
    }

    @Test("a super word is worth three, guessed or skipped")
    func superWord() throws {
        var (runner, clock) = Fixture.runner(teams: 2, superWords: true)

        // Classic puts it somewhere in each team's first five words.
        runner.startTurn()
        while runner.wordsInPlay.first?.isSuperWord == false { runner.answerNext(.correct) }
        let guessedBefore = try #require(runner.currentTeam).score
        let guessed = runner.answerNext(.correct)
        #expect(guessed?.isSuperWord == true)
        #expect(try #require(runner.currentTeam).score - guessedBefore == 3)
        #expect(runner.currentTeam?.superWordsGuessed == 1)
        runner.runOutClock(clock)

        runner.startTurn()
        while runner.wordsInPlay.first?.isSuperWord == false { runner.answerNext(.correct) }
        let skippedBefore = try #require(runner.currentTeam).score
        let skipped = runner.answerNext(.skipped)
        #expect(skipped?.isSuperWord == true)
        #expect(try #require(runner.currentTeam).score - skippedBefore == -3)
    }
}
