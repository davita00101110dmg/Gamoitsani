//
//  WordSupply.swift
//  GameCore
//
import Foundation

/// How many words a game needs, and when it needs more.
public enum WordSupply {

    /// How many words one turn can plausibly get through: about one every two seconds for a
    /// quick pair, and never fewer than 20.
    static func wordsPerTurn(roundLength: TimeInterval) -> Int {
        max(20, Int((roundLength / 2).rounded(.up)))
    }

    /// The deck dealt at the start. Only an opening hand: the deck is topped up during play.
    public static func openingDeckSize(teamCount: Int, rounds: Int, roundLength: TimeInterval) -> Int {
        max(80, teamCount * rounds * wordsPerTurn(roundLength: roundLength))
    }

    /// Whether the deck has dropped below one turn's worth while the game is still on.
    public static func needsTopUp(_ state: GameState) -> Bool {
        state.phase != .finished
            && state.deck.count < wordsPerTurn(roundLength: state.settings.roundLength)
    }

    /// How many words a top-up asks for: two turns' worth.
    public static func topUpSize(roundLength: TimeInterval) -> Int {
        wordsPerTurn(roundLength: roundLength) * 2
    }
}

/// Every word put into one game's deck, so a top-up never repeats a card and the words the
/// room actually saw can be told apart from the ones merely dealt in.
public struct DeckLedger: Sendable, Hashable {

    private var ids: Set<String>

    /// Starts from what the deck holds now. A resumed game starts from what is left, because
    /// anything played before the save was already recorded as seen.
    public init(deck: Deck) {
        ids = Set(deck.remainingIDs)
    }

    /// Ids a top-up must not return.
    public var excludedIDs: Set<String> { ids }

    /// Records words that arrived in a top-up.
    public mutating func add(_ words: [DeckWord]) {
        ids.formUnion(words.map(\.id))
    }

    /// Words that have left the deck, so were shown to the room.
    public func playedIDs(in deck: Deck) -> Set<String> {
        ids.subtracting(deck.remainingIDs)
    }
}
