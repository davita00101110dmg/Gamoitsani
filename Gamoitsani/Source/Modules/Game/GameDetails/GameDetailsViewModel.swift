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

protocol GameDetailsViewModelDelegate: AnyObject {
    func applySnapshot(_ snapshot: GameDetailsSnapshot, animatingDifferences: Bool)
}

final class GameDetailsViewModel: ObservableObject {
    
    init() {
        configureDataSource()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    private let networkMonitor = NWPathMonitor()
    private var shouldFetchWordsFromServer = true
    
    @Published private var teams: [GameDetailsTeamCellItem] = []
    private var subscribers = Set<AnyCancellable>()
    private var snapshot: GameDetailsSnapshot?
    
    weak var delegate: GameDetailsViewModelDelegate?
    
    private func configureDataSource() {
        teamsPublished
            .sink { [weak self] items in
                guard let self else { return }
                
                self.snapshot = GameDetailsSnapshot()
                self.snapshot?.appendSections([0])
                self.snapshot?.appendItems(items)
                
                if let snapshot {
                    self.delegate?.applySnapshot(snapshot, animatingDifferences: true)
                }
                
            }.store(in: &subscribers)
    }
    
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
    
    func fetchWordsFromServer() {
        if shouldFetchWordsFromServer {
            FirebaseManager.shared.fetchWords { words in
                let savedCount = CoreDataManager.shared.saveWordsFromFirebase(words)
                dump("Saved \(savedCount) words to Core Data")
                
                GameStory.shared.words = CoreDataManager.shared.fetchWordsFromCoreData()
            }
        } else {
            GameStory.shared.words = CoreDataManager.shared.fetchWordsFromCoreData()
        }
    }
    
    func observeNetworkConnection() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            
            shouldFetchWordsFromServer = path.status == .satisfied
        }
        
        let queue = DispatchQueue(label: ViewModelConstants.networkObserverThreadName)
        networkMonitor.start(queue: queue)
    }
}

extension GameDetailsViewModel {
    enum ViewModelConstants {
        static let networkObserverThreadName: String = "NetworkMonitor"
    }
}
