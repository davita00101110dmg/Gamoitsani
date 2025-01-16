//
//  GameViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//
//

import Foundation
import OrderedCollections
import SwiftUI

final class GameViewModel: ObservableObject {
    @Published var gameState: GameModels.GameState = .info
    
    var currentTeamName: String { gameStory.teams.keys[gameStory.currentTeamIndex] }
    var currentRound: Int { gameStory.currentRound }
    var currentExtraRound: Int { gameStory.currentRound - gameStory.numberOfRounds }
    var currentTeamScore: Int { gameStory.teams.values[gameStory.currentTeamIndex] }
    var sortedTeams: [(key: String, value: Int)] { gameStory.teams.sorted { $0.value > $1.value } }

    var gameMode: GameMode { gameStory.gameMode }
    var gameStory = GameStory.shared
    
    private var playingSessionCount: Int { gameStory.playingSessionCount }
    private var numberOfTeams: Int { gameStory.teams.count }

    private lazy var audioManager = AudioManager()
    
    private let isTestEnvironment: Bool
    
    init(isTestEnvironment: Bool = false) {
        self.isTestEnvironment = isTestEnvironment
        configureAudioManager()
    }
}

// MARK: - Game Logic
extension GameViewModel {
    func createGameInfoViewModel() -> GameInfoViewModel {
        GameModeFactory.createInfoViewModel(
            teamName: currentTeamName,
            round: currentRound,
            extraRound: currentExtraRound
        )
    }

    func createGameOverViewModel() -> GameOverViewModel {
        let winner = getWinnerTeam()
        return GameModeFactory.createGameOverViewModel(
            teamName: winner?.key,
            score: winner?.value ?? 0
        )
    }
    
    func createClassicViewModel() -> ClassicGamePlayViewModel {
        GameModeFactory.createClassicViewModel(
            using: gameStory,
            audioManager: audioManager
        )
    }
    
    func createArcadeViewModel() -> ArcadeGamePlayViewModel {
        GameModeFactory.createArcadeViewModel(
            using: gameStory,
            audioManager: audioManager
        )
    }
    
    func startPlaying() {
        GameStory.shared.isGameInProgress = true
        gameState = .play
    }
    
    func handleGamePlayResult(score: Int) {
        withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
            updateGameInfo(with: score)
            
            if handleEndOfGame() {
                gameState = .gameOver
                GameStory.shared.isGameInProgress = false
            } else {
                gameState = .info
            }
        }
    }
    
    func startNewGame() {
        gameStory.reset()
        gameState = .info
    }
    
    func getWinnerTeam() -> (key: String, value: Int)? {
        guard let firstTeam = sortedTeams.first else { return nil }
        
        let tiedTeams = sortedTeams.filter { $0.value == firstTeam.value }
        
        if tiedTeams.count > 1 {
            return nil
        }
        
        return firstTeam
    }
    
    func generateShareImage() -> UIImage {
        let view = GameShareUIView.loadFromNib()
        view?.configure(with: sortedTeams[0].key)
        
        guard let image = view?.asImage() else { return UIImage() }
        return image
    }
    
    private func isTie() -> Bool {
        return sortedTeams[0].value == sortedTeams[1].value
    }

    private func isEndGame() -> Bool {
        gameStory.currentRound > gameStory.numberOfRounds && gameStory.currentTeamIndex == 0
    }
    
    private func handleEndOfGame() -> Bool {
        guard isEndGame() else {
            return false
        }

        if isTie() {
            gameStory.currentExtraRound = gameStory.currentRound - gameStory.numberOfRounds
            return false
        }

        return true
    }

    private func updateGameInfo(with roundScore: Int) {
        let currentTeamName = gameStory.teams.keys[gameStory.currentTeamIndex]
        gameStory.teams[currentTeamName, default: 0] += roundScore
        log(.info, "Round: \(currentRound) Team: \(currentTeamName) Score: \(gameStory.teams[currentTeamName] ?? 0)")
        gameStory.currentTeamIndex = playingSessionCount % numberOfTeams
        gameStory.currentRound = playingSessionCount / numberOfTeams + 1
    }
}

// MARK: - Audio Manager
extension GameViewModel {
    private func configureAudioManager() {
        let operationQueue = OperationQueue()
        let audioSetupOperation = BlockOperation { [weak self] in
            self?.audioManager.setupSounds()
        }
        operationQueue.addOperation(audioSetupOperation)
    }
}

// MARK: - Admob Implementation
extension GameViewModel {
    func loadAd() {
        guard !isTestEnvironment else { return }
        Task {
            await InterstitialAdManager.shared.loadAd()
        }
    }
    
    func showAd() {
        guard !isTestEnvironment else { return }
        InterstitialAdManager.shared.showAdIfAvailable()
    }
}
