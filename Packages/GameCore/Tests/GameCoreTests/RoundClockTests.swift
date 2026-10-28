//
//  RoundClockTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

@Suite("Round clock")
struct RoundClockTests {

    @Test("the round clock counts down from the configured length")
    func clockCountsDown() {
        var (runner, clock) = Fixture.runner(roundLength: 45)
        runner.startTurn()

        #expect(runner.remainingTime == 45)
        clock.advance(by: 20)
        #expect(runner.remainingTime == 25)
        #expect(runner.timer?.duration == 45)
    }

    @Test("the round ends when the clock runs out, not a moment before")
    func endsAtTheDeadline() {
        var (runner, clock) = Fixture.runner(roundLength: 60, teams: 2)
        runner.startTurn()

        // Quarter seconds, the app's own tick, and exact in floating point.
        clock.advance(by: 59.75)
        let early = runner.checkExpiry()
        #expect(early == false)
        #expect(runner.state.phase == .playing)

        clock.advance(by: 0.25)
        let onTime = runner.checkExpiry()
        #expect(onTime)
        #expect(runner.state.phase == .turnInfo)
        #expect(runner.currentTeam?.name == "T1", "the turn passes to the next team")
        #expect(runner.state.turnWords.isEmpty)
        #expect(runner.timer == nil)
        #expect(runner.remainingTime == 0)
    }

    @Test("answering does not buy more time")
    func answersDoNotExtendTheRound() {
        var (runner, clock) = Fixture.runner(roundLength: 30)
        runner.startTurn()
        for _ in 0..<10 {
            clock.advance(by: 2)
            runner.answerNext(.correct)
        }
        #expect(runner.remainingTime == 10)
    }

    /// The whole reason for a wall-clock deadline: backgrounding must not pause the round.
    @Test("returning from the background after the deadline ends the turn")
    func expiryAfterBackgrounding() {
        var (runner, clock) = Fixture.runner(roundLength: 45, teams: 2)
        runner.startTurn()
        #expect(runner.state.currentTeamIndex == 0)

        clock.advance(by: 600)
        let expired = runner.checkExpiry()
        #expect(expired)
        #expect(runner.state.phase == .turnInfo)
        #expect(runner.state.currentTeamIndex == 1, "the turn passed while we were away")
    }

    @Test("checkExpiry is inert outside play")
    func expiryOnlyDuringPlay() {
        var (runner, clock) = Fixture.runner()
        clock.advance(by: 10_000)
        let beforeTurn = runner.checkExpiry()
        #expect(beforeTurn == false, "not playing, so there is nothing to expire")

        runner.send(.beginTurn)
        clock.advance(by: 10_000)
        let duringCountdown = runner.checkExpiry()
        #expect(duringCountdown == false, "the countdown does not run the round clock")
        #expect(runner.remainingTime == 0)
    }

    @Test("a saved game keeps the time it had left, however long it is put away")
    func saveAndResume() throws {
        var (runner, clock) = Fixture.runner(roundLength: 60)
        runner.startTurn()
        clock.advance(by: 20)

        let saved = runner.stateForSaving()
        #expect(saved.pausedRemaining == 40)
        #expect(saved.roundEndsAt == nil)

        clock.advance(by: 86_400)
        var resumed = GameRunner(resuming: saved, clock: clock, random: SeededGenerator(seed: 1))
        #expect(resumed.remainingTime == 40)
        let early = resumed.checkExpiry()
        #expect(early == false)

        clock.advance(by: 40)
        let onTime = resumed.checkExpiry()
        #expect(onTime)
        #expect(resumed.state.phase == .turnInfo)
    }

    @Test("saving does not stop the live round")
    func savingLeavesTheLiveClockAlone() {
        var (runner, clock) = Fixture.runner(roundLength: 60)
        runner.startTurn()
        _ = runner.stateForSaving()
        clock.advance(by: 60)
        let expired = runner.checkExpiry()
        #expect(expired, "only the saved copy is paused")
    }
}
