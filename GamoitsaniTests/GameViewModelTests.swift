//
//  GameViewModelTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 28/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import XCTest
import CoreData
import OrderedCollections
@testable import Gamoitsani

private struct TeamData {
    let name: String
    let score: Int
    let gamesWon: Int
    let wordsGuessed: Int
    let wordsSkipped: Int
    
    init(name: String, score: Int, gamesWon: Int = 0, wordsGuessed: Int = 0, wordsSkipped: Int = 0) {
        self.name = name
        self.score = score
        self.gamesWon = gamesWon
        self.wordsGuessed = wordsGuessed
        self.wordsSkipped = wordsSkipped
    }
}

final class GameViewModelTests: XCTestCase {
    
    // MARK: - Properties
    var sut: GameViewModel!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        sut = GameViewModel()
        GameStory.shared.reset()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Basic Game State Tests
    func testDefaultGameMode() {
        XCTAssertEqual(GameStory.shared.gameMode, .classic)
    }
    
    func testGameStateTransitions() {
        // Test Classic Mode
        setupGameState(mode: .classic)
        verifyGameStateTransition(score: 5)
        
        // Test Arcade Mode
        setupGameState(mode: .arcade)
        verifyGameStateTransition(score: 10)
    }
    
    func testGameReset() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10),
            TeamData(name: "Team2", score: 15)
        ])
        
        GameStory.shared.currentTeamIndex = 1
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 3
        
        // Act
        sut.startNewGame()
        
        // Assert
        XCTAssertEqual(GameStory.shared.currentRound, 1)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 0)
        XCTAssertEqual(GameStory.shared.playingSessionCount, 0)
        XCTAssertEqual(GameStory.shared.teams[0].score, 0)
        XCTAssertEqual(GameStory.shared.teams[1].score, 0)
        XCTAssertEqual(sut.gameState, .info)
    }
    
    // MARK: - Scoring Tests
    func testScoreAccumulationAndTeamRotation() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0),
            TeamData(name: "Team2", score: 0)
        ])
        
        // Act & Assert - First round (Team 1)
        playTurn(score: 10)
        XCTAssertEqual(GameStory.shared.teams[0].score, 10)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 1)
        
        // Act & Assert - Second round (Team 2)
        playTurn(score: 5)
        XCTAssertEqual(GameStory.shared.teams[0].score, 10)
        XCTAssertEqual(GameStory.shared.teams[1].score, 5)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 0)
        XCTAssertEqual(GameStory.shared.currentRound, 2)
    }
    
    func testScoreUpdatesWithMultipleTeams() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0),
            TeamData(name: "Team2", score: 0),
            TeamData(name: "Team3", score: 0)
        ])
        
        // Act
        for i in 1...6 { // 2 rounds * 3 teams = 6 turns
            playTurn(score: i)
        }
        
        // Assert
        XCTAssertEqual(GameStory.shared.teams[0].score, 1 + 4)
        XCTAssertEqual(GameStory.shared.teams[1].score, 2 + 5)
        XCTAssertEqual(GameStory.shared.teams[2].score, 3 + 6)
    }
    
    func testHandlingNegativeScores() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 5),
            TeamData(name: "Team2", score: 5)
        ])
        
        // Act & Assert
        playTurn(score: -3)
        XCTAssertEqual(GameStory.shared.teams[0].score, 2)
        XCTAssertEqual(GameStory.shared.currentTeamIndex, 1)
    }
    
    // MARK: - Game Mode Tests
    func testGameModePersistence() {
        // Arrange
        setupGameState(mode: .arcade, teams: [
            TeamData(name: "Team1", score: 0),
            TeamData(name: "Team2", score: 0)
        ])
        GameStory.shared.numberOfRounds = 2
        
        // Act - Complete rounds
        playTurn(score: 5)
        XCTAssertEqual(GameStory.shared.gameMode, .arcade, "Mode should persist after round")
        
        completeFourTurns(score: 5)
        sut.startNewGame()
        
        // Assert
        XCTAssertEqual(GameStory.shared.gameMode, .arcade, "Mode should persist after reset")
    }
    
    func testDifferentScoringSystems() {
        // Test Classic Mode
        setupGameState(mode: .classic)
        playTurn(score: -2)
        XCTAssertEqual(GameStory.shared.teams[0].score, -2)
        
        // Test Arcade Mode
        setupGameState(mode: .arcade)
        playTurn(score: 15)
        XCTAssertEqual(GameStory.shared.teams[0].score, 15)
        
        playTurn(score: GameMode.arcade.skipPenalty)
        XCTAssertEqual(GameStory.shared.teams[1].score, GameMode.arcade.skipPenalty)
    }
    
    func testGameModeViewModels() {
        let testWords = createTestWords(count: 50)
        GameStory.shared.words = testWords
        
        // Test Classic Mode
        testClassicModeViewModel()
        
        // Test Arcade Mode
        testArcadeModeViewModel(with: testWords)
    }
    
    // MARK: - End Game Tests
    func testGameOverCondition() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10),
            TeamData(name: "Team2", score: 5)
        ])
        setupEndGameState()
        
        // Act
        playTurn(score: 7)
        
        // Assert
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(sut.getWinnerTeam()?.name, "Team2")
        XCTAssertEqual(sut.getWinnerTeam()?.score, 12)
    }
    
    func testTieBreaker() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10),
            TeamData(name: "Team2", score: 10)
        ])
        setupEndGameState()
        
        // Act
        playTurn(score: 0)
        
        // Assert
        XCTAssertEqual(sut.gameState, .info)
        XCTAssertEqual(sut.currentExtraRound, 1)
        XCTAssertEqual(GameStory.shared.currentRound, 3)
    }
    
    func testTieBreakingInExtraRounds() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10),
            TeamData(name: "Team2", score: 10)
        ])
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentRound = 3
        GameStory.shared.playingSessionCount = 4
        
        // First extra round - still tied
        playTurn(score: 5)
        playTurn(score: 5)
        XCTAssertEqual(sut.gameState, .info)
        XCTAssertEqual(sut.currentExtraRound, 2, "Extra round should be 2 (3 - numberOfRounds)")
        
        // Second extra round - winner determined
        playTurn(score: 3)
        playTurn(score: 2)
        XCTAssertEqual(sut.gameState, .gameOver)
        XCTAssertEqual(sut.getWinnerTeam()?.name, "Team1")
        XCTAssertEqual(sut.getWinnerTeam()?.score, 18)
    }

    func testWordStatisticsTracking() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0),
            TeamData(name: "Team2", score: 0)
        ])
        
        // Act - Simulate some guessed and skipped words
        sut.handleGamePlayResult(score: 3, wasSkipped: 2, wordsGuessed: 5)
        
        // Assert
        XCTAssertEqual(GameStory.shared.teams[0].score, 3)
        XCTAssertEqual(GameStory.shared.teams[0].wordsSkipped, 2)
        XCTAssertEqual(GameStory.shared.teams[0].totalWordsGuessed, 5)
    }

    func testGameStatisticsTracking() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10),
            TeamData(name: "Team2", score: 5)
        ])
        setupEndGameState()
        
        // Act - Finish game with Team2 as winner
        sut.handleGamePlayResult(score: 7, wasSkipped: 1, wordsGuessed: 8)
        
        // Assert
        XCTAssertEqual(GameStory.shared.teams[0].gamesPlayed, 1, "All teams should increment games played")
        XCTAssertEqual(GameStory.shared.teams[1].gamesPlayed, 1, "All teams should increment games played")
        
        XCTAssertEqual(GameStory.shared.teams[0].gamesWon, 0, "Losing team should not increment games won")
        XCTAssertEqual(GameStory.shared.teams[1].gamesWon, 1, "Winning team should increment games won")
    }

    func testStatisticsResetOnNewGame() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10, gamesWon: 5, wordsGuessed: 30, wordsSkipped: 10),
            TeamData(name: "Team2", score: 5, gamesWon: 2, wordsGuessed: 15, wordsSkipped: 5)
        ])
        
        // Act
        sut.startNewGame()
        
        // Assert
        XCTAssertEqual(GameStory.shared.teams[0].score, 0)
        XCTAssertEqual(GameStory.shared.teams[0].wordsSkipped, 0)
        XCTAssertEqual(GameStory.shared.teams[0].totalWordsGuessed, 0)
        XCTAssertEqual(GameStory.shared.teams[0].gamesWon, 5, "Games played should not reset")
    }
    
    // MARK: - Helper Methods
    private func createTeams(_ teamData: [TeamData]) -> [Team] {
        teamData.map { data in
            Team(name: data.name,
                 score: data.score,
                 gamesWon: data.gamesWon,
                 totalWordsGuessed: data.wordsGuessed,
                 wordsSkipped: data.wordsSkipped)
        }
    }
    
    private func playTurn(score: Int, wasSkipped: Int = 0, wordsGuessed: Int = 0) {
        GameStory.shared.playingSessionCount += 1
        sut.handleGamePlayResult(score: score, wasSkipped: wasSkipped, wordsGuessed: wordsGuessed)
    }

    
    private func setupGameState(mode: GameMode, teams: [TeamData] = [
        TeamData(name: "Team1", score: 0),
        TeamData(name: "Team2", score: 0)
    ]) {
        GameStory.shared.reset()
        GameStory.shared.gameMode = mode
        GameStory.shared.setTeams(createTeams(teams))
        GameStory.shared.numberOfRounds = 1
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0
    }
    
    private func setupEndGameState() {
        GameStory.shared.numberOfRounds = 2
        GameStory.shared.currentTeamIndex = 1
        GameStory.shared.currentRound = 2
        GameStory.shared.playingSessionCount = 3
    }
    
    private func completeFourTurns(score: Int) {
        for _ in 0...3 {
            playTurn(score: score)
        }
    }
    
    private func verifyGameStateTransition(score: Int) {
        XCTAssertEqual(sut.gameState, .info)
        sut.gameState = .play
        XCTAssertEqual(sut.gameState, .play)
        playTurn(score: score)
        XCTAssertEqual(sut.gameState, .info)
    }
    
    private func testClassicModeViewModel() {
        GameStory.shared.gameMode = .classic
        let viewModel = sut.createClassicViewModel()
        viewModel.startGame()
        XCTAssertNotNil(viewModel.currentWord)
        viewModel.stopGame()
    }
    
    private func testArcadeModeViewModel(with words: [Word]) {
        GameStory.shared.reset()
        GameStory.shared.words = words
        GameStory.shared.gameMode = .arcade
        
        let viewModel = sut.createArcadeViewModel()
        viewModel.startGame()
        
        let expectation = XCTestExpectation(description: "Wait for words update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertFalse(viewModel.currentWords.isEmpty)
            XCTAssertEqual(viewModel.currentWords.count, 5)
            viewModel.stopGame()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    private func createTestWords(count: Int) -> [Word] {
        let context = TestCoreDataStack().persistentContainer.viewContext
        var words: [Word] = []
        
        for i in 0..<count {
            let word = Word(context: context)
            word.baseWord = "test_word_\(i)"
            
            let translation = Translation(context: context)
            translation.word = "test_translation_\(i)"
            translation.languageCode = "en"
            translation.difficulty = 1
            word.addToWordTranslations(translation)
            
            words.append(word)
        }
        
        return words
    }
}

// MARK: - Test Core Data Stack
private class TestCoreDataStack {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Gamoitsani")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Failed to load test store: \(error)")
            }
        }
        return container
    }()
}
