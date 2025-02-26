//
//  GamePlayViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

final class ClassicGamePlayViewModel: BaseGamePlayViewModel {
    @Published var currentWord: String?
    @Published var isSuperWord: Bool = false
    
    private var gameStory = GameStory.shared
    private var wordsShown: Int = 0
    
    private let superWordPosition = Int.random(in: 1...5)
    
    override func onGameStart() {
        super.onGameStart()
        updateCurrentWord()
    }
    
    func wordButtonAction(tag: Int) {
        let isCorrect = tag == 1
        
        let points: Int
        if isSuperWord {
            points = isCorrect ? WordItem.Constants.superWordPoints : -WordItem.Constants.superWordPoints
            
            if isCorrect {
                gameStory.incrementSuperWordsGuessed()
            }
        } else {
            points = isCorrect ? WordItem.Constants.regularPoints : WordItem.Constants.skippedRegularPoints
        }
        
        playSound(isCorrect: isCorrect, isSuper: isSuperWord)
        updateScore(points: points, wasSkipped: !isCorrect)
        
        if isSuperWord {
            gameStory.markSuperWordEncountered()
        }
        
        updateCurrentWord()
    }
    
    private func updateCurrentWord() {
        guard let word = words.popLast() else {
            currentWord = L10n.Screen.Game.NoMoreWords.message
            isSuperWord = false
            return
        }
        
        wordsShown += 1
        currentWord = getTranslation(for: word)
        
        isSuperWord = shouldBeSuperWord()
    }
    
    private func shouldBeSuperWord() -> Bool {
        if !gameStory.isSuperWordEnabled {
            return false
        }
        
        if gameStory.hasSuperWordEncountered() {
            return false
        }
        
        return wordsShown == superWordPosition
    }
}
