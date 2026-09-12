//
//  GameSettings.swift
//  GamoitsaniCore
//
import Foundation

/// Everything chosen on the setup screen before a game starts.
public struct GameSettings: Sendable, Hashable, Codable {

    public static let roundsRange = 1...5
    public static let roundLengthRange: ClosedRange<Int> = 30...90
    public static let roundLengthStep = 5
    public static let teamCountRange = 2...5
    public static let maxTeamNameLength = 30

    public private(set) var rounds: Int
    public private(set) var roundLength: TimeInterval
    public var mode: GameMode
    public var superWordsEnabled: Bool
    public var challengesEnabled: Bool
    public var difficulty: WordDifficulty

    public init(
        // Three, not one. At one round every team takes a single turn and the game is
        // decided by whoever drew the kinder words — there is no chance to come back from
        // a bad turn, which is most of what makes this fun to play twice. The stepper is
        // right there for anyone who wants it shorter.
        rounds: Int = 3,
        roundLength: TimeInterval = 60,
        mode: GameMode = .classic,
        superWordsEnabled: Bool = false,
        challengesEnabled: Bool = false,
        difficulty: WordDifficulty = .mixed
    ) {
        self.rounds = Self.roundsRange.clamping(rounds)
        self.roundLength = TimeInterval(Self.roundLengthRange.clamping(Int(roundLength)))
        self.mode = mode
        self.superWordsEnabled = superWordsEnabled
        self.challengesEnabled = challengesEnabled
        self.difficulty = difficulty
    }

    /// Decoded by hand only because `difficulty` arrived after games were already being
    /// saved. The synthesised version throws `keyNotFound` on a payload without it, and
    /// `GameStateStore.load` swallows that with `try?` — an in-progress game would vanish
    /// silently on upgrade. Any further property needs the same treatment.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rounds = try container.decode(Int.self, forKey: .rounds)
        roundLength = try container.decode(TimeInterval.self, forKey: .roundLength)
        mode = try container.decode(GameMode.self, forKey: .mode)
        superWordsEnabled = try container.decode(Bool.self, forKey: .superWordsEnabled)
        challengesEnabled = try container.decode(Bool.self, forKey: .challengesEnabled)
        difficulty = try container.decodeIfPresent(WordDifficulty.self, forKey: .difficulty) ?? .mixed
    }

    public mutating func setRounds(_ value: Int) {
        rounds = Self.roundsRange.clamping(value)
    }

    public mutating func setRoundLength(_ value: TimeInterval) {
        roundLength = TimeInterval(Self.roundLengthRange.clamping(Int(value)))
    }
}

/// Why a proposed set of teams cannot start a game.
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
