//
//  GameRules.swift
//  GamoitsaniCore
//
import Foundation

/// Pure decisions about a `GameState`. No mutation, no clock, no I/O — every rule is a
public enum GameRules {

    /// Whether every scheduled round has been completed by every team.
    public static func hasPlayedAllRounds(_ state: GameState) -> Bool {
        state.round > state.settings.rounds && state.currentTeamIndex == 0
    }

    /// Whether the leaders are level and the game therefore cannot end.
    public static func isTie(_ state: GameState) -> Bool {
        let standings = state.standings
        guard standings.count >= 2 else { return false }
        return standings[0].score == standings[1].score
    }

    /// Whether the game is over: all rounds played and somebody is ahead.
    public static func isGameOver(_ state: GameState) -> Bool {
        hasPlayedAllRounds(state) && !isTie(state)
    }

    /// Whether another tie-break round is required.
    public static func needsExtraRound(_ state: GameState) -> Bool {
        hasPlayedAllRounds(state) && isTie(state)
    }

    /// The outright winner, or nil while anyone is level with the leader.
    public static func winner(_ state: GameState) -> Team? {
        let standings = state.standings
        guard let leader = standings.first else { return nil }
        guard standings.count == 1 || standings[1].score < leader.score else { return nil }
        return leader
    }

    /// Whether this team may still receive a super word this round.
    public static func canReceiveSuperWord(_ state: GameState, teamID: UUID) -> Bool {
        state.settings.superWordsEnabled && !state.superWordSpentBy.contains(teamID)
    }

    /// Whether a turn can begin. False when the deck is spent.
    public static func canStartTurn(_ state: GameState) -> Bool {
        state.deck.canDealTurn
    }

    /// Words still unplayed in the current turn.
    public static func unplayedWords(_ state: GameState) -> [DeckWord] {
        state.turnWords.filter { !state.playedWordIDs.contains($0.id) }
    }

    /// Whether every word in the current set has been played, so the next set is due.
    public static func isSetComplete(_ state: GameState) -> Bool {
        !state.turnWords.isEmpty && unplayedWords(state).isEmpty
    }
}
