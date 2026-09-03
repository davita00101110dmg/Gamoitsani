//
//  GameEngineTests.swift
//  GamoitsaniEngineTests
//

import Testing
import Foundation
import GamoitsaniCore
@testable import GamoitsaniEngine

@MainActor
@Suite("Game engine")
struct GameEngineTests {

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    /// A controllable clock. Nothing in the engine calls Date() directly, which is what
    /// makes expiry testable without waiting 45 seconds.
    private final class Clock: @unchecked Sendable {
        var now: Date
        init(_ now: Date) { self.now = now }
    }

    private func makeEngine(
        roundLength: TimeInterval = 45,
        teams: Int = 2,
        words: Int = 50
    ) -> (GameEngine, Clock) {
        let clock = Clock(t0)
        let state = GameState(
            settings: GameSettings(rounds: 1, roundLength: roundLength),
            teams: (0..<teams).map { Team(name: "T\($0)") },
            deck: Deck(words: (0..<words).map { DeckWord(id: "\($0)", text: "w\($0)") })
        )
        return (GameEngine(state: state, now: { clock.now }), clock)
    }

    @Test("send applies the event and publishes the new state")
    func sendAppliesEvent() {
        let (engine, _) = makeEngine()
        #expect(engine.state.phase == .turnInfo)
        #expect(engine.send(.beginTurn))
        #expect(engine.state.phase == .countdown)
    }

    /// A rejection means the UI offered something the rules disallow — surfaced, not
    /// swallowed.
    @Test("a refused event leaves the state untouched and records why")
    func rejectionIsSurfaced() {
        let (engine, _) = makeEngine()
        let before = engine.state

        #expect(engine.send(.countdownFinished) == false)
        #expect(engine.state == before)
        #expect(engine.lastRejection == .wrongPhase(.turnInfo))

        #expect(engine.send(.beginTurn))
        #expect(engine.lastRejection == nil, "a success clears the previous rejection")
    }

    @Test("the round clock counts down from the configured length")
    func clockCountsDown() {
        let (engine, clock) = makeEngine(roundLength: 45)
        engine.send(.beginTurn)
        engine.send(.countdownFinished)

        #expect(engine.remainingTime == 45)
        clock.now = t0.addingTimeInterval(20)
        #expect(engine.remainingTime == 25)
    }

    @Test("checkExpiry does nothing while time remains")
    func expiryWaits() {
        let (engine, clock) = makeEngine(roundLength: 45)
        engine.send(.beginTurn)
        engine.send(.countdownFinished)

        clock.now = t0.addingTimeInterval(44)
        #expect(engine.checkExpiry() == false)
        #expect(engine.state.phase == .playing)
    }

    /// The whole reason for a wall-clock deadline: v1 used Timer.publish, which does not
    /// fire while suspended, so backgrounding paused the round and returned the time.
    @Test("returning from the background after the deadline ends the turn")
    func expiryAfterBackgrounding() {
        let (engine, clock) = makeEngine(roundLength: 45, teams: 2)
        engine.send(.beginTurn)
        engine.send(.countdownFinished)
        #expect(engine.state.currentTeamIndex == 0)

        // App suspended well past the deadline, then resumed.
        clock.now = t0.addingTimeInterval(600)
        #expect(engine.checkExpiry())
        #expect(engine.state.phase == .turnInfo)
        #expect(engine.state.currentTeamIndex == 1, "the turn passed while we were away")
    }

    @Test("checkExpiry is inert outside play")
    func expiryOnlyDuringPlay() {
        let (engine, clock) = makeEngine()
        clock.now = t0.addingTimeInterval(10_000)
        #expect(engine.checkExpiry() == false, "not playing, so there is nothing to expire")
    }

    @Test("convenience accessors reflect the state")
    func accessors() {
        let (engine, _) = makeEngine(teams: 2)
        engine.send(.beginTurn)
        engine.send(.countdownFinished)

        #expect(engine.currentTeam?.name == "T0")
        #expect(engine.wordsInPlay.count == 1)
        #expect(engine.isFinished == false)
        #expect(engine.standings.count == 2)
    }
}
