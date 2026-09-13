//
//  ChallengeTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Challenges")
struct ChallengeTests {

    private func teams(_ n: Int) -> [Team] {
        (1...n).map { Team(name: "Team \($0)") }
    }

    @Test("every team gets a rule, and no two teams share one")
    func drawIsDistinct() {
        var generator = SeededGenerator(seed: 7)
        let drawn = Challenge.draw(for: teams(5), using: &generator)

        #expect(drawn.count == 5)
        #expect(Set(drawn.values).count == 5, "two teams drew the same rule")
    }

    /// Five teams is the maximum a game allows, so the deck must never need reshuffling
    /// in practice — but it must not crash or drop a team if it ever did.
    @Test("more teams than rules still deals every team something")
    func drawSurvivesASmallDeck() {
        var generator = SeededGenerator(seed: 11)
        let many = teams(Challenge.allCases.count + 3)
        let drawn = Challenge.draw(for: many, using: &generator)

        #expect(drawn.count == many.count)
        #expect(many.allSatisfy { drawn[$0.id] != nil })
    }

    @Test("the same seed always deals the same rules")
    func drawIsDeterministic() {
        let roster = teams(4)
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        #expect(Challenge.draw(for: roster, using: &a) == Challenge.draw(for: roster, using: &b))
    }

    @Test("each rule points at a catalogue key")
    func textKeys() {
        for challenge in Challenge.allCases {
            #expect(challenge.textKey == "challenge.\(challenge.rawValue)")
        }
    }

    /// The rule the whole set is curated around: a challenge may change how a player
    /// speaks or stands, but must never add an action between guesses. A rule costing two
    /// seconds a word costs thirty over a turn, and teams are scored against each other —
    /// so anything per-guess is a handicap dealt at random, not a flavour.
    ///
    /// Enforced by name because that is the only handle the code has on it: every rule
    /// v1 had of that kind was phrased "after each correct guess".
    @Test("no rule is charged per correct guess")
    func noPerGuessRules() {
        let banned = ["highFive", "celebrationDance", "animalSounds",
                      "toeTouches", "spinAround", "countAloud", "fingerSnapping"]
        for name in banned {
            #expect(
                Challenge(rawValue: name) == nil,
                "\(name) charges the clock per guess — see the note on Challenge"
            )
        }
    }

    // MARK: - In a game

    @Test("rules are dealt only when challenges are switched on")
    func onlyWhenEnabled() {
        let roster = teams(2)
        let off = GameState(
            settings: GameSettings(challengesEnabled: false),
            teams: roster,
            deck: Deck(words: [])
        )
        #expect(off.challenges.isEmpty)
        #expect(off.currentChallenge == nil)

        let on = GameState(
            settings: GameSettings(challengesEnabled: true),
            teams: roster,
            deck: Deck(words: []),
            challenges: Challenge.draw(for: roster)
        )
        #expect(on.currentChallenge != nil)
        #expect(on.challenge(for: roster[1].id) != nil)
    }

    @Test("a team keeps its rule as the turn passes between teams")
    func ruleFollowsTheTeam() throws {
        let roster = teams(2)
        let drawn = Challenge.draw(for: roster)
        var state = GameState(
            settings: GameSettings(rounds: 2, challengesEnabled: true),
            teams: roster,
            deck: Deck(words: (1...40).map { DeckWord(id: "\($0)", text: "w\($0)") }),
            challenges: drawn
        )

        #expect(state.currentChallenge == drawn[roster[0].id])
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        state = try GameReducer.reduce(state, .beginTurn, at: t0).get()
        state = try GameReducer.reduce(state, .countdownFinished, at: t0).get()
        state = try GameReducer.reduce(state, .timeExpired, at: t0).get()

        #expect(state.currentChallenge == drawn[roster[1].id], "the second team's own rule")
    }

    /// A saved game from before challenges existed must still load — `GameStateStore.load`
    /// swallows a decode failure with `try?`, so a missing key would lose the game.
    @Test("a game saved before challenges existed still loads")
    func legacyDecode() throws {
        let roster = teams(2)
        let state = GameState(
            settings: GameSettings(challengesEnabled: true),
            teams: roster,
            deck: Deck(words: [DeckWord(id: "1", text: "word")]),
            challenges: Challenge.draw(for: roster)
        )

        var object = try #require(
            JSONSerialization.jsonObject(with: try JSONEncoder().encode(state)) as? [String: Any]
        )
        #expect(object["challenges"] != nil, "nothing was stripped, so this proves nothing")
        object.removeValue(forKey: "challenges")

        let data = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(GameState.self, from: data)

        #expect(restored.challenges.isEmpty)
        #expect(restored.currentChallenge == nil)
        #expect(restored.teams.count == 2)
    }

    /// Such a save still has the setting switched on, so resuming it would otherwise put
    /// an empty card on the challenge screen. `GameSession.resume` heals it through this.
    @Test("a game with the setting on but no rules can be dealt them late")
    func assignsLate() {
        let roster = teams(2)
        var state = GameState(
            settings: GameSettings(challengesEnabled: true),
            teams: roster,
            deck: Deck(words: [])
        )
        #expect(state.currentChallenge == nil)

        state.assignChallenges(Challenge.draw(for: roster))
        #expect(state.currentChallenge != nil)

        // Never overwrites rules a game already has.
        let settled = state.challenges
        state.assignChallenges(Challenge.draw(for: roster))
        #expect(state.challenges == settled)
    }
}
