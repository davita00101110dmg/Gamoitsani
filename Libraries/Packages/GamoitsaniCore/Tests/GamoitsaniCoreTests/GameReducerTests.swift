//
//  GameReducerTests.swift
//  GamoitsaniCoreTests
//

import Testing
import Foundation
@testable import GamoitsaniCore

@Suite("Game reducer")
struct GameReducerTests {

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func words(_ n: Int) -> [DeckWord] {
        (0..<n).map { DeckWord(id: "\($0)", text: "w\($0)") }
    }

    private func game(
        mode: GameMode = .classic,
        rounds: Int = 1,
        teams teamCount: Int = 2,
        superWords: Bool = false,
        challenges: Bool = false,
        wordCount: Int = 100,
        placement: SuperWordPlacement = SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)
    ) -> GameState {
        GameState(
            settings: GameSettings(rounds: rounds, mode: mode,
                                   superWordsEnabled: superWords, challengesEnabled: challenges),
            teams: (0..<teamCount).map { Team(name: "T\($0)") },
            deck: Deck(words: words(wordCount)),
            placement: placement
        )
    }

    /// Drives the reducer, failing the test on any rejection.
    private func apply(_ state: GameState, _ events: [GameEvent], at now: Date) throws -> GameState {
        var s = state
        for event in events {
            s = try GameReducer.reduce(s, event, at: now).get()
        }
        return s
    }

    // MARK: - Phases

    @Test("a turn walks info -> countdown -> playing when challenges are off")
    func phaseWalkWithoutChallenge() throws {
        var s = game()
        #expect(s.phase == .turnInfo)
        s = try apply(s, [.beginTurn], at: t0)
        #expect(s.phase == .countdown, "challenges off, so the challenge phase is skipped")
        s = try apply(s, [.countdownFinished], at: t0)
        #expect(s.phase == .playing)
        #expect(s.turnWords.count == 1, "classic puts one word on the table")
    }

    @Test("the challenge phase appears only when enabled")
    func phaseWalkWithChallenge() throws {
        var s = try apply(game(challenges: true), [.beginTurn], at: t0)
        #expect(s.phase == .challenge)
        s = try apply(s, [.acknowledgeChallenge, .countdownFinished], at: t0)
        #expect(s.phase == .playing)
    }

    /// Events are refused rather than silently ignored, so a UI bug is a value to assert
    /// on instead of a missing side effect.
    @Test("events out of phase are rejected")
    func outOfPhase() {
        let s = game()
        #expect(GameReducer.reduce(s, .countdownFinished, at: t0) == .failure(.wrongPhase(.turnInfo)))
        #expect(GameReducer.reduce(s, .answer(wordID: "0", outcome: .correct), at: t0)
                == .failure(.wrongPhase(.turnInfo)))
        #expect(GameReducer.reduce(s, .rematch, at: t0) == .failure(.wrongPhase(.turnInfo)))
    }

    // MARK: - Scoring through the loop

    @Test("answering scores the current team and deals the next word")
    func classicAnswerScores() throws {
        var s = try apply(game(), [.beginTurn, .countdownFinished], at: t0)
        let first = try #require(s.turnWords.first)

        s = try apply(s, [.answer(wordID: first.id, outcome: .correct)], at: t0)
        #expect(s.teams[0].score == 1)
        #expect(s.teams[0].wordsGuessed == 1)
        #expect(s.turnWords.count == 1)
        #expect(s.turnWords.first?.id != first.id, "a fresh word is on the table")
    }

    /// v1's arcade toggled isGuessed, so re-tapping subtracted the points again and
    /// counted the word as both guessed and skipped.
    @Test("the same word cannot be answered twice")
    func noDoubleScoring() throws {
        var s = try apply(game(mode: .arcade), [.beginTurn, .countdownFinished], at: t0)
        let word = try #require(s.turnWords.first)

        s = try apply(s, [.answer(wordID: word.id, outcome: .correct)], at: t0)
        #expect(s.teams[0].score == 1)

        let repeated = GameReducer.reduce(s, .answer(wordID: word.id, outcome: .correct), at: t0)
        #expect(repeated == .failure(.wordNotInPlay(word.id)))
    }

    @Test("a word that is not on the table is rejected")
    func unknownWord() throws {
        let s = try apply(game(), [.beginTurn, .countdownFinished], at: t0)
        #expect(GameReducer.reduce(s, .answer(wordID: "nope", outcome: .correct), at: t0)
                == .failure(.wordNotInPlay("nope")))
    }

    // MARK: - Arcade

    @Test("arcade deals five words and refills when the set is cleared")
    func arcadeSet() throws {
        var s = try apply(game(mode: .arcade), [.beginTurn, .countdownFinished], at: t0)
        #expect(s.turnWords.count == 5)

        for word in s.turnWords {
            s = try apply(s, [.answer(wordID: word.id, outcome: .correct)], at: t0)
        }
        #expect(s.teams[0].score == 5)
        #expect(s.turnWords.count == 5, "a fresh set is dealt once the last card is played")
        #expect(s.setIndex == 2)
    }

    @Test("skipping a set costs two points and deals a new one")
    func arcadeSkipSet() throws {
        var s = try apply(game(mode: .arcade), [.beginTurn, .countdownFinished], at: t0)
        let firstSet = Set(s.turnWords.map(\.id))

        s = try apply(s, [.skipSet], at: t0)
        #expect(s.teams[0].score == -2)
        #expect(s.teams[0].setsSkipped == 1)
        #expect(Set(s.turnWords.map(\.id)).isDisjoint(with: firstSet))
    }

    @Test("classic has no set to skip")
    func classicCannotSkipSet() throws {
        let s = try apply(game(mode: .classic), [.beginTurn, .countdownFinished], at: t0)
        #expect(GameReducer.reduce(s, .skipSet, at: t0) == .failure(.notAvailableInMode(.classic)))
    }

    // MARK: - Super words

    @Test("the super word scores three and is spent only when played")
    func superWordScoring() throws {
        // Classic, super word at position 1, so the very first word is it.
        var s = try apply(
            game(superWords: true, placement: SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)),
            [.beginTurn, .countdownFinished], at: t0)

        let word = try #require(s.turnWords.first)
        #expect(word.isSuperWord)
        let teamID = try #require(s.currentTeam?.id)
        #expect(s.superWordSpentBy.contains(teamID) == false, "not spent merely by being dealt")

        s = try apply(s, [.answer(wordID: word.id, outcome: .correct)], at: t0)
        #expect(s.teams[0].score == 3)
        #expect(s.teams[0].superWordsGuessed == 1)
        #expect(s.superWordSpentBy.contains(teamID), "spent once played")
    }

    @Test("a skipped super word costs three")
    func superWordSkipped() throws {
        var s = try apply(
            game(superWords: true, placement: SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)),
            [.beginTurn, .countdownFinished], at: t0)
        let word = try #require(s.turnWords.first)
        s = try apply(s, [.answer(wordID: word.id, outcome: .skipped)], at: t0)
        #expect(s.teams[0].score == -3)
    }

    @Test("no super word appears when the setting is off")
    func superWordsOff() throws {
        let s = try apply(
            game(superWords: false, placement: SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)),
            [.beginTurn, .countdownFinished], at: t0)
        #expect(s.turnWords.contains { $0.isSuperWord } == false)
    }

    // MARK: - Turn and round rotation

    @Test("time expiring ends the turn and passes to the next team")
    func turnRotation() throws {
        var s = try apply(game(rounds: 2, teams: 2), [.beginTurn, .countdownFinished], at: t0)
        #expect(s.currentTeamIndex == 0)

        s = try apply(s, [.timeExpired], at: t0)
        #expect(s.phase == .turnInfo)
        #expect(s.currentTeamIndex == 1)
        #expect(s.round == 1, "the round only advances once everyone has played")
        #expect(s.turnWords.isEmpty)

        s = try apply(s, [.beginTurn, .countdownFinished, .timeExpired], at: t0)
        #expect(s.currentTeamIndex == 0)
        #expect(s.round == 2)
    }

    @Test("the game finishes once every round is played and someone leads")
    func gameFinishes() throws {
        var s = game(rounds: 1, teams: 2)
        // Team 0 scores, team 1 does not.
        s = try apply(s, [.beginTurn, .countdownFinished], at: t0)
        let word = try #require(s.turnWords.first)
        s = try apply(s, [.answer(wordID: word.id, outcome: .correct), .timeExpired], at: t0)
        s = try apply(s, [.beginTurn, .countdownFinished, .timeExpired], at: t0)

        #expect(s.phase == .finished)
        #expect(GameRules.winner(s)?.name == "T0")
    }

    /// A tie must not end the game — it forces another full round for everyone.
    @Test("a tie forces an extra round instead of finishing")
    func tieForcesExtraRound() throws {
        var s = game(rounds: 1, teams: 2)
        for _ in 0..<2 {
            s = try apply(s, [.beginTurn, .countdownFinished], at: t0)
            let word = try #require(s.turnWords.first)
            s = try apply(s, [.answer(wordID: word.id, outcome: .correct), .timeExpired], at: t0)
        }
        #expect(s.teams[0].score == 1 && s.teams[1].score == 1)
        #expect(s.phase == .turnInfo, "still playing")
        #expect(s.round == 2)
        #expect(s.isExtraRound)
        #expect(s.extraRound == 1)
    }

    // MARK: - Deck exhaustion

    /// v1 let an exhausted deck award +1 per tap indefinitely, because nothing checked.
    @Test("a turn cannot begin once the deck is spent")
    func deckExhaustion() throws {
        var s = game(teams: 2, wordCount: 1)
        s = try apply(s, [.beginTurn, .countdownFinished], at: t0)
        let word = try #require(s.turnWords.first)
        s = try apply(s, [.answer(wordID: word.id, outcome: .correct)], at: t0)
        #expect(s.turnWords.isEmpty, "nothing left to deal")

        s = try apply(s, [.timeExpired], at: t0)
        #expect(GameReducer.reduce(s, .beginTurn, at: t0) == .failure(.deckExhausted))
    }

    // MARK: - Rematch

    @Test("a rematch clears scores but keeps the teams")
    func rematch() throws {
        var s = game(rounds: 1, teams: 2)
        s = try apply(s, [.beginTurn, .countdownFinished], at: t0)
        let word = try #require(s.turnWords.first)
        s = try apply(s, [.answer(wordID: word.id, outcome: .correct), .timeExpired], at: t0)
        s = try apply(s, [.beginTurn, .countdownFinished, .timeExpired], at: t0)
        #expect(s.phase == .finished)

        let ids = s.teams.map(\.id)
        s = try apply(s, [.rematch], at: t0)
        #expect(s.phase == .turnInfo)
        #expect(s.round == 1)
        #expect(s.teams.allSatisfy { $0.score == 0 })
        #expect(s.teams.map(\.id) == ids, "same teams, same identities")
    }

    // MARK: - Persistence

    /// An in-progress game survives being killed. v1 held everything in a singleton and
    /// persisted none of it.
    @Test("state round-trips through Codable")
    func codableRoundTrip() throws {
        let s = try apply(game(mode: .arcade, superWords: true), [.beginTurn, .countdownFinished], at: t0)
        let data = try JSONEncoder().encode(s)
        let restored = try JSONDecoder().decode(GameState.self, from: data)
        #expect(restored == s)
    }
}

@Suite("Undoing a mistaken answer")
struct UndoTests {

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func arcadeGame(superWords: Bool = false) -> GameState {
        GameState(
            settings: GameSettings(mode: .arcade, superWordsEnabled: superWords),
            teams: [Team(name: "A"), Team(name: "B")],
            deck: Deck(words: (0..<40).map { DeckWord(id: "\($0)", text: "w\($0)") }),
            placement: SuperWordPlacement(classicPosition: 1, arcadeSet: 1, arcadeSlot: 1)
        )
    }

    private func started(_ state: GameState) throws -> GameState {
        var s = try GameReducer.reduce(state, .beginTurn, at: t0).get()
        s = try GameReducer.reduce(s, .countdownFinished, at: t0).get()
        return s
    }

    /// The behaviour v1 got wrong. Re-tapping there scored the word as *skipped*, so one
    /// word counted as both guessed and skipped and the streak broke on a correct answer.
    @Test("undo reverses the play instead of applying the opposite one")
    func undoIsNotAToggle() throws {
        var s = try started(arcadeGame())
        let word = try #require(s.turnWords.first)

        s = try GameReducer.reduce(s, .answer(wordID: word.id, outcome: .correct), at: t0).get()
        #expect(s.teams[0].score == 1)
        #expect(s.teams[0].wordsGuessed == 1)
        #expect(s.teams[0].currentStreak == 1)

        s = try GameReducer.reduce(s, .undoAnswer(wordID: word.id), at: t0).get()
        #expect(s.teams[0].score == 0)
        #expect(s.teams[0].wordsGuessed == 0)
        #expect(s.teams[0].wordsSkipped == 0, "undo must not count the word as skipped")
        #expect(s.teams[0].currentStreak == 0)
        #expect(s.playedWordIDs.contains(word.id) == false, "the word is back in play")
    }

    @Test("an undone word can be answered again")
    func replayAfterUndo() throws {
        var s = try started(arcadeGame())
        let word = try #require(s.turnWords.first)

        s = try GameReducer.reduce(s, .answer(wordID: word.id, outcome: .correct), at: t0).get()
        s = try GameReducer.reduce(s, .undoAnswer(wordID: word.id), at: t0).get()
        s = try GameReducer.reduce(s, .answer(wordID: word.id, outcome: .correct), at: t0).get()

        #expect(s.teams[0].score == 1, "scored once, not twice")
        #expect(s.teams[0].wordsGuessed == 1)
    }

    /// A mistaken tap must not cost the team their one super word for the round.
    @Test("undoing a super word returns the allowance")
    func superWordAllowanceReturned() throws {
        var s = try started(arcadeGame(superWords: true))
        let superWord = try #require(s.turnWords.first { $0.isSuperWord })
        let teamID = try #require(s.currentTeam?.id)

        s = try GameReducer.reduce(s, .answer(wordID: superWord.id, outcome: .correct), at: t0).get()
        #expect(s.teams[0].score == 3)
        #expect(s.superWordSpentBy.contains(teamID))

        s = try GameReducer.reduce(s, .undoAnswer(wordID: superWord.id), at: t0).get()
        #expect(s.teams[0].score == 0)
        #expect(s.teams[0].superWordsGuessed == 0)
        #expect(s.superWordSpentBy.contains(teamID) == false, "the allowance comes back")
    }

    @Test("undoing something never played is refused")
    func undoUnknown() throws {
        let s = try started(arcadeGame())
        let word = try #require(s.turnWords.first)
        #expect(GameReducer.reduce(s, .undoAnswer(wordID: word.id), at: t0)
                == .failure(.wordNotInPlay(word.id)))
        #expect(GameReducer.reduce(s, .undoAnswer(wordID: "nope"), at: t0)
                == .failure(.wordNotInPlay("nope")))
    }

    @Test("undoing a skip removes the penalty and the skip count")
    func undoASkip() throws {
        var s = try started(arcadeGame())
        let word = try #require(s.turnWords.first)

        s = try GameReducer.reduce(s, .answer(wordID: word.id, outcome: .skipped), at: t0).get()
        #expect(s.teams[0].score == -1)
        #expect(s.teams[0].wordsSkipped == 1)

        s = try GameReducer.reduce(s, .undoAnswer(wordID: word.id), at: t0).get()
        #expect(s.teams[0].score == 0)
        #expect(s.teams[0].wordsSkipped == 0)
    }
}
