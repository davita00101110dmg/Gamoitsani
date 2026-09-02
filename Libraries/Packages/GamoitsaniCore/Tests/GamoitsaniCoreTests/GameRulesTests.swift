//
//  GameRulesTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Game rules")
struct GameRulesTests {

    private func state(
        scores: [Int],
        rounds: Int = 1,
        round: Int = 1,
        teamIndex: Int = 0,
        deck: Deck = Deck(words: [DeckWord(id: "1", text: "a")])
    ) -> GameState {
        GameState(
            settings: GameSettings(rounds: rounds),
            teams: scores.enumerated().map { Team(name: "T\($0.offset)", score: $0.element) },
            deck: deck,
            round: round,
            currentTeamIndex: teamIndex
        )
    }

    // MARK: - The v1 crash

    /// v1's isTie() reads sortedTeams[1] unguarded, so this traps.
    @Test("a single team is not a tie and must not crash")
    func singleTeamDoesNotCrash() {
        #expect(GameRules.isTie(state(scores: [5])) == false)
    }

    @Test("no teams at all is not a tie")
    func noTeams() {
        #expect(GameRules.isTie(state(scores: [])) == false)
        #expect(GameRules.winner(state(scores: [])) == nil)
    }

    // MARK: - Ties

    @Test("tie detection compares only the top two", arguments: [
        ([5, 5], true),
        ([5, 3], false),
        ([5, 5, 5], true),      // three-way tie for first
        ([9, 4, 4], false),     // tie for second is irrelevant
        ([0, 0], true),
        ([-2, -2], true),       // scores can be negative
    ])
    func tieDetection(scores: [Int], expected: Bool) {
        #expect(GameRules.isTie(state(scores: scores)) == expected)
    }

    @Test("winner is nil while anyone is level with the leader")
    func winnerRequiresDaylight() {
        #expect(GameRules.winner(state(scores: [7, 3]))?.score == 7)
        #expect(GameRules.winner(state(scores: [5, 5])) == nil)
        #expect(GameRules.winner(state(scores: [5, 5, 1])) == nil)
        #expect(GameRules.winner(state(scores: [4]))?.score == 4)
    }

    // MARK: - End of game

    @Test("the game ends only after every team has played the final round")
    func endCondition() {
        // 2 teams, 1 round. Mid-round: team 2 still to play.
        #expect(GameRules.hasPlayedAllRounds(state(scores: [3, 1], rounds: 1, round: 1, teamIndex: 1)) == false)
        // Round rolled over to 2 and back to team 0 — everyone has played.
        #expect(GameRules.hasPlayedAllRounds(state(scores: [3, 1], rounds: 1, round: 2, teamIndex: 0)))
    }

    @Test("a tie at the end requires an extra round instead of ending")
    func tieForcesExtraRound() {
        let tied = state(scores: [4, 4], rounds: 1, round: 2, teamIndex: 0)
        #expect(GameRules.isGameOver(tied) == false)
        #expect(GameRules.needsExtraRound(tied))

        let decided = state(scores: [5, 4], rounds: 1, round: 2, teamIndex: 0)
        #expect(GameRules.isGameOver(decided))
        #expect(GameRules.needsExtraRound(decided) == false)
    }

    @Test("extra round number counts past the scheduled rounds")
    func extraRoundNumbering() {
        #expect(state(scores: [1, 1], rounds: 3, round: 3).extraRound == 0)
        #expect(state(scores: [1, 1], rounds: 3, round: 4).extraRound == 1)
        #expect(state(scores: [1, 1], rounds: 3, round: 6).isExtraRound)
    }

    // MARK: - Deck exhaustion

    /// v1 let an exhausted pool award +1 per tap forever in classic and charge -2 per tap
    /// in arcade, because nothing checked.
    @Test("a turn cannot start on an empty deck")
    func emptyDeckBlocksTurn() {
        #expect(GameRules.canStartTurn(state(scores: [1, 1], deck: Deck(words: []))) == false)
        #expect(GameRules.canStartTurn(state(scores: [1, 1])))
    }

    // MARK: - Super words

    @Test("a team gets at most one super word per round")
    func superWordBudget() {
        var s = GameState(
            settings: GameSettings(superWordsEnabled: true),
            teams: [Team(name: "A"), Team(name: "B")],
            deck: Deck(words: [])
        )
        let a = s.teams[0].id
        #expect(GameRules.canReceiveSuperWord(s, teamID: a))

        s.spendSuperWord(for: a)
        #expect(GameRules.canReceiveSuperWord(s, teamID: a) == false)
        #expect(GameRules.canReceiveSuperWord(s, teamID: s.teams[1].id), "other teams keep theirs")
    }

    @Test("the allowance resets when the round rolls over")
    func superWordResetsPerRound() {
        var s = GameState(
            settings: GameSettings(superWordsEnabled: true),
            teams: [Team(name: "A"), Team(name: "B")],
            deck: Deck(words: [])
        )
        let a = s.teams[0].id
        s.spendSuperWord(for: a)

        s.advanceTurn()   // -> team B, same round
        #expect(GameRules.canReceiveSuperWord(s, teamID: a) == false)

        s.advanceTurn()   // -> wraps to team A, round 2
        #expect(s.round == 2)
        #expect(GameRules.canReceiveSuperWord(s, teamID: a), "a new round restores the allowance")
    }

    @Test("super words are off unless enabled")
    func superWordsDisabled() {
        let s = GameState(settings: GameSettings(superWordsEnabled: false),
                          teams: [Team(name: "A")], deck: Deck(words: []))
        #expect(GameRules.canReceiveSuperWord(s, teamID: s.teams[0].id) == false)
    }

    // MARK: - Turn rotation

    @Test("turns rotate through every team before the round advances")
    func rotation() {
        var s = state(scores: [0, 0, 0], rounds: 2)
        #expect(s.round == 1 && s.currentTeamIndex == 0)

        s.advanceTurn(); #expect(s.currentTeamIndex == 1 && s.round == 1)
        s.advanceTurn(); #expect(s.currentTeamIndex == 2 && s.round == 1)
        s.advanceTurn(); #expect(s.currentTeamIndex == 0 && s.round == 2)
    }
}
