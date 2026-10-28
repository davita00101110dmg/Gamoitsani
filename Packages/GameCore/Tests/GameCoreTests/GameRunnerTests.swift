//
//  GameRunnerTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

/// `GameEngine`'s suite, held against the runner, so the switch-over changes nothing.
@Suite("Game runner")
struct GameRunnerTests {

    @Test("send applies the event and keeps the new state")
    func sendAppliesEvent() {
        var (runner, _) = Fixture.runner()
        #expect(runner.state.phase == .turnInfo)
        let accepted = runner.send(.beginTurn)
        #expect(accepted)
        #expect(runner.state.phase == .countdown)
    }

    @Test("a refused event leaves the state untouched and records why")
    func rejectionIsSurfaced() {
        var (runner, _) = Fixture.runner()
        let before = runner.state

        let refused = runner.send(.countdownFinished)
        #expect(refused == false)
        #expect(runner.state == before)
        #expect(runner.lastRejection == .wrongPhase(.turnInfo))

        runner.send(.beginTurn)
        #expect(runner.lastRejection == nil, "a success clears the previous rejection")
    }

    @Test("convenience accessors reflect the state")
    func accessors() {
        var (runner, _) = Fixture.runner(teams: 2)
        runner.startTurn()

        #expect(runner.currentTeam?.name == "T0")
        #expect(runner.wordsInPlay.count == 1)
        #expect(runner.isFinished == false)
        #expect(runner.standings.count == 2)
        #expect(runner.winner == nil, "level at zero")
    }

    @Test("a new game deals rules only when challenges are on")
    func startDealsChallenges() {
        let (off, _) = Fixture.runner(teams: 3, challenges: false)
        #expect(off.state.challenges.isEmpty)

        let (on, _) = Fixture.runner(teams: 3, challenges: true)
        #expect(on.state.challenges.count == 3)
        #expect(Set(on.state.challenges.values).count == 3, "no two teams share a rule")
    }

    @Test("a save from before challenges existed is dealt them on resume")
    func resumeDealsMissingChallenges() {
        let saved = GameState(
            settings: GameSettings(challengesEnabled: true),
            teams: Fixture.teams(2),
            deck: Deck(words: Fixture.words(10))
        )
        let runner = GameRunner(resuming: saved, clock: ManualClock(Fixture.t0),
                                random: SeededGenerator(seed: 1))
        #expect(runner.state.challenges.count == 2)
    }

    @Test("a resumed game keeps the rules it was saved with")
    func resumeKeepsChallenges() {
        let (original, _) = Fixture.runner(challenges: true, seed: 1)
        let resumed = GameRunner(resuming: original.state, clock: ManualClock(Fixture.t0),
                                 random: SeededGenerator(seed: 999))
        #expect(resumed.state.challenges == original.state.challenges)
    }
}

@Suite("Determinism")
struct DeterminismTests {

    /// Plays three rounds of arcade with super words and challenges, the most random a game gets.
    /// Each team guesses a different share, so the game reaches a winner.
    private func play(seed: UInt64) -> GameState {
        var (runner, clock) = Fixture.runner(
            mode: .arcade, rounds: 3, teams: 3, words: 1_000,
            superWords: true, challenges: true, seed: seed
        )
        for _ in 0..<40 where !runner.isFinished {
            let team = runner.state.currentTeamIndex
            runner.startTurn()
            for answer in 0..<7 {
                clock.advance(by: 2)
                runner.answerNext(answer < 5 - team ? .correct : .skipped)
            }
            runner.send(.skipSet)
            runner.runOutClock(clock)
        }
        #expect(runner.isFinished)
        runner.send(.rematch)
        return runner.state
    }

    @Test("the same seed and the same clock give the same game")
    func sameSeedSameGame() {
        #expect(play(seed: 42) == play(seed: 42))
    }

    @Test("a different seed gives a different game")
    func differentSeedDifferentGame() {
        #expect(play(seed: 42) != play(seed: 43))
    }
}
