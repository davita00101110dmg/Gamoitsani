//
//  TeamCodingTests.swift
//  GameCoreTests
//

import Foundation
import Testing
@testable import GameCore

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
