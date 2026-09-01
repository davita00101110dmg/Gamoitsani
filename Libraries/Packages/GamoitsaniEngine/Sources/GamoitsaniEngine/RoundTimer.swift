//
//  RoundTimer.swift
//  GamoitsaniEngine
//

import Foundation

/// Deadline-based round timing.
///
/// Stores an end date and derives the remaining time, rather than decrementing a tick
/// counter as v1 did with two unsynchronised timers. Deriving from a deadline makes
/// backgrounding correct for free: no ticks are missed while suspended because none are
/// counted. Phase 5 wires this to the engine and `scenePhase`.
public struct RoundTimer: Sendable, Equatable {
    public let endDate: Date
    public let duration: TimeInterval

    public init(startingAt start: Date = Date(), duration: TimeInterval) {
        self.duration = duration
        self.endDate = start.addingTimeInterval(duration)
    }

    public func remaining(at now: Date = Date()) -> TimeInterval {
        max(0, endDate.timeIntervalSince(now))
    }

    public func hasExpired(at now: Date = Date()) -> Bool {
        remaining(at: now) <= 0
    }
}
