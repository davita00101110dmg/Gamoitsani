//
//  GameSettingsTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Game settings")
struct GameSettingsTests {

    @Test("rounds are clamped to v1's range", arguments: [
        (0, 1), (1, 1), (3, 3), (5, 5), (9, 5), (-4, 1),
    ])
    func rounds(input: Int, expected: Int) {
        #expect(GameSettings(rounds: input).rounds == expected)
    }

    @Test("round length is clamped to v1's range", arguments: [
        (5.0, 15.0), (15.0, 15.0), (45.0, 45.0), (75.0, 75.0), (600.0, 75.0),
    ])
    func roundLength(input: TimeInterval, expected: TimeInterval) {
        #expect(GameSettings(roundLength: input).roundLength == expected)
    }

    @Test("defaults match v1")
    func defaults() {
        let s = GameSettings()
        #expect(s.rounds == 1)
        #expect(s.roundLength == 45)
        #expect(s.mode == .classic)
        #expect(s.superWordsEnabled == false)
        #expect(s.challengesEnabled == false)
    }

    @Test("a game with no tier chosen plays the whole database")
    func difficultyDefaultsToMixed() {
        #expect(GameSettings().difficulty == .mixed)
        #expect(WordDifficulty.mixed.range == 1...5)
    }

    // MARK: - Surviving the upgrade

    /// The synthesised decoder throws `keyNotFound` on a payload saved before `difficulty`
    /// existed, and `GameStateStore.load` swallows that with `try?` — the in-progress game
    /// would disappear on upgrade with no error anywhere. This is the guard.
    @Test("settings saved before difficulty existed decode instead of throwing")
    func legacySettingsDecode() throws {
        let legacy = """
        {
          "rounds": 3,
          "roundLength": 60,
          "mode": "arcade",
          "superWordsEnabled": true,
          "challengesEnabled": false
        }
        """
        let settings = try JSONDecoder().decode(GameSettings.self, from: Data(legacy.utf8))
        #expect(settings.difficulty == .mixed)
        #expect(settings.rounds == 3)
        #expect(settings.roundLength == 60)
        #expect(settings.mode == .arcade)
        #expect(settings.superWordsEnabled)
    }

    /// The same thing through the type that is actually persisted. Built by stripping the
    /// key from real encoded output rather than hand-writing a payload, so it stays honest
    /// as `GameState` gains properties.
    @Test("a whole saved game from before the field still loads")
    func legacyGameStateDecodes() throws {
        let state = GameState(
            settings: GameSettings(rounds: 3, roundLength: 60, mode: .arcade, difficulty: .hard),
            teams: [Team(name: "Team 1"), Team(name: "Team 2")],
            deck: Deck(words: [DeckWord(id: "4711", text: "ბროწეული")])
        )

        var object = try #require(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(state)) as? [String: Any]
        )
        var settings = try #require(object["settings"] as? [String: Any])
        #expect(settings["difficulty"] != nil, "nothing was stripped, so the test proves nothing")
        settings.removeValue(forKey: "difficulty")
        object["settings"] = settings

        let data = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(GameState.self, from: data)

        #expect(restored.settings.difficulty == .mixed)
        #expect(restored.settings.rounds == 3)
        #expect(restored.settings.mode == .arcade)
        #expect(restored.teams.count == 2)
        #expect(restored.deck.count == 1)
    }

    @Test("difficulty survives a round trip", arguments: WordDifficulty.allCases)
    func roundTrip(difficulty: WordDifficulty) throws {
        let settings = GameSettings(rounds: 2, difficulty: difficulty)
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(GameSettings.self, from: data) == settings)
    }

    /// `GameState` is the type that actually reaches disk, so it carries the same guard.
    /// Stripping the newest key must not cost the player their game.
    @Test("a saved game from before deckLanguage still loads")
    func legacyDeckLanguageDecodes() throws {
        let state = GameState(
            settings: GameSettings(rounds: 2),
            teams: [Team(name: "Team 1"), Team(name: "Team 2")],
            deck: Deck(words: [DeckWord(id: "4711", text: "ბროწეული")]),
            deckLanguage: "en"
        )

        var object = try #require(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(state)) as? [String: Any]
        )
        #expect(object["deckLanguage"] != nil, "nothing was stripped, so this proves nothing")
        object.removeValue(forKey: "deckLanguage")

        let data = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(GameState.self, from: data)

        // Georgian, because it was the only language with words when saves began.
        #expect(restored.deckLanguage == "ka")
        #expect(restored.teams.count == 2)
        #expect(restored.deck.count == 1)
    }

    @Test("the deck's language survives a round trip and a resume")
    func deckLanguageRoundTrips() throws {
        let state = GameState(
            settings: GameSettings(),
            teams: [Team(name: "A"), Team(name: "B")],
            deck: Deck(words: [DeckWord(id: "1", text: "word")]),
            deckLanguage: "ja"
        )
        let restored = try JSONDecoder().decode(
            GameState.self, from: try JSONEncoder().encode(state)
        )
        #expect(restored.deckLanguage == "ja")
    }
}

@Suite("Team validation")
struct TeamValidationTests {

    private func teams(_ names: [String]) -> [Team] {
        names.map { Team(name: $0) }
    }

    @Test("two to five teams are allowed")
    func count() {
        #expect(TeamValidator.isValid(teams(["A", "B"])))
        #expect(TeamValidator.isValid(teams(["A", "B", "C", "D", "E"])))
        #expect(TeamValidator.isValid(teams(["A"])) == false)
        #expect(TeamValidator.isValid(teams(["A", "B", "C", "D", "E", "F"])) == false)
    }

    @Test("blank and whitespace-only names are rejected")
    func emptyNames() {
        #expect(TeamValidator.validate(teams(["A", ""])).contains(.emptyName))
        #expect(TeamValidator.validate(teams(["A", "   "])).contains(.emptyName))
    }

    /// Two teams called "Team 1" are the same team to everyone in the room.
    @Test("duplicate names are rejected regardless of case or padding")
    func duplicates() {
        #expect(TeamValidator.isValid(teams(["Team 1", "team 1"])) == false)
        #expect(TeamValidator.isValid(teams(["Team 1", " Team 1 "])) == false)
        #expect(TeamValidator.isValid(teams(["Team 1", "Team 2"])))
    }

    /// v1 computed a max length inside validateName and then never compared against it.
    @Test("the name length limit is actually enforced")
    func lengthEnforced() {
        let long = String(repeating: "a", count: GameSettings.maxTeamNameLength + 1)
        let errors = TeamValidator.validate(teams(["A", long]))
        #expect(errors.contains { if case .nameTooLong = $0 { true } else { false } })

        let atLimit = String(repeating: "a", count: GameSettings.maxTeamNameLength)
        #expect(TeamValidator.isValid(teams(["A", atLimit])))
    }

    /// The setup screen needs to mark every bad row, not just the first.
    @Test("all problems are reported together")
    func reportsEveryProblem() {
        let errors = TeamValidator.validate(teams(["", "dup", "dup"]))
        #expect(errors.contains(.emptyName))
        #expect(errors.contains(.duplicateName("dup")))
    }
}
