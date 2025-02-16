//
//  GameModeFactory.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum GameModeFactory {
    enum ViewModelType {
        case classic
        case arcade
        case info(teamName: String, round: Int, extraRound: Int)
        case gameOver(teams: [Team])
    }
}

// MARK: - Creation Methods
extension GameModeFactory {
    static func createClassicViewModel(
        using gameStory: GameStory,
        audioManager: AudioManager
    ) -> ClassicGamePlayViewModel {
        let words = gameStory.words.removeFirstNItems(50) ?? []
        return ClassicGamePlayViewModel(
            words: words,
            roundLength: gameStory.lengthOfRound,
            audioManager: audioManager
        )
    }
    
    static func createArcadeViewModel(
        using gameStory: GameStory,
        audioManager: AudioManager
    ) -> ArcadeGamePlayViewModel {
        let words = gameStory.words.removeFirstNItems(50) ?? []
        return ArcadeGamePlayViewModel(
            words: words,
            roundLength: gameStory.lengthOfRound,
            audioManager: audioManager
        )
    }
    
    static func createInfoViewModel(
        teamName: String,
        round: Int,
        extraRound: Int
    ) -> GameInfoViewModel {
        GameInfoViewModel(
            teamName: teamName,
            currentRound: round,
            currentExtraRound: extraRound
        )
    }
    
    static func createGameOverViewModel(
        using gameStory: GameStory
    ) -> GameOverViewModel {
        GameOverViewModel(teams: gameStory.teams)
    }
}
