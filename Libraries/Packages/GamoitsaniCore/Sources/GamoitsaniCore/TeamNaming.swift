//
//  TeamNaming.swift
//  GamoitsaniCore
//
import Foundation

/// Picks the number for a new team's default name.
public enum TeamNaming {

    /// The smallest positive integer not already taken.
    public static func nextNumber(usedNumbers: Set<Int>) -> Int {
        var candidate = 1
        while usedNumbers.contains(candidate) { candidate += 1 }
        return candidate
    }

    /// Numbers already in use, read off the trailing digits of existing names.
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
