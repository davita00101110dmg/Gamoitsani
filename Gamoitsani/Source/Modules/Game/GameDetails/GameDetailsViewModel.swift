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
import SwiftUI

final class GameDetailsViewModel: ObservableObject {
    @Published var roundsAmount: Double = GameDetailsConstants.Game.defaultRoundsAmount
    @Published var roundsLength: Double = GameDetailsConstants.Game.defaultRoundLength
    @Published var selectedGameMode: GameMode = .classic
    
    @Published var currentAlert: AlertType?
    @Published var teamSectionMode: GameDetailsTeamSectionMode = .teams
    @Published var areWordsLoading = false
    @Published private var collection = GameDetailsTeamSectionMode.Collection(teams: [], players: [])
    
    @Published var isSuperWordEnabled: Bool = false
    @Published var isRandomChallengeEnabled: Bool = false
    
    var teams: [GameDetailsTeam] { collection.teams }
    var players: [GameDetailsPlayer] { collection.players }
    
    var canStartGame: Bool {
        switch teamSectionMode {
        case .teams:
            return teams.count >= GameDetailsConstants.Game.minimumTeams
        case .players:
            return players.count >= GameDetailsConstants.Game.minimumPlayers
        }
    }
    
    private let networkMonitor = NWPathMonitor()
    private var shouldFetchWordsFromServer = true
    private var subscribers = Set<AnyCancellable>()
    
    init() {
        observeNetworkConnection()
    }
    
    deinit {
        networkMonitor.cancel()
    }
    
    func updateGameStory() {
        let gameStory = GameStory.shared
        gameStory.gameMode = selectedGameMode
        gameStory.numberOfRounds = roundsAmount.toInt
        gameStory.lengthOfRound = roundsLength
        gameStory.isSuperWordEnabled = isSuperWordEnabled
        gameStory.isRandomChallengeEnabled = isRandomChallengeEnabled
        gameStory.setTeams(createTeams())
    }
    
    func observeNetworkConnection() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            shouldFetchWordsFromServer = path.status == .satisfied
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    func fetchWordsFromServer() {
        areWordsLoading = true
        FirebaseManager.shared.fetchWordsIfNeeded(
            completion: { [weak self] words in
                GameStory.shared.words = words
                self?.areWordsLoading = false
            },
            onStorageWarning: { [weak self] in
                self?.showInfoAlert(
                    title: L10n.Screen.GameDetails.StorageWarning.title,
                    message: L10n.Screen.GameDetails.StorageWarning.message
                )
            }
        )
    }
    
    func add(with name: String) {
        if let error = validateName(name, isTeam: teamSectionMode == .teams) {
            return
        }
        
        withAnimation(.spring(
            response: GameDetailsConstants.Animation.addSpringResponse,
            dampingFraction: GameDetailsConstants.Animation.addSpringDamping
        )) {
            collection.append(name, for: teamSectionMode)
        }
    }
    
    func update(at index: Int, with name: String) {
        if let error = validateName(name, isTeam: teamSectionMode == .teams) {
            showInfoAlert(title: L10n.Screen.GameDetails.Alert.invalidParameter, message: error)
            return
        }
        
        withAnimation(.spring(
            response: GameDetailsConstants.Animation.updateSpringResponse,
            dampingFraction: GameDetailsConstants.Animation.updateSpringDamping
        )) {
            _ = collection.update(at: index, with: name, for: teamSectionMode)
        }
    }
    
    func remove(at index: Int) {
        withAnimation(.spring(
            response: GameDetailsConstants.Animation.updateSpringResponse,
            dampingFraction: GameDetailsConstants.Animation.updateSpringDamping
        )) {
            _ = collection.remove(at: index, for: teamSectionMode)
        }
    }
    
    private func validateName(_ name: String, isTeam: Bool) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxLength = isTeam ?
        GameDetailsConstants.Validation.maxTeamNameLength :
        GameDetailsConstants.Validation.maxPlayerNameLength
        
        if trimmed.isEmpty {
            return L10n.Screen.GameDetails.Alert.emptyName
        }
        
        return nil
    }
    
    func teamsAreUnique() -> Bool {
        let teamNames = teams.map(\.name)
        return Set(teamNames).count == teamNames.count
    }
    
    func createTeams() -> [Team] {
        teams.map { Team(name: $0.name) }
    }
    
    func createRandomTeams() {
        if players.count % 2 != 0 {
            currentAlert = .info(
                L10n.Screen.GameDetails.Alert.invalidParameter,
                L10n.Screen.GameDetails.Players.oddCount
            )
            return
        }
        
        if players.count < GameDetailsConstants.Game.minimumPlayers {
            currentAlert = .info(
                L10n.Screen.GameDetails.Alert.invalidParameter,
                L10n.Screen.GameDetails.Players.notEnough
            )
            return
        }
        
        var shuffledPlayers = players.shuffled()
        collection.teams.removeAll()
        
        while !shuffledPlayers.isEmpty {
            let player1 = shuffledPlayers.removeFirst().name
            guard !shuffledPlayers.isEmpty else { break }
            let player2 = shuffledPlayers.removeFirst().name
            collection.teams.append(.init(name: "\(player1) \(L10n.and) \(player2)"))
        }
        
        withAnimation(.easeInOut) {
            teamSectionMode = .teams
        }
    }
    
    func showAlert(_ type: AlertType) {
        guard teams.count < GameDetailsConstants.Game.maximumTeams else {
            showInfoAlert(
                title: L10n.Screen.GameDetails.Alert.invalidParameter,
                message: L10n.Screen.GameDetails.Alert.maximumTeams
            )
            return
        }
        currentAlert = type
    }
    
    func showInfoAlert(title: String, message: String) {
        currentAlert = .info(title, message)
    }
}

#if DEBUG
// MARK: - Development Helpers
extension GameDetailsViewModel {
    func addRandomTeam() {
        let teamNames = [
            "დინამო",
            "საბურთალო",
            "ლოკომოტივი",
            "ტორპედო",
            "გაგრა",
            "სამგურალი",
            "რუსთავი",
            "ბათუმი",
            "გორი",
            "თელავი"
        ]
        
        let randomName = teamNames.randomElement() ?? "გუნდი"
        let uniqueName = makeUniqueName(randomName)
        add(with: uniqueName)
    }
    
    private func makeUniqueName(_ baseName: String) -> String {
        var name = baseName
        var counter = 1
        
        while teams.contains(where: { $0.name == name }) {
            name = "\(baseName) \(counter)"
            counter += 1
        }
        
        return name
    }
}
#endif
