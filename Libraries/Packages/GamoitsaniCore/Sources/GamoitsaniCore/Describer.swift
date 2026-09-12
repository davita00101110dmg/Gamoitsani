//
//  Describer.swift
//  GamoitsaniCore
//
import Foundation

/// Who is describing this turn.
///
/// Teams already carry the names typed into the roster, so the app can say whose turn it
/// is instead of leaving the room to work it out — and once it knows, a word guessed can
/// be credited to a person rather than only to a team.
///
/// Rotation is derived, never stored. A turn number and a member list are enough, and
/// anything stored would be another field to keep in step with `GameState` and another way
/// for a resumed game to disagree with itself.
public enum Describer {

    /// The member of `team` describing on this turn, or `nil` when the team has no names —
    /// teams can be typed straight in without the player draw.
    public static func name(for team: Team, round: Int, extraRound: Int) -> String? {
        guard !team.members.isEmpty else { return nil }
        return team.members[index(memberCount: team.members.count, round: round, extraRound: extraRound)]
    }

    /// Who is up after this turn. Shown alongside the current describer so the next player
    /// knows to be ready, which is most of what the room asks out loud.
    public static func next(for team: Team, round: Int, extraRound: Int) -> String? {
        guard team.members.count > 1 else { return nil }
        let current = index(memberCount: team.members.count, round: round, extraRound: extraRound)
        return team.members[(current + 1) % team.members.count]
    }

    /// Turns taken by a team before this one, wrapped onto its members.
    ///
    /// Extra rounds continue the rotation rather than restarting it: a tie-break is more
    /// of the same game, and starting over would hand the same player two turns running.
    static func index(memberCount: Int, round: Int, extraRound: Int) -> Int {
        guard memberCount > 0 else { return 0 }
        let turnsTaken = max(0, round - 1) + max(0, extraRound)
        return turnsTaken % memberCount
    }
}
