//
//  Deck.swift
//  GamoitsaniCore
//

import Foundation

/// One playable word, already resolved to the display language.
///
/// The engine never sees a database row or a translation dictionary — resolution happens
/// once, when the deck is built. v1 resolved the language per word at display time by
/// casting a Core Data relationship to `Set<Translation>` and doing a linear search inside
/// the view model, on the main thread, firing a fault each time.
public struct DeckWord: Identifiable, Hashable, Sendable, Codable {
    public let id: String
    /// The text actually shown to the player.
    public let text: String
    public let isSuperWord: Bool

    public init(id: String, text: String, isSuperWord: Bool = false) {
        self.id = id
        self.text = text
        self.isSuperWord = isSuperWord
    }
}

/// The word supply for one game.
///
/// Deals are explicit and exhaustion is a state the caller must handle, which is the whole
/// point of this type. In v1 the pool was sliced with `removeFirstNItems(50)`, which
/// returns `nil` — not the remainder — when fewer than 50 words are left. So the final
/// under-50 words were never dealt, and the turn began with an *empty* list. Neither mode
/// checked for that:
///
/// - Classic showed "no more words" but `wordButtonAction` kept awarding **+1 per tap,
///   indefinitely**.
/// - Arcade rendered an empty grid while the skip button still charged **−2 per tap**.
///
/// With 1500 words at 50 per turn that is 30 turns; five teams over five rounds is 25, and
/// tie-break rounds are unbounded, so real games reach it.
public struct Deck: Sendable, Hashable, Codable {

    /// Words dealt per turn. v1's value, preserved.
    public static let wordsPerTurn = 50

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

    /// A turn's worth of words.
    public mutating func dealTurn() -> [DeckWord] {
        deal(Self.wordsPerTurn)
    }

    /// Whether a turn can still be played. The engine refuses to start a turn on an empty
    /// deck rather than presenting an unscoreable screen.
    public var canDealTurn: Bool { !remaining.isEmpty }
}

/// Decides which word in a turn is the super word.
///
/// v1 fixed both positions at view-model construction with `Int.random`, which made the
/// behaviour untestable. The rule is preserved exactly but the randomness is injected:
///
/// - **Classic**: a position 1...5, so the super word is always among the turn's first five.
/// - **Arcade**: set 1 or 2 (50/50), slot 1...5 within it.
///
/// One behavioural fix. v1 marked the super word "encountered" at different moments per
/// mode — arcade at *generation*, classic at *button press* — so an arcade super word the
/// team never reached still burned their one-per-round allowance. Here the allowance is
/// spent when the word is actually played.
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
    ///
    /// - Parameters:
    ///   - wordIndex: 1-based position within the turn (classic) or within the set (arcade).
    ///   - setIndex: 1-based set number within the turn. Always 1 in classic.
    public func isSuperWord(mode: GameMode, wordIndex: Int, setIndex: Int) -> Bool {
        switch mode {
        case .classic:
            wordIndex == classicPosition
        case .arcade:
            setIndex == arcadeSet && wordIndex == arcadeSlot
        }
    }
}
