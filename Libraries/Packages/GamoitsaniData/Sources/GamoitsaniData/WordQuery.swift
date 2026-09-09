//
//  WordQuery.swift
//  GamoitsaniData
//
import Foundation

/// One row of the bundled database.
///
/// `id` is an `Int` here because that is what the file stores, and because it is promised
/// stable across content updates — it is the key player state is recorded against.
public struct WordRow: Sendable, Hashable, Identifiable {
    public let id: Int
    public let lemma: String

    public init(id: Int, lemma: String) {
        self.id = id
        self.lemma = lemma
    }
}

/// What to draw from the database.
public struct WordQuery: Sendable, Hashable {

    /// Inclusive difficulty bounds, 1 easy to 5 hard.
    public var difficulty: ClosedRange<Int>

    /// Ids to leave out — words this group has already played.
    public var excluding: Set<Int>

    /// The most rows to return. Fewer come back when the pool holds fewer.
    public var limit: Int

    public init(difficulty: ClosedRange<Int> = 1...5, excluding: Set<Int> = [], limit: Int) {
        self.difficulty = difficulty
        self.excluding = excluding
        self.limit = limit
    }
}

/// Why the database could not be read.
public enum WordDatabaseError: Error, Sendable, Hashable {
    /// No `words_<language>.db` ships in the bundle.
    case notBundled(language: String)
    case cannotOpen(path: String, code: Int32)
    case query(message: String)
}
