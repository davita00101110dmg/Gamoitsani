//
//  CachedWord.swift
//  GamoitsaniData
//
import Foundation
import SwiftData

/// A word in the local cache.
@Model
public final class CachedWord {

    #Unique<CachedWord>([\.id])
    #Index<CachedWord>([\.id], [\.updatedAt], [\.languageIndex])

    /// Firestore document id.
    public var id: String = ""

    /// The Georgian source word, and the fallback when a translation is missing.
    public var baseWord: String = ""

    /// Language code to display text. Read-only reference data.
    public var translations: [String: String] = [:]

    /// Server-side last-modified, used as the sync checkpoint.
    public var updatedAt: Date = Date.distantPast

    /// Playable language codes as a delimited string: `"|en|ka|ru|"`.
    ///
    /// A string, not `[String]`: SwiftData cannot query array attributes. A predicate
    /// against one segfaults inside SQLite rather than failing to compile.
    public var languageIndex: String = ""

    public init(id: String, baseWord: String, translations: [String: String], updatedAt: Date) {
        self.id = id
        self.baseWord = baseWord
        self.translations = translations
        self.updatedAt = updatedAt
        self.languageIndex = Self.languageIndex(baseWord: baseWord, translations: translations)
    }

    /// The languages this word can be played in.
    public var playableLanguages: [String] {
        languageIndex.split(separator: "|").map(String.init)
    }

    /// Applies incoming data, touching only what changed.
    @discardableResult
    public func update(baseWord: String, translations: [String: String], updatedAt: Date) -> Bool {
        guard self.baseWord != baseWord
                || self.translations != translations
                || self.updatedAt != updatedAt else {
            return false
        }
        self.baseWord = baseWord
        self.translations = translations
        self.updatedAt = updatedAt
        self.languageIndex = Self.languageIndex(baseWord: baseWord, translations: translations)
        return true
    }

    static func languageIndex(baseWord: String, translations: [String: String]) -> String {
        var codes = Set(translations.compactMap { $0.value.isEmpty ? nil : $0.key })
        if !baseWord.isEmpty { codes.insert(georgian) }
        return token(codes.sorted().joined(separator: "|"))
    }

    /// Wraps a code, or a joined run of them, in the delimiter.
    static func token(_ value: String) -> String { "|\(value)|" }

    /// The base word is Georgian, so every word is playable in Georgian.
    public static let georgian = "ka"

    /// Display text for a language, falling back to the Georgian base word.
    public func text(for language: String) -> String {
        if let translated = translations[language], !translated.isEmpty { return translated }
        return baseWord
    }
}
