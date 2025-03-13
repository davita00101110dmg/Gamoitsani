//
//  GameModels.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum GameModels {
    enum GameState {
        case info
        case countdown
        case play
        case gameOver
    }
}

enum GameMode: String, CaseIterable {
    case classic
    case arcade
    
    var title: String {
        switch self {
        case .classic:
            return L10n.Screen.GameDetails.Classic.title
        case .arcade:
            return L10n.Screen.GameDetails.Arcade.title
        }
    }
    
    var description: String {
        switch self {
        case .classic:
            return L10n.Screen.GameDetails.Classic.description
        case .arcade:
            return L10n.Screen.GameDetails.Arcade.description
        }
    }
    
    var skipPenalty: Int {
        switch self {
        case .classic:
            return 0
        case .arcade:
            return -2
        }
    }
}
