//
//  SavedGameTests.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

/// A game saved by today's app has to load after the switch, or a player loses it on upgrade.
@Suite("Saved games")
struct SavedGameTests {

    /// Written by `GamoitsaniCore`'s `JSONEncoder` from a real mid-turn arcade game: super
    /// words and challenges on, one word guessed, one skipped, then put down at 35 s left.
    private static let savedByGamoitsaniCore = #"""
    {
      "challenges" : [
        "11111111-1111-1111-1111-111111111111",
        "whisper",
        "22222222-2222-2222-2222-222222222222",
        "robotVoice"
      ],
      "currentTeamIndex" : 0,
      "deck" : {
        "remaining" : [
          {
            "id" : "6",
            "isSuperWord" : false,
            "text" : "word6"
          },
          {
            "id" : "7",
            "isSuperWord" : false,
            "text" : "word7"
          }
        ]
      },
      "deckLanguage" : "en",
      "pausedRemaining" : 35,
      "phase" : {
        "playing" : {

        }
      },
      "placement" : {
        "arcadeSet" : 1,
        "arcadeSlot" : 2,
        "classicPosition" : 3
      },
      "playedOutcomes" : {
        "2" : "correct",
        "4" : "skipped"
      },
      "round" : 1,
      "setIndex" : 1,
      "settings" : {
        "challengesEnabled" : true,
        "difficulty" : "hard",
        "mode" : "arcade",
        "roundLength" : 45,
        "rounds" : 2,
        "superWordsEnabled" : true
      },
      "superWordSpentBy" : [
        "11111111-1111-1111-1111-111111111111"
      ],
      "teams" : [
        {
          "bestStreak" : 1,
          "currentStreak" : 0,
          "guessStartedAt" : 821692809,
          "id" : "11111111-1111-1111-1111-111111111111",
          "members" : [
            "Nino",
            "Giorgi"
          ],
          "name" : "წითლები",
          "score" : 2,
          "setsSkipped" : 0,
          "superWordsGuessed" : 1,
          "totalGuessTime" : 7,
          "wordsGuessed" : 1,
          "wordsSkipped" : 1
        },
        {
          "bestStreak" : 0,
          "currentStreak" : 0,
          "id" : "22222222-2222-2222-2222-222222222222",
          "members" : [
            "Ana",
            "Luka"
          ],
          "name" : "Blue",
          "score" : 0,
          "setsSkipped" : 0,
          "superWordsGuessed" : 0,
          "totalGuessTime" : 0,
          "wordsGuessed" : 0,
          "wordsSkipped" : 0
        }
      ],
      "turnWords" : [
        {
          "id" : "1",
          "isSuperWord" : false,
          "text" : "word1"
        },
        {
          "id" : "2",
          "isSuperWord" : true,
          "text" : "word2"
        },
        {
          "id" : "3",
          "isSuperWord" : false,
          "text" : "word3"
        },
        {
          "id" : "4",
          "isSuperWord" : false,
          "text" : "word4"
        },
        {
          "id" : "5",
          "isSuperWord" : false,
          "text" : "word5"
        }
      ],
      "wordsShownThisTurn" : 5
    }
    """#

    private func decode() throws -> GameState {
        try JSONDecoder().decode(GameState.self, from: Data(Self.savedByGamoitsaniCore.utf8))
    }

    @Test("a game saved by today's app loads with nothing lost")
    func decodesTodaysSave() throws {
        let state = try decode()
        let red = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        let blue = try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))

        #expect(state.phase == .playing)
        #expect(state.settings == GameSettings(
            rounds: 2, roundLength: 45, mode: .arcade,
            superWordsEnabled: true, challengesEnabled: true, difficulty: .hard
        ))
        #expect(state.teams.map(\.name) == ["წითლები", "Blue"])
        #expect(state.teams[0].members == ["Nino", "Giorgi"])
        #expect(state.teams[0].score == 2)
        #expect(state.teams[0].superWordsGuessed == 1)
        #expect(state.challenges == [red: .whisper, blue: .robotVoice])
        #expect(state.superWordSpentBy == [red])
        #expect(state.playedOutcomes == ["2": .correct, "4": .skipped])
        #expect(state.turnWords.map(\.id) == ["1", "2", "3", "4", "5"])
        #expect(state.turnWords[1].isSuperWord)
        #expect(state.deck.remainingIDs == ["6", "7"])
        #expect(state.deckLanguage == "en")
        #expect(state.pausedRemaining == 35)
        #expect(state.roundEndsAt == nil)
    }

    @Test("it resumes mid-turn with the time it had left")
    func resumesTodaysSave() throws {
        let clock = ManualClock(Fixture.t0)
        var runner = GameRunner(resuming: try decode(), clock: clock, random: SeededGenerator(seed: 1))
        #expect(runner.remainingTime == 35)
        #expect(runner.wordsInPlay.map(\.id) == ["1", "3", "5"])

        let answered = runner.send(.answer(wordID: "3", outcome: .correct))
        #expect(answered)
        #expect(runner.currentTeam?.score == 3)

        clock.advance(by: 35)
        let expired = runner.checkExpiry()
        #expect(expired)
        #expect(runner.currentTeam?.name == "Blue")
    }

    @Test("GameCore writes a save it reads back unchanged")
    func roundTrips() throws {
        let state = try decode()
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(GameState.self, from: data) == state)
    }
}
