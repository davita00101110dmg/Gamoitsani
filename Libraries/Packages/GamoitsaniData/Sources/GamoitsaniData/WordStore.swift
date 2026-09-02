//
//  WordStore.swift
//  GamoitsaniData
//

import Foundation
import SwiftData
import GamoitsaniCore

/// The local word cache.
///
/// A `@ModelActor`, so every access is isolated and the `ModelContext` never leaves it.
/// **No method returns a `@Model`** — everything is converted to a `Sendable` value type at
/// the boundary. That is the entire point of this type.
///
/// v1's equivalent returned background-context `NSManagedObject`s from
/// `fetchWordsFromCoreData`, handed them to the main actor via `MainActor.run`, stored them
/// in a singleton, and then fired their relationship faults on the main thread during
/// gameplay. That is a textbook thread-confinement violation, it would trap immediately
/// under `-com.apple.CoreData.ConcurrencyDebug 1`, and it is the most plausible cause of
/// the freezes the 2.0 audit was commissioned over. Here it is not expressible: a
/// `CachedWord` cannot cross the actor boundary because it is not `Sendable`.
@ModelActor
public actor WordStore {

    // MARK: - Reading

    /// How many words are cached.
    public func count() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<CachedWord>())
    }

    /// How many are playable in a language.
    public func count(language: String) throws -> Int {
        try modelContext.fetchCount(Self.descriptor(language: language))
    }

    /// A random sample of playable words, as value types.
    ///
    /// Two v1 bugs are fixed by the shape of this query alone:
    ///
    /// - v1 applied `fetchLimit = 1500` sorted by `last_updated` descending and *then*
    ///   shuffled the result, so it shuffled within a fixed window. Only the 1500 most
    ///   recently updated words were ever reachable, no matter how large the catalogue
    ///   grew. Sampling happens across everything playable here.
    /// - v1 did no language filtering at all, at query time or otherwise.
    public func words(language: String, limit: Int) throws -> [WordItem] {
        guard limit > 0 else { return [] }

        // SwiftData has no ORDER BY RANDOM(). Sampling therefore happens in Swift, over
        // the playable set — which is the correct scope. v1's mistake was not that it
        // shuffled in memory, but that it shuffled *after* applying a 1500-row limit
        // ordered by recency, so the sample could only ever come from a fixed window.
        let candidates = try modelContext.fetch(Self.descriptor(language: language))
        guard !candidates.isEmpty else { return [] }

        let chosen = candidates.count <= limit ? candidates : Array(candidates.shuffled().prefix(limit))
        return chosen.map { WordItem($0, language: language) }
    }

    /// A shuffled deck for one game, ready for the engine.
    public func deck(language: String, count: Int) async throws -> Deck {
        let items = try words(language: language, limit: count)
        return Deck(words: items.map { DeckWord(id: $0.id, text: $0.text) })
    }

    // MARK: - Writing

    /// Inserts or updates words, touching only what changed.
    ///
    /// Returns how many rows were actually written. v1 issued one fetch per incoming word
    /// against an unindexed `baseWord` and then destroyed and recreated every translation
    /// regardless of whether anything differed — eleven objects deleted and reinserted per
    /// word per weekly sync for data that had not moved.
    @discardableResult
    public func upsert(_ incoming: [WordRecord]) throws -> Int {
        guard !incoming.isEmpty else { return 0 }

        // One fetch for everything we might touch, not one per word.
        let ids = Set(incoming.map(\.id))
        var existing: [String: CachedWord] = [:]
        for word in try modelContext.fetch(
            FetchDescriptor<CachedWord>(predicate: #Predicate { ids.contains($0.id) })
        ) {
            existing[word.id] = word
        }

        var written = 0
        for record in incoming {
            if let current = existing[record.id] {
                if current.update(baseWord: record.baseWord,
                                  translations: record.translations,
                                  updatedAt: record.updatedAt) {
                    written += 1
                }
            } else {
                modelContext.insert(CachedWord(id: record.id,
                                               baseWord: record.baseWord,
                                               translations: record.translations,
                                               updatedAt: record.updatedAt))
                written += 1
            }
        }

        if written > 0 { try modelContext.save() }
        return written
    }

    /// The newest `updatedAt` in the cache, which is the sync checkpoint.
    ///
    /// Derived from the data rather than stored separately, so it cannot drift out of step
    /// with what was actually imported — v1 kept `lastWordSyncDate` in UserDefaults and
    /// stamped it even when the fetch had failed.
    public func latestUpdatedAt() throws -> Date? {
        var descriptor = FetchDescriptor<CachedWord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.updatedAt
    }

    /// Trims the cache to its most recent `keeping` words.
    ///
    /// v1 had no pruning at all: the store grew without bound while only the newest 1500
    /// rows were ever reachable, and its `maxWordsToSaveInCoreData = 20000` constant was
    /// dead code referenced nowhere.
    @discardableResult
    public func prune(keeping: Int) throws -> Int {
        let total = try count()
        guard total > keeping else { return 0 }

        var descriptor = FetchDescriptor<CachedWord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .forward)]
        )
        descriptor.fetchLimit = total - keeping

        let stale = try modelContext.fetch(descriptor)
        for word in stale { modelContext.delete(word) }
        try modelContext.save()
        return stale.count
    }

    /// Empties the cache. It is disposable by design, so this is a normal operation rather
    /// than a disaster.
    public func removeAll() throws {
        try modelContext.delete(model: CachedWord.self)
        try modelContext.save()
    }

    // MARK: - Queries

    private static func descriptor(language: String) -> FetchDescriptor<CachedWord> {
        // Substring search against the delimited key. Querying the `[String]` this
        // replaced segfaults inside SQLite — see CachedWord.languageIndex.
        let token = CachedWord.token(language)
        return FetchDescriptor<CachedWord>(
            predicate: #Predicate { $0.languageIndex.contains(token) }
        )
    }
}

extension WordStore: WordProvider {}
