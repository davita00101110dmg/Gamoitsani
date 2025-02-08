//
//  Team.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation

struct Team: Identifiable, Equatable {
    let id: UUID
    let name: String
    private(set) var score: Int
    private(set) var gamesPlayed: Int
    private(set) var gamesWon: Int
    private(set) var totalWordsGuessed: Int
    private(set) var wordsSkipped: Int
    
    init(id: UUID = UUID(),
         name: String,
         score: Int = 0,
         gamesPlayed: Int = 0,
         gamesWon: Int = 0,
         totalWordsGuessed: Int = 0,
         wordsSkipped: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.totalWordsGuessed = totalWordsGuessed
        self.wordsSkipped = wordsSkipped
    }
    
    mutating func updateScore(_ points: Int, skippedWords: Int, guessedWords: Int) {
        score += points
        wordsSkipped += skippedWords
        totalWordsGuessed += guessedWords
    }
    
    mutating func incrementGamesPlayed(didWin: Bool) {
        gamesPlayed += 1
        if didWin {
            gamesWon += 1
        }
    }
    
    mutating func resetScore() {
        score = 0
        wordsSkipped = 0
        totalWordsGuessed = 0
    }
}
