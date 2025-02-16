//
//  GameOverViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

struct GameOverViewModel {
    let teams: [Team]
    
    init(teams: [Team]) {
        self.teams = teams.sorted { $0.score > $1.score }
    }
}
