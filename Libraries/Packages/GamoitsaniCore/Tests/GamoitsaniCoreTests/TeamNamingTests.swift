//
//  TeamNamingTests.swift
//  GamoitsaniCoreTests
//

import Testing
@testable import GamoitsaniCore

@Suite("Team naming")
struct TeamNamingTests {

    /// The reported bug: add a third team, delete the second, add again — and the count
    /// hands out "Team 3" a second time.
    @Test("a deleted number is reused instead of colliding")
    func reportedDuplicateBug() {
        // Team 1, Team 2, Team 3 -> delete Team 2
        let names = ["Team 1", "Team 3"]
        #expect(TeamNaming.nextNumber(afterNames: names) == 2)

        // Naming from the count would have produced 3 again.
        #expect(names.count + 1 == 3, "count-based naming would collide here")
    }

    @Test("the smallest free number is chosen", arguments: [
        ([] as [Int], 1),
        ([1], 2),
        ([1, 2, 3], 4),
        ([2, 3], 1),
        ([1, 3], 2),
        ([1, 2, 4], 3),
    ])
    func smallestFree(used: [Int], expected: Int) {
        #expect(TeamNaming.nextNumber(usedNumbers: Set(used)) == expected)
    }

    /// Digit-based so it keeps working in every language the app ships.
    @Test("numbers are read from any localised name", arguments: [
        (["Team 1", "Team 2"], 3),
        (["გუნდი 1", "გუნდი 2"], 3),
        (["Команда 1", "Команда 3"], 2),
        (["Equipo 5"], 1),
    ])
    func localisedNames(names: [String], expected: Int) {
        #expect(TeamNaming.nextNumber(afterNames: names) == expected)
    }

    @Test("a custom name reserves nothing")
    func customNames() {
        #expect(TeamNaming.nextNumber(afterNames: ["The Winners", "Losers"]) == 1)
        #expect(TeamNaming.nextNumber(afterNames: ["The Winners", "Team 1"]) == 2)
    }

    @Test("names with no trailing digits are ignored, not misread")
    func noTrailingDigits() {
        #expect(TeamNaming.usedNumbers(in: ["4ever"]).isEmpty)
        #expect(TeamNaming.usedNumbers(in: ["Team 2 B"]).isEmpty)
        #expect(TeamNaming.usedNumbers(in: ["Team 12"]) == [12])
    }
}
