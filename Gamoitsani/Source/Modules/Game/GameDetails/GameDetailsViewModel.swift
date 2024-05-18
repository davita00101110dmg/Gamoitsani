//
//  GameDetailsViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 03/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine
import Collections
import Network

final class GameDetailsViewModel {
    
    private let networkMonitor = NWPathMonitor()
    private var shouldFetchWords = true
    
    @Published private var teams: [GameDetailsTeamCellItem] = []
    
    var teamsPublished: Published<[GameDetailsTeamCellItem]>.Publisher { $teams }
    
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
    
    func updateOrder(with newOrderTeams: [GameDetailsTeamCellItem]) {
        teams = newOrderTeams
    }
    
    func fetchWords() {
        FirebaseManager.shared.fetchWords { words in
            GameStory.shared.words = words
        }
    }
    
    func observeNetworkConnection() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            shouldFetchWords = path.status == .satisfied
        
            if path.status == .satisfied && GameStory.shared.words.isEmpty {
                // TODO: Test when i will have at least 500 elements in DB
                fetchWords()
            }
        }
        
        let queue = DispatchQueue(label: ViewModelConstants.networkObserverThreadName)
        networkMonitor.start(queue: queue)
    }
    
    func hasNetworkConnection() -> Bool {
        shouldFetchWords
    }
}

extension GameDetailsViewModel {
    enum ViewModelConstants {
        static let networkObserverThreadName: String = "NetworkMonitor"
    }
}
