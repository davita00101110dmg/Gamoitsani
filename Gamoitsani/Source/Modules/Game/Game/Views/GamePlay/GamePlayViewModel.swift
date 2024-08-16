//
//  GamePlayViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

class GamePlayViewModel: ObservableObject {

    private var roundLengthTimer: Timer?
    private var countdownTimer: Timer?
    
    private var shouldShowGeorgianWords: Bool { !AppConstants.isAppInEnglish }

    @Published var words: [Word]
    @Published var timeRemaining: Double
    @Published var score: Int = 0
    @Published var currentWord: String?
    
    var audioManager: AudioManager
    var onTimerFinished: ((Int) -> Void)?
    
    init(words: [Word], roundLength: Double, audioManager: AudioManager) {
        self.words = words
        self.timeRemaining = roundLength
        self.audioManager = audioManager
    }

    func startGame() {
        
        var roundLength = timeRemaining
        
        #if DEBUG
        roundLength = 2
        #endif
        
        roundLengthTimer = Timer.scheduledTimer(withTimeInterval: roundLength, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.stopGame()
            self.onTimerFinished?(self.score) // Assuming you have onTimerFinished closure in the view model
        }
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.updateTimer()
        }
        
        updateCurrentWord()
    }
    
    func stopGame() {
        invalidateTimers()
    }
    
    func wordButtonAction(tag: Int) {
        audioManager.playSound(tag: tag)
        score += tag == 1 ? 1 : -1
        updateCurrentWord()
    }
    
    private func invalidateTimers() {
        roundLengthTimer?.invalidate()
        countdownTimer?.invalidate()
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
    }

    private func updateCurrentWord() {
        currentWord = (shouldShowGeorgianWords ? words.popLast()?.wordKa : words.popLast()?.wordEn)
                        ?? L10n.Screen.Game.NoMoreWords.message
    }
    
}
