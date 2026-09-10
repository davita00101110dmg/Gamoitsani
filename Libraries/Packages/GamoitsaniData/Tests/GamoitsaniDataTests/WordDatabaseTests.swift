//
//  WordDatabaseTests.swift
//  GamoitsaniDataTests
//

import Testing
import Foundation
import GamoitsaniCore
@testable import GamoitsaniData

/// Against the real bundled file, not a fixture. The point of these is that the database
/// the app actually ships still holds what the difficulty tiers assume.
@Suite("Word database")
struct WordDatabaseTests {

    private func openDatabase() throws -> WordDatabase {
        let url = try #require(WordDatabase.bundledURL(language: "ka"))
        return try WordDatabase(url: url)
    }

    // MARK: - The file itself

    @Test("the Georgian database is bundled and opens read-only")
    func opens() async throws {
        let database = try openDatabase()
        let language = try await database.metaValue(forKey: "language")
        #expect(language == "ka")
    }

    @Test("every language the app offers ships a word file")
    func everyLanguageBundled() {
        let expected: Set<String> = ["ka", "en", "ru", "uk", "tr", "hy", "az", "de", "es", "fr", "ja"]
        #expect(WordDatabase.bundledLanguages() == expected)
        for language in expected {
            #expect(WordDatabase.bundledURL(language: language) != nil, "no file for \(language)")
        }
        #expect(WordDatabase.bundledURL(language: "zz") == nil)
    }

    /// Georgian is curated and has a real spread. Everything exported from v1's Firestore
    /// is flat — 99.9% of each file lands on `<= 3` — so a tier selector there would be a
    /// lie, and the setup screen leaves it out.
    @Test("only Georgian has a difficulty spread worth selecting on")
    func difficultyIsUsableOnlyForGeorgian() async throws {
        let georgian = try openDatabase()
        #expect(try await georgian.hasUsableDifficulty())

        for language in ["en", "ru", "ja", "de"] {
            let url = try #require(WordDatabase.bundledURL(language: language))
            let database = try WordDatabase(url: url)
            #expect(try await database.hasUsableDifficulty() == false, "\(language) looked usable")
        }
    }

    @Test("no exported file smuggled in duplicate words")
    func exportsAreDeduplicated() async throws {
        for language in ["en", "ru", "ja", "tr", "az"] {
            let url = try #require(WordDatabase.bundledURL(language: language))
            let database = try WordDatabase(url: url)
            let rows = try await database.words(matching: WordQuery(limit: 100_000))
            let distinct = Set(rows.map { $0.lemma.lowercased() })
            #expect(distinct.count == rows.count, "\(language) has repeated words")
        }
    }

    /// Derived rather than hard-coded: the file is expected to grow as review finishes, and
    /// a bigger database is not a regression. What must stay true is the shape — the tiers
    /// are caps, so Easy is inside Normal, and Normal and Hard together are the whole file.
    @Test("the difficulty tiers still carve up the file the way the selector assumes")
    func tierShape() async throws {
        let database = try openDatabase()
        func count(_ range: ClosedRange<Int>) async throws -> Int {
            try await database.count(matching: WordQuery(difficulty: range, limit: 1))
        }

        let easy = try await count(WordDifficulty.easy.range)
        let normal = try await count(WordDifficulty.normal.range)
        let hard = try await count(WordDifficulty.hard.range)
        let mixed = try await count(WordDifficulty.mixed.range)

        #expect(easy < normal, "Normal is a cap, so it must contain every Easy word")
        #expect(normal + hard == mixed, "Normal and Hard should partition the file")
        #expect(String(mixed) == (try await database.metaValue(forKey: "word_count")))

        // Enough for a long evening's game — four teams, three rounds, a fast word every
        // two seconds of a 60-second round. The absolute maximum (five teams, five rounds
        // at 75s, ~950 words) deliberately leans on the mid-game top-up instead, which is
        // why this is not asserted against the worst case.
        let longGame = 4 * 3 * 30
        for (name, size) in [("easy", easy), ("normal", normal), ("hard", hard)] {
            #expect(size >= longGame, "the \(name) tier is too thin to play: \(size)")
        }
    }

    @Test("every word has a difficulty, so no tier silently drops rows")
    func noNullDifficulty() async throws {
        let database = try openDatabase()
        let all = try await database.count(matching: WordQuery(difficulty: 1...5, limit: 1))
        let stated = try await database.metaValue(forKey: "word_count")
        #expect(String(all) == stated)
    }

    // MARK: - Drawing

    @Test("a draw stays inside the requested difficulty and returns no duplicates")
    func drawIsClean() async throws {
        let database = try openDatabase()
        let rows = try await database.words(matching: WordQuery(difficulty: 4...5, limit: 200))

        #expect(rows.count == 200)
        #expect(Set(rows.map(\.id)).count == rows.count)
        #expect(rows.allSatisfy { !$0.lemma.isEmpty })
    }

    @Test("a tier thinner than the request returns what it has rather than throwing")
    func thinTier() async throws {
        let database = try openDatabase()
        let hard = WordDifficulty.hard.range
        let available = try await database.count(matching: WordQuery(difficulty: hard, limit: 1))

        let rows = try await database.words(matching: WordQuery(difficulty: hard, limit: 100_000))
        #expect(rows.count == available)
    }

    @Test("excluded ids never come back")
    func exclusionsHonoured() async throws {
        let database = try openDatabase()
        let first = try await database.words(matching: WordQuery(difficulty: 1...5, limit: 500))
        let excluded = Set(first.map(\.id))

        let second = try await database.words(
            matching: WordQuery(difficulty: 1...5, excluding: excluded, limit: 500)
        )
        #expect(second.count == 500)
        #expect(Set(second.map(\.id)).isDisjoint(with: excluded))
    }

    @Test("excluding everything in a tier leaves nothing to draw")
    func exhaustedPool() async throws {
        let database = try openDatabase()
        let hard = WordDifficulty.hard.range
        let all = try await database.words(matching: WordQuery(difficulty: hard, limit: 100_000))

        let rows = try await database.words(
            matching: WordQuery(difficulty: hard, excluding: Set(all.map(\.id)), limit: 100)
        )
        #expect(rows.isEmpty)
    }

    @Test("two draws of the whole pool come back in different orders")
    func drawIsRandom() async throws {
        let database = try openDatabase()
        let a = try await database.words(matching: WordQuery(difficulty: 1...5, limit: 300))
        let b = try await database.words(matching: WordQuery(difficulty: 1...5, limit: 300))
        #expect(a.map(\.id) != b.map(\.id))
    }
}
