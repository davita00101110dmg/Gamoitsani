//
//  GameDetailsModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

typealias GameDetailsSnapshot = NSDiffableDataSourceSnapshot<Int, GameDetailsTeamCellItem>

struct GameDetailsTeamCellItem: Hashable {
    let id = UUID()
    var name: String
}
