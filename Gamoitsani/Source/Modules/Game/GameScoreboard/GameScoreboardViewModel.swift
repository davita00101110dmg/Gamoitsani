//
//  GameScoreboardViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class GameScoreboardViewModel {
    @Published var teams: [GameTeamCellItem] = []
    
    var teamsPublished: AnyPublisher<[GameTeamCellItem], Never> {
        $teams.eraseToAnyPublisher()
    }
    
    func fetchTeams() {
        teams = GameStory.shared.teams.map { .init(name: $0.key, score: $0.value) }
    }
}
