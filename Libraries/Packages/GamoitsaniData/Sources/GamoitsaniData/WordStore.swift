//
//  WordStore.swift
//  GamoitsaniData
//
import Foundation
import SwiftData
import GamoitsaniCore

/// The local word cache.
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
    public func words(language: String, limit: Int) throws -> [WordItem] {
        guard limit > 0 else { return [] }

        // SwiftData has no ORDER BY RANDOM(). Sampling therefore happens in Swift, over
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
    public func latestUpdatedAt() throws -> Date? {
        var descriptor = FetchDescriptor<CachedWord>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.updatedAt
    }

    /// Trims the cache to its most recent `keeping` words.
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
