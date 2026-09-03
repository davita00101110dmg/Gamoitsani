//
//  TeamDraw.swift
//  GamoitsaniCore
//
import Foundation

/// Splits a room full of people into teams.
///
/// v1 refused an odd number of players outright — "Need an even number of players to
/// create teams" — which is exactly the situation a party is usually in. Seven people
/// split four and three; the only real rule is that no team is more than one player
/// larger than another.
public enum TeamDraw {

    /// Names cleaned up the way a list typed at a party needs: trimmed, blanks dropped,
    /// and the same person not entered twice.
    public static func tidy(_ players: [String]) -> [String] {
        var seen = Set<String>()
        return players
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { seen.insert($0.lowercased()).inserted }
    }

    /// Nobody plays alone: one person has nobody to guess for them, so a team of one
    /// cannot take a turn at all.
    public static let minimumTeamSize = 2

    /// The fewest players any draw can work with — two teams that can both actually play.
    public static var minimumPlayers: Int {
        GameSettings.teamCountRange.lowerBound * minimumTeamSize
    }

    /// How many teams this many players can fill without stranding anyone on their own,
    /// within the game's own limits.
    public static func teamCountRange(forPlayers count: Int) -> ClosedRange<Int>? {
        let lower = GameSettings.teamCountRange.lowerBound
        let fillable = count / minimumTeamSize
        guard fillable >= lower else { return nil }
        return lower...min(GameSettings.teamCountRange.upperBound, fillable)
    }

    /// Deals players into `teamCount` teams at random.
    ///
    /// Shuffle, then deal one at a time round the table. Chunking the shuffled list
    /// instead would put the remainder all on one team — with 7 players and 2 teams that
    /// is 4 and 3 either way, but with 5 players and 4 teams it is 2/1/1/1 rather than
    /// the 2/1/1/1 spread dealing guarantees at any size.
    public static func draw(
        players: [String],
        into teamCount: Int,
        using generator: inout some RandomNumberGenerator
    ) -> [[String]] {
        let people = tidy(players)
        guard let range = teamCountRange(forPlayers: people.count) else { return [] }

        let count = min(max(teamCount, range.lowerBound), range.upperBound)
        var teams = Array(repeating: [String](), count: count)
        for (index, player) in people.shuffled(using: &generator).enumerated() {
            teams[index % count].append(player)
        }
        return teams
    }

    public static func draw(players: [String], into teamCount: Int) -> [[String]] {
        var generator = SystemRandomNumberGenerator()
        return draw(players: players, into: teamCount, using: &generator)
    }
}
