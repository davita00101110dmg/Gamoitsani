//
//  WordDifficulty.swift
//  GamoitsaniCore
//
import Foundation

/// How hard the words in a game should be.
///
/// The tiers are caps rather than bands, so Normal contains every Easy word. Mixed is the
/// whole database and is the default: it is the only tier that puts the hardest words in
/// front of a group that did not deliberately ask for them, and the deepest pool once
/// already-played words are excluded.
public enum WordDifficulty: String, CaseIterable, Sendable, Hashable, Codable, Identifiable {
    case easy
    case normal
    case hard
    case mixed

    public var id: String { rawValue }

    /// Inclusive bounds against the database's 1–5 `difficulty` column.
    public var range: ClosedRange<Int> {
        switch self {
        case .easy: 1...2
        case .normal: 1...3
        case .hard: 4...5
        case .mixed: 1...5
        }
    }
}
