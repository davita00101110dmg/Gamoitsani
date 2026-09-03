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

    public init(state: GameState, now: @escaping @Sendable () -> Date = { Date() }) {
        self.state = state
        self.now = now
    }

    // MARK: - Events

    @discardableResult
    public func send(_ event: GameEvent) -> Bool {
        switch GameReducer.reduce(state, event, at: now()) {
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
