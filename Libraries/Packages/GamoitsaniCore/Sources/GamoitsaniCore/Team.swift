//
//  Team.swift
//  GamoitsaniCore
//

import Foundation

/// A team in a game.
///
/// Identity-keyed, unlike v1, where per-team state lived in parallel arrays indexed by
/// position (`GameStory.teams`, plus separate dictionaries for challenges and super-word
/// flags). Anything that belongs to a team belongs on the team.
public struct Team: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var score: Int

    public init(id: UUID = UUID(), name: String, score: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
    }
}
