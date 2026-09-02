//
//  Route.swift
//  Gamoitsani2
//

import Foundation

/// Every destination the app can navigate to, as one closed set.
///
/// v1 used 8 coordinator classes plus `BaseCoordinator`, `BaseViewController` and six
/// copies of UIHostingController boilerplate to express this. All of that is deleted: a
/// typed enum plus `NavigationStack` covers the same ground, and because there is no
/// parent/child coordinator object graph there is nothing to retain — which removes the
/// entire leak class rather than fixing its instances.
public enum Route: Hashable {
    /// The game flow. Setup is the root, so it is not a route.
    case game
    case addWord
    case settings
}
