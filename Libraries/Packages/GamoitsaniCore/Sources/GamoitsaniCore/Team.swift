//
//  Team.swift
//  GamoitsaniCore
//
import Foundation

/// A team and everything it accumulates during a game.
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
    public var averageGuessTime: TimeInterval {
        wordsGuessed > 0 ? totalGuessTime / Double(wordsGuessed) : 0
    }

    // MARK: - Mutation

    /// Marks the moment a word became visible, so the guess can be timed.
    public mutating func beginGuessing(at now: Date) {
        guessStartedAt = now
    }

    /// Records the outcome of one word: score, streak, counters and elapsed time together,
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

    /// Reverses a recorded play, for a word tapped by mistake.
    public mutating func undo(_ outcome: PlayOutcome, isSuperWord: Bool) {
        score -= Scoring.points(for: outcome, isSuperWord: isSuperWord)

        switch outcome {
        case .correct:
            wordsGuessed = max(0, wordsGuessed - 1)
            currentStreak = max(0, currentStreak - 1)
            if isSuperWord { superWordsGuessed = max(0, superWordsGuessed - 1) }
        case .skipped:
            wordsSkipped = max(0, wordsSkipped - 1)
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
