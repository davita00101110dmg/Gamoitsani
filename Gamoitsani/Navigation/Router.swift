//
//  Router.swift
//  Gamoitsani
//
import Observation
import SwiftUI

/// Owns the navigation path.
@MainActor
@Observable
final class Router {
    var path: [Route] = []

    /// Ignores a repeat of whatever is already on top. Two taps landing either side of an
    /// await would otherwise stack the same screen twice, and popping once would leave the
    /// player on a second copy of it.
    func push(_ route: Route) {
        guard path.last != route else { return }
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }
}
