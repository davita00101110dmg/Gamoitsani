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

final class GameViewModel { 
    private var gameStory = GameStory.shared
    private var shouldShowInfoView: Bool = false
    
    private var playingSessionCount: Int {
        gameStory.playingSessionCount
    }
    
    private var numberOfTeams: Int {
        gameStory.teams.count
    }
    
    var currentTeamName: String {
        gameStory.teams.keys[gameStory.currentTeamIndex]
    }
    
    var currentRound: Int {
        gameStory.currentRound
    }
    
    var currentExtraRound: Int {
        gameStory.currentRound - gameStory.numberOfRounds
    }
    
    var sortedTeams: [(key: String, value: Int)] {
        gameStory.teams.sorted { $0.value > $1.value }
    }
    
    private func isTie() -> Bool {
        return sortedTeams[0].value == sortedTeams[1].value
    }
    
    private func isEndGame() -> Bool {
        gameStory.currentRound > gameStory.numberOfRounds && gameStory.currentTeamIndex == 0
    }
    
    func handleEndOfGame() -> Bool {
        guard isEndGame() else {
            return false
        }
        
        if isTie() {
            gameStory.currentExtraRound = gameStory.currentRound - gameStory.numberOfRounds
            return false
        }
        
        return true
    }
    
    func updateGameInfo(with roundScore: Int) {
        gameStory.teams.values[gameStory.currentTeamIndex] = roundScore
        dump("Round: \(currentRound) Team: \(currentTeamName) Score: \(gameStory.teams.values[gameStory.currentTeamIndex])")
        gameStory.currentTeamIndex = playingSessionCount % numberOfTeams
        gameStory.currentRound = playingSessionCount / numberOfTeams + 1
    }
}
