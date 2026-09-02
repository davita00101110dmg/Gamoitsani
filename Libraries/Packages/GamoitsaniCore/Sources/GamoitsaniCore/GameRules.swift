//
//  GameRules.swift
//  GamoitsaniCore
//

import Foundation

/// Pure decisions about a `GameState`. No mutation, no clock, no I/O — every rule is a
/// function of the state you hand it, which is what makes the whole rule set testable
/// without a simulator.
public enum GameRules {

    /// Whether every scheduled round has been completed by every team.
    ///
    /// v1's condition was `currentRound > numberOfRounds && currentTeamIndex == 0`,
    /// evaluated *after* advancing. Same rule, stated directly.
    public static func hasPlayedAllRounds(_ state: GameState) -> Bool {
        state.round > state.settings.rounds && state.currentTeamIndex == 0
    }

    /// Whether the leaders are level and the game therefore cannot end.
    ///
    /// **This is where v1 crashes.** `GameViewModel.isTie()` reads `sortedTeams[1]` with no
    /// bounds check, so a single-team state traps — reachable because `GameStory` was a
    /// singleton anything could populate, and it is also called unconditionally for
    /// analytics. Fewer than two teams cannot be tied, so it returns false.
    ///
    /// A three-way tie for first counts, because the top two of the sorted list are equal.
    /// A tie for second does not, which matches v1 and is the right rule: the game ends
    /// when there is a single winner.
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
    ///
    /// One per team per round, and only when the setting is on. The allowance is spent when
    /// a super word is actually *played* — v1 spent it in arcade at generation time, so a
    /// super word the team never reached still consumed it.
    public static func canReceiveSuperWord(_ state: GameState, teamID: UUID) -> Bool {
        state.settings.superWordsEnabled && !state.superWordSpentBy.contains(teamID)
    }

    /// Whether a turn can begin. False when the deck is spent.
    ///
    /// v1 had no such check, which is why an exhausted pool let classic award +1 per tap
    /// forever and arcade charge −2 per tap on an empty grid.
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
