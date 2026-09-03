//
//  WordStoreTests.swift
//  GamoitsaniDataTests
//

import Testing
import Foundation
import GamoitsaniCore
@testable import GamoitsaniData

/// Serialized because each case builds its own in-memory `ModelContainer`, and creating
/// several concurrently crashes the SwiftData stack. Swift Testing runs cases in parallel
/// by default, which is right for the pure-domain suites but not here.
@Suite("Word store", .serialized)
struct WordStoreTests {

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func record(_ n: Int, langs: [String] = ["en"], at offset: TimeInterval = 0) -> WordRecord {
        WordRecord(
            id: "w\(n)",
            baseWord: "ქართული\(n)",
            translations: Dictionary(uniqueKeysWithValues: langs.map { ($0, "\($0)-word\(n)") }),
            updatedAt: t0.addingTimeInterval(offset)
        )
    }

    // MARK: - Upsert

    @Test("inserting then re-inserting the same words writes nothing the second time")
    func upsertIsIdempotent() async throws {
        let store = try WordStoreFactory.makeInMemory()
        let batch = (0..<10).map { record($0) }

        #expect(try await store.upsert(batch) == 10)
        #expect(try await store.count() == 10)

        // v1 deleted and recreated every translation on every sync regardless of change.
        #expect(try await store.upsert(batch) == 0, "unchanged data must not write")
        #expect(try await store.count() == 10)
    }

    /// v1 had no uniqueness constraint on baseWord and deduped with a fetch per word.
    @Test("the same id never produces a duplicate row")
    func uniqueness() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert([record(1)])
        try await store.upsert([WordRecord(id: "w1", baseWord: "changed",
                                           translations: ["en": "changed"], updatedAt: t0)])
        #expect(try await store.count() == 1)
    }

    @Test("a changed word is updated in place")
    func updateInPlace() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert([record(1, langs: ["en"])])

        let written = try await store.upsert([
            WordRecord(id: "w1", baseWord: "ქართული1",
                       translations: ["en": "new", "ka": "ქართული1"],
                       updatedAt: t0.addingTimeInterval(60))
        ])
        #expect(written == 1)

        let items = try await store.words(language: "en", limit: 10)
        #expect(items.first?.text == "new")
    }

    // MARK: - Language filtering

    /// v1 did no language filtering anywhere, so choosing Japanese silently showed the raw
    /// Georgian base word for every word without a `ja` translation.
    @Test("only words playable in the language come back")
    func languageFiltering() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert([
            record(1, langs: ["en", "ka"]),
            record(2, langs: ["en"]),
            record(3, langs: ["ja"]),
        ])

        #expect(try await store.count(language: "en") == 2)
        #expect(try await store.count(language: "ja") == 1)
        #expect(try await store.count(language: "de") == 0)
    }

    @Test("every word is playable in Georgian because the base word is Georgian")
    func georgianAlwaysPlayable() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert([record(1, langs: ["en"]), record(2, langs: ["fr"])])
        #expect(try await store.count(language: "ka") == 2)
    }

    @Test("text falls back to the base word when a translation is missing")
    func fallback() {
        let word = CachedWord(id: "1", baseWord: "სახლი", translations: ["en": "house"], updatedAt: Date())
        #expect(word.text(for: "en") == "house")
        #expect(word.text(for: "ja") == "სახლი")
    }

    @Test("an empty translation does not count as coverage")
    func emptyTranslationIsNotCoverage() {
        let word = CachedWord(id: "1", baseWord: "სახლი", translations: ["en": ""], updatedAt: Date())
        #expect(word.playableLanguages.contains("en") == false)
        #expect(word.playableLanguages.contains("ka"))
    }

    // MARK: - Sampling

    /// v1 applied fetchLimit = 1500 sorted by last_updated and *then* shuffled, so it only
    /// ever shuffled within a fixed window — older words were unreachable forever.
    @Test("sampling draws from the whole catalogue, not a recency window")
    func samplingCoversTheCatalogue() async throws {
        let store = try WordStoreFactory.makeInMemory()
        // The oldest words would be permanently invisible under v1's approach.
        try await store.upsert((0..<200).map { record($0, at: TimeInterval($0)) })

        var seen = Set<String>()
        for _ in 0..<40 {
            for item in try await store.words(language: "en", limit: 20) { seen.insert(item.id) }
        }
        // With genuine sampling, the oldest ids show up.
        #expect(seen.contains("w0") || seen.contains("w1"), "the oldest words must be reachable")
        #expect(seen.count > 100, "sampling should range widely across the catalogue")
    }

    @Test("asking for more than exists returns everything, not an error")
    func limitLargerThanCatalogue() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert((0..<5).map { record($0) })
        #expect(try await store.words(language: "en", limit: 100).count == 5)
    }

    @Test("a non-positive limit returns nothing")
    func zeroLimit() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert([record(1)])
        #expect(try await store.words(language: "en", limit: 0).isEmpty)
    }

    // MARK: - Deck

    @Test("the store builds a deck the engine can play")
    func deckBuilding() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert((0..<30).map { record($0) })

        var deck = try await store.deck(language: "en", count: 10)
        #expect(deck.count == 10)

        let hand = deck.deal(4)
        #expect(hand.count == 4)
        #expect(hand.allSatisfy { $0.text.hasPrefix("en-word") })
    }

    // MARK: - Checkpoint and pruning

    /// Derived from the data, so it cannot drift from what actually landed. v1 kept it in
    /// UserDefaults and stamped it even when the fetch had failed.
    @Test("the checkpoint is the newest updatedAt in the cache")
    func checkpoint() async throws {
        let store = try WordStoreFactory.makeInMemory()
        #expect(try await store.latestUpdatedAt() == nil)

        try await store.upsert([record(1, at: 0), record(2, at: 500), record(3, at: 100)])
        #expect(try await store.latestUpdatedAt() == t0.addingTimeInterval(500))
    }

    /// v1 never pruned; the store grew without bound while only 1500 rows were reachable,
    /// and its maxWordsToSaveInCoreData constant was dead code.
    @Test("pruning keeps the newest words and drops the rest")
    func pruning() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert((0..<100).map { record($0, at: TimeInterval($0)) })

        #expect(try await store.prune(keeping: 40) == 60)
        #expect(try await store.count() == 40)
        // The newest survived.
        #expect(try await store.latestUpdatedAt() == t0.addingTimeInterval(99))
    }

    @Test("pruning below the threshold does nothing")
    func pruningNoOp() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert((0..<10).map { record($0) })
        #expect(try await store.prune(keeping: 50) == 0)
        #expect(try await store.count() == 10)
    }

    @Test("the cache can be emptied")
    func removeAll() async throws {
        let store = try WordStoreFactory.makeInMemory()
        try await store.upsert((0..<10).map { record($0) })
        try await store.removeAll()
        #expect(try await store.count() == 0)
    }
}
