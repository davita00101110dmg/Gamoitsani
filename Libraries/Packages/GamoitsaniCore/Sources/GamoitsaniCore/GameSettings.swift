//
//  GameSettings.swift
//  GamoitsaniCore
//

import Foundation

/// Everything chosen on the setup screen before a game starts.
///
/// Ranges are enforced here rather than by the stepper that happens to be on screen, so a
/// value that reaches the engine is always playable. v1 declared `maxTeamNameLength = 30`
/// and `maxPlayerNameLength = 15`, computed them inside `validateName`, and then never
/// compared anything against them — the limits existed only as documentation.
public struct GameSettings: Sendable, Hashable, Codable {

    public static let roundsRange = 1...5
    public static let roundLengthRange: ClosedRange<Int> = 15...75
    public static let roundLengthStep = 5
    public static let teamCountRange = 2...5
    public static let maxTeamNameLength = 30

    public private(set) var rounds: Int
    public private(set) var roundLength: TimeInterval
    public var mode: GameMode
    public var superWordsEnabled: Bool
    public var challengesEnabled: Bool

    public init(
        rounds: Int = 1,
        roundLength: TimeInterval = 45,
        mode: GameMode = .classic,
        superWordsEnabled: Bool = false,
        challengesEnabled: Bool = false
    ) {
        self.rounds = Self.roundsRange.clamping(rounds)
        self.roundLength = TimeInterval(Self.roundLengthRange.clamping(Int(roundLength)))
        self.mode = mode
        self.superWordsEnabled = superWordsEnabled
        self.challengesEnabled = challengesEnabled
    }

    public mutating func setRounds(_ value: Int) {
        rounds = Self.roundsRange.clamping(value)
    }

    public mutating func setRoundLength(_ value: TimeInterval) {
        roundLength = TimeInterval(Self.roundLengthRange.clamping(Int(value)))
    }
}

/// Why a proposed set of teams cannot start a game.
///
/// An enum rather than a `Bool` because the setup screen has to tell the player which
/// problem to fix. v1's `add(with:)` computed the error and discarded it, silently dropping
/// invalid names with no alert.
public enum TeamValidationError: Error, Sendable, Hashable {
    case tooFewTeams(minimum: Int)
    case tooManyTeams(maximum: Int)
    case emptyName
    case duplicateName(String)
    case nameTooLong(String, maximum: Int)
}

public enum TeamValidator {

    /// Validates a proposed roster, returning every problem rather than only the first, so
    /// the UI can mark all offending rows at once.
    public static func validate(_ teams: [Team]) -> [TeamValidationError] {
        var errors: [TeamValidationError] = []

        if teams.count < GameSettings.teamCountRange.lowerBound {
            errors.append(.tooFewTeams(minimum: GameSettings.teamCountRange.lowerBound))
        }
        if teams.count > GameSettings.teamCountRange.upperBound {
            errors.append(.tooManyTeams(maximum: GameSettings.teamCountRange.upperBound))
        }

        var seen = Set<String>()
        for team in teams {
            let trimmed = team.name.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.isEmpty {
                errors.append(.emptyName)
                continue
            }
            if trimmed.count > GameSettings.maxTeamNameLength {
                errors.append(.nameTooLong(trimmed, maximum: GameSettings.maxTeamNameLength))
            }
            // Case- and whitespace-insensitive: "Team 1" and "team 1 " are the same team to
            // everyone in the room, so they should be to the app.
            let key = trimmed.lowercased()
            if !seen.insert(key).inserted {
                errors.append(.duplicateName(trimmed))
            }
        }

        return errors
    }

    public static func isValid(_ teams: [Team]) -> Bool {
        validate(teams).isEmpty
    }
}

extension ClosedRange where Bound: Comparable {
    fileprivate func clamping(_ value: Bound) -> Bound {
        Swift.min(Swift.max(value, lowerBound), upperBound)
    }
}
