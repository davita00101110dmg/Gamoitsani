//
//  GameRunner.swift
//  GameCore
//
import Foundation

/// Drives one game: reads the clock, draws the randomness, and hands both to the reducer.
///
/// `GameEngine` without `Observation` or the main actor, plus the rule parts of the app's
/// `GameSession`. Nothing here calls `Date()` or the system generator directly.
public struct GameRunner: Sendable {

    public private(set) var state: GameState

    /// The last refused event. A rejection means the UI offered something the rules disallow.
    public private(set) var lastRejection: GameEventRejection?

    private let clock: any GameClock
    private var random: ErasedGenerator

    public init(
        state: GameState,
        clock: any GameClock = SystemClock(),
        random: any RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        self.state = state
        self.clock = clock
        self.random = ErasedGenerator(base: random)
    }

    /// A new game. Challenges are dealt once, here, so each team keeps its rule for the game.
    public init(
        settings: GameSettings,
        teams: [Team],
        deck: Deck,
        language: String = "ka",
        clock: any GameClock = SystemClock(),
        random: any RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        var random = random
        let placement = SuperWordPlacement.random(using: &random)
        let challenges = settings.challengesEnabled ? Challenge.draw(for: teams, using: &random) : [:]
        let state = GameState(
            settings: settings,
            teams: teams,
            deck: deck,
            placement: placement,
            deckLanguage: language,
            challenges: challenges
        )
        self.init(state: state, clock: clock, random: random)
    }

    /// A saved game picked up again, its clock restarted with the time that was left on it.
    public init(
        resuming saved: GameState,
        clock: any GameClock = SystemClock(),
        random: any RandomNumberGenerator & Sendable = SystemRandomNumberGenerator()
    ) {
        var state = saved
        var random = random
        state.resumeClock(at: clock.now())
        // A save from before challenges existed has the setting on and no rules to show.
        if state.settings.challengesEnabled && state.challenges.isEmpty {
            state.assignChallenges(Challenge.draw(for: state.teams, using: &random))
        }
        self.init(state: state, clock: clock, random: random)
    }

    /// The game as it goes to disk. A saved game is a paused one, so the clock is frozen.
    public func stateForSaving() -> GameState {
        var paused = state
        paused.pauseClock(at: clock.now())
        return paused
    }

    // MARK: - Events

    @discardableResult
    public mutating func send(_ event: GameEvent) -> Bool {
        let placement = SuperWordPlacement.random(using: &random)
        // Only a rematch deals rules again, so only a rematch draws them.
        let challenges = event == .rematch ? Challenge.draw(for: state.teams, using: &random) : [:]
        return resolve(
            GameReducer.reduce(
                state, event, at: clock.now(),
                nextPlacement: placement,
                nextChallenges: challenges
            )
        )
    }

    /// Reports the result of work started elsewhere, such as words drawn mid-game.
    @discardableResult
    public mutating func apply(_ effect: GameEffect) -> Bool {
        resolve(GameReducer.apply(state, effect))
    }

    private mutating func resolve(_ result: Result<GameState, GameEventRejection>) -> Bool {
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
        let length = state.settings.roundLength
        // `RoundTimer` traps on a zero-length round; only a hand-edited save can hold one.
        guard let endsAt = state.roundEndsAt, length > 0 else { return nil }
        return RoundTimer(startingAt: endsAt.addingTimeInterval(-length), duration: length)
    }

    /// Seconds left in the round, never negative. Zero outside play and while paused.
    public var remainingTime: TimeInterval {
        guard let endsAt = state.roundEndsAt else { return 0 }
        return max(0, endsAt.timeIntervalSince(clock.now()))
    }

    /// Ends the turn if the deadline has passed.
    @discardableResult
    public mutating func checkExpiry() -> Bool {
        guard state.phase == .playing,
              let endsAt = state.roundEndsAt,
              clock.now() >= endsAt
        else { return false }
        return send(.timeExpired)
    }

    // MARK: - Convenience

    public var currentTeam: Team? { state.currentTeam }
    public var wordsInPlay: [DeckWord] { GameRules.unplayedWords(state) }
    public var isFinished: Bool { state.phase == .finished }
    public var winner: Team? { GameRules.winner(state) }
    public var standings: [Team] { state.standings }
}

/// Lets the stored generator be passed `inout` to the generic draws.
private struct ErasedGenerator: RandomNumberGenerator, Sendable {
    var base: any RandomNumberGenerator & Sendable
    mutating func next() -> UInt64 { base.next() }
}
