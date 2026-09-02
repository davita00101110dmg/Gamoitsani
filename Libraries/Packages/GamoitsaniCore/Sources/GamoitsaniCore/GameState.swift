//
//  GameState.swift
//  GamoitsaniCore
//

import Foundation

/// Where a game is in its lifecycle.
///
/// v1 sequenced these with `asyncAfter` delays of 0.2/0.3/0.5/1.5s plus a Combine countdown
/// chain, so "which screen are we on" was a function of elapsed wall time. Here it is data,
/// and animation is purely a view concern.
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
///
/// `Codable` so an in-progress game survives the app being killed. v1 kept all of this in
/// `GameStory.shared` and persisted none of it, so a phone call could destroy a session
/// mid-round.
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

    /// Words dealt to the current turn, most recent last.
    public private(set) var turnWords: [DeckWord]

    /// Which of `turnWords` have been played, so a card cannot be scored twice.
    ///
    /// v1's arcade *toggled* `isGuessed`, so re-tapping a guessed card subtracted the
    /// points again and incremented `wordsSkipped` — the same word counted as both guessed
    /// and skipped, inflating every statistic and breaking the streak.
    public private(set) var playedWordIDs: Set<String>

    /// 1-based set number within the current turn, for arcade super-word placement.
    public private(set) var setIndex: Int

    /// Teams that have already had their one super word this round.
    public private(set) var superWordSpentBy: Set<UUID>

    /// When the current round ends. Nil outside `.playing`.
    public private(set) var roundEndsAt: Date?

    public init(
        settings: GameSettings,
        teams: [Team],
        deck: Deck,
        placement: SuperWordPlacement = .random(),
        round: Int = 1,
        currentTeamIndex: Int = 0,
        phase: GamePhase = .turnInfo,
        turnWords: [DeckWord] = [],
        playedWordIDs: Set<String> = [],
        setIndex: Int = 1,
        superWordSpentBy: Set<UUID> = [],
        roundEndsAt: Date? = nil
    ) {
        self.settings = settings
        self.teams = teams
        self.deck = deck
        self.placement = placement
        self.round = round
        self.currentTeamIndex = currentTeamIndex
        self.phase = phase
        self.turnWords = turnWords
        self.playedWordIDs = playedWordIDs
        self.setIndex = setIndex
        self.superWordSpentBy = superWordSpentBy
        self.roundEndsAt = roundEndsAt
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

    // MARK: - Mutation (package-internal; the engine drives these)

    package mutating func setPhase(_ phase: GamePhase) {
        self.phase = phase
    }

    package mutating func setRoundEnd(_ date: Date?) {
        roundEndsAt = date
    }

    package mutating func updateCurrentTeam(_ transform: (inout Team) -> Void) {
        guard teams.indices.contains(currentTeamIndex) else { return }
        transform(&teams[currentTeamIndex])
    }

    package mutating func dealTurn() {
        turnWords = deck.dealTurn()
        playedWordIDs = []
        setIndex = 1
    }

    package mutating func markPlayed(_ id: String) {
        playedWordIDs.insert(id)
    }

    package mutating func advanceSet() {
        setIndex += 1
    }

    package mutating func spendSuperWord(for teamID: UUID) {
        superWordSpentBy.insert(teamID)
    }

    package mutating func advanceTurn() {
        currentTeamIndex += 1
        if currentTeamIndex >= teams.count {
            currentTeamIndex = 0
            round += 1
            // One super word per team per round, so the ledger clears with the round.
            superWordSpentBy = []
        }
    }

    package mutating func resetForRematch() {
        for index in teams.indices { teams[index].resetForNewGame() }
        round = 1
        currentTeamIndex = 0
        phase = .turnInfo
        turnWords = []
        playedWordIDs = []
        setIndex = 1
        superWordSpentBy = []
        roundEndsAt = nil
    }
}
