//
//  GameStory.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 06/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Collections

class GameStory {
    static let shared = GameStory()
    
    private init() {}
    
    var numberOfRounds: Int = 1
    var lengthOfRound: Double = 45
    var words: [String] = []
    
    var currentRound: Int = 1
    var teams: OrderedDictionary<String, Int> = [:]
    
    var playingSessionCount = 0
    var maxTotalSessions = 0
    var currentTeamIndex = 0
    
    func reset() {

        teams.keys.forEach { teams[$0] = 0 }
        
        words = []
        currentRound = 1
        
        playingSessionCount = 0
        maxTotalSessions = 0
        currentTeamIndex = 0
    }
}

