//
//  ReviewPromptTests.swift
//  GamoitsaniCoreTests
//

import Foundation
import Testing
@testable import GamoitsaniCore

@Suite("Review prompt")
struct ReviewPromptTests {

    private let now = Date(timeIntervalSince1970: 1_000_000)
    private let policy = ReviewPromptPolicy()

    @Test("a first-time player is not asked")
    func warmUp() {
        for played in 0..<policy.gamesBeforeFirstPrompt {
            let state = ReviewPromptState(gamesFinished: played)
            #expect(!policy.allowsPrompt(state, at: now), "asked after \(played) games")
        }
    }

    /// The bug this mirrors is v1's, where the prompt was gated on a counter that was read
    /// but never written — so it sat at zero and the sheet never appeared once in the life
    /// of the app.
    @Test("a real player actually reaches the sheet")
    func itFires() {
        let state = ReviewPromptState(gamesFinished: policy.gamesBeforeFirstPrompt)
        #expect(policy.allowsPrompt(state, at: now))
    }

    @Test("asking again needs both more games and more time")
    func spacing() {
        var state = ReviewPromptState(gamesFinished: 3)
        state = policy.prompted(state, at: now)

        // Immediately after: neither gate is open.
        #expect(!policy.allowsPrompt(state, at: now))

        // Enough games, not enough time.
        state.gamesFinished += policy.gamesBetweenPrompts
        #expect(!policy.allowsPrompt(state, at: now + policy.minimumInterval - 1))

        // Enough time, not enough games.
        var stale = policy.prompted(ReviewPromptState(gamesFinished: 3), at: now)
        stale.gamesFinished += policy.gamesBetweenPrompts - 1
        #expect(!policy.allowsPrompt(stale, at: now + policy.minimumInterval))

        // Both.
        #expect(policy.allowsPrompt(state, at: now + policy.minimumInterval))
    }

    @Test("it stops for good after the ceiling")
    func ceiling() {
        var state = ReviewPromptState(gamesFinished: 3)
        var clock = now

        for ask in 1...policy.maximumPrompts {
            #expect(policy.allowsPrompt(state, at: clock), "stopped after \(ask - 1) asks")
            state = policy.prompted(state, at: clock)
            clock += policy.minimumInterval
            state.gamesFinished += policy.gamesBetweenPrompts
        }

        #expect(!policy.allowsPrompt(state, at: clock))
        #expect(!policy.allowsPrompt(state, at: clock.addingTimeInterval(10 * 365 * 24 * 3600)))
    }

    @Test("a replayed prompt count cannot wrap back into asking")
    func clamped() {
        var state = ReviewPromptState(gamesFinished: 999, promptCount: policy.maximumPrompts + 500)
        state = policy.prompted(state, at: now)

        #expect(state.promptCount == policy.maximumPrompts)
        #expect(!policy.allowsPrompt(state, at: now + 10 * 365 * 24 * 3600))
    }

    @Test("the debug policy asks immediately and keeps asking")
    func unrestricted() {
        let policy = ReviewPromptPolicy.unrestricted
        var state = ReviewPromptState()
        #expect(policy.allowsPrompt(state, at: now))

        state = policy.prompted(state, at: now)
        #expect(policy.allowsPrompt(state, at: now))
    }

    /// It is persisted, so it survives an upgrade only if it round-trips.
    @Test("state survives a save and load")
    func codable() throws {
        let state = ReviewPromptState(
            gamesFinished: 12,
            lastPromptedAt: now,
            gamesAtLastPrompt: 3,
            promptCount: 1
        )
        let data = try JSONEncoder().encode(state)
        #expect(try JSONDecoder().decode(ReviewPromptState.self, from: data) == state)
    }
}
