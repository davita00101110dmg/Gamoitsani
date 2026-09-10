//
//  GameEvent.swift
//  GamoitsaniCore
//
import Foundation

/// Everything that can happen to a game.
public enum GameEvent: Sendable, Hashable {

    /// The player dismissed the turn-info screen.
    case beginTurn

    /// The challenge card was acknowledged. Only reachable when challenges are enabled.
    case acknowledgeChallenge

    /// The 3-2-1 finished; the clock starts now.
    case countdownFinished

    /// A word was answered. `id` identifies which — required in arcade, where five are on
    /// screen, and it is what makes double-scoring the same card impossible.
    case answer(wordID: String, outcome: PlayOutcome)

    /// Take back a word answered by mistake, while it is still on the table.
    case undoAnswer(wordID: String)

    /// Arcade only: swap the whole set for a flat penalty.
    case skipSet

    /// The round clock reached zero.
    case timeExpired

    /// Play again with the same teams and settings.
    case rematch
}

/// Something that happened outside the game and now has to be folded into it.
///
/// Kept apart from `GameEvent` because these are results, not intentions. A screen sends
/// events; only the layer that started the work reports back with one of these, so a view
/// cannot inject words into a running game.
public enum GameEffect: Sendable, Hashable {
    /// More words arrived while the game was being played, so a long game does not
    /// dead-end on an empty deck.
    case deckRefilled([DeckWord])
}

/// Why an event was refused.
public enum GameEventRejection: Error, Sendable, Hashable {
    /// The event does not belong in the current phase.
    case wrongPhase(GamePhase)
    /// That word is not in the current turn, or has already been answered.
    case wordNotInPlay(String)
    /// Set-skipping is arcade only.
    case notAvailableInMode(GameMode)
    /// No words left; a turn cannot begin.
    case deckExhausted
}
