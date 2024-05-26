//
//  GameStory.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 06/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import OrderedCollections

class GameStory {
    static let shared = GameStory()
    
    private init() {}
    
    var numberOfRounds: Int = 1
    var lengthOfRound: Double = 45
    var words: [Word] = []
    
    var currentRound: Int = 1
    var currentExtraRound: Int = 0
    var teams: OrderedDictionary<String, Int> = [:]
    
    var playingSessionCount: Int = 0
    var currentTeamIndex: Int = 0
    
    var finishedGamesCountInSession: Int = 0
    
    func reset() {
        teams.keys.forEach { teams[$0] = 0 }

        currentRound = 1
        currentExtraRound = 0
        
        playingSessionCount = 0
        currentTeamIndex = 0
    }
}

