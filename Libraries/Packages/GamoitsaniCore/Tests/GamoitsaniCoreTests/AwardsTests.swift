//
//  AwardsTests.swift
//  GamoitsaniCoreTests
//

import Foundation
import Testing
@testable import GamoitsaniCore

@Suite("Awards")
struct AwardsTests {

    private func team(
        _ name: String,
        guessed: Int = 0,
        skipped: Int = 0,
        streak: Int = 0,
        time: TimeInterval = 0,
        superWords: Int = 0
    ) -> Team {
        Team(
            name: name,
            wordsGuessed: guessed,
            wordsSkipped: skipped,
            bestStreak: streak,
            totalGuessTime: time,
            superWordsGuessed: superWords
        )
    }

    @Test("the strictly best streak takes the title")
    func streak() {
        let awards = Awards.all(for: [team("A", streak: 6), team("B", streak: 4)])
        let streak = awards.first { $0.kind == .streak }
        #expect(streak?.teamName == "A")
        #expect(streak?.value == 6)
    }

    /// "Team A & Team B" does not fit on a card, and a shared title is not a title.
    @Test("a tie awards nobody")
    func tiedStreak() {
        let awards = Awards.all(for: [team("A", streak: 5), team("B", streak: 5)])
        #expect(!awards.contains { $0.kind == .streak })
    }

    @Test("a streak below the floor is not a streak")
    func trivialStreak() {
        let awards = Awards.all(for: [team("A", streak: 2), team("B", streak: 1)])
        #expect(!awards.contains { $0.kind == .streak })
    }

    /// `averageGuessTime` is zero when a team never guessed, so the fastest award would
    /// otherwise go to whoever did nothing at all.
    @Test("a team that guessed nothing is not the fastest")
    func idleTeamIsNotFastest() {
        let awards = Awards.all(for: [
            team("Idle"),
            team("Busy", guessed: 8, time: 40),
        ])
        let speed = awards.first { $0.kind == .speed }
        #expect(speed?.teamName == "Busy")
    }

    /// One lucky guess is not a mean.
    @Test("too few guesses means no speed award")
    func speedNeedsEnoughGuesses() {
        let awards = Awards.all(for: [
            team("Lucky", guessed: 1, time: 0.5),
            team("Steady", guessed: 2, time: 8),
        ])
        #expect(!awards.contains { $0.kind == .speed })
    }

    @Test("fastest is the lowest mean, not the highest count")
    func fastestIsLowestMean() {
        let awards = Awards.all(for: [
            team("Quick", guessed: 4, time: 8),    // 2.0s
            team("Prolific", guessed: 20, time: 80), // 4.0s
        ])
        let speed = awards.first { $0.kind == .speed }
        #expect(speed?.teamName == "Quick")
        #expect(speed?.value == 2)
    }

    @Test("most skips is awarded too — it is the fun one")
    func skips() {
        let awards = Awards.all(for: [team("A", skipped: 7), team("B", skipped: 1)])
        #expect(awards.first { $0.kind == .skips }?.teamName == "A")
    }

    @Test("an empty game earns nothing")
    func emptyGame() {
        #expect(Awards.all(for: [team("A"), team("B")]).isEmpty)
    }

    @Test("a solitary team can still earn titles")
    func singleTeam() {
        let awards = Awards.all(for: [team("Alone", guessed: 5, streak: 4, time: 10)])
        #expect(awards.contains { $0.kind == .streak })
        #expect(awards.contains { $0.kind == .words })
    }

    /// The winner sweeping every title reads as a boast, and a card naming one team three
    /// times is a worse card.
    @Test("featured titles are spread across teams")
    func featuredPrefersDistinctTeams() {
        let sweeper = team("Sweeper", guessed: 20, skipped: 0, streak: 9, time: 30, superWords: 3)
        let quiet = team("Quiet", guessed: 4, skipped: 6, streak: 2, time: 40)

        let featured = Awards.featured(for: [sweeper, quiet], limit: 3)
        #expect(Set(featured.map(\.teamName)).count == 2, "one team took every slot")
        #expect(featured.contains { $0.teamName == "Quiet" })
    }

    /// With only one team earning anything, the limit still fills rather than returning one.
    @Test("featured backfills when there are not enough teams")
    func featuredBackfills() {
        let only = team("Solo", guessed: 12, skipped: 5, streak: 6, time: 24)
        let featured = Awards.featured(for: [only], limit: 3)
        #expect(featured.count == 3)
        #expect(Set(featured.map(\.kind)).count == 3)
    }

    @Test("featured never exceeds its limit")
    func featuredRespectsLimit() {
        let teams = [
            team("A", guessed: 20, streak: 9, time: 30, superWords: 3),
            team("B", guessed: 4, skipped: 8, streak: 2, time: 40),
        ]
        #expect(Awards.featured(for: teams, limit: 2).count <= 2)
        #expect(Awards.featured(for: teams, limit: 0).isEmpty)
    }

    @Test("no team is ever named twice for the same title")
    func idsAreUnique() {
        let awards = Awards.all(for: [
            team("A", guessed: 9, skipped: 1, streak: 5, time: 18, superWords: 2),
            team("B", guessed: 3, skipped: 6, streak: 2, time: 21),
        ])
        #expect(Set(awards.map(\.kind)).count == awards.count)
    }
}
