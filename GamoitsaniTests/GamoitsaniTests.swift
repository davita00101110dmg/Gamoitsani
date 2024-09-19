//
//  GamoitsaniTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 28/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import XCTest
@testable import Gamoitsani

class GameViewModelTests: XCTestCase {
    
    var sut: GameViewModel!
    
    override func setUp() {
        super.setUp()
        sut = GameViewModel()
        GameStory.shared.reset() // Ensure we start with a clean state
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func playTurn(score: Int) {
        GameStory.shared.playingSessionCount += 1
        sut.handleGamePlayResult(score: score)
    }
    
    func testScoreAccumulationAndTeamRotation() {
        // Arrange
        GameStory.shared.teams = ["Team1": 0, "Team2": 0]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0
        
        // Act & Assert - First round (Team 1)
        playTurn(score: 10)
        XCTAssertEqual(GameStory.shared.teams["Team1"], 10)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 1)
        
        // Act & Assert - Second round (Team 2)
        playTurn(score: 5)
        XCTAssertEqual(GameStory.shared.teams["Team1"], 10)
        XCTAssertEqual(GameStory.shared.teams["Team2"], 5)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 0)
        XCTAssertEqual(GameStory.shared.currentRound, 2)
        
        // Act & Assert - Third round (Team 1 again)
        playTurn(score: 7)
        XCTAssertEqual(GameStory.shared.teams["Team1"], 17, "Score should accumulate for Team 1")
        XCTAssertEqual(GameStory.shared.teams["Team2"], 5, "Team 2's score should remain unchanged")
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 2)
        
        // Act & Assert - Fourth round (Team 2 again)
        playTurn(score: 8)
        XCTAssertEqual(GameStory.shared.teams["Team1"], 17)
        XCTAssertEqual(GameStory.shared.teams["Team2"], 13, "Score should accumulate for Team 2")
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 0)
        XCTAssertEqual(GameStory.shared.currentRound, 3)
    }
    
    func testGameOverCondition() {
        // Arrange
        GameStory.shared.teams = ["Team1": 10, "Team2": 5]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 1
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 3 // Last turn of the last round
        
        // Act
        playTurn(score: 7)
        
        // Assert
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(sut.getWinnerTeam()?.key, "Team2")
        XCTAssertEqual(sut.getWinnerTeam()?.value, 12)
    }
    
    func testTieBreaker() {
        // Arrange
        GameStory.shared.teams = ["Team1": 10, "Team2": 10]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 1
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 3 // Last turn of the last round
        
        // Act
        playTurn(score: 0) // This should trigger a tie
        
        // Assert
        XCTAssertEqual(sut.gameState, .info)
        XCTAssertEqual(sut.currentExtraRound, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 3) // Should start extra round
    }
    
    func testMaximumRounds() {
        // Arrange
        GameStory.shared.teams = ["Team1": 0, "Team2": 0]
        GameStory.shared.numberOfRounds = 3
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0

        // Act
        for _ in 1...5 { // 3 rounds * 2 teams = 5 turns
            playTurn(score: 5)
        }

        playTurn(score: 6) // last team 1 point greater
        
        // Assert
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(GameStory.shared.currentRound, 4) // Should be one more than max rounds
    }
    
    func testScoreUpdatesWithMultipleTeams() {
        // Arrange
        GameStory.shared.teams = ["Team1": 0, "Team2": 0, "Team3": 0]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0

        // Act
        for i in 1...6 { // 2 rounds * 3 teams = 6 turns
            playTurn(score: i)
        }

        // Assert
        XCTAssertEqual(GameStory.shared.teams["Team1"], 1 + 4)
        XCTAssertEqual(GameStory.shared.teams["Team2"], 2 + 5)
        XCTAssertEqual(GameStory.shared.teams["Team3"], 3 + 6)
    }
    
    func testTieBreakingInExtraRounds() {
        // Arrange
        GameStory.shared.teams = ["Team1": 10, "Team2": 10]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.currentRound = 3 // Start in extra round
        GameStory.shared.playingSessionCount = 4 // 2 rounds * 2 teams

        // Act - First extra round
        playTurn(score: 5)
        playTurn(score: 5)

        // Assert - Still tied
        XCTAssertEqual(sut.gameState, .info)
        XCTAssertEqual(sut.currentExtraRound, 2)

        // Act - Second extra round
        playTurn(score: 3)
        playTurn(score: 2)

        // Assert - Game Over
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(sut.getWinnerTeam()?.key, "Team1")
        XCTAssertEqual(sut.getWinnerTeam()?.value, 18)
    }
    
    func testGameReset() {
        // Arrange
        GameStory.shared.teams = ["Team1": 10, "Team2": 15]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 1
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 3

        // Act
        sut.startNewGame()

        // Assert
        XCTAssertEqual(GameStory.shared.currentRound, 1)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 0)
        XCTAssertEqual(GameStory.shared.playingSessionCount, 0)
        XCTAssertEqual(GameStory.shared.teams["Team1"], 0)
        XCTAssertEqual(GameStory.shared.teams["Team2"], 0)
        XCTAssertEqual(sut.gameState, .info)
    }
    
    func testHandlingNegativeScores() {
        // Arrange
        GameStory.shared.teams = ["Team1": 5, "Team2": 5]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0

        // Act
        playTurn(score: -3)

        // Assert
        XCTAssertEqual(GameStory.shared.teams["Team1"], 2)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 1)
    }
    
    func testWinnerDeterminationWithTiedScores() {
        // Arrange
        GameStory.shared.teams = ["Team1": 10, "Team2": 10, "Team3": 8]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 2
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 5 // Last turn of the last round

        // Act
        playTurn(score: 2) // This should end the game with a tie between Team1 and Team2

        // Assert
        XCTAssertEqual(sut.gameState, .info) // Should go to extra round
        XCTAssertEqual(sut.currentExtraRound, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 3)
        XCTAssertNil(sut.getWinnerTeam()) // No winner yet due to tie
    }
    
    func testWinnerDeterminationWithClearWinner() {
        // Arrange
        GameStory.shared.teams = ["Team1": 15, "Team2": 10, "Team3": 8]
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 2
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 5 // Last turn of the last round

        // Act
        playTurn(score: 0) // This should end the game with Team1 as the clear winner

        // Assert
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(sut.getWinnerTeam()?.key, "Team1")
        XCTAssertEqual(sut.getWinnerTeam()?.value, 15)
    }
}
