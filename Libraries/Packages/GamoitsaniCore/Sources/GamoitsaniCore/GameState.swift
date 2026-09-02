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

    /// The words currently on the table: one in classic, five in arcade.
    ///
    /// v1 sliced 50 words off a global list per turn and then drew from that slice, which
    /// is the intermediate that produced its worst bug — `removeFirstNItems(50)` returning
    /// nil rather than the remainder. There is no such intermediate here: sets are drawn
    /// from the deck as play proceeds.
    public private(set) var turnWords: [DeckWord]

    /// How many words this team has been shown this turn, for classic super-word
    /// placement (v1 put it at a random position among the turn's first five).
    public private(set) var wordsShownThisTurn: Int

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
        wordsShownThisTurn: Int = 0,
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
        self.wordsShownThisTurn = wordsShownThisTurn
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
    /// word.
    ///
    /// Assignment happens here because it depends on position — classic on the word's
    /// index within the turn, arcade on the set and slot — which is not known until the
    /// word reaches the table. The allowance is only consulted, never spent: it is spent
    /// when the word is actually played, so a super word the team never reaches does not
    /// burn their one per round the way v1's arcade did.
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
        playedWordIDs = []
    }

    /// Clears the table at the end of a turn.
    mutating func clearTurn() {
        turnWords = []
        playedWordIDs = []
        wordsShownThisTurn = 0
        setIndex = 1
    }

    mutating func markPlayed(_ id: String) {
        playedWordIDs.insert(id)
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
        playedWordIDs = []
        wordsShownThisTurn = 0
        setIndex = 1
        superWordSpentBy = []
        roundEndsAt = nil
    }
}
