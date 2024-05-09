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
    
    @Published private var teams: [GameSettingsTeamCellItem] = []
    
    var teamsPublished: Published<[GameSettingsTeamCellItem]>.Publisher { $teams }
    
    func addTeam(with team: String) {
        teams.append(.init(name: team))
    }
    
    func updateTeam(at index: Int, with newTeam: String) {
        guard teams.indices.contains(index) else { return }
        teams[index].name = newTeam
    }
    
    func getTeam(at index: Int) -> String? {
        guard teams.indices.contains(index) else { return nil }
        return teams[index].name
    }
    
    func getTeamsCount() -> Int {
        teams.count
    }
    
    func teamsAreUnique() -> Bool {
        let teamNames = teams.map { $0.name }
        return Set(teamNames).count != teamNames.count
    }
    
    func getTeamsDictionary() -> OrderedDictionary<String, Int> {
        .init(uniqueKeysWithValues: teams.map { ($0.name, 0) })
    }
    
    @discardableResult
    func remove(at index: Int) -> String? {
        guard teams.indices.contains(index) else { return nil }
        teams.swapAt(index, teams.count - 1)
        return teams.popLast()?.name
    }
    
    func updateOrder(with newOrderTeams: [GameSettingsTeamCellItem]) {
        teams = newOrderTeams
    }
    
    func fetchWords() {
        FirebaseManager.shared.fetchWords { words in
            GameStory.shared.words = words
        }
    }
}
