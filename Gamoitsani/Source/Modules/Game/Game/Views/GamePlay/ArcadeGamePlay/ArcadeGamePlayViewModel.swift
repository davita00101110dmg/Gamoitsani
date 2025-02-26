//
//  ArcadeGamePlayViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

final class ArcadeGamePlayViewModel: BaseGamePlayViewModel {
    
    @Published var currentWords: [WordItem] = []
    private var gameStory = GameStory.shared
    private var setsShown: Int = 0
    private let superWordSetPosition = Int.random(in: 1...2)
    private let superWordPositionInSet = Int.random(in: 1...5)
    
    override func onGameStart() {
        super.onGameStart()
        setsShown = 1
        updateCurrentWords()
        gameStory.startGuessing()
    }
    
    func wordGuessed(id: UUID) {
        guard let index = currentWords.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentWords[index].isGuessed.toggle()
            let wordItem = currentWords[index]
            
            updateScore(points: wordItem.points, wasSkipped: !wordItem.isGuessed)
            playSound(isCorrect: wordItem.isGuessed, isSuper: wordItem.isSuperWord)
        }
        
        if currentWords.allSatisfy({ $0.isGuessed }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateCurrentWords()
                self?.gameStory.startGuessing()
            }
        }
    }
    
    func skipCurrentSet() {
        let penaltyPoints = GameMode.arcade.skipPenalty
        
        gameStory.incrementSkippedSets()
        
        updateScore(points: penaltyPoints, wasSkipped: true)
        
        playSound(isCorrect: false)
        updateCurrentWords()
        gameStory.startGuessing()
    }
    
    private func updateCurrentWords() {
        let newWords = (0..<GameDetailsConstants.Game.arcadeWordCount).compactMap { index -> WordItem? in
            guard let word = words.popLast() else { return nil }
            
            let isSuperWord = shouldBeSuperWord(wordIndex: index + 1)
            
            if isSuperWord {
                gameStory.markSuperWordEncountered()
            }
            
            return WordItem(
                word: word,
                translation: getTranslation(for: word),
                isSuperWord: isSuperWord
            )
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWords = newWords
        }
        
        if !newWords.isEmpty {
            setsShown += 1
        }
    }
    
    private func shouldBeSuperWord(wordIndex: Int) -> Bool {
        if !gameStory.isSuperWordEnabled {
            return false
        }
        
        if gameStory.hasSuperWordEncountered() {
            return false
        }
        
        return setsShown == superWordSetPosition && wordIndex == superWordPositionInSet
    }
}
