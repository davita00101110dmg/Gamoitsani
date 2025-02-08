//
//  GameStory.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 06/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

final class GameStory {
    static let shared = GameStory()
    
    private init() {}
    
    var gameMode: GameMode = .classic
    var numberOfRounds: Int = 1
    var lengthOfRound: Double = 45
    var words: [Word] = []
    
    var currentRound: Int = 1
    var currentExtraRound: Int = 0
    private(set) var teams: [Team] = []
    
    var playingSessionCount: Int = 0
    var currentTeamIndex: Int = 0
    
    var finishedGamesCountInSession: Int = 0
    var isGameInProgress: Bool = false
    
    var currentTeam: Team? {
        guard currentTeamIndex < teams.count else { return nil }
        return teams[currentTeamIndex]
    }
    
    func setTeams(_ teams: [Team]) {
        self.teams = teams
    }
    
    func addTeam(_ name: String) {
        teams.append(Team(name: name))
    }
    
    func updateScore(for teamIndex: Int, points: Int, wasSkipped: Int, wordsGuessed: Int) {
        guard teamIndex < teams.count else { return }
        teams[teamIndex].updateScore(points, skippedWords: wasSkipped, guessedWords: wordsGuessed)
    }
    
    func updateTeamStats(winner: Team?) {
        for i in 0..<teams.count {
            var team = teams[i]
            let didWin = team.id == winner?.id
            team.incrementGamesPlayed(didWin: didWin)
            teams[i] = team
        }
    }
    
    func reset() {
        teams.resetAllScores()
        currentRound = 1
        currentExtraRound = 0
        playingSessionCount = 0
        currentTeamIndex = 0
    }
}
