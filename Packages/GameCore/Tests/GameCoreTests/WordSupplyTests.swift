//
//  WordSupplyTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("Word supply")
struct WordSupplyTests {

    @Test("a turn's worth of words follows the clock and never drops below 20", arguments: [
        (30.0, 20), (40.0, 20), (41.0, 21), (45.0, 23), (60.0, 30), (90.0, 45),
    ])
    func wordsPerTurn(roundLength: TimeInterval, expected: Int) {
        #expect(WordSupply.wordsPerTurn(roundLength: roundLength) == expected)
    }

    @Test("the opening deck covers the game, and is never under 80", arguments: [
        (2, 1, 30.0, 80),
        (2, 3, 60.0, 180),
        (5, 5, 90.0, 1_125),
    ])
    func openingDeck(teams: Int, rounds: Int, roundLength: TimeInterval, expected: Int) {
        #expect(WordSupply.openingDeckSize(teamCount: teams, rounds: rounds, roundLength: roundLength) == expected)
    }

    @Test("a top-up asks for two turns' worth")
    func topUpSize() {
        #expect(WordSupply.topUpSize(roundLength: 30) == 40)
        #expect(WordSupply.topUpSize(roundLength: 60) == 60)
    }
}

@Suite("Deck ledger")
struct DeckLedgerTests {

    @Test("a top-up is told about every word the game has held")
    func excludesEverythingDealtIn() {
        var deck = Deck(words: Fixture.words(5))
        var ledger = DeckLedger(deck: deck)
        _ = deck.deal(3)
        let topUp = Fixture.words(2, from: 50)
        deck.add(topUp)
        ledger.add(topUp)

        #expect(ledger.excludedIDs == ["0", "1", "2", "3", "4", "50", "51"])
    }

    @Test("played words are the ones that have left the deck")
    func playedIsWhatLeft() {
        var deck = Deck(words: Fixture.words(5))
        let ledger = DeckLedger(deck: deck)
        #expect(ledger.playedIDs(in: deck).isEmpty)
        _ = deck.deal(2)
        #expect(ledger.playedIDs(in: deck) == ["0", "1"])
    }

    @Test("a resumed game tracks from what was left")
    func resumeStartsFromRemaining() {
        var deck = Deck(words: Fixture.words(5))
        _ = deck.deal(2)
        let ledger = DeckLedger(deck: deck)
        #expect(ledger.excludedIDs == ["2", "3", "4"])
    }
}
