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
    
    var gameInfoViewModel: GameInfoViewModel {
        GameInfoViewModel(
            teamName: currentTeamName,
            currentRound: currentRound,
            currentExtraRound: currentExtraRound
        )
    }

    var gamePlayViewModel: GamePlayViewModel {
        GamePlayViewModel(
            words: gameStory.words.removeFirstNItems(50) ?? [],
            roundLength: gameStory.lengthOfRound,
            audioManager: audioManager
        )
    }
    
    var gameOverViewModel: GameOverViewModel {
        GameOverViewModel(
            teamName: getWinnerTeam()?.key ?? .empty,
            score: getWinnerTeam()?.value ?? 0
        )
    }
    
    @Published var gameState: GameModels.GameState = .info
    
    var currentTeamName: String { gameStory.teams.keys[gameStory.currentTeamIndex] }
    var currentRound: Int { gameStory.currentRound }
    var currentExtraRound: Int { gameStory.currentRound - gameStory.numberOfRounds }
    var currentTeamScore: Int { gameStory.teams.values[gameStory.currentTeamIndex] }
    var sortedTeams: [(key: String, value: Int)] { gameStory.teams.sorted { $0.value > $1.value } }

    var gameStory = GameStory.shared
    
    private var playingSessionCount: Int { gameStory.playingSessionCount }
    private var numberOfTeams: Int { gameStory.teams.count }

    private lazy var audioManager = AudioManager()
    
    init() {
        configureAudioManager()
    }
}

// MARK: - Game Logic
extension GameViewModel {
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
        
        // Check if there's a tie for first place
        let tiedTeams = sortedTeams.filter { $0.value == firstTeam.value }
        
        // If there's more than one team with the highest score, it's a tie
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
        dump("Round: \(currentRound) Team: \(currentTeamName) Score: \(gameStory.teams[currentTeamName] ?? 0)")
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
        Task {
            await InterstitialAdManager.shared.loadAd()
        }
    }
    
    func showAd() {
        InterstitialAdManager.shared.showAdIfAvailable()
    }
}
