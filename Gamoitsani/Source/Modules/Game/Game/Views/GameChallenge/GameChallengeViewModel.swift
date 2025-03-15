//
//  GameChallengeViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation

struct GameChallengeViewModel {
    let teamName: String
    let teamIndex: Int
    let challengeText: String
    
    init(teamName: String, teamIndex: Int) {
        self.teamName = teamName
        self.teamIndex = teamIndex
        self.challengeText = ChallengesManager.shared.getRandomChallengeForTeam(at: teamIndex)
    }
}
