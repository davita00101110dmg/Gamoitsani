//
//  GameEngine.swift
//  GamoitsaniEngine
//
import Foundation
import Observation
import GamoitsaniCore

/// Drives a game.
@MainActor
@Observable
public final class GameEngine {

    public private(set) var state: GameState

    /// The last refused event, for debugging and tests. A rejection means the UI offered
    public private(set) var lastRejection: GameEventRejection?

    /// Injected so tests can control time. Nothing in the engine calls `Date()` directly.
    private let now: @Sendable () -> Date

    /// Injected for the same reason as `now`: a rematch needs a fresh super-word position,
    /// and the reducer must not draw one itself.
    private let nextPlacement: @Sendable () -> SuperWordPlacement

    /// Injected alongside `now` and `nextPlacement`, so a rematch's rules are as
    /// controllable in a test as its clock.
    private let drawChallenges: @Sendable ([Team]) -> [Team.ID: Challenge]

    public init(
        state: GameState,
        now: @escaping @Sendable () -> Date = { Date() },
        nextPlacement: @escaping @Sendable () -> SuperWordPlacement = { .random() },
        drawChallenges: @escaping @Sendable ([Team]) -> [Team.ID: Challenge] = {
            Challenge.draw(for: $0)
        }
    ) {
        self.state = state
        self.now = now
        self.nextPlacement = nextPlacement
        self.drawChallenges = drawChallenges
    }

    // MARK: - Events

    @discardableResult
    public func send(_ event: GameEvent) -> Bool {
        // Only a rematch deals rules again, so only a rematch pays for the draw.
        let challenges = event == .rematch ? drawChallenges(state.teams) : [:]
        return resolve(
            GameReducer.reduce(
                state, event, at: now(),
                nextPlacement: nextPlacement(),
                nextChallenges: challenges
            )
        )
    }

    /// Reports the result of work started elsewhere — words drawn while a game is running.
    /// Deliberately a different method from `send`, so screens cannot reach it.
    @discardableResult
    public func apply(_ effect: GameEffect) -> Bool {
        resolve(GameReducer.apply(state, effect))
    }

    private func resolve(_ result: Result<GameState, GameEventRejection>) -> Bool {
        switch result {
        case let .success(next):
            state = next
            lastRejection = nil
            return true
        case let .failure(rejection):
            lastRejection = rejection
            return false
        }
    }

    // MARK: - Time

    /// The current round's clock, or nil outside play.
    public var timer: RoundTimer? {
        guard let endsAt = state.roundEndsAt else { return nil }
        return RoundTimer(
            startingAt: endsAt.addingTimeInterval(-state.settings.roundLength),
            duration: state.settings.roundLength
        )
    }

    public var remainingTime: TimeInterval {
        timer?.remaining(at: now()) ?? 0
    }

    /// Ends the turn if the deadline has passed.
    @discardableResult
    public func checkExpiry() -> Bool {
        guard state.phase == .playing, let timer, timer.hasExpired(at: now()) else { return false }
        return send(.timeExpired)
    }

    // MARK: - Convenience

    public var currentTeam: Team? { state.currentTeam }
    public var wordsInPlay: [DeckWord] { GameRules.unplayedWords(state) }
    public var isFinished: Bool { state.phase == .finished }
    public var winner: Team? { GameRules.winner(state) }
    public var standings: [Team] { state.standings }
}
