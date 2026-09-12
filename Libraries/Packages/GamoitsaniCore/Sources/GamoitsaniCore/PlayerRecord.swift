//
//  PlayerRecord.swift
//  GamoitsaniCore
//
import Foundation

/// What one person has done across every game on this device.
///
/// Local only. There is no account and no server, so two people called the same thing on
/// two phones are simply two records, and that is the honest answer for a game played in
/// one room.
public struct PlayerRecord: Sendable, Hashable, Codable, Identifiable {
    /// The name as first typed, kept for display.
    public let name: String
    /// Matched on, so "Nika" and "nika " are the same person to the app as they are to the
    /// room. The same rule `TeamValidator` uses for team names.
    public var id: String { PlayerRecord.key(for: name) }

    public var gamesPlayed: Int
    public var gamesWon: Int
    /// Words guessed while this person was describing.
    public var wordsDescribed: Int
    /// The most guessed in a single turn.
    public var bestTurn: Int

    public init(
        name: String,
        gamesPlayed: Int = 0,
        gamesWon: Int = 0,
        wordsDescribed: Int = 0,
        bestTurn: Int = 0
    ) {
        self.name = name
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.wordsDescribed = wordsDescribed
        self.bestTurn = bestTurn
    }

    public static func key(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// One turn's contribution to a person's record.
public struct TurnCredit: Sendable, Hashable {
    public let describer: String
    public let wordsGuessed: Int

    public init(describer: String, wordsGuessed: Int) {
        self.describer = describer
        self.wordsGuessed = wordsGuessed
    }
}

/// Folds finished games into records.
///
/// Pure, so what a game is worth can be decided without a database in the way.
public enum PlayerLedger {

    /// Applies one finished game.
    ///
    /// `winners` are the names on the winning team — a draw has none, and nobody is
    /// credited a win for it.
    public static func apply(
        to records: [String: PlayerRecord],
        played: [String],
        winners: [String],
        credits: [TurnCredit]
    ) -> [String: PlayerRecord] {
        var result = records

        // A person appearing twice in a roster is still one player in one game.
        for name in unique(played) {
            var record = result[PlayerRecord.key(for: name)] ?? PlayerRecord(name: name)
            record.gamesPlayed += 1
            result[record.id] = record
        }

        for name in unique(winners) {
            let key = PlayerRecord.key(for: name)
            guard var record = result[key] else { continue }
            record.gamesWon += 1
            result[key] = record
        }

        for credit in credits {
            let key = PlayerRecord.key(for: credit.describer)
            // Only someone who was in the roster. A credit for a name nobody played under
            // would create a record out of nothing.
            guard var record = result[key] else { continue }
            record.wordsDescribed += credit.wordsGuessed
            record.bestTurn = max(record.bestTurn, credit.wordsGuessed)
            result[key] = record
        }

        return result
    }

    /// Names in order, one each, ignoring case and surrounding space.
    private static func unique(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.filter { name in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return false }
            return seen.insert(PlayerRecord.key(for: trimmed)).inserted
        }
    }
}
