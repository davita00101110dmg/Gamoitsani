//
//  DescriberTests.swift
//  GameCoreTests
//

import Foundation
import Testing
@testable import GameCore

@Suite("Describer")
struct DescriberTests {

    private func team(_ members: [String]) -> Team {
        Team(name: "Blue", members: members)
    }

    @Test("the turn goes round the team")
    func rotates() {
        let blue = team(["ნიკა", "დათა", "გიო"])
        #expect(Describer.name(for: blue, round: 1, extraRound: 0) == "ნიკა")
        #expect(Describer.name(for: blue, round: 2, extraRound: 0) == "დათა")
        #expect(Describer.name(for: blue, round: 3, extraRound: 0) == "გიო")
        #expect(Describer.name(for: blue, round: 4, extraRound: 0) == "ნიკა", "and round again")
    }

    @Test("it says who is up next")
    func next() {
        let blue = team(["ნიკა", "დათა"])
        #expect(Describer.next(for: blue, round: 1, extraRound: 0) == "დათა")
        #expect(Describer.next(for: blue, round: 2, extraRound: 0) == "ნიკა")
    }

    @Test("nobody is next in a team of one")
    func soloHasNoNext() {
        #expect(Describer.next(for: team(["ნიკა"]), round: 1, extraRound: 0) == nil)
    }

    /// Teams can be typed straight in without the player draw.
    @Test("a team with no names has no describer")
    func anonymousTeam() {
        #expect(Describer.name(for: team([]), round: 1, extraRound: 0) == nil)
        #expect(Describer.next(for: team([]), round: 1, extraRound: 0) == nil)
    }

    /// A tie-break is more of the same game. Restarting the rotation would hand the same
    /// player two turns in a row.
    @Test("extra rounds continue the rotation")
    func extraRounds() {
        let blue = team(["ნიკა", "დათა", "გიო"])
        let lastNormal = Describer.name(for: blue, round: 3, extraRound: 0)
        let firstExtra = Describer.name(for: blue, round: 3, extraRound: 1)
        #expect(lastNormal != firstExtra)
        #expect(firstExtra == "ნიკა")
    }
}
