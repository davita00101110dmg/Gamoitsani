//
//  WordRecord.swift
//  GamoitsaniData
//
import Foundation

/// A word as it arrives from the server, before it is cached.
public struct WordRecord: Sendable, Hashable, Codable, Identifiable {
    public let id: String
    public let baseWord: String
    public let translations: [String: String]
    public let updatedAt: Date

    public init(id: String, baseWord: String, translations: [String: String], updatedAt: Date) {
        self.id = id
        self.baseWord = baseWord
        self.translations = translations
        self.updatedAt = updatedAt
    }
}

/// A word ready to play, resolved to one language.
public struct WordItem: Sendable, Hashable, Identifiable {
    public let id: String
    public let text: String

    public init(id: String, text: String) {
        self.id = id
        self.text = text
    }
}

extension WordItem {
    init(_ cached: CachedWord, language: String) {
        self.init(id: cached.id, text: cached.text(for: language))
    }
}
