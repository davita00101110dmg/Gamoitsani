//
//  NoRepeatedWordsTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("No repeated words")
struct NoRepeatedWordsTests {

    /// Runs one step and logs whatever it dealt, read off the deck as it shrinks.
    private func step(
        _ runner: inout GameRunner,
        _ shown: inout [String],
        _ action: (inout GameRunner) -> Void
    ) {
        let before = runner.state.deck.count
        action(&runner)
        let dealt = before - runner.state.deck.count
        guard dealt > 0 else { return }
        #expect(runner.state.turnWords.count == dealt)
        shown += runner.state.turnWords.map(\.id)
    }

    /// Plays a whole game to the end. Each team guesses a different share, so it ends.
    private func playGame(_ runner: inout GameRunner, clock: ManualClock, shown: inout [String]) {
        for _ in 0..<40 where !runner.isFinished {
            let team = runner.state.currentTeamIndex
            step(&runner, &shown) { $0.startTurn() }
            for answer in 0..<12 {
                clock.advance(by: 2)
                let outcome: PlayOutcome = answer < 9 - team ? .correct : .skipped
                step(&runner, &shown) { $0.answerNext(outcome) }
                if runner.state.settings.mode == .arcade && answer == 6 {
                    step(&runner, &shown) { $0.send(.skipSet) }
                }
            }
            step(&runner, &shown) { $0.runOutClock(clock) }
        }
        #expect(runner.isFinished)
    }

    @Test("a whole game never shows the same word twice", arguments: GameMode.allCases)
    func wholeGame(mode: GameMode) {
        var (runner, clock) = Fixture.runner(mode: mode, rounds: 3, teams: 3, words: 1_000)
        var shown: [String] = []
        playGame(&runner, clock: clock, shown: &shown)

        #expect(shown.count > 90)
        #expect(Set(shown).count == shown.count)
    }

    @Test("a rematch carries on through the deck instead of starting it over")
    func rematchCarriesOn() {
        var (runner, clock) = Fixture.runner(rounds: 2, teams: 2, words: 1_000)
        var shown: [String] = []
        playGame(&runner, clock: clock, shown: &shown)
        let firstGame = shown.count

        runner.send(.rematch)
        playGame(&runner, clock: clock, shown: &shown)

        #expect(shown.count > firstGame)
        #expect(Set(shown).count == shown.count)
    }

    /// The pool always answers from its start, so only the exclusion keeps a top-up fresh.
    @Test("top-ups never bring back a word already in the game")
    func topUpsExcludeTheGame() {
        let pool = Fixture.words(1_000)
        let clock = ManualClock(Fixture.t0)
        var runner = GameRunner(
            settings: GameSettings(rounds: 3, roundLength: 30),
            teams: Fixture.teams(3),
            deck: Deck(words: Array(pool.prefix(25))),
            clock: clock,
            random: SeededGenerator(seed: 9)
        )
        var ledger = DeckLedger(deck: runner.state.deck)
        var shown: [String] = []
        var topUps = 0

        for _ in 0..<40 where !runner.isFinished {
            let team = runner.state.currentTeamIndex
            for answer in -1..<15 {
                if WordSupply.needsTopUp(runner.state) {
                    let excluded = ledger.excludedIDs
                    let size = WordSupply.topUpSize(roundLength: runner.state.settings.roundLength)
                    let more = Array(pool.lazy.filter { !excluded.contains($0.id) }.prefix(size))
                    if runner.apply(.deckRefilled(more)) {
                        ledger.add(more)
                        topUps += 1
                    }
                }
                if answer < 0 {
                    step(&runner, &shown) { $0.startTurn() }
                } else {
                    clock.advance(by: 1)
                    let outcome: PlayOutcome = answer < 12 - team ? .correct : .skipped
                    step(&runner, &shown) { $0.answerNext(outcome) }
                }
            }
            step(&runner, &shown) { $0.runOutClock(clock) }
        }

        #expect(runner.isFinished)
        #expect(topUps >= 3)
        #expect(Set(shown).count == shown.count)
        #expect(ledger.playedIDs(in: runner.state.deck) == Set(shown))
    }
}
