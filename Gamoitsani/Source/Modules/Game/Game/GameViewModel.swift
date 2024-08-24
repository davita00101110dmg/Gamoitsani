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

class GameViewModel: ObservableObject {
    
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
    func handleGamePlayResult(score: Int) {
        withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {       
            updateGameInfo(with: score)
            
            if handleEndOfGame() {
                gameState = .gameOver
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
        guard let winnerTeam = sortedTeams.first else { return nil }
        return winnerTeam
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
        gameStory.teams.values[gameStory.currentTeamIndex] = roundScore
        dump("Round: \(currentRound) Team: \(currentTeamName) Score: \(gameStory.teams.values[gameStory.currentTeamIndex])")
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
