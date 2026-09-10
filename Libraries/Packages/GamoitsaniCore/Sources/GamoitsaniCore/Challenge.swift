//
//  Challenge.swift
//  GamoitsaniCore
//
import Foundation

/// A silly rule a team plays the whole game under.
///
/// The text lives in the string catalogue under `challenge.<case>` — these are short
/// translated sentences, which is what that file is for.
///
/// **Every rule here changes how a player speaks or stands, and none adds an action
/// between guesses.** That is the criterion, and it exists because teams are scored
/// against each other. A rule costing two seconds a word costs thirty over a turn, so
/// "dance after every correct guess" against "speak in a robot voice" is not a difference
/// in flavour, it is a handicap handed out at random. v1's set was mostly the former;
/// those are gone, along with one that asked a player to hold their breath while
/// speaking, one that asked the guesser to shut eyes they never used, one nobody could
/// enforce, and one that demanded a squat for a whole game.
public enum Challenge: String, CaseIterable, Sendable, Hashable, Codable {
    case accent
    case commentator
    case handOnHead
    case lookAway
    case onlyQuestions
    case questionForm
    case robotVoice
    case royalTitles
    case shoutIt
    case singIt
    case thirdPerson
    case whisper

    /// The catalogue key holding this challenge's text.
    public var textKey: String { "challenge.\(rawValue)" }
}

extension Challenge {
    /// Deals a different rule to each team.
    ///
    /// Drawn by the caller, not inside the reducer, for the same reason the super word's
    /// position is: the same inputs must always produce the same game. With more teams
    /// than rules the deck reshuffles, which cannot happen at five teams and twelve.
    public static func draw(
        for teams: [Team],
        using generator: inout some RandomNumberGenerator
    ) -> [Team.ID: Challenge] {
        var pool = allCases.shuffled(using: &generator)
        var drawn: [Team.ID: Challenge] = [:]
        for team in teams {
            if pool.isEmpty { pool = allCases.shuffled(using: &generator) }
            drawn[team.id] = pool.removeLast()
        }
        return drawn
    }

    public static func draw(for teams: [Team]) -> [Team.ID: Challenge] {
        var generator = SystemRandomNumberGenerator()
        return draw(for: teams, using: &generator)
    }
}
