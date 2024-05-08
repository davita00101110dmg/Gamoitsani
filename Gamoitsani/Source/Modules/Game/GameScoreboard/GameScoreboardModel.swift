//
//  GameScoreboardModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

typealias GameScoreboardSnapshot = NSDiffableDataSourceSnapshot<Int, GameScoreboardTeamCellItem>
typealias GameScoreboardDataSource = UITableViewDiffableDataSource<Int, GameScoreboardTeamCellItem>

struct GameScoreboardTeamCellItem: Hashable {
    let id = UUID()
    var name: String
    var score: Int
}
