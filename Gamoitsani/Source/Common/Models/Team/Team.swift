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
    private(set) var totalWordsGuessed: Int
    private(set) var wordsSkipped: Int
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var totalGuessTime: TimeInterval = 0
    private(set) var lastGuessStartTime: Date?
    private(set) var skippedSets: Int = 0
    private(set) var superWordsGuessed: Int = 0
    
    var averageGuessTime: TimeInterval {
        guard totalWordsGuessed > 0 else { return 0 }
        return totalGuessTime / Double(totalWordsGuessed)
    }
    
    var formattedAverageTime: String {
        String(format: "%.1fs", averageGuessTime)
    }
    
    init(id: UUID = UUID(),
         name: String,
         score: Int = 0,
         totalWordsGuessed: Int = 0,
         wordsSkipped: Int = 0,
         currentStreak: Int = 0,
         bestStreak: Int = 0,
         totalGuessTime: TimeInterval = 0,
         skippedSets: Int = 0,
         superWordsGuessed: Int = 0) {
        self.id = id
        self.name = name
        self.score = score
        self.totalWordsGuessed = totalWordsGuessed
        self.wordsSkipped = wordsSkipped
        self.currentStreak = currentStreak
        self.bestStreak = bestStreak
        self.totalGuessTime = totalGuessTime
        self.skippedSets = skippedSets
        self.superWordsGuessed = superWordsGuessed
    }
    
    mutating func startGuessing() {
        lastGuessStartTime = Date()
    }
    
    mutating func updateStreak(guessedCorrectly: Bool) {
        if let startTime = lastGuessStartTime {
            totalGuessTime += Date().timeIntervalSince(startTime)
            lastGuessStartTime = nil
        }
            
        if guessedCorrectly {
            totalWordsGuessed += 1
            currentStreak += 1
            bestStreak = max(bestStreak, currentStreak)
        } else {
            wordsSkipped += 1
            currentStreak = 0
        }
    }
    
    mutating func updateScore(_ points: Int) {
        score += points
    }
    
    mutating func resetScore() {
        score = 0
        wordsSkipped = 0
        totalWordsGuessed = 0
        currentStreak = 0
        bestStreak = 0
        totalGuessTime = 0
        skippedSets = 0
        superWordsGuessed = 0
    }
    
    mutating func incrementSkippedSets() {
        skippedSets += 1
    }
    
    mutating func incrementSuperWordsGuessed() {
        superWordsGuessed += 1
    }
}
