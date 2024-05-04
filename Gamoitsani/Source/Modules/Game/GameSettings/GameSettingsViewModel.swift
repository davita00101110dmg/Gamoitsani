//
//  GameSettingsViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class GameSettingsViewModel {
    
    @Published private var teams = [GameSettingsCellItem]()
    
    var gameSettingsMode: GameSettingsModel?
    
    var teamsPublished: Published<[GameSettingsCellItem]>.Publisher { $teams }
    
    func addTeam(with teamMembers: String...) {
        teams.append(.teams(model: .init(id: UUID(), firstMemberName: teamMembers[0], secondMemberName: teamMembers[1], score: 0), id: UUID()))
    }
    
    func getTeamsCount() -> Int {
        teams.count
    }
    
    func remove(at index: Int) {
        teams.remove(at: index)
    }
    
    func removeLastTeam() {
        teams.removeLast()
    }
}
