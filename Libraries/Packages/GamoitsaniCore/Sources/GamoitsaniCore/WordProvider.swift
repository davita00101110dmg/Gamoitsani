//
//  WordProvider.swift
//  GamoitsaniCore
//

import Foundation

/// Supplies the words for a game.
///
/// A domain boundary, deliberately placed in Core so both the engine (which consumes a
/// deck) and the data layer (which builds one) depend on it without depending on each
/// other. The engine takes a finished deck and never performs I/O, so every rule test runs
/// against a fixed set of words with no async and no fake database.
///
/// Everything hard — querying, filtering by language, sampling, shuffling — belongs to
/// whoever conforms to this.
public protocol WordProvider: Sendable {
    /// A deck for one game.
    ///
    /// - Parameters:
    ///   - language: BCP-47-ish code matching the app's current language.
    ///   - count: how many words to draw. The result may be smaller if the catalogue is.
    func deck(language: String, count: Int) async throws -> Deck
}
