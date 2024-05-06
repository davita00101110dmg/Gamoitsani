//
//  GameSettingsViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine
import Collections

final class GameSettingsViewModel {
    
    @Published private var teams: [GameSettingsCellItem] = []
    
    var teamsPublished: Published<[GameSettingsCellItem]>.Publisher { $teams }
    
    private var teamStrings: [String] = [] {
        didSet {
            updateTeams()
        }
    }
    
    func addTeam(with team: String) {
        teamStrings.append(team)
    }
    
    func remove(at index: Int) {
        teamStrings.remove(at: index)
    }
    
    func removeLastTeam() {
        teamStrings.removeLast()
    }
    
    func clearTeams() {
        teamStrings.removeAll()
    }
    
    func getTeamsCount() -> Int {
        teamStrings.count
    }
    
    func areTeamsUniques() -> Bool {
        Set(teamStrings).count == teamStrings.count
    }
    
    func getTeams() -> [String] {
        teamStrings
    }
    
    func getTeamsDictionary() -> OrderedDictionary<String, Int> {
        .init(uniqueKeysWithValues: teamStrings.map { ($0, 0) })
    }
    
    private func updateTeams() {
        teams = teamStrings.map { GameSettingsCellItem.teams(model: .init(id: UUID(), team: $0), id: UUID()) }
    }
    
}
