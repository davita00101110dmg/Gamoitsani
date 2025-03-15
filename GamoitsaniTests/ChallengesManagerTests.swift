//
//  ChallengesManagerTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import XCTest
@testable import Gamoitsani

final class ChallengesManagerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset the state before each test
        GameStory.shared.reset()
        ChallengesManager.shared.resetUsedChallenges()
        
        // Initialize with default challenges if needed
        setupDefaultChallenges()
    }
    
    private func setupDefaultChallenges() {
        // This simulates the challenges being loaded from cache or Firebase
        // We're setting up the test data directly for simplicity
        let challenges: [ChallengesManager.Challenge] = [
            ChallengesManager.Challenge(id: "1", text: ["en": "Every time you guess correctly, do a little dance"]),
            ChallengesManager.Challenge(id: "2", text: ["en": "Speak in a funny accent while guessing"]),
            ChallengesManager.Challenge(id: "3", text: ["en": "Team must high-five after each correct guess"]),
            ChallengesManager.Challenge(id: "4", text: ["en": "Guesser must stand on one leg"]),
            ChallengesManager.Challenge(id: "5", text: ["en": "Whisper all your guesses"]),
        ]
        
        // Add the challenges to the manager's cache
        saveChallengesForTesting(challenges)
    }
    
    private func saveChallengesForTesting(_ challenges: [ChallengesManager.Challenge]) {
        // Access the internal property using reflection to set up our test data
        let manager = ChallengesManager.shared
        let mirror = Mirror(reflecting: manager)
        for child in mirror.children {
            if child.label == "challenges", let challengesRef = child.value as? NSMutableArray {
                challengesRef.removeAllObjects()
                for challenge in challenges {
                    challengesRef.add(challenge)
                }
                break
            }
        }
    }
    
    func testGetRandomChallengeForTeam() {
        // Set up teams in GameStory
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B"), Team(name: "Team C")]
        gameStory.setTeams(teams)
        
        // Get challenges for each team
        let challenge1 = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let challenge2 = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        let challenge3 = ChallengesManager.shared.getRandomChallengeForTeam(at: 2)
        
        // Challenges should not be empty
        XCTAssertFalse(challenge1.isEmpty, "Challenge should not be empty")
        XCTAssertFalse(challenge2.isEmpty, "Challenge should not be empty")
        XCTAssertFalse(challenge3.isEmpty, "Challenge should not be empty")
        
        // Each team should get a different challenge
        XCTAssertNotEqual(challenge1, challenge2, "Challenges should be different for different teams")
        XCTAssertNotEqual(challenge1, challenge3, "Challenges should be different for different teams")
        XCTAssertNotEqual(challenge2, challenge3, "Challenges should be different for different teams")
    }
    
    func testSameChallengeForSameTeam() {
        // Set up teams
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameStory.setTeams(teams)
        
        // Get challenge for Team A
        let firstChallenge = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        
        // Get challenge for Team A again - should be the same
        let secondChallenge = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        
        // The same team should get the same challenge
        XCTAssertEqual(firstChallenge, secondChallenge, "Challenge should be the same for the same team")
        
        // Get challenge for Team B - should be different
        let teamBChallenge = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        
        // Different teams should get different challenges
        XCTAssertNotEqual(firstChallenge, teamBChallenge, "Challenges should be different for different teams")
    }
    
    func testChallengeResetBetweenGames() {
        // Set up teams for first game
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameStory.setTeams(teams)
        
        // Get challenges for first game
        let firstGameChallengeA = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let firstGameChallengeB = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        
        // Reset game state for new game
        gameStory.reset()
        ChallengesManager.shared.resetUsedChallenges()
        gameStory.setTeams(teams)
        
        // Get challenges for second game
        let secondGameChallengeA = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let secondGameChallengeB = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        
        // Teams should get different challenges in new game
        XCTAssertNotEqual(firstGameChallengeA, secondGameChallengeA, "Challenges should be reset between games")
        XCTAssertNotEqual(firstGameChallengeB, secondGameChallengeB, "Challenges should be reset between games")
    }
    
    func testResetUsedChallenges() {
        // Set up teams
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B"), Team(name: "Team C")]
        gameStory.setTeams(teams)
        
        // Get challenges for all teams
        let challenge1 = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let challenge2 = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        let _ = ChallengesManager.shared.getRandomChallengeForTeam(at: 2)
        
        // Reset used challenges
        ChallengesManager.shared.resetUsedChallenges()
        
        // Get new challenges - should be different from original
        let newChallenge1 = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let newChallenge2 = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        
        // The cached challenges in GameStory should be returned
        XCTAssertEqual(challenge1, newChallenge1, "Should return existing challenge from GameStory")
        XCTAssertEqual(challenge2, newChallenge2, "Should return existing challenge from GameStory")
        
        // Clear GameStory challenges and try again
        gameStory.reset()
        gameStory.setTeams(teams)
        
        // Get fresh challenges after reset
        let freshChallenge1 = ChallengesManager.shared.getRandomChallengeForTeam(at: 0)
        let freshChallenge2 = ChallengesManager.shared.getRandomChallengeForTeam(at: 1)
        
        // These should be different after complete reset
        XCTAssertNotEqual(challenge1, freshChallenge1, "Should get new challenge after GameStory reset")
        XCTAssertNotEqual(challenge2, freshChallenge2, "Should get new challenge after GameStory reset")
    }
}
