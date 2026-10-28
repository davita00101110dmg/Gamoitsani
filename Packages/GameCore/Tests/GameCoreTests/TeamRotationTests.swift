//
//  TeamRotationTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("Team rotation")
struct TeamRotationTests {

    @Test("teams play in order, and the round turns over after the last one")
    func rotation() {
        var (runner, clock) = Fixture.runner(rounds: 2, teams: 3)
        var order: [String] = []
        for _ in 0..<6 {
            order.append("r\(runner.state.round) \(runner.currentTeam?.name ?? "-")")
            // T0 scores, so the game is decided rather than running into a tie-break.
            let outcomes: [PlayOutcome] = runner.state.currentTeamIndex == 0 ? [.correct] : []
            runner.playTurn(outcomes, clock: clock)
        }
        #expect(order == ["r1 T0", "r1 T1", "r1 T2", "r2 T0", "r2 T1", "r2 T2"])
        #expect(runner.isFinished)
    }

    @Test("a tie-break round starts again from the first team")
    func tieBreakOrder() {
        var (runner, clock) = Fixture.runner(rounds: 1, teams: 3)
        for _ in 0..<3 { runner.playTurn([], clock: clock) }
        #expect(runner.state.isExtraRound)
        #expect(runner.currentTeam?.name == "T0")
    }

    @Test("a resumed game carries on with the team whose turn it was")
    func rotationSurvivesResume() {
        var (runner, clock) = Fixture.runner(rounds: 2, teams: 3)
        runner.playTurn([.correct], clock: clock)

        let resumed = GameRunner(resuming: runner.stateForSaving(), clock: clock,
                                 random: SeededGenerator(seed: 3))
        #expect(resumed.currentTeam?.name == "T1")
        #expect(resumed.state.round == 1)
    }

    @Test("each team's describer moves on one member per turn")
    func describerRotation() {
        let clock = ManualClock(Fixture.t0)
        var runner = GameRunner(
            settings: GameSettings(rounds: 3),
            teams: Fixture.teams(2, members: ["Nino", "Ana", "Luka"]),
            deck: Deck(words: Fixture.words(200)),
            clock: clock,
            random: SeededGenerator(seed: 5)
        )
        var describers: [String] = []
        for _ in 0..<6 {
            describers.append(currentDescriber(runner) ?? "-")
            let outcomes: [PlayOutcome] = runner.state.currentTeamIndex == 0 ? [.correct] : []
            runner.playTurn(outcomes, clock: clock)
        }
        #expect(describers == ["Nino", "Nino", "Ana", "Ana", "Luka", "Luka"])
    }

    /// In a live game `round` already counts tie-break rounds, and `Describer` adds
    /// `extraRound` on top, so the first tie-break skips a member. With two members and
    /// the default three rounds, one player describes twice running. Kept as-is in the copy.
    @Test("a tie-break hands the describer on to the next member")
    func describerThroughTieBreak() {
        let clock = ManualClock(Fixture.t0)
        var runner = GameRunner(
            settings: GameSettings(rounds: 3),
            teams: Fixture.teams(2, members: ["Nino", "Ana"]),
            deck: Deck(words: Fixture.words(200)),
            clock: clock,
            random: SeededGenerator(seed: 5)
        )
        for _ in 0..<4 { runner.playTurn([], clock: clock) }
        let lastScheduled = currentDescriber(runner)
        for _ in 0..<2 { runner.playTurn([], clock: clock) }
        #expect(runner.state.isExtraRound)
        #expect(lastScheduled == "Nino")

        withKnownIssue("Describer counts extra rounds twice") {
            #expect(currentDescriber(runner) == "Ana")
        }
    }

    private func currentDescriber(_ runner: GameRunner) -> String? {
        guard let team = runner.currentTeam else { return nil }
        return Describer.name(for: team, round: runner.state.round, extraRound: runner.state.extraRound)
    }
}
