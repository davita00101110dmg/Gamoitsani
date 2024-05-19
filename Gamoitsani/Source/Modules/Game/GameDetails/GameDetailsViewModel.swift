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
    
    deinit {
        networkMonitor.cancel()
    }
    
    private let networkMonitor = NWPathMonitor()
    private var shouldFetchWords = true
    
    @Published private var teams: [GameDetailsTeamCellItem] = []
    
    var teamsPublished: AnyPublisher<[GameDetailsTeamCellItem], Never> {
        $teams.eraseToAnyPublisher()
    }
    
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
    
    func remove(at index: Int) {
        guard teams.indices.contains(index) else { return }
        teams.remove(at: index)
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
