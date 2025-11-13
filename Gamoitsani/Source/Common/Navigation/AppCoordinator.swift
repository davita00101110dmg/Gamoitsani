//
//  AppCoordinator.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

final class AppCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreen: FullScreenDestination?

    // MARK: - Sheet Destinations

    enum SheetDestination: Identifiable {
        case settings
        case gameScoreboard(GameStory)
        case gameShare(GameStory)

        var id: String {
            switch self {
            case .settings:
                return "settings"
            case .gameScoreboard:
                return "gameScoreboard"
            case .gameShare:
                return "gameShare"
            }
        }
    }

    // MARK: - Full Screen Destinations

    enum FullScreenDestination: Identifiable {
        case game(GameStory)

        var id: String {
            switch self {
            case .game:
                return "game"
            }
        }
    }

    // MARK: - Navigation Methods

    func push(_ route: Route) {
        path.append(route)
    }

    func pop() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }

    func presentSheet(_ destination: SheetDestination) {
        presentedSheet = destination
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func presentFullScreen(_ destination: FullScreenDestination) {
        presentedFullScreen = destination
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }
}
