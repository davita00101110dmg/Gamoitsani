//
//  DeckTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Deck")
struct DeckTests {

    private func words(_ n: Int) -> [DeckWord] {
        (0..<n).map { DeckWord(id: "\($0)", text: "w\($0)") }
    }

    /// The v1 bug this type exists to prevent: removeFirstNItems(50) returned nil rather
    /// than the remainder, so the last under-50 words were never dealt and the turn began
    /// empty.
    @Test("dealing more than remains returns the remainder, not nothing", arguments: [
        (60, 5, 5, 55),
        (5, 5, 5, 0),
        (3, 5, 3, 0),        // v1 returned nil here and dealt an empty turn
        (1, 5, 1, 0),
        (0, 5, 0, 0),
    ])
    func partialDeal(available: Int, request: Int, dealt: Int, left: Int) {
        var deck = Deck(words: words(available))
        let hand = deck.deal(request)
        #expect(hand.count == dealt)
        #expect(deck.count == left)
    }

    @Test("dealt words are removed and never dealt twice")
    func noDuplicates() {
        var deck = Deck(words: words(10))
        let first = deck.deal(4)
        let second = deck.deal(4)
        #expect(Set(first.map(\.id)).isDisjoint(with: Set(second.map(\.id))))
        #expect(deck.count == 2)
    }

    @Test("an empty deck cannot start a turn")
    func exhaustion() {
        var deck = Deck(words: words(1))
        #expect(deck.canDealTurn)
        _ = deck.deal(1)
        #expect(deck.isEmpty)
        #expect(deck.canDealTurn == false)
    }
}

@Suite("Super word placement")
struct SuperWordPlacementTests {

    @Test("classic puts the super word at its position within the turn")
    func classic() {
        let p = SuperWordPlacement(classicPosition: 3, arcadeSet: 1, arcadeSlot: 1)
        #expect(p.isSuperWord(mode: .classic, wordIndex: 3, setIndex: 1))
        #expect(p.isSuperWord(mode: .classic, wordIndex: 2, setIndex: 1) == false)
    }

    @Test("arcade requires both the set and the slot to match")
    func arcade() {
        let p = SuperWordPlacement(classicPosition: 1, arcadeSet: 2, arcadeSlot: 4)
        #expect(p.isSuperWord(mode: .arcade, wordIndex: 4, setIndex: 2))
        #expect(p.isSuperWord(mode: .arcade, wordIndex: 4, setIndex: 1) == false)
        #expect(p.isSuperWord(mode: .arcade, wordIndex: 3, setIndex: 2) == false)
    }

    /// v1 fixed both positions with Int.random at view-model init, which made the rule
    /// untestable. Seeding proves the ranges are the ones v1 used.
    @Test("random placement stays inside v1's ranges")
    func ranges() {
        var generator = SeededGenerator(seed: 42)
        for _ in 0..<200 {
            let p = SuperWordPlacement.random(using: &generator)
            #expect((1...5).contains(p.classicPosition))
            #expect((1...2).contains(p.arcadeSet))
            #expect((1...5).contains(p.arcadeSlot))
        }
    }
}

/// Deterministic generator so placement tests are reproducible.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
