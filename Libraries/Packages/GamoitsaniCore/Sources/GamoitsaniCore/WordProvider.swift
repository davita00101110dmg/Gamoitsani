//
//  WordProvider.swift
//  GamoitsaniCore
//
import Foundation

/// Supplies the words for a game.
public protocol WordProvider: Sendable {
    /// A deck for one game.
    func deck(language: String, count: Int) async throws -> Deck
}
