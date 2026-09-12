//
//  GameState.swift
//  GamoitsaniCore
//
import Foundation

/// Where a game is in its lifecycle.
public enum GamePhase: Sendable, Hashable, Codable {
    /// Between turns: whose turn it is, and the reminder of how to play.
    case turnInfo
    /// The per-team challenge on a screen of its own.
    ///
    /// No longer entered — the rule is shown on the turn-info screen instead, which saved
    /// a tap on every single turn. Kept so a game saved while this phase still existed
    /// still decodes; `GameStateStore.load` uses `try?`, so a removed case would lose the
    /// game silently rather than loudly.
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

    /// The language the deck was drawn from, which is not always the language being
    /// displayed — a language with no word file falls back. Carried in state because
    /// anything recording what was played has to key it the same way, and after a resume
    /// there is nowhere else to learn it from.
    public private(set) var deckLanguage: String

    /// The rule each team is playing under, when challenges are on. Empty otherwise.
    /// Drawn once at the start and kept, so a team's rule is theirs for the game.
    public private(set) var challenges: [Team.ID: Challenge]

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
        pausedRemaining: TimeInterval? = nil,
        deckLanguage: String = "ka",
        challenges: [Team.ID: Challenge] = [:]
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
        self.deckLanguage = deckLanguage
        self.challenges = challenges
    }

    /// Decoded by hand because this is the type that actually goes to disk, and
    /// `GameStateStore.load` swallows a decode failure with `try?` — a synthesised decoder
    /// throws `keyNotFound` on any game saved before a new property existed, and the game
    /// would vanish silently on upgrade. Every property here is optional-decoded with a
    /// default for that reason. Add new ones the same way.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        settings = try container.decode(GameSettings.self, forKey: .settings)
        teams = try container.decode([Team].self, forKey: .teams)
        deck = try container.decode(Deck.self, forKey: .deck)
        placement = try container.decode(SuperWordPlacement.self, forKey: .placement)
        round = try container.decode(Int.self, forKey: .round)
        currentTeamIndex = try container.decode(Int.self, forKey: .currentTeamIndex)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        turnWords = try container.decode([DeckWord].self, forKey: .turnWords)
        wordsShownThisTurn = try container.decode(Int.self, forKey: .wordsShownThisTurn)
        playedOutcomes = try container.decode([String: PlayOutcome].self, forKey: .playedOutcomes)
        setIndex = try container.decode(Int.self, forKey: .setIndex)
        superWordSpentBy = try container.decode(Set<UUID>.self, forKey: .superWordSpentBy)
        roundEndsAt = try container.decodeIfPresent(Date.self, forKey: .roundEndsAt)
        pausedRemaining = try container.decodeIfPresent(TimeInterval.self, forKey: .pausedRemaining)
        // Georgian, because it was the only language with words when games were first saved.
        deckLanguage = try container.decodeIfPresent(String.self, forKey: .deckLanguage) ?? "ka"
        challenges = try container.decodeIfPresent(
            [Team.ID: Challenge].self, forKey: .challenges
        ) ?? [:]
    }

    /// Fills in rules for a game that has none — a save from before challenges existed,
    /// resumed with the setting still on.
    public mutating func assignChallenges(_ drawn: [Team.ID: Challenge]) {
        guard challenges.isEmpty else { return }
        challenges = drawn
    }

    /// The rule the given team is playing under, if challenges are on.
    public func challenge(for teamID: Team.ID) -> Challenge? { challenges[teamID] }

    /// The rule the team currently playing is under.
    public var currentChallenge: Challenge? {
        currentTeam.flatMap { challenges[$0.id] }
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

    /// Moves the super word for the turn about to start.
    ///
    /// Drawn per turn, not per game. Held for a whole game it landed on the same word
    /// number for every team in every round, so after the first turn the table knew
    /// exactly which word was worth three — and a super word nobody is surprised by is
    /// just a word. Each team still gets exactly one per round; only where it sits moves.
    mutating func movePlacement(to newPlacement: SuperWordPlacement) {
        placement = newPlacement
    }

    /// Takes a fresh placement rather than drawing one: the super word sat in exactly the
    /// same slot every rematch otherwise, and a group that noticed could see it coming.
    /// Passed in so the reducer stays pure.
    mutating func resetForRematch(
        placement newPlacement: SuperWordPlacement,
        challenges newChallenges: [Team.ID: Challenge]
    ) {
        placement = newPlacement
        // A rematch is a new game, so the rules are dealt again.
        if !challenges.isEmpty { challenges = newChallenges }
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
