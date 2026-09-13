//
//  MovingSuperWordTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

/// Where the super word lands across a game, as opposed to `SuperWordPlacement`'s own
/// rules, which `DeckTests` covers.
///
/// It is worth three points, and it stops being worth anything as a surprise the moment
/// the table can predict it. Held for a whole game it sat on the same word number for
/// every team in every round, which is exactly that.
@Suite("Moving the super word")
struct MovingSuperWordTests {

    private func teams(_ n: Int) -> [Team] {
        (1...n).map { Team(name: "Team \($0)") }
    }

    private func state(rounds: Int = 2, teams roster: [Team]) -> GameState {
        GameState(
            settings: GameSettings(rounds: rounds, superWordsEnabled: true),
            teams: roster,
            deck: Deck(words: (1...80).map { DeckWord(id: "\($0)", text: "w\($0)") }),
            placement: SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)
        )
    }

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    @Test("a turn takes the placement it is given")
    func turnTakesGivenPlacement() throws {
        var s = state(teams: teams(2))
        let moved = SuperWordPlacement(classicPosition: 4, arcadeSet: 2, arcadeSlot: 3)

        s = try GameReducer.reduce(s, .beginTurn, at: t0, nextPlacement: moved).get()

        #expect(s.placement == moved)
    }

    /// The actual regression: two teams in a row must not be handed the same slot.
    @Test("consecutive turns get different placements")
    func placementMovesBetweenTurns() throws {
        var s = state(teams: teams(2))
        let first = SuperWordPlacement(classicPosition: 2, arcadeSet: 1, arcadeSlot: 2)
        let second = SuperWordPlacement(classicPosition: 5, arcadeSet: 2, arcadeSlot: 4)

        s = try GameReducer.reduce(s, .beginTurn, at: t0, nextPlacement: first).get()
        #expect(s.placement == first)

        s = try GameReducer.reduce(s, .countdownFinished, at: t0).get()
        s = try GameReducer.reduce(s, .timeExpired, at: t0).get()
        s = try GameReducer.reduce(s, .beginTurn, at: t0, nextPlacement: second).get()

        #expect(s.placement == second, "the second team plays a different slot")
    }

    /// Moving it must not quietly hand anyone a second one, or a team could out-score
    /// another by three for no reason they could see.
    @Test("each team still gets exactly one per round")
    func fairnessIsUnchanged() throws {
        let roster = teams(2)
        var s = state(teams: roster)

        #expect(GameRules.canReceiveSuperWord(s, teamID: roster[0].id))
        s.spendSuperWord(for: roster[0].id)
        #expect(!GameRules.canReceiveSuperWord(s, teamID: roster[0].id), "not twice in a round")
        #expect(GameRules.canReceiveSuperWord(s, teamID: roster[1].id), "the other team still has theirs")
    }

    /// A game put down mid-turn and picked up again must keep the slot it was playing,
    /// which is why the draw happens on `beginTurn` and not on the countdown.
    @Test("resuming mid-turn keeps the placement")
    func resumeKeepsPlacement() throws {
        var s = state(teams: teams(2))
        let drawn = SuperWordPlacement(classicPosition: 3, arcadeSet: 1, arcadeSlot: 5)

        s = try GameReducer.reduce(s, .beginTurn, at: t0, nextPlacement: drawn).get()
        s = try GameReducer.reduce(s, .countdownFinished, at: t0).get()

        let encoded = try JSONEncoder().encode(s)
        let restored = try JSONDecoder().decode(GameState.self, from: encoded)

        #expect(restored.placement == drawn)
    }
}
