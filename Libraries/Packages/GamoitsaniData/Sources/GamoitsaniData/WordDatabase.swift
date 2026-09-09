//
//  WordDatabase.swift
//  GamoitsaniData
//
import Foundation
import SQLite3

/// Reads the word database bundled with the app.
///
/// Read-only by construction. The file ships inside the package and is never written to —
/// player state lives in its own store, keyed by `words.id`. Raw SQLite3 rather than a
/// wrapper library: this is one read-only file behind three queries.
public actor WordDatabase {

    private let connection: Connection

    private var handle: OpaquePointer { connection.handle }

    /// SQLite borrows bound text unless told otherwise, and a bridged Swift string does not
    /// outlive the call. `SQLITE_TRANSIENT` makes it take a copy.
    private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    /// Owns the handle so it is closed exactly once, when the actor goes away. The close
    /// lives on a class rather than in the actor's own `deinit` because that deinit is
    /// nonisolated and cannot touch a non-`Sendable` `OpaquePointer`.
    private final class Connection {
        let handle: OpaquePointer
        init(handle: OpaquePointer) { self.handle = handle }
        deinit { sqlite3_close(handle) }
    }

    public init(url: URL) throws {
        var handle: OpaquePointer?
        let status = sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READONLY, nil)
        guard status == SQLITE_OK, let opened = handle else {
            if let handle { sqlite3_close(handle) }
            throw WordDatabaseError.cannotOpen(path: url.path, code: status)
        }
        self.connection = Connection(handle: opened)
    }

    /// Where the word files live inside the package bundle.
    private static let resourceDirectory = "WordFiles"

    /// The database shipped for a language, or nil when that language has no word file.
    /// Adding a language is a file drop into `Resources` — no code change.
    public static func bundledURL(language: String) -> URL? {
        Bundle.module.url(
            forResource: "words_\(language)",
            withExtension: "db",
            subdirectory: resourceDirectory
        )
    }

    /// Every language that ships a word file, as language codes.
    ///
    /// The language picker is built from this, so it can never offer a language the app
    /// has no words for.
    public static func bundledLanguages() -> Set<String> {
        let urls = Bundle.module.urls(
            forResourcesWithExtension: "db",
            subdirectory: resourceDirectory
        ) ?? []
        return Set(
            urls.compactMap { url in
                let name = url.deletingPathExtension().lastPathComponent
                return name.hasPrefix("words_") ? String(name.dropFirst("words_".count)) : nil
            }
        )
    }

    /// Whether this file's `difficulty` column is worth putting a selector in front of.
    ///
    /// The curated Georgian database has a real spread. The files exported from v1's
    /// Firestore do not — 99.9% of every one of them lands on `<= 3`, and the hard tier
    /// holds single digits — so offering four tiers there would deal the same deck four
    /// times over and call one of them Hard.
    public func hasUsableDifficulty(minimumPerTier: Int = 200) throws -> Bool {
        let easy = try count(matching: WordQuery(difficulty: 1...2, limit: 1))
        let hard = try count(matching: WordQuery(difficulty: 4...5, limit: 1))
        return easy >= minimumPerTier && hard >= minimumPerTier
    }

    /// Draws matching words in random order.
    ///
    /// Returns fewer than `limit` when the pool holds fewer — a thin tier is a shorter
    /// game, not an error.
    public func words(matching query: WordQuery) throws -> [WordRow] {
        let statement = try prepare("""
            SELECT id, lemma FROM words
            WHERE difficulty BETWEEN ?1 AND ?2
              AND id NOT IN (SELECT value FROM json_each(?3))
            ORDER BY RANDOM() LIMIT ?4;
            """)
        defer { sqlite3_finalize(statement) }

        bindFilter(query, to: statement)
        sqlite3_bind_int(statement, 4, Int32(query.limit))

        var rows: [WordRow] = []
        rows.reserveCapacity(query.limit)
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let lemma = sqlite3_column_text(statement, 1) else { continue }
            rows.append(
                WordRow(id: Int(sqlite3_column_int64(statement, 0)), lemma: String(cString: lemma))
            )
        }
        return rows
    }

    /// How many words a query could draw from. Lets the caller notice an exhausted pool
    /// before it deals a game too short to play.
    public func count(matching query: WordQuery) throws -> Int {
        let statement = try prepare("""
            SELECT COUNT(*) FROM words
            WHERE difficulty BETWEEN ?1 AND ?2
              AND id NOT IN (SELECT value FROM json_each(?3));
            """)
        defer { sqlite3_finalize(statement) }

        bindFilter(query, to: statement)
        guard sqlite3_step(statement) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int64(statement, 0))
    }

    /// A value from the `meta` table — `content_version`, `word_count`, `language`.
    public func metaValue(forKey key: String) throws -> String? {
        let statement = try prepare("SELECT value FROM meta WHERE key = ?1;")
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, key, -1, Self.transient)
        guard sqlite3_step(statement) == SQLITE_ROW,
              let value = sqlite3_column_text(statement, 0)
        else { return nil }
        return String(cString: value)
    }

    // MARK: - Statements

    private func prepare(_ sql: String) throws -> OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK,
              let prepared = statement
        else {
            sqlite3_finalize(statement)
            throw WordDatabaseError.query(message: String(cString: sqlite3_errmsg(handle)))
        }
        return prepared
    }

    /// Binds the difficulty bounds and exclusions shared by the draw and the count, so the
    /// two can never disagree about what the pool is.
    private func bindFilter(_ query: WordQuery, to statement: OpaquePointer) {
        sqlite3_bind_int(statement, 1, Int32(query.difficulty.lowerBound))
        sqlite3_bind_int(statement, 2, Int32(query.difficulty.upperBound))
        sqlite3_bind_text(statement, 3, Self.jsonArray(query.excluding), -1, Self.transient)
    }

    /// `json_each` wants a JSON array. Ids are integers, so this needs no escaping.
    private static func jsonArray(_ ids: Set<Int>) -> String {
        "[\(ids.map(String.init).joined(separator: ","))]"
    }
}
