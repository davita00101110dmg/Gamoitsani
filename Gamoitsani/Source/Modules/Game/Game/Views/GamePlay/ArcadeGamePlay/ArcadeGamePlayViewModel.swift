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
    struct WordItem: Identifiable, Equatable {
        let id = UUID()
        let word: Word
        let translation: String
        var isGuessed: Bool = false
    }
    
    @Published var currentWords: [WordItem] = []
    
    override func onGameStart() {
        super.onGameStart()
        updateCurrentWords()
    }
    
    func wordGuessed(id: UUID) {
        guard let index = currentWords.firstIndex(where: { $0.id == id }) else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentWords[index].isGuessed.toggle()
            
            if currentWords[index].isGuessed {
                updateScore(points: 1, wasSkipped: false)
                playSound(isCorrect: true)
            } else {
                updateScore(points: -1, wasSkipped: true)
                playSound(isCorrect: false)
            }
        }
        
        if currentWords.allSatisfy({ $0.isGuessed }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateCurrentWords()
            }
        }
    }
    
    func skipCurrentSet() {
        let unguessedCount = currentWords.filter { !$0.isGuessed }.count
        let penaltyPoints = GameMode.arcade.skipPenalty
        updateScore(points: penaltyPoints, wasSkipped: true)
        playSound(isCorrect: false)
        updateCurrentWords()
    }
    
    private func updateCurrentWords() {
        let newWords = (0..<GameDetailsConstants.Game.arcadeWordCount).compactMap { _ -> WordItem? in
            guard let word = words.popLast() else { return nil }
            return WordItem(word: word, translation: getTranslation(for: word))
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentWords = newWords
        }
    }
}
