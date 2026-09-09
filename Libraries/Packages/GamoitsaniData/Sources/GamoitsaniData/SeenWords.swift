//
//  SeenWords.swift
//  GamoitsaniData
//
import Foundation

/// Remembers which words a group has already played, so they work through the database
/// instead of meeting the same cards every few evenings.
///
/// Keyed by `words.id`, which is promised stable across content updates — a word that was
/// seen stays seen when a newer database ships.
public actor SeenWords {

    private let url: URL
    private var byLanguage: [String: Set<Int>]

    public init(filename: String = "seen-words.json", directory: URL = .applicationSupportDirectory) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appending(path: filename)

        let stored = try? JSONDecoder().decode([String: [Int]].self, from: Data(contentsOf: url))
        self.byLanguage = (stored ?? [:]).mapValues(Set.init)
    }

    public func ids(language: String) -> Set<Int> {
        byLanguage[language] ?? []
    }

    public func record(_ ids: some Sequence<Int>, language: String) {
        var seen = byLanguage[language] ?? []
        seen.formUnion(ids)
        byLanguage[language] = seen
        persist()
    }

    /// Starts the language over. Called when the remaining pool drops below a game's worth.
    public func clear(language: String) {
        byLanguage[language] = nil
        persist()
    }

    public func clearAll() {
        byLanguage = [:]
        persist()
    }

    private func persist() {
        // Losing this costs some repeated words, not a game.
        let payload = byLanguage.mapValues(Array.init)
        try? JSONEncoder().encode(payload).write(to: url, options: .atomic)
    }
}
