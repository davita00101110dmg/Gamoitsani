//
//  Awards.swift
//  GamoitsaniCore
//
import Foundation

/// A title one team earned outright.
public struct Award: Identifiable, Hashable, Sendable {

    public enum Kind: String, Sendable, Hashable, CaseIterable {
        /// Longest unbroken run of correct guesses.
        case streak
        /// Most words guessed.
        case words
        /// Lowest mean seconds per guess.
        case speed
        /// Most super words taken.
        case superWords
        /// Most words skipped. The one nobody wants.
        case skips
    }

    public let kind: Kind
    public let teamID: Team.ID
    public let teamName: String
    /// Seconds for `.speed`, a count otherwise.
    public let value: Double

    public var id: Kind { kind }

    public init(kind: Kind, teamID: Team.ID, teamName: String, value: Double) {
        self.kind = kind
        self.teamID = teamID
        self.teamName = teamName
        self.value = value
    }
}

/// Works out which titles a finished game earned.
///
/// A title needs a *strict* winner: if two teams tie on best streak, nobody gets it. A
/// shared title is not a title, and "Team 1 & Team 2 & Team 3" does not fit on a card.
public enum Awards {

    /// Below these, the number is not worth printing — a "best streak" of 1 is just a
    /// correct answer, and one skip is not a habit.
    private static let streakFloor = 3
    private static let wordsFloor = 1
    private static let skipsFloor = 3
    private static let superWordsFloor = 1

    /// Guesses needed before a mean time means anything. Without this the award goes to
    /// whoever guessed once, luckily — or to a team that guessed nothing at all, whose
    /// `averageGuessTime` is zero.
    private static let speedMinimumGuesses = 3

    /// Every title the game earned, in the order a card should show them.
    public static func all(for teams: [Team]) -> [Award] {
        var result: [Award] = []

        if let award = best(teams, kind: .streak, floor: Double(streakFloor), value: { Double($0.bestStreak) }) {
            result.append(award)
        }
        if let award = best(teams, kind: .words, floor: Double(wordsFloor), value: { Double($0.wordsGuessed) }) {
            result.append(award)
        }
        if let award = fastest(teams) {
            result.append(award)
        }
        if let award = best(teams, kind: .superWords, floor: Double(superWordsFloor), value: { Double($0.superWordsGuessed) }) {
            result.append(award)
        }
        if let award = best(teams, kind: .skips, floor: Double(skipsFloor), value: { Double($0.wordsSkipped) }) {
            result.append(award)
        }

        return result
    }

    /// Up to `limit` titles, spread across as many teams as possible.
    ///
    /// Taking the top few by priority alone handed every title to the winning team, which
    /// reads as a boast and wastes the space — a result card is more fun when everyone at
    /// the table is named. Teams already named are passed over until the rest have had a
    /// turn, then the remainder backfills in priority order.
    public static func featured(for teams: [Team], limit: Int = 3) -> [Award] {
        let everything = all(for: teams)
        var chosen: [Award] = []
        var named: Set<Team.ID> = []

        for award in everything where chosen.count < limit && !named.contains(award.teamID) {
            chosen.append(award)
            named.insert(award.teamID)
        }
        for award in everything where chosen.count < limit && !chosen.contains(award) {
            chosen.append(award)
        }

        // Back into priority order, so the card's rows do not reshuffle by who won what.
        return chosen.sorted { left, right in
            let order = everything.map(\.kind)
            return (order.firstIndex(of: left.kind) ?? 0) < (order.firstIndex(of: right.kind) ?? 0)
        }
    }

    /// The single highest scorer on `value`, or nothing if it is tied or below `floor`.
    private static func best(
        _ teams: [Team],
        kind: Award.Kind,
        floor: Double,
        value: (Team) -> Double
    ) -> Award? {
        let ranked = teams.map { (team: $0, value: value($0)) }.sorted { $0.value > $1.value }
        guard let leader = ranked.first, leader.value >= floor else { return nil }
        if ranked.count > 1, ranked[1].value == leader.value { return nil }
        return Award(kind: kind, teamID: leader.team.id, teamName: leader.team.name, value: leader.value)
    }

    /// Lowest mean guess time, among teams that guessed often enough to have a mean.
    private static func fastest(_ teams: [Team]) -> Award? {
        let eligible = teams
            .filter { $0.wordsGuessed >= speedMinimumGuesses }
            .map { (team: $0, value: $0.averageGuessTime) }
            .sorted { $0.value < $1.value }

        guard let leader = eligible.first, leader.value > 0 else { return nil }
        if eligible.count > 1, eligible[1].value == leader.value { return nil }
        return Award(kind: .speed, teamID: leader.team.id, teamName: leader.team.name, value: leader.value)
    }
}
