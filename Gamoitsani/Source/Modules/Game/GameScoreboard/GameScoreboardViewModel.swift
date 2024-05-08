//
//  GameScoreboardViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

final class GameScoreboardViewModel {
    @Published var teams: [GameScoreboardTeamCellItem] = []
    
    var teamsPublished: Published<[GameScoreboardTeamCellItem]>.Publisher { $teams }
    
    func fetchTeams() {
        teams = GameStory.shared.teams.map { .init(name: $0.key, score: $0.value) }
    }
}
