//
//  GameOverTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("Game over")
struct GameOverTests {

    @Test("the game ends once every team has played every round")
    func endsAfterTheLastTurn() {
        var (runner, clock) = Fixture.runner(rounds: 2, teams: 2)
        runner.playTurn([.correct], clock: clock)
        runner.playTurn([], clock: clock)
        runner.playTurn([], clock: clock)
        #expect(runner.isFinished == false, "T1 has not had its last turn")

        runner.playTurn([], clock: clock)
        #expect(runner.isFinished)
        #expect(runner.winner?.name == "T0")
        #expect(runner.state.roundEndsAt == nil)
        #expect(runner.state.turnWords.isEmpty)
    }

    @Test("a big lead does not end the game early")
    func noEarlyFinish() {
        var (runner, clock) = Fixture.runner(rounds: 3, teams: 2)
        runner.playTurn(Array(repeating: .correct, count: 20), clock: clock)
        runner.playTurn([.skipped], clock: clock)
        #expect(runner.isFinished == false)
        #expect(runner.state.round == 2)
    }

    @Test("a tie at the end plays extra rounds until somebody leads after a full round")
    func tieBreak() {
        var (runner, clock) = Fixture.runner(rounds: 1, teams: 2)
        runner.playTurn([.correct], clock: clock)
        runner.playTurn([.correct], clock: clock)
        #expect(runner.isFinished == false)
        #expect(runner.state.extraRound == 1)
        #expect(runner.winner == nil)

        runner.playTurn([], clock: clock)
        runner.playTurn([], clock: clock)
        #expect(runner.isFinished == false, "still level")
        #expect(runner.state.extraRound == 2)

        runner.playTurn([.correct], clock: clock)
        #expect(runner.isFinished == false, "T1 still gets its turn in the extra round")
        runner.playTurn([], clock: clock)
        #expect(runner.isFinished)
        #expect(runner.winner?.name == "T0")
    }

    @Test("only the top two have to differ")
    func levelBelowTheLeader() {
        var (runner, clock) = Fixture.runner(rounds: 1, teams: 3)
        runner.playTurn([.correct, .correct], clock: clock)
        runner.playTurn([], clock: clock)
        runner.playTurn([], clock: clock)
        #expect(runner.isFinished)
        #expect(runner.winner?.name == "T0")
    }

    @Test("a finished game refuses play, more words and the clock")
    func finishedIsFinal() {
        var (runner, clock) = Fixture.runner(rounds: 1, teams: 2)
        runner.playTurn([.correct], clock: clock)
        runner.playTurn([], clock: clock)
        #expect(runner.isFinished)

        let began = runner.send(.beginTurn)
        #expect(began == false)
        #expect(runner.lastRejection == .wrongPhase(.finished))
        let timedOut = runner.send(.timeExpired)
        #expect(timedOut == false)
        clock.advance(by: 1_000)
        let expired = runner.checkExpiry()
        #expect(expired == false)
        let refilled = runner.apply(.deckRefilled(Fixture.words(5, from: 5_000)))
        #expect(refilled == false)
        #expect(WordSupply.needsTopUp(runner.state) == false)
    }

    @Test("a rematch starts again with the same teams and the rest of the deck")
    func rematch() {
        var (runner, clock) = Fixture.runner(rounds: 1, teams: 2, challenges: true, seed: 11)
        runner.playTurn([.correct], clock: clock)
        runner.playTurn([], clock: clock)
        let firstGame = runner.state

        let accepted = runner.send(.rematch)
        #expect(accepted)
        #expect(runner.state.phase == .turnInfo)
        #expect(runner.state.round == 1)
        #expect(runner.state.currentTeamIndex == 0)
        #expect(runner.state.teams.map(\.id) == firstGame.teams.map(\.id))
        #expect(runner.state.teams.allSatisfy { $0.score == 0 })
        #expect(runner.state.challenges.count == 2, "rules are dealt again")
        #expect(runner.state.deck == firstGame.deck)
    }
}
