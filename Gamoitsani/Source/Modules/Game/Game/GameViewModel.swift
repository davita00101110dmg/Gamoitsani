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
    
    var currentTeam: Team? { gameStory.currentTeam }
    var currentRound: Int { gameStory.currentRound }
    var currentExtraRound: Int { gameStory.currentRound - gameStory.numberOfRounds }
    var sortedTeams: [Team] { gameStory.teams.sorted { $0.score > $1.score } }

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
            teamName: currentTeam?.name ?? .empty,
            round: currentRound,
            extraRound: currentExtraRound
        )
    }

    func createGameOverViewModel() -> GameOverViewModel {
        let winner = getWinnerTeam()
        return GameModeFactory.createGameOverViewModel(
            teamName: winner?.name,
            score: winner?.score ?? 0
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
    
    func handleGamePlayResult(score: Int, wasSkipped: Int, wordsGuessed: Int) {
        withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
            updateGameInfo(with: score, wasSkipped: wasSkipped, wordsGuessed: wordsGuessed)
            
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
    
    func getWinnerTeam() -> Team? {
        guard let firstTeam = sortedTeams.first else { return nil }
        
        let tiedTeams = sortedTeams.filter { $0.score == firstTeam.score }
        
        if tiedTeams.count > 1 {
            return nil
        }
        
        return firstTeam
    }
    
    func generateShareImage() -> UIImage {
        let view = GameShareUIView.loadFromNib()
        view?.configure(with: sortedTeams.first?.name ?? .empty)
        
        guard let image = view?.asImage() else { return UIImage() }
        return image
    }
    
    private func isTie() -> Bool {
        return sortedTeams.first?.score == sortedTeams[1].score
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

    private func updateGameInfo(with roundScore: Int, wasSkipped: Int, wordsGuessed: Int) {
        gameStory.updateScore(for: gameStory.currentTeamIndex, points: roundScore, wasSkipped: wasSkipped, wordsGuessed: wordsGuessed)
        log(.info, "Round: \(currentRound) Team: \(currentTeam?.name ?? .empty) Score: \(currentTeam?.score ?? 0)")
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
