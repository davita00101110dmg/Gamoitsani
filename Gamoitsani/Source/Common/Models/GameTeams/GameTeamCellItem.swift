//
//  GameTeamCellItem.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

struct GameTeamCellItem: Hashable {
    let id = UUID()
    var name: String
    var score: Int
}
