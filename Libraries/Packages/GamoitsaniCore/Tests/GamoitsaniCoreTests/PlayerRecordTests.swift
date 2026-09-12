//
//  PlayerRecordTests.swift
//  GamoitsaniCoreTests
//

import Foundation
import Testing
@testable import GamoitsaniCore

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

@Suite("Player ledger")
struct PlayerLedgerTests {

    @Test("a first game creates a record for everyone who played")
    func firstGame() {
        let records = PlayerLedger.apply(
            to: [:],
            played: ["ნიკა", "დათა"],
            winners: ["ნიკა"],
            credits: [TurnCredit(describer: "ნიკა", wordsGuessed: 7)]
        )

        #expect(records.count == 2)
        let nika = try! #require(records[PlayerRecord.key(for: "ნიკა")])
        #expect(nika.gamesPlayed == 1)
        #expect(nika.gamesWon == 1)
        #expect(nika.wordsDescribed == 7)
        #expect(nika.bestTurn == 7)

        let data = try! #require(records[PlayerRecord.key(for: "დათა")])
        #expect(data.gamesPlayed == 1)
        #expect(data.gamesWon == 0)
    }

    @Test("games accumulate")
    func accumulates() {
        var records = PlayerLedger.apply(
            to: [:], played: ["ნიკა"], winners: ["ნიკა"],
            credits: [TurnCredit(describer: "ნიკა", wordsGuessed: 5)]
        )
        records = PlayerLedger.apply(
            to: records, played: ["ნიკა"], winners: [],
            credits: [TurnCredit(describer: "ნიკა", wordsGuessed: 3)]
        )

        let nika = try! #require(records[PlayerRecord.key(for: "ნიკა")])
        #expect(nika.gamesPlayed == 2)
        #expect(nika.gamesWon == 1)
        #expect(nika.wordsDescribed == 8)
        #expect(nika.bestTurn == 5, "the best turn is not the latest one")
    }

    /// The same rule team names use: what the room considers one person, the app should.
    @Test("case and stray spaces are the same player")
    func matching() {
        var records = PlayerLedger.apply(to: [:], played: ["ნიკა"], winners: [], credits: [])
        records = PlayerLedger.apply(to: records, played: [" ნიკა "], winners: [], credits: [])

        #expect(records.count == 1)
        #expect(records.values.first?.gamesPlayed == 2)
    }

    @Test("a name twice in one roster is still one game")
    func duplicatesInARoster() {
        let records = PlayerLedger.apply(
            to: [:], played: ["ნიკა", "ნიკა"], winners: [], credits: []
        )
        #expect(records.count == 1)
        #expect(records.values.first?.gamesPlayed == 1)
    }

    @Test("a draw credits nobody with a win")
    func draw() {
        let records = PlayerLedger.apply(
            to: [:], played: ["ნიკა", "დათა"], winners: [], credits: []
        )
        #expect(records.values.allSatisfy { $0.gamesWon == 0 })
    }

    /// Otherwise a stray credit would conjure a player who never appeared in a roster.
    @Test("a credit for someone who did not play is ignored")
    func creditWithoutPlaying() {
        let records = PlayerLedger.apply(
            to: [:], played: ["ნიკა"], winners: [],
            credits: [TurnCredit(describer: "ვინმე", wordsGuessed: 9)]
        )
        #expect(records.count == 1)
        #expect(records[PlayerRecord.key(for: "ვინმე")] == nil)
    }

    @Test("several turns in a game add up")
    func manyTurns() {
        let records = PlayerLedger.apply(
            to: [:], played: ["ნიკა"], winners: [],
            credits: [
                TurnCredit(describer: "ნიკა", wordsGuessed: 4),
                TurnCredit(describer: "ნიკა", wordsGuessed: 6)
            ]
        )
        let nika = try! #require(records[PlayerRecord.key(for: "ნიკა")])
        #expect(nika.wordsDescribed == 10)
        #expect(nika.bestTurn == 6)
    }

    @Test("blank names are not players")
    func blanks() {
        let records = PlayerLedger.apply(to: [:], played: ["", "   "], winners: [], credits: [])
        #expect(records.isEmpty)
    }

    @Test("records survive a save and load")
    func codable() throws {
        let record = PlayerRecord(
            name: "ნიკა", gamesPlayed: 12, gamesWon: 7, wordsDescribed: 96, bestTurn: 11
        )
        let data = try JSONEncoder().encode(record)
        #expect(try JSONDecoder().decode(PlayerRecord.self, from: data) == record)
    }
}
