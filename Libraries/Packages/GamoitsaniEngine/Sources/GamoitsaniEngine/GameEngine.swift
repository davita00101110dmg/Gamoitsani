//
//  GameEngine.swift
//  GamoitsaniEngine
//

import Foundation
import Observation
import GamoitsaniCore

/// Supplies the words for a game.
///
/// The engine takes a finished deck and never performs I/O, so every rule test runs
/// against a fixed set of words with no async and no fake database. Building the deck —
/// querying, filtering by language, shuffling — belongs to whoever conforms to this.
public protocol WordProvider: Sendable {
    func deck(language: String, count: Int) async throws -> Deck
}

/// Drives a game.
///
/// A thin shell over `GameReducer`: it owns the current state, hands events to the pure
/// function, and publishes the result. All the rules live in the reducer, so this type has
/// almost nothing in it — which is the point. v1's equivalent responsibilities were spread
/// across `GameViewModel`, `GameStory.shared`, `BaseGamePlayViewModel` and two subclasses.
///
/// `@MainActor` because it drives UI, and under Swift 6 that is enforced rather than
/// assumed.
@MainActor
@Observable
public final class GameEngine {

    public private(set) var state: GameState

    /// The last refused event, for debugging and tests. A rejection means the UI offered
    /// something the rules do not allow, which is a bug worth surfacing rather than
    /// swallowing.
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
    ///
    /// Called on every tick and on returning from the background. Because the deadline is
    /// wall-clock, time spent suspended has genuinely elapsed — v1 used `Timer.publish`,
    /// which does not fire while suspended, so backgrounding the app silently paused the
    /// round and handed the time back.
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
