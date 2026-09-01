//
//  Scoring.swift
//  GamoitsaniCore
//

import Foundation

/// The single authority on what a play is worth.
///
/// v1 spread this across three places that could disagree: `WordItem.Constants`,
/// `ClassicGamePlayViewModel.wordButtonAction` and `GameMode.skipPenalty`. Phase 5 ports
/// the real rules here; this is the seam they land on.
public enum Scoring {
    public static let correct = 1
    public static let skipPenalty = -1

    public static func points(for outcome: PlayOutcome) -> Int {
        switch outcome {
        case .correct: correct
        case .skipped: skipPenalty
        }
    }
}

public enum PlayOutcome: Sendable, Hashable {
    case correct
    case skipped
}
