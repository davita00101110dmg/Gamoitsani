//
//  Router.swift
//  Gamoitsani2
//

import Observation
import SwiftUI

/// Owns the navigation path.
///
/// `@MainActor` because it drives UI, and under Swift 6 language mode that is enforced by
/// the compiler rather than assumed. Views read and mutate this directly; there is no
/// delegate chain and no coordinator lifetime to manage.
@MainActor
@Observable
final class Router {
    var path: [Route] = []

    func push(_ route: Route) {
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
