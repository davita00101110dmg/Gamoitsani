//
//  Scoring.swift
//  GamoitsaniCore
//

import Foundation

public enum PlayOutcome: String, Sendable, Hashable, Codable, CaseIterable {
    case correct
    case skipped
}

public enum GameMode: String, Sendable, Hashable, Codable, CaseIterable {
    /// One word at a time.
    case classic
    /// Five words at once; the whole set can be swapped for a flat penalty.
    case arcade

    /// How many words are on screen at once.
    public var wordsPerSet: Int {
        switch self {
        case .classic: 1
        case .arcade: 5
        }
    }
}

/// The single authority on what a play is worth.
///
/// v1 spread these numbers across three places that disagreed with each other:
/// `WordItem.Constants` held the four values; `ClassicGamePlayViewModel.wordButtonAction`
/// recomputed super-word scoring inline as `isCorrect ? superWordPoints : -superWordPoints`
/// instead of reading the skipped constant; and `GameMode.skipPenalty` declared `.classic`
/// as `0` while classic skips actually cost −1, so the property was quietly wrong and only
/// ever read for arcade. Everything that decides a number now lives here.
public enum Scoring {

    /// A correctly guessed ordinary word.
    public static let regular = 1

    /// An ordinary word skipped or missed.
    public static let regularSkipped = -1

    /// A correctly guessed super word.
    public static let superWord = 3

    /// A super word skipped or missed.
    public static let superWordSkipped = -3

    /// Flat penalty for abandoning a whole set of words. Arcade only.
    public static let setSkip = -2

    /// Points for one word.
    public static func points(for outcome: PlayOutcome, isSuperWord: Bool) -> Int {
        switch (outcome, isSuperWord) {
        case (.correct, false): regular
        case (.skipped, false): regularSkipped
        case (.correct, true): superWord
        case (.skipped, true): superWordSkipped
        }
    }

    /// Penalty for swapping out a whole set. Classic has no set to skip, so this is zero
    /// rather than an error — it keeps callers branch-free.
    public static func setSkipPenalty(for mode: GameMode) -> Int {
        switch mode {
        case .classic: 0
        case .arcade: setSkip
        }
    }
}
