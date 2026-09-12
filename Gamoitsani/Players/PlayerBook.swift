//
//  PlayerBook.swift
//  Gamoitsani
//
import SwiftUI
import Observation
import GamoitsaniCore
import GamoitsaniEngine

/// Everyone who has played on this device, and what they have done.
///
/// Local only, by design: there is no account and no server, so this is the memory of one
/// phone that has been passed around a table.
@MainActor
@Observable
final class PlayerBook {

    private(set) var records: [String: PlayerRecord]

    /// What each turn of the current game was worth, gathered as it is played. A turn's
    /// score is only known once it ends, and the game is only over later.
    @ObservationIgnored private var credits: [TurnCredit] = []

    init() {
        records = Self.load()
    }

    /// Everyone, most active first — the order people look for themselves in.
    var all: [PlayerRecord] {
        records.values.sorted {
            $0.gamesPlayed == $1.gamesPlayed
                ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                : $0.gamesPlayed > $1.gamesPlayed
        }
    }

    func record(for name: String) -> PlayerRecord? {
        records[PlayerRecord.key(for: name)]
    }

    /// A turn ended. Credited to whoever was describing it.
    func turnEnded(describer: String?, wordsGuessed: Int) {
        guard let describer, !describer.isEmpty else { return }
        credits.append(TurnCredit(describer: describer, wordsGuessed: wordsGuessed))
    }

    /// A game reached the podium.
    ///
    /// Called behind the podium's own "counted once" flag, the same guard `ads` and the
    /// review prompt sit behind — `onAppear` fires more than once.
    func gameFinished(_ state: GameState) {

        let played = state.teams.flatMap(\.members)
        guard !played.isEmpty else {
            // Teams typed straight in, without the player draw. Nobody to credit.
            credits = []
            return
        }

        // A draw has no winner, and nobody should collect a win for one.
        let ranked = state.standings
        let winners: [String]
        if let best = ranked.first, ranked.count < 2 || best.score > ranked[1].score {
            winners = best.members
        } else {
            winners = []
        }

        records = PlayerLedger.apply(
            to: records,
            played: played,
            winners: winners,
            credits: credits
        )
        credits = []
        Self.save(records)
    }

    /// A new game is starting; anything gathered for an abandoned one goes.
    func reset() {
        credits = []
    }

    // MARK: - Storage

    private static let key = "players.records"

    private static func load() -> [String: PlayerRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONDecoder().decode([String: PlayerRecord].self, from: data)
        else { return [:] }
        return stored
    }

    private static func save(_ records: [String: PlayerRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    #if DEBUG
    var debugSummary: [(String, String)] {
        [
            ("players", "\(records.count)"),
            ("turns this game", "\(credits.count)")
        ]
    }

    func debugClear() {
        records = [:]
        credits = []
        UserDefaults.standard.removeObject(forKey: Self.key)
    }
    #endif
}
