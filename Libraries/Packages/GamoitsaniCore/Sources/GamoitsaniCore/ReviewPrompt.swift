//
//  ReviewPrompt.swift
//  GamoitsaniCore
//
import Foundation

/// What the app remembers about asking for a review.
///
/// Persisted, because the whole point is not asking the same person again next week.
public struct ReviewPromptState: Sendable, Hashable, Codable {
    /// Games finished on this install, ever.
    public var gamesFinished: Int
    /// When the sheet was last requested.
    public var lastPromptedAt: Date?
    /// `gamesFinished` at that moment.
    ///
    /// Stored rather than derived: `gamesFinished` is a running total, so "ten games since
    /// the last ask" has to be measured against a mark.
    public var gamesAtLastPrompt: Int
    /// How many times it has been requested.
    public var promptCount: Int

    public init(
        gamesFinished: Int = 0,
        lastPromptedAt: Date? = nil,
        gamesAtLastPrompt: Int = 0,
        promptCount: Int = 0
    ) {
        self.gamesFinished = gamesFinished
        self.lastPromptedAt = lastPromptedAt
        self.gamesAtLastPrompt = gamesAtLastPrompt
        self.promptCount = promptCount
    }
}

/// When to ask for an App Store review.
///
/// v1 had this and it never once fired: the prompt required
/// `finishedGamesCountInSession >= 3`, and that counter was read but never written, so it
/// sat at zero for the life of the app. Every rule here runs off a count this type is
/// handed directly, and a test walks a plausible player all the way to the sheet.
///
/// iOS decides whether a sheet actually appears and allows at most three a year, so a
/// badly timed ask does not annoy someone twice — it spends one of three chances. That is
/// what the spacing rules protect.
public struct ReviewPromptPolicy: Sendable, Hashable {

    /// Games finished before the first ask. A first-time player has not seen enough of the
    /// app to have an opinion worth collecting.
    public var gamesBeforeFirstPrompt: Int

    /// Games that must pass between asks.
    public var gamesBetweenPrompts: Int

    /// And a wall-clock floor, so one long evening of short games cannot spend every
    /// chance in a single sitting.
    public var minimumInterval: TimeInterval

    /// Never ask more than this.
    public var maximumPrompts: Int

    public init(
        gamesBeforeFirstPrompt: Int = 3,
        gamesBetweenPrompts: Int = 10,
        minimumInterval: TimeInterval = 60 * 60 * 24 * 90,
        maximumPrompts: Int = 3
    ) {
        self.gamesBeforeFirstPrompt = gamesBeforeFirstPrompt
        self.gamesBetweenPrompts = gamesBetweenPrompts
        self.minimumInterval = minimumInterval
        self.maximumPrompts = maximumPrompts
    }

    /// Every gate removed, for the debug menu.
    public static let unrestricted = ReviewPromptPolicy(
        gamesBeforeFirstPrompt: 0,
        gamesBetweenPrompts: 0,
        minimumInterval: 0,
        maximumPrompts: .max
    )

    /// Whether to ask right now.
    public func allowsPrompt(_ state: ReviewPromptState, at now: Date) -> Bool {
        guard state.promptCount < maximumPrompts else { return false }
        guard state.gamesFinished >= gamesBeforeFirstPrompt else { return false }

        if let last = state.lastPromptedAt {
            guard now.timeIntervalSince(last) >= minimumInterval else { return false }
        }
        if state.promptCount > 0 {
            let since = state.gamesFinished - state.gamesAtLastPrompt
            guard since >= gamesBetweenPrompts else { return false }
        }
        return true
    }

    /// Records that the sheet was requested. Clamped, so a replayed count cannot overflow
    /// past the ceiling and wrap back into asking.
    public func prompted(_ state: ReviewPromptState, at now: Date) -> ReviewPromptState {
        var result = state
        result.promptCount = min(state.promptCount + 1, maximumPrompts)
        result.lastPromptedAt = now
        result.gamesAtLastPrompt = state.gamesFinished
        return result
    }
}
