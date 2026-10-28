//
//  TestSupport.swift
//  GameCoreTests
//

import Testing
import Foundation
@testable import GameCore

/// A clock that only moves when a test moves it.
final class ManualClock: GameClock, @unchecked Sendable {
    private let lock = NSLock()
    private var current: Date

    init(_ start: Date) { current = start }

    func now() -> Date {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        current = current.addingTimeInterval(seconds)
    }
}

// `SeededGenerator` comes with the ported `DeckTests.swift`.

enum Fixture {
    static let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    static func words(_ count: Int, from start: Int = 0) -> [DeckWord] {
        (start..<(start + count)).map { DeckWord(id: "\($0)", text: "word\($0)") }
    }

    /// Fixed ids, so two games built the same way are equal.
    static func teams(_ count: Int, members: [String] = []) -> [Team] {
        (0..<count).map { index in
            Team(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012ld", index))!,
                name: "T\(index)",
                members: members
            )
        }
    }

    static func runner(
        mode: GameMode = .classic,
        rounds: Int = 1,
        roundLength: TimeInterval = 60,
        teams: Int = 2,
        words: Int = 200,
        superWords: Bool = false,
        challenges: Bool = false,
        seed: UInt64 = 7
    ) -> (GameRunner, ManualClock) {
        let clock = ManualClock(t0)
        let runner = GameRunner(
            settings: GameSettings(
                rounds: rounds,
                roundLength: roundLength,
                mode: mode,
                superWordsEnabled: superWords,
                challengesEnabled: challenges
            ),
            teams: Fixture.teams(teams),
            deck: Deck(words: Fixture.words(words)),
            clock: clock,
            random: SeededGenerator(seed: seed)
        )
        return (runner, clock)
    }
}

extension GameRunner {

    /// Turn info, through the countdown, to a running clock.
    mutating func startTurn(sourceLocation: SourceLocation = #_sourceLocation) {
        let began = send(.beginTurn)
        #expect(began, "beginTurn refused: \(String(describing: lastRejection))",
                sourceLocation: sourceLocation)
        let started = send(.countdownFinished)
        #expect(started, sourceLocation: sourceLocation)
    }

    /// Answers the first word on the table and returns it, or nil when the table is empty.
    @discardableResult
    mutating func answerNext(_ outcome: PlayOutcome) -> DeckWord? {
        guard let word = wordsInPlay.first else { return nil }
        return send(.answer(wordID: word.id, outcome: outcome)) ? word : nil
    }

    /// Lets the round's clock run out and ends the turn.
    mutating func runOutClock(_ clock: ManualClock, sourceLocation: SourceLocation = #_sourceLocation) {
        clock.advance(by: remainingTime)
        let expired = checkExpiry()
        #expect(expired, sourceLocation: sourceLocation)
    }

    /// One whole turn: start, answer each outcome in order, then time runs out.
    mutating func playTurn(_ outcomes: [PlayOutcome], clock: ManualClock) {
        startTurn()
        for outcome in outcomes { answerNext(outcome) }
        runOutClock(clock)
    }
}
