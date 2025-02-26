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
    let wordsGuessed: Int
    let wordsSkipped: Int
    let totalGuessTime: TimeInterval
    
    init(name: String,
         score: Int = 0,
         wordsGuessed: Int = 0,
         wordsSkipped: Int = 0,
         totalGuessTime: TimeInterval = 0) {
        self.name = name
        self.score = score
        self.wordsGuessed = wordsGuessed
        self.wordsSkipped = wordsSkipped
        self.totalGuessTime = totalGuessTime
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
    
    func testStatisticsResetOnNewGame() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 10, wordsGuessed: 30, wordsSkipped: 10),
            TeamData(name: "Team2", score: 5,wordsGuessed: 15, wordsSkipped: 5)
        ])
        
        // Act
        sut.startNewGame()
        
        // Assert
        XCTAssertEqual(GameStory.shared.teams[0].score, 0)
        XCTAssertEqual(GameStory.shared.teams[0].wordsSkipped, 0)
        XCTAssertEqual(GameStory.shared.teams[0].totalWordsGuessed, 0)
    }
    
    // MARK: - Helper Methods
    private func createTeams(_ teamData: [TeamData]) -> [Team] {
        teamData.map { data in
            Team(name: data.name,
                 score: data.score,
                 totalWordsGuessed: data.wordsGuessed,
                 wordsSkipped: data.wordsSkipped,
                 totalGuessTime: data.totalGuessTime)
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
        GameStory.shared.isSuperWordEnabled = false
        
        let initialTeams = teams.map { data in
            Team(name: data.name,
                 score: data.score,
                 totalWordsGuessed: data.wordsGuessed,
                 wordsSkipped: data.wordsSkipped)
        }
        
        GameStory.shared.setTeams(initialTeams)
        GameStory.shared.numberOfRounds = 1
        GameStory.shared.currentTeamIndex = 0
        GameStory.shared.playingSessionCount = 0
    }
    
    func testWordTimingCalculation() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0)
        ])
        
        // Simulate start guessing
        GameStory.shared.startGuessing()
        
        // Wait for 1 second
        Thread.sleep(forTimeInterval: 1.0)
        
        // Act - Complete word with correct guess
        GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 0, wordsGuessed: 1)
        
        // Assert
        let averageTime = GameStory.shared.currentTeam?.averageGuessTime ?? 0
        XCTAssertGreaterThan(averageTime, 0.9)
        XCTAssertLessThan(averageTime, 1.1)
    }
    
    func testMultipleWordTimingCalculation() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0)
        ])
        
        // Act - Simulate multiple words with different timings
        for _ in 1...3 {
            GameStory.shared.startGuessing()
            Thread.sleep(forTimeInterval: 0.5)
            GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 0, wordsGuessed: 1)
        }
        
        // Assert
        let averageTime = GameStory.shared.currentTeam?.averageGuessTime ?? 0
        XCTAssertGreaterThan(averageTime, 0.4)
        XCTAssertLessThan(averageTime, 0.6)
    }
    
    func testStreakTracking() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0)
        ])
        
        // Act - Build up streak
        for _ in 1...3 {
            GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 0, wordsGuessed: 1)
        }
        
        // Assert
        XCTAssertEqual(GameStory.shared.currentTeam?.currentStreak, 3)
        XCTAssertEqual(GameStory.shared.currentTeam?.bestStreak, 3)
        
        // Break streak
        GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 1, wordsGuessed: 0)
        XCTAssertEqual(GameStory.shared.currentTeam?.currentStreak, 0)
        XCTAssertEqual(GameStory.shared.currentTeam?.bestStreak, 3)
        
        // Build smaller streak
        for _ in 1...2 {
            GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 0, wordsGuessed: 1)
        }
        XCTAssertEqual(GameStory.shared.currentTeam?.currentStreak, 2)
        XCTAssertEqual(GameStory.shared.currentTeam?.bestStreak, 3)
    }
    
    func testWordCountingAccuracy() {
        // Arrange
        setupGameState(mode: .classic, teams: [
            TeamData(name: "Team1", score: 0)
        ])
        
        // Act - Simulate exactly two correct guesses
        for _ in 1...2 {
            GameStory.shared.startGuessing()
            Thread.sleep(forTimeInterval: 0.5)
            GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 0, wordsGuessed: 1)
        }
        
        // Assert
        XCTAssertEqual(GameStory.shared.currentTeam?.totalWordsGuessed, 2, "Should have exactly 2 words guessed")
        
        // Add an incorrect guess
        GameStory.shared.startGuessing()
        Thread.sleep(forTimeInterval: 0.5)
        GameStory.shared.updateScore(for: GameStory.shared.currentTeamIndex, points: 0, wasSkipped: 1, wordsGuessed: 0)
        
        // Assert the count hasn't changed
        XCTAssertEqual(GameStory.shared.currentTeam?.totalWordsGuessed, 2, "Count should still be 2 after incorrect guess")
    }
    
    // MARK: - Super word tests
    func testSuperWordToggle() {
        // Arrange
        setupGameState(mode: .classic)
        
        // Test disabled by default
        XCTAssertFalse(GameStory.shared.isSuperWordEnabled)
        
        // Enable super word
        GameStory.shared.isSuperWordEnabled = true
        XCTAssertTrue(GameStory.shared.isSuperWordEnabled)
    }

    func testSuperWordScoring() {
        // Arrange
        setupGameState(mode: .classic)
        GameStory.shared.isSuperWordEnabled = true
        
        // Create test words
        let testWords = createTestWords(count: 10)
        GameStory.shared.words = testWords
        
        // Get a classic view model
        let classicViewModel = sut.createClassicViewModel()
        
        // Initial state check
        XCTAssertEqual(GameStory.shared.teams[0].score, 0)
        
        // Force super word in view model
        classicViewModel.isSuperWord = true
        
        // Simulate a super word correct guess (+3 points)
        classicViewModel.wordButtonAction(tag: 1)
        
        // Create RoundStats as would be created when timer ends
        let correctStats = RoundStats(
            score: classicViewModel.score,
            wordsSkipped: classicViewModel.wordsSkipped,
            wordsGuessed: classicViewModel.wordsGuessed
        )
        
        // Update game state with round stats (same as when timer ends)
        sut.handleGamePlayResult(
            score: correctStats.score,
            wasSkipped: correctStats.wordsSkipped,
            wordsGuessed: correctStats.wordsGuessed
        )
        
        // Check score is correctly updated to 3 points
        XCTAssertEqual(GameStory.shared.teams[0].score, WordItem.Constants.superWordPoints)
        
        // Reset for next test
        setupGameState(mode: .classic)
        GameStory.shared.isSuperWordEnabled = true
        GameStory.shared.words = createTestWords(count: 10)
        
        // Get a new classic view model
        let newViewModel = sut.createClassicViewModel()
        
        // Force super word in view model
        newViewModel.isSuperWord = true
        
        // Simulate missing a super word (-3 points)
        newViewModel.wordButtonAction(tag: 0)
        
        // Create RoundStats as would be created when timer ends
        let incorrectStats = RoundStats(
            score: newViewModel.score,
            wordsSkipped: newViewModel.wordsSkipped,
            wordsGuessed: newViewModel.wordsGuessed
        )
        
        // Update game state with round stats (same as when timer ends)
        sut.handleGamePlayResult(
            score: incorrectStats.score,
            wasSkipped: incorrectStats.wordsSkipped,
            wordsGuessed: incorrectStats.wordsGuessed
        )
        
        // Check score is correctly updated to -3 points
        XCTAssertEqual(GameStory.shared.teams[0].score, -WordItem.Constants.superWordPoints)
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
        
#if DEBUG
        viewModel.isTestMode = true
#endif
        
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
