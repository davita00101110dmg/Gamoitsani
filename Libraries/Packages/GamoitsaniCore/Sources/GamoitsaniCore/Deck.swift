//
//  Deck.swift
//  GamoitsaniCore
//
import Foundation

/// One playable word, already resolved to the display language.
public struct DeckWord: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    /// The text actually shown to the player.
    public let text: String

    /// Assigned when the word is dealt, not when the deck is built — whether a given word
    public internal(set) var isSuperWord: Bool

    public init(id: String, text: String, isSuperWord: Bool = false) {
        self.id = id
        self.text = text
        self.isSuperWord = isSuperWord
    }
}

/// The word supply for one game.
public struct Deck: Sendable, Hashable, Codable {

    private var remaining: [DeckWord]

    public init(words: [DeckWord]) {
        self.remaining = words
    }

    public var count: Int { remaining.count }
    public var isEmpty: Bool { remaining.isEmpty }

    /// Takes up to `count` words, returning however many are left when there are not
    /// enough — never nil, never silently empty.
    public mutating func deal(_ count: Int) -> [DeckWord] {
        precondition(count >= 0, "cannot deal a negative number of words")
        let taken = Array(remaining.prefix(count))
        remaining.removeFirst(taken.count)
        return taken
    }

    /// Whether a turn can still be played. The engine refuses to start a turn on an empty
    /// deck rather than presenting an unscoreable screen.
    public var canDealTurn: Bool { !remaining.isEmpty }
}

/// Decides which word in a turn is the super word.
public struct SuperWordPlacement: Sendable, Hashable, Codable {
    public let classicPosition: Int
    public let arcadeSet: Int
    public let arcadeSlot: Int

    public init(classicPosition: Int, arcadeSet: Int, arcadeSlot: Int) {
        self.classicPosition = classicPosition
        self.arcadeSet = arcadeSet
        self.arcadeSlot = arcadeSlot
    }

    public static func random(using generator: inout some RandomNumberGenerator) -> Self {
        Self(
            classicPosition: Int.random(in: 1...5, using: &generator),
            arcadeSet: Int.random(in: 1...2, using: &generator),
            arcadeSlot: Int.random(in: 1...5, using: &generator)
        )
    }

    public static func random() -> Self {
        var generator = SystemRandomNumberGenerator()
        return random(using: &generator)
    }

    /// Whether the word at this position should be the super word.
    public func isSuperWord(mode: GameMode, wordIndex: Int, setIndex: Int) -> Bool {
        switch mode {
        case .classic:
            wordIndex == classicPosition
        case .arcade:
            setIndex == arcadeSet && wordIndex == arcadeSlot
        }
    }
}
