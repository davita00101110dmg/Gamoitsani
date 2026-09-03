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
