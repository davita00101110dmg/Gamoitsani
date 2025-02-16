//
//  GameScoreboardViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class GameScoreboardViewModel: ObservableObject {
    @Published private(set) var teams: [Team] = []
    @Published private(set) var winningTeam: Team?
    @Published private(set) var selectedTeamId: UUID?
    
    private var gameStory = GameStory.shared
    
    init() {
        fetchTeams()
        if !gameStory.isGameInProgress {
            winningTeam = findWinningTeam()
            selectedTeamId = winningTeam?.id ?? teams.first?.id
        }
    }
    
    func fetchTeams() {
        teams = gameStory.teams.sorted { $0.score > $1.score }
    }
    
    private func findWinningTeam() -> Team? {
        guard let firstTeam = teams.first else { return nil }
        let tiedTeams = teams.filter { $0.score == firstTeam.score }
        return tiedTeams.count > 1 ? nil : firstTeam
    }
    
    func selectTeam(_ teamId: UUID) {
        selectedTeamId = teamId
    }
}
