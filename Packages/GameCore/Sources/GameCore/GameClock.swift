//
//  GameClock.swift
//  GameCore
//
import Foundation

/// Where a game reads the time. Wall-clock on purpose: a round's deadline is a `Date`,
/// so it keeps running while the app is suspended and goes to disk with the game.
public protocol GameClock: Sendable {
    func now() -> Date
}

/// The real clock.
public struct SystemClock: GameClock {
    public init() {}
    public func now() -> Date { Date() }
}
