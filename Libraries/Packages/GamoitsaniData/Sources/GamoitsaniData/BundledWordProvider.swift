//
//  BundledWordProvider.swift
//  GamoitsaniData
//
import Foundation
import GamoitsaniCore

/// Deals a game's deck from the bundled database.
///
/// Difficulty and the seen-word list ride on the provider rather than on
/// `WordProvider.deck(language:count:)`, which is what lets the seam the rest of the app
/// talks to stay exactly as it was.
public struct BundledWordProvider: WordProvider {

    private let difficulty: ClosedRange<Int>
    private let seen: SeenWords?
    private let fallbackLanguage: String

    public init(
        difficulty: ClosedRange<Int> = 1...5,
        seen: SeenWords? = nil,
        fallbackLanguage: String = "ka"
    ) {
        self.difficulty = difficulty
        self.seen = seen
        self.fallbackLanguage = fallbackLanguage
    }

    public func deck(language: String, count: Int) async throws -> Deck {
        let resolved = resolvedLanguage(for: language)
        guard let url = WordDatabase.bundledURL(language: resolved) else {
            throw WordDatabaseError.notBundled(language: language)
        }
        let database = try WordDatabase(url: url)

        var excluded = await seen?.ids(language: resolved) ?? []

        // Fewer words left than a game needs means the group has worked through this tier.
        // Start it over rather than dealing a deck too thin to finish.
        if !excluded.isEmpty {
            let remaining = try await database.count(
                matching: WordQuery(difficulty: difficulty, excluding: excluded, limit: count)
            )
            if remaining < count {
                await seen?.clear(language: resolved)
                excluded = []
            }
        }

        let rows = try await database.words(
            matching: WordQuery(difficulty: difficulty, excluding: excluded, limit: count)
        )
        return Deck(words: rows.map { DeckWord(id: String($0.id), text: $0.lemma) })
    }

    /// Extra words for a game already under way.
    ///
    /// Unlike `deck`, this never resets the seen list — a top-up mid-game should not start
    /// the whole pool over. When nothing unseen is left it draws from words seen in earlier
    /// games instead, so the table is only ever empty if this one game already holds the
    /// entire tier.
    public func more(
        language: String,
        count: Int,
        excluding: Set<Int>
    ) async throws -> [DeckWord] {
        let resolved = resolvedLanguage(for: language)
        guard let url = WordDatabase.bundledURL(language: resolved) else {
            throw WordDatabaseError.notBundled(language: language)
        }
        let database = try WordDatabase(url: url)
        let alreadySeen = await seen?.ids(language: resolved) ?? []

        var rows = try await database.words(
            matching: WordQuery(
                difficulty: difficulty,
                excluding: excluding.union(alreadySeen),
                limit: count
            )
        )
        if rows.isEmpty {
            rows = try await database.words(
                matching: WordQuery(difficulty: difficulty, excluding: excluding, limit: count)
            )
        }
        return rows.map { DeckWord(id: String($0.id), text: $0.lemma) }
    }

    private func resolvedLanguage(for language: String) -> String {
        Self.resolvedLanguage(for: language, fallback: fallbackLanguage)
    }

    /// Whether a difficulty selector makes sense for this language's word file.
    ///
    /// False for everything exported from v1's Firestore, whose difficulty column is flat.
    /// Answered here so the setup screen can simply not draw a control that would lie.
    public static func hasUsableDifficulty(language: String) async -> Bool {
        guard let url = bundledURL(forResolved: resolvedLanguage(for: language)) else {
            return false
        }
        guard let database = try? WordDatabase(url: url) else { return false }
        return (try? await database.hasUsableDifficulty()) ?? false
    }

    private static func bundledURL(forResolved language: String) -> URL? {
        WordDatabase.bundledURL(language: language)
    }

    /// The languages that ship a word file, so the picker can offer only those.
    public static var availableLanguages: Set<String> {
        WordDatabase.bundledLanguages()
    }

    /// The language whose file will actually be read.
    ///
    /// Falls back when a language has no word file of its own — Georgian is the only one
    /// today, so an English player currently gets Georgian words, which gating the language
    /// picker on available files is what fixes. Public because anything recording what was
    /// played has to key it the same way, or a fallback files Georgian words under English.
    public static func resolvedLanguage(for language: String, fallback: String = "ka") -> String {
        WordDatabase.bundledURL(language: language) != nil ? language : fallback
    }
}
