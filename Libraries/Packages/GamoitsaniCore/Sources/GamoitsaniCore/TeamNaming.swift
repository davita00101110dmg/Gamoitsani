//
//  TeamNaming.swift
//  GamoitsaniCore
//

import Foundation

/// Picks the number for a new team's default name.
///
/// Naming from `teams.count + 1` looks right and is wrong: add a third team, delete the
/// second, add another, and you get a second "Team 3". The count is not the identity of a
/// team, and after any deletion the two stop agreeing.
///
/// The smallest unused number is chosen instead, so names stay tight and never collide —
/// deleting Team 2 from 1/2/3 and adding again gives you Team 2 back, not Team 4.
///
/// This lives in Core rather than the setup screen because it is a rule about teams, and
/// because a bug this quiet deserves a test.
public enum TeamNaming {

    /// The smallest positive integer not already taken.
    public static func nextNumber(usedNumbers: Set<Int>) -> Int {
        var candidate = 1
        while usedNumbers.contains(candidate) { candidate += 1 }
        return candidate
    }

    /// Numbers already in use, read off the trailing digits of existing names.
    ///
    /// Digit-based rather than prefix-based so it survives localisation: "Team 2",
    /// "გუნდი 2" and "Команда 2" all yield 2, and a hand-typed name like "The Winners"
    /// yields nothing and simply does not reserve a number.
    public static func usedNumbers(in names: [String]) -> Set<Int> {
        var numbers: Set<Int> = []
        for name in names {
            let trailing = name.reversed().prefix { $0.isNumber }.reversed()
            if let value = Int(String(trailing)) { numbers.insert(value) }
        }
        return numbers
    }

    /// Convenience: the next free number given the current names.
    public static func nextNumber(afterNames names: [String]) -> Int {
        nextNumber(usedNumbers: usedNumbers(in: names))
    }
}
