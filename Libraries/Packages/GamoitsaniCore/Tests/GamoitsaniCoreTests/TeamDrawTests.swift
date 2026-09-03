//
//  TeamDrawTests.swift
//  GamoitsaniCoreTests
//

import Foundation
import Testing
@testable import GamoitsaniCore

/// Fixed sequence, so a draw can be asserted rather than described.
private struct FixedGenerator: RandomNumberGenerator {
    var value: UInt64 = 0
    mutating func next() -> UInt64 {
        value &+= 0x9E37_79B9_7F4A_7C15
        return value
    }
}

@Suite("Team draw")
struct TeamDrawTests {

    private let eight = ["Nino", "Giorgi", "Ana", "Luka", "Mari", "Dato", "Sopo", "Nika"]

    /// v1 refused this outright. A party is usually an odd number of people.
    @Test("an odd number of players still splits", arguments: [5, 7, 9, 11, 13])
    func oddPlayerCounts(count: Int) {
        let players = (1...count).map { "P\($0)" }
        let teams = TeamDraw.draw(players: players, into: 2)

        #expect(teams.count == 2)
        #expect(teams.flatMap(\.self).count == count)
        let sizes = teams.map(\.count)
        #expect((sizes.max()! - sizes.min()!) <= 1, "sizes \(sizes) differ by more than one")
    }

    @Test("no team is ever more than one player larger", arguments: [2, 3, 4, 5])
    func balanced(teamCount: Int) {
        for playerCount in (teamCount * TeamDraw.minimumTeamSize)...13 {
            let players = (1...playerCount).map { "P\($0)" }
            let sizes = TeamDraw.draw(players: players, into: teamCount).map(\.count)
            #expect((sizes.max()! - sizes.min()!) <= 1, "\(playerCount) into \(teamCount): \(sizes)")
        }
    }

    @Test("every player is dealt exactly once")
    func everyoneIsPlaced() {
        let teams = TeamDraw.draw(players: eight, into: 3)
        let dealt = teams.flatMap(\.self)
        #expect(dealt.count == eight.count)
        #expect(Set(dealt) == Set(eight))
    }

    @Test("blank and duplicate names are dropped")
    func tidying() {
        let messy = ["  Nino ", "", "nino", "Ana", "   ", "Ana"]
        #expect(TeamDraw.tidy(messy) == ["Nino", "Ana"])
    }

    /// A team of one has nobody to guess for them, so it cannot take a turn. Asking for
    /// more teams than the room can fill gives fewer, larger teams rather than strays.
    @Test("nobody is ever left on a team alone", arguments: 4...15)
    func neverATeamOfOne(playerCount: Int) {
        let players = (1...playerCount).map { "P\($0)" }
        for requested in 2...5 {
            let teams = TeamDraw.draw(players: players, into: requested)
            #expect(!teams.isEmpty)
            #expect(teams.allSatisfy { $0.count >= TeamDraw.minimumTeamSize },
                    "\(playerCount) into \(requested) gave \(teams.map(\.count))")
        }
    }

    @Test("fewer than four players cannot be drawn")
    func notEnoughPlayers() {
        for count in 0...3 {
            let players = (0..<count).map { "P\($0)" }
            #expect(TeamDraw.draw(players: players, into: 2).isEmpty, "\(count) players drew teams")
            #expect(TeamDraw.teamCountRange(forPlayers: count) == nil)
        }
        #expect(TeamDraw.minimumPlayers == 4)
        #expect(TeamDraw.teamCountRange(forPlayers: 4) == 2...2)
    }

    @Test("the team count is held inside the game's own limits")
    func clampsToGameLimits() {
        let many = (1...20).map { "P\($0)" }
        #expect(TeamDraw.draw(players: many, into: 99).count == GameSettings.teamCountRange.upperBound)
        #expect(TeamDraw.draw(players: many, into: 0).count == GameSettings.teamCountRange.lowerBound)
        // Five players fill two pairs at most, not three teams.
        #expect(TeamDraw.teamCountRange(forPlayers: 5) == 2...2)
        #expect(TeamDraw.teamCountRange(forPlayers: 7) == 2...3)
    }

    @Test("the same seed draws the same teams")
    func deterministicUnderAFixedSeed() {
        var one = FixedGenerator()
        var two = FixedGenerator()
        #expect(TeamDraw.draw(players: eight, into: 2, using: &one)
                == TeamDraw.draw(players: eight, into: 2, using: &two))
    }

    /// Otherwise "shuffle again" would hand back the same teams and look broken.
    @Test("redrawing can produce a different split")
    func redrawVaries() {
        let first = TeamDraw.draw(players: eight, into: 2)
        let differs = (0..<40).contains { _ in
            TeamDraw.draw(players: eight, into: 2) != first
        }
        #expect(differs, "40 draws of 8 players never differed")
    }
}

@Suite("Team persistence")
struct TeamCodingTests {

    /// A game saved before `members` existed must still load. The synthesised decoder
    /// throws `keyNotFound` here, and `GameStateStore` uses `try?` — so this failing means
    /// an in-progress game silently disappears when the user updates.
    @Test("a team saved without members still decodes")
    func decodesLegacyPayload() throws {
        let legacy = """
        {
          "id": "1B4E28BA-2FA1-11D2-883F-0016D3CCA427",
          "name": "Team 1",
          "score": 7,
          "wordsGuessed": 9,
          "wordsSkipped": 2,
          "currentStreak": 1,
          "bestStreak": 4,
          "totalGuessTime": 31.5,
          "setsSkipped": 0,
          "superWordsGuessed": 1
        }
        """
        let team = try JSONDecoder().decode(Team.self, from: Data(legacy.utf8))
        #expect(team.name == "Team 1")
        #expect(team.score == 7)
        #expect(team.bestStreak == 4)
        #expect(team.members.isEmpty)
    }

    @Test("members survive a round trip")
    func roundTrip() throws {
        let team = Team(name: "Team 1", score: 3, members: ["Nino", "Ana"])
        let data = try JSONEncoder().encode(team)
        let restored = try JSONDecoder().decode(Team.self, from: data)
        #expect(restored == team)
        #expect(restored.members == ["Nino", "Ana"])
    }
}
