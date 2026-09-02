//
//  RoundTimer.swift
//  GamoitsaniEngine
//

import Foundation

/// Deadline-based round timing.
///
/// Stores an end date and derives everything from it. v1 ran **two unsynchronised timers**:
/// `Timer.publish(every: duration).first()` decided when the round actually ended, while a
/// separate 1-second publisher decremented a `timeRemaining` counter for display. Nothing
/// kept them in step, so the number on screen and the real end could drift apart.
///
/// Deriving from a deadline also makes backgrounding correct rather than accidental. v1
/// handles the scene phase nowhere, and because `Timer.publish` does not fire while
/// suspended, backgrounding silently *paused* the round and handed the time back — you
/// could stop the clock by swiping up. Here the deadline is wall-clock, so time spent
/// suspended is time spent, and the UI only has to re-read on resume.
public struct RoundTimer: Sendable, Hashable, Codable {

    public let startedAt: Date
    public let endsAt: Date

    public init(startingAt start: Date, duration: TimeInterval) {
        precondition(duration > 0, "a round must have a positive duration")
        self.startedAt = start
        self.endsAt = start.addingTimeInterval(duration)
    }

    public var duration: TimeInterval {
        endsAt.timeIntervalSince(startedAt)
    }

    /// Seconds left, never negative.
    public func remaining(at now: Date) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(now))
    }

    public func hasExpired(at now: Date) -> Bool {
        now >= endsAt
    }

    /// 0 at the start, 1 at the deadline. For progress rings and colour ramps.
    public func progress(at now: Date) -> Double {
        guard duration > 0 else { return 1 }
        return min(1, max(0, now.timeIntervalSince(startedAt) / duration))
    }

    /// Whether the clock is in its final seconds, which the UI signals with colour and
    /// haptics.
    ///
    /// v1 signalled this with a shake. That is the one motion Reduce Motion has to
    /// *replace* rather than remove, or the warning disappears entirely for anyone with
    /// the setting on — hence colour plus haptic as the primary cue.
    public func isUrgent(at now: Date, threshold: TimeInterval = 5) -> Bool {
        !hasExpired(at: now) && remaining(at: now) <= threshold
    }
}
