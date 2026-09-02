//
//  Team.swift
//  GamoitsaniCore
//

import Foundation

/// A team and everything it accumulates during a game.
///
/// Identity-keyed. v1 kept per-team state in parallel arrays and dictionaries indexed by
/// position, so anything that reordered teams moved their data with it; here whatever
/// belongs to a team lives on the team.
///
/// No method reads the clock. v1's `Team` called `Date()` inside `startGuessing` and
/// `updateStreak`, which made guess timing untestable — and, in the end, wrong: classic
/// never called `startGuessing` at all, so it always reported an average of 0.0s.
public struct Team: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID
    public var name: String

    public private(set) var score: Int
    public private(set) var wordsGuessed: Int
    public private(set) var wordsSkipped: Int
    public private(set) var currentStreak: Int
    public private(set) var bestStreak: Int
    public private(set) var totalGuessTime: TimeInterval
    public private(set) var setsSkipped: Int
    public private(set) var superWordsGuessed: Int

    /// When the current word was shown. Nil between words.
    public private(set) var guessStartedAt: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        score: Int = 0,
        wordsGuessed: Int = 0,
        wordsSkipped: Int = 0,
        currentStreak: Int = 0,
        bestStreak: Int = 0,
        totalGuessTime: TimeInterval = 0,
        setsSkipped: Int = 0,
        superWordsGuessed: Int = 0,
        guessStartedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.wordsGuessed = wordsGuessed
        self.wordsSkipped = wordsSkipped
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.totalGuessTime = totalGuessTime
        self.setsSkipped = setsSkipped
        self.superWordsGuessed = superWordsGuessed
        self.guessStartedAt = guessStartedAt
    }

    /// Mean time to guess a word, or zero when nothing has been guessed.
    ///
    /// Zero rather than NaN: an unguarded division would render as "nan" on the
    /// scoreboard, and a formatter will not save you from it.
    public var averageGuessTime: TimeInterval {
        wordsGuessed > 0 ? totalGuessTime / Double(wordsGuessed) : 0
    }

    // MARK: - Mutation

    /// Marks the moment a word became visible, so the guess can be timed.
    public mutating func beginGuessing(at now: Date) {
        guessStartedAt = now
    }

    /// Records the outcome of one word: score, streak, counters and elapsed time together,
    /// so they cannot disagree.
    ///
    /// v1 replayed these in bulk at the end of a turn — every guess first, then every
    /// skip — which meant the recorded streak was never the real in-turn sequence and
    /// `bestStreak` always came out equal to the turn's guess count.
    public mutating func record(_ outcome: PlayOutcome, isSuperWord: Bool, at now: Date) {
        if let guessStartedAt {
            totalGuessTime += now.timeIntervalSince(guessStartedAt)
            self.guessStartedAt = nil
        }

        score += Scoring.points(for: outcome, isSuperWord: isSuperWord)

        switch outcome {
        case .correct:
            wordsGuessed += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
            if isSuperWord { superWordsGuessed += 1 }
        case .skipped:
            wordsSkipped += 1
            currentStreak = 0
        }
    }

    /// Arcade only: abandoning a whole set of words for a flat penalty.
    public mutating func skipSet(mode: GameMode) {
        setsSkipped += 1
        score += Scoring.setSkipPenalty(for: mode)
        currentStreak = 0
        guessStartedAt = nil
    }

    /// Clears play state but keeps identity, for a rematch with the same teams.
    public mutating func resetForNewGame() {
        score = 0
        wordsGuessed = 0
        wordsSkipped = 0
        currentStreak = 0
        bestStreak = 0
        totalGuessTime = 0
        setsSkipped = 0
        superWordsGuessed = 0
        guessStartedAt = nil
    }
}
