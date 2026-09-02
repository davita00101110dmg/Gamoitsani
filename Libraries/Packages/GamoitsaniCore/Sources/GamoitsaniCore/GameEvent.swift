//
//  GameEvent.swift
//  GamoitsaniCore
//

import Foundation

/// Everything that can happen to a game.
///
/// A closed set, so the reducer must handle each case and adding one is a compiler error
/// at every decision point rather than a silent gap. v1 spread the equivalent across view
/// models, view bodies and `asyncAfter` closures, which is how `playingSessionCount` came
/// to be incremented inside a SwiftUI view — a double tap there skipped a team's turn.
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

    /// Arcade only: swap the whole set for a flat penalty.
    case skipSet

    /// The round clock reached zero.
    case timeExpired

    /// Play again with the same teams and settings.
    case rematch
}

/// Why an event was refused.
///
/// The reducer rejects rather than silently no-ops, so a UI bug surfaces as a value it can
/// assert on instead of a missing side effect.
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
