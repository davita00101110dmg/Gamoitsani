//
//  RoundTimer.swift
//  GamoitsaniEngine
//
import Foundation

/// Deadline-based round timing.
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
    public func isUrgent(at now: Date, threshold: TimeInterval = 5) -> Bool {
        !hasExpired(at: now) && remaining(at: now) <= threshold
    }
}
