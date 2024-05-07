//
//  GameSettingsModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

typealias GameSettingsSnapshot = NSDiffableDataSourceSnapshot<Int, GameSettingsTeamCellItem>

struct GameSettingsTeamCellItem: Hashable {
    let id = UUID()
    var name: String
}
