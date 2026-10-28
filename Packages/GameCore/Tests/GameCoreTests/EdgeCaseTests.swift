//
//  EdgeCaseTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("One team")
struct OneTeamTests {

    @Test("setup refuses a game with one team")
    func validatorRefuses() {
        #expect(TeamValidator.validate(Fixture.teams(1)) == [.tooFewTeams(minimum: 2)])
    }

    @Test("the rules still carry a lone team through every round to a win")
    func loneTeamFinishes() {
        var (runner, clock) = Fixture.runner(rounds: 3, teams: 1)
        for round in 1...3 {
            #expect(runner.state.round == round)
            #expect(runner.currentTeam?.name == "T0")
            runner.playTurn([.skipped], clock: clock)
        }
        #expect(runner.isFinished, "there is nobody to tie with")
        #expect(runner.winner?.name == "T0")
        #expect(runner.winner?.score == -3, "the only team wins even below zero")
    }
}

@Suite("Running out of words")
struct RunningOutOfWordsTests {

    @Test("an empty deck cannot start a game")
    func emptyDeck() {
        var (runner, _) = Fixture.runner(words: 0)
        let began = runner.send(.beginTurn)
        #expect(began == false)
        #expect(runner.lastRejection == .deckExhausted)
        #expect(runner.state.phase == .turnInfo)
    }

    @Test("a deck that runs dry mid-turn leaves an empty table until time is up")
    func classicRunsDry() {
        var (runner, clock) = Fixture.runner(roundLength: 60, teams: 2, words: 3)
        runner.startTurn()
        for _ in 0..<3 { runner.answerNext(.correct) }
        #expect(runner.wordsInPlay.isEmpty)
        #expect(runner.currentTeam?.score == 3)

        let late = runner.send(.answer(wordID: "0", outcome: .correct))
        #expect(late == false)
        #expect(runner.lastRejection == .wordNotInPlay("0"))

        clock.advance(by: 30)
        let early = runner.checkExpiry()
        #expect(early == false, "the turn still runs its full length")
        runner.runOutClock(clock)
        #expect(runner.currentTeam?.name == "T1")

        let began = runner.send(.beginTurn)
        #expect(began == false)
        #expect(runner.lastRejection == .deckExhausted)
        #expect(runner.state.phase == .turnInfo)
    }

    @Test("an arcade deck deals a short last set, then nothing")
    func arcadeShortSet() {
        var (runner, _) = Fixture.runner(mode: .arcade, words: 7)
        runner.startTurn()
        #expect(runner.wordsInPlay.count == 5)
        for _ in 0..<5 { runner.answerNext(.correct) }
        #expect(runner.wordsInPlay.map(\.id) == ["5", "6"])
        for _ in 0..<2 { runner.answerNext(.correct) }
        #expect(runner.wordsInPlay.isEmpty)
    }

    /// The button stays enabled on an empty table, and the reducer accepts it. Current
    /// behaviour, pinned so the switch-over keeps it.
    @Test("skipping a set when nothing is left still costs two")
    func skipOnEmptyTable() {
        var (runner, _) = Fixture.runner(mode: .arcade, words: 5)
        runner.startTurn()
        for _ in 0..<5 { runner.answerNext(.correct) }
        let skipped = runner.send(.skipSet)
        #expect(skipped)
        #expect(runner.currentTeam?.score == 3)
        #expect(runner.wordsInPlay.isEmpty)
    }

    @Test("words that arrive mid-game let the next turn start")
    func refillUnblocks() {
        var (runner, clock) = Fixture.runner(teams: 2, words: 1)
        runner.playTurn([.correct], clock: clock)
        let blocked = runner.send(.beginTurn)
        #expect(blocked == false)

        let refilled = runner.apply(.deckRefilled(Fixture.words(30, from: 100)))
        #expect(refilled)
        runner.startTurn()
        #expect(runner.wordsInPlay.first?.id == "100")
    }

    @Test("the deck asks for more once it is below one turn's worth")
    func asksForMore() {
        // 60-second rounds want 30 words a turn.
        var (runner, _) = Fixture.runner(roundLength: 60, words: 31)
        #expect(WordSupply.needsTopUp(runner.state) == false)
        runner.startTurn()
        #expect(runner.state.deck.count == 30)
        #expect(WordSupply.needsTopUp(runner.state) == false)
        runner.answerNext(.correct)
        #expect(WordSupply.needsTopUp(runner.state))
    }
}

@Suite("Zero-length round")
struct ZeroLengthRoundTests {

    @Test("a zero-length round cannot be set up", arguments: [0.0, -10.0, 29.0])
    func clampedToMinimum(length: TimeInterval) {
        #expect(GameSettings(roundLength: length).roundLength == 30)
        var settings = GameSettings()
        settings.setRoundLength(length)
        #expect(settings.roundLength == 30)
    }

    @Test("a save holding no round length ends the turn at once instead of trapping")
    func zeroLengthSave() throws {
        let json = #"{"rounds":1,"roundLength":0,"mode":"classic","superWordsEnabled":false,"challengesEnabled":false}"#
        let settings = try JSONDecoder().decode(GameSettings.self, from: Data(json.utf8))
        #expect(settings.roundLength == 0, "decoding does not clamp, so a damaged save can hold this")

        let clock = ManualClock(Fixture.t0)
        var runner = GameRunner(
            state: GameState(settings: settings, teams: Fixture.teams(2), deck: Deck(words: Fixture.words(10))),
            clock: clock,
            random: SeededGenerator(seed: 1)
        )
        runner.startTurn()
        #expect(runner.timer == nil)
        #expect(runner.remainingTime == 0)
        let expired = runner.checkExpiry()
        #expect(expired)
        #expect(runner.currentTeam?.name == "T1")
    }

    @Test("a game saved with no time left ends the turn as soon as it resumes")
    func resumedWithNothingLeft() {
        var (runner, clock) = Fixture.runner(roundLength: 30)
        runner.startTurn()
        clock.advance(by: 30)
        let saved = runner.stateForSaving()
        #expect(saved.pausedRemaining == 0)

        var resumed = GameRunner(resuming: saved, clock: clock, random: SeededGenerator(seed: 1))
        #expect(resumed.remainingTime == 0)
        let expired = resumed.checkExpiry()
        #expect(expired)
    }
}
