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
import Combine

final class GameViewModel: ObservableObject {
    @Published var gameState: GameModels.GameState = .info
    @Published var countdownValue: Int = 3
    
    var currentTeam: Team? { gameStory.currentTeam }
    var currentRound: Int { gameStory.currentRound }
    var currentExtraRound: Int { gameStory.currentRound - gameStory.numberOfRounds }
    var sortedTeams: [Team] { gameStory.teams.sorted { $0.score > $1.score } }
    var gameMode: GameMode { gameStory.gameMode }
    var gameStory = GameStory.shared
    
    let audioManager = AudioManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var countdownCancellable: AnyCancellable?
    
    private var playingSessionCount: Int { gameStory.playingSessionCount }
    private var numberOfTeams: Int { gameStory.teams.count }
    private let isTestEnvironment: Bool
    private var cachedClassicViewModel: ClassicGamePlayViewModel?
    private var cachedArcadeViewModel: ArcadeGamePlayViewModel?
    
    init(isTestEnvironment: Bool = false) {
        self.isTestEnvironment = isTestEnvironment
        configureAudioManager()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
        countdownCancellable?.cancel()
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
        GameModeFactory.createGameOverViewModel(using: gameStory)
    }
    
    func createClassicViewModel() -> ClassicGamePlayViewModel {
        if let cached = cachedClassicViewModel {
            return cached
        }
        
        let viewModel = GameModeFactory.createClassicViewModel(
            using: gameStory,
            audioManager: audioManager
        )
        cachedClassicViewModel = viewModel
        return viewModel
    }
    
    func createArcadeViewModel() -> ArcadeGamePlayViewModel {
        if let cached = cachedArcadeViewModel {
            return cached
        }
        
        let viewModel = GameModeFactory.createArcadeViewModel(
            using: gameStory,
            audioManager: audioManager
        )
        cachedArcadeViewModel = viewModel
        return viewModel
    }
    
    func startPlaying() {
        startCombineCountdown()
    }
    
    func startGameAfterCountdown() {
        GameStory.shared.isGameInProgress = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeIn(duration: 0.5)) {
                self.gameState = .play
            }
            
            if self.gameStory.gameStartTime == nil {
                self.gameStory.gameStartTime = Date()
            }
            
            AnalyticsManager.shared.logGameStart(
                gameMode: self.gameStory.gameMode.rawValue.lowercased(),
                teamsCount: self.gameStory.teams.count,
                roundsCount: self.gameStory.numberOfRounds
            )
        }
    }
    
    func handleGamePlayResult(score: Int, wasSkipped: Int, wordsGuessed: Int) {
        withAnimation(.smooth(duration: AppConstants.viewAnimationTime)) {
            updateGameInfo(with: score, wasSkipped: wasSkipped, wordsGuessed: wordsGuessed)
            
            resetViewModels()
            
            if handleEndOfGame() {
                gameState = .gameOver
                GameStory.shared.isGameInProgress = false
                
                let gameStartTime = gameStory.gameStartTime ?? Date().addingTimeInterval(-600)
                let gameDuration = Date().timeIntervalSince(gameStartTime)
                let winnerTeam = getWinnerTeam()?.name
                
                AnalyticsManager.shared.logGameCompleted(
                    gameMode: gameStory.gameMode.rawValue.lowercased(),
                    duration: gameDuration,
                    winnerTeam: winnerTeam,
                    isTie: isTie(),
                    roundsPlayed: currentRound
                )
            } else {
                gameState = .info
            }
        }
    }
    
    func startNewGame() {
        gameStory.reset()
        gameState = .info
        resetViewModels()
    }
    
    private func resetViewModels() {
        cachedClassicViewModel = nil
        cachedArcadeViewModel = nil
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
        let currentTeamName = currentTeam?.name ?? .empty
        let roundNumber = currentRound
        
        gameStory.updateScore(for: gameStory.currentTeamIndex, points: roundScore, wasSkipped: wasSkipped, wordsGuessed: wordsGuessed)
        log(.info, "Round: \(roundNumber) Team: \(currentTeamName) Score: \(currentTeam?.score ?? 0)")
        
        AnalyticsManager.shared.logRoundCompleted(
            roundNumber: roundNumber,
            teamName: currentTeamName,
            score: roundScore,
            wordsGuessed: wordsGuessed,
            wordsSkipped: wasSkipped
        )
        
        gameStory.currentTeamIndex = playingSessionCount % numberOfTeams
        gameStory.currentRound = playingSessionCount / numberOfTeams + 1
        
        if playingSessionCount % numberOfTeams == 0 {
            gameStory.onNewRound()
        }
    }
    
    private func startCombineCountdown() {
        countdownCancellable?.cancel()
        
        countdownValue = 3
        gameState = .countdown
        
        let number3 = Just(3).delay(for: 0, scheduler: RunLoop.main)
        let number2 = Just(2).delay(for: 1.2, scheduler: RunLoop.main)
        let number1 = Just(1).delay(for: 2.4, scheduler: RunLoop.main)
        let number0 = Just(0).delay(for: 3.6, scheduler: RunLoop.main)
        
        countdownCancellable = Publishers.Merge4(number3, number2, number1, number0)
            .filter { [weak self] _ in
                return self?.gameState == .countdown
            }
            .sink(receiveCompletion: { _ in
                
            }, receiveValue: { [weak self] value in
                guard let self = self else { return }
                self.countdownValue = value
            })
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
