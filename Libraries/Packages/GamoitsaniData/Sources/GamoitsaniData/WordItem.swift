//
//  WordItem.swift
//  GamoitsaniData
//

import Foundation

/// A word, as a value type.
///
/// The data layer vends these rather than `NSManagedObject`s. In v1, background-context
/// managed objects were handed to the main actor and their relationship faults fired
/// during gameplay — a thread-confinement violation and the most likely cause of the
/// reported freezes. A `Sendable` struct cannot do that.
public struct WordItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let baseWord: String
    public let translations: [String: String]

    public init(id: String, baseWord: String, translations: [String: String] = [:]) {
        self.id = id
        self.baseWord = baseWord
        self.translations = translations
    }

    /// The word to display for a language, falling back to the Georgian base word.
    public func text(for languageCode: String) -> String {
        translations[languageCode] ?? baseWord
    }
}

/// Phase 6 implements this over Core Data as an `actor`.
public protocol WordStore: Sendable {
    func words(limit: Int, language: String) async throws -> [WordItem]
}
