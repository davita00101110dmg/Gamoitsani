//
//  CachedWord.swift
//  GamoitsaniData
//

import Foundation
import SwiftData

/// A word in the local cache.
///
/// The store is a **disposable cache** of Firestore, not a source of truth. That single
/// fact drives most of the design here: nothing needs migrating, because anything wrong can
/// be thrown away and re-synced. v1 treated its Core Data store as precious and called
/// `fatalError` when it failed to load, so one non-inferrable model change would have
/// bricked every installed copy.
///
/// Differences from v1's `Word` entity, each deliberate:
///
/// - **`#Unique` on `id`.** v1 had no uniqueness constraint and no index, so every import
///   issued a fetch per word — `NSPredicate(format: "baseWord == %@")` in a loop — to check
///   whether the word already existed. On a full catalogue that is one SQLite query per
///   word.
/// - **`#Index` on `language` and `updatedAt`,** the only two things ever queried on.
/// - **Translations are a stored dictionary, not a to-many relationship.** v1 modelled
///   them as a `Translation` entity and then deleted and recreated *every* translation for
///   *every* touched word on *every* sync, changed or not. Worse, the relationship was the
///   thing being faulted on the main thread during gameplay. They are read-only reference
///   data; a dictionary is the honest model.
/// - **The eight attributes added by v1's "Word 2.0" migration are gone.** Not one of them
///   was ever read — `categories`, `relatedWords`, `isGeorgianOrigin`, `formalityLevel`,
///   `isProperNoun`, `wordType`, `isAbstract`, `ageAppropriateness`, and
///   `Translation.difficulty`. The migration bought nothing. They come back when something
///   consumes them.
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
    /// A string rather than the `[String]` this obviously wants to be, because **SwiftData
    /// cannot query array attributes**. A predicate of the form
    /// `$0.playableLanguages.contains(code)` against a `[String]` property does not fail to
    /// compile and does not throw — it segfaults inside SQLite, in
    /// `_NSCoreDataStringSearch` → `CFStringGetLength` on a null pointer, because the array
    /// is stored as an opaque blob that the string-search opcode then reads as text.
    ///
    /// Delimiting on both sides matters: without it, searching for `"ka"` would also match
    /// a hypothetical `"kab"`. Substring search *is* supported in predicates and can be
    /// indexed, so language filtering still happens in the query rather than in memory.
    ///
    /// v1 did no filtering at all — it fetched 1500 words regardless of language and
    /// resolved each at display time, so choosing Japanese silently showed the Georgian
    /// base word for every word lacking a `ja` translation.
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
    ///
    /// Returns whether anything actually differed, so a sync that brings nothing new does
    /// no writes at all.
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
    ///
    /// The fallback is kept because a catalogue is never perfectly complete, but queries
    /// filter on `playableLanguages` so it should rarely be reached — unlike v1, where it
    /// was the normal outcome for eight of eleven languages.
    public func text(for language: String) -> String {
        if let translated = translations[language], !translated.isEmpty { return translated }
        return baseWord
    }
}
