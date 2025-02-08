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
    
    override func onGameStart() {
        super.onGameStart()
        updateCurrentWord()
    }
    
    func wordButtonAction(tag: Int) {
        let isCorrect = tag == 1
        playSound(isCorrect: isCorrect)
        updateScore(points: isCorrect ? 1 : -1, wasSkipped: !isCorrect)
        updateCurrentWord()
    }
    
    private func updateCurrentWord() {
        guard let word = words.popLast() else {
            currentWord = L10n.Screen.Game.NoMoreWords.message
            return
        }
        currentWord = getTranslation(for: word)
    }
}
