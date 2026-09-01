//
//  GameChallengeViewModelTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import XCTest
@testable import Gamoitsani

final class GameChallengeViewModelTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Reset the GameStory singleton
        GameStory.shared.reset()
        // Reset used challenges
        ChallengesManager.shared.resetUsedChallenges()
    }
    
    func testViewModelCreation() {
        // Setup
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameStory.setTeams(teams)
        
        // Create view model for team 0
        let viewModel = GameChallengeViewModel(teamName: "Team A", teamIndex: 0)
        
        // Assertions
        XCTAssertEqual(viewModel.teamName, "Team A")
        XCTAssertEqual(viewModel.teamIndex, 0)
        XCTAssertFalse(viewModel.challengeText.isEmpty, "Challenge text should not be empty")
    }
    
    func testViewModelConsistentChallenges() throws {
        // Same root cause as ChallengesManagerTests: with no challenges loaded, every
        // team receives the identical hardcoded fallback string, so "different teams get
        // different challenges" cannot hold. Needs the Phase 4 injection seam.
        throw XCTSkip("Needs seedable ChallengesManager — see Phase 4 of docs/2.0/PLAN.md")

        // Setup
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameStory.setTeams(teams)
        
        // Create view models for team 0
        let viewModel1 = GameChallengeViewModel(teamName: "Team A", teamIndex: 0)
        let viewModel2 = GameChallengeViewModel(teamName: "Team A", teamIndex: 0)
        
        // Create view model for team 1
        let viewModel3 = GameChallengeViewModel(teamName: "Team B", teamIndex: 1)
        
        // Assertions
        XCTAssertEqual(viewModel1.challengeText, viewModel2.challengeText, "Challenge should be the same for multiple instances of the same team's view model")
        XCTAssertNotEqual(viewModel1.challengeText, viewModel3.challengeText, "Challenges should be different for different teams")
    }
    
    func testViewModelAfterReset() throws {
        // Needs the Phase 4 injection seam, as above. Note this assertion is also random
        // by construction even with data loaded — its own comment concedes it fails "if
        // by coincidence the same challenge is selected". Re-point it at a seeded manager
        // and assert on the used-index bookkeeping rather than on inequality of output.
        throw XCTSkip("Needs seedable ChallengesManager — see Phase 4 of docs/2.0/PLAN.md")

        // Setup initial game
        let gameStory = GameStory.shared
        let teams = [Team(name: "Team A"), Team(name: "Team B")]
        gameStory.setTeams(teams)
        
        // Get challenge for team 0 before reset
        let viewModel1 = GameChallengeViewModel(teamName: "Team A", teamIndex: 0)
        let originalChallenge = viewModel1.challengeText
        
        // Reset for new game
        gameStory.reset()
        ChallengesManager.shared.resetUsedChallenges()
        gameStory.setTeams(teams)
        
        // Get challenge for team 0 after reset
        let viewModel2 = GameChallengeViewModel(teamName: "Team A", teamIndex: 0)
        let newChallenge = viewModel2.challengeText
        
        // The challenge should likely be different after reset
        // This has a small chance of failing if by coincidence the same challenge is selected
        XCTAssertNotEqual(originalChallenge, newChallenge, "Challenges should be different after game reset")
    }
}
