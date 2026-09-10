//
//  GameState.swift
//  GamoitsaniCore
//
import Foundation

/// Where a game is in its lifecycle.
public enum GamePhase: Sendable, Hashable, Codable {
    /// Between turns: whose turn it is, and the reminder of how to play.
    case turnInfo
    /// The optional per-team challenge, shown only when enabled.
    case challenge
    /// 3-2-1 before the clock starts.
    case countdown
    /// The clock is running.
    case playing
    /// Every round is done and the winner is decided.
    case finished
}

/// The whole of a game, as one value.
public struct GameState: Sendable, Hashable, Codable {

    public var settings: GameSettings
    public private(set) var teams: [Team]
    public private(set) var deck: Deck
    public private(set) var placement: SuperWordPlacement

    /// 1-based. Climbs past `settings.rounds` during tie-break rounds.
    public private(set) var round: Int

    /// Index into `teams` for whoever is playing now.
    public private(set) var currentTeamIndex: Int

    public private(set) var phase: GamePhase

    /// The words currently on the table: one in classic, five in arcade.
    public private(set) var turnWords: [DeckWord]

    /// How many words this team has been shown this turn, for classic super-word
    /// placement (v1 put it at a random position among the turn's first five).
    public private(set) var wordsShownThisTurn: Int

    /// How each played word was answered, so a mistaken tap can be reversed exactly.
    public private(set) var playedOutcomes: [String: PlayOutcome]

    /// Which of `turnWords` have been answered.
    public var playedWordIDs: Set<String> { Set(playedOutcomes.keys) }

    /// 1-based set number within the current turn, for arcade super-word placement.
    public private(set) var setIndex: Int

    /// Teams that have already had their one super word this round.
    public private(set) var superWordSpentBy: Set<UUID>

    /// When the current round ends. Nil outside `.playing`, and nil while paused.
    public private(set) var roundEndsAt: Date?

    /// Seconds left when the game was put down. Set only while paused.
    public private(set) var pausedRemaining: TimeInterval?

    public init(
        settings: GameSettings,
        teams: [Team],
        deck: Deck,
        placement: SuperWordPlacement = .random(),
        round: Int = 1,
        currentTeamIndex: Int = 0,
        phase: GamePhase = .turnInfo,
        turnWords: [DeckWord] = [],
        wordsShownThisTurn: Int = 0,
        playedOutcomes: [String: PlayOutcome] = [:],
        setIndex: Int = 1,
        superWordSpentBy: Set<UUID> = [],
        roundEndsAt: Date? = nil,
        pausedRemaining: TimeInterval? = nil
    ) {
        self.settings = settings
        self.teams = teams
        self.deck = deck
        self.placement = placement
        self.round = round
        self.currentTeamIndex = currentTeamIndex
        self.phase = phase
        self.turnWords = turnWords
        self.wordsShownThisTurn = wordsShownThisTurn
        self.playedOutcomes = playedOutcomes
        self.setIndex = setIndex
        self.superWordSpentBy = superWordSpentBy
        self.roundEndsAt = roundEndsAt
        self.pausedRemaining = pausedRemaining
    }

    // MARK: - Derived

    public var currentTeam: Team? {
        teams.indices.contains(currentTeamIndex) ? teams[currentTeamIndex] : nil
    }

    /// Teams ordered by score, highest first. Ties keep their existing order.
    public var standings: [Team] {
        teams.sorted { $0.score > $1.score }
    }

    /// How far past the scheduled rounds we are. Zero during normal play.
    public var extraRound: Int {
        max(0, round - settings.rounds)
    }

    public var isExtraRound: Bool { extraRound > 0 }

    public var isPaused: Bool { pausedRemaining != nil }

    /// Freezes the clock, for a game being put away rather than merely backgrounded.
    ///
    /// Suspending the app must not stop the round — that would let anyone pause by swiping
    /// up. Deliberately leaving, or being terminated, is different: the game is set down,
    /// and it should be waiting where it was.
    public mutating func pauseClock(at now: Date) {
        guard phase == .playing, let roundEndsAt else { return }
        pausedRemaining = max(0, roundEndsAt.timeIntervalSince(now))
        self.roundEndsAt = nil
    }

    /// Restarts a frozen clock with the time that was left on it.
    public mutating func resumeClock(at now: Date) {
        guard let pausedRemaining else { return }
        roundEndsAt = now.addingTimeInterval(pausedRemaining)
        self.pausedRemaining = nil
    }

    // MARK: - Mutation (internal; only GameReducer drives these)

    mutating func setPhase(_ phase: GamePhase) {
        self.phase = phase
    }

    mutating func setRoundEnd(_ date: Date?) {
        roundEndsAt = date
    }

    mutating func updateCurrentTeam(_ transform: (inout Team) -> Void) {
        guard teams.indices.contains(currentTeamIndex) else { return }
        transform(&teams[currentTeamIndex])
    }

    /// Draws the next set from the deck and decides which word, if any, is the super
    mutating func dealSet() {
        let size = settings.mode.wordsPerSet
        var drawn = deck.deal(size)
        guard !drawn.isEmpty else {
            turnWords = []
            return
        }

        let eligible = currentTeam.map { GameRules.canReceiveSuperWord(self, teamID: $0.id) } ?? false
        if eligible {
            for offset in drawn.indices {
                // 1-based, and in classic the index continues across the whole turn.
                let wordIndex = settings.mode == .classic
                    ? wordsShownThisTurn + offset + 1
                    : offset + 1
                if placement.isSuperWord(mode: settings.mode, wordIndex: wordIndex, setIndex: setIndex) {
                    drawn[offset].isSuperWord = true
                    break
                }
            }
        }

        wordsShownThisTurn += drawn.count
        turnWords = drawn
        playedOutcomes = [:]
    }

    /// Adds words to a deck that is running low, mid-game.
    mutating func refillDeck(with words: [DeckWord]) {
        deck.add(words)
    }

    /// Clears the table at the end of a turn.
    mutating func clearTurn() {
        turnWords = []
        playedOutcomes = [:]
        wordsShownThisTurn = 0
        setIndex = 1
    }

    mutating func markPlayed(_ id: String, as outcome: PlayOutcome) {
        playedOutcomes[id] = outcome
    }

    /// Forgets a play, so the word is back on the table.
    @discardableResult
    mutating func unmarkPlayed(_ id: String) -> PlayOutcome? {
        playedOutcomes.removeValue(forKey: id)
    }

    mutating func returnSuperWord(to teamID: UUID) {
        superWordSpentBy.remove(teamID)
    }

    mutating func advanceSet() {
        setIndex += 1
    }

    mutating func spendSuperWord(for teamID: UUID) {
        superWordSpentBy.insert(teamID)
    }

    mutating func advanceTurn() {
        currentTeamIndex += 1
        if currentTeamIndex >= teams.count {
            currentTeamIndex = 0
            round += 1
            // One super word per team per round, so the ledger clears with the round.
            superWordSpentBy = []
        }
    }

    mutating func resetForRematch() {
        for index in teams.indices { teams[index].resetForNewGame() }
        round = 1
        currentTeamIndex = 0
        phase = .turnInfo
        turnWords = []
        playedOutcomes = [:]
        wordsShownThisTurn = 0
        setIndex = 1
        superWordSpentBy = []
        roundEndsAt = nil
    }
}
