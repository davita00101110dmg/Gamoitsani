//
//  Route.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import Foundation

enum Route: Hashable {
    case home
    case rules
    case gameDetails
    case game(GameStory)
    case addWord

    // Hash implementation for NavigationPath
    func hash(into hasher: inout Hasher) {
        switch self {
        case .home:
            hasher.combine("home")
        case .rules:
            hasher.combine("rules")
        case .gameDetails:
            hasher.combine("gameDetails")
        case .game:
            hasher.combine("game")
        case .addWord:
            hasher.combine("addWord")
        }
    }

    // Equatable implementation
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.home, .home),
             (.rules, .rules),
             (.gameDetails, .gameDetails),
             (.game, .game),
             (.addWord, .addWord):
            return true
        default:
            return false
        }
    }
}
