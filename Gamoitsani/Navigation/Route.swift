//
//  Route.swift
//  Gamoitsani
//
import Foundation

/// Every destination the app can navigate to, as one closed set.
public enum Route: Hashable {
    /// The game flow. Setup is the root, so it is not a route.
    case game
    case settings
}
