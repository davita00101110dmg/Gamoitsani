//
//  GameSettingsModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

typealias GameSettingsDataSource = UITableViewDiffableDataSource<Int, GameSettingsCellItem>
typealias GameSettingsSnapshot = NSDiffableDataSourceSnapshot<Int, GameSettingsCellItem>

struct GameSettingsModel {
    let numberOfRounds: Int
    let lengthOfRound: Double
    let words: [String]
    
    var currentRound: Int = 1
    var teams: [String: Int]
}

enum GameSettingsCellItem: Hashable, Equatable {
    case teams(model: GameSettingsTeamTableViewCellModel, id: UUID = UUID())
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .teams(_, let id):
            hasher.combine(id)
        }
    }
    
    static func == (lhs: GameSettingsCellItem, rhs: GameSettingsCellItem) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

