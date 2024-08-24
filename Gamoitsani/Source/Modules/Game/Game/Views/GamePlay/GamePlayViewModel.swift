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

final class GamePlayViewModel: ObservableObject {

    @Published var words: [Word]
    @Published var timeRemaining: Double
    @Published var score: Int = 0
    @Published var currentWord: String?
    
    var audioManager: AudioManager
    var onTimerFinished: ((Int) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    private var shouldShowGeorgianWords: Bool { !AppConstants.isAppInEnglish }
    
    init(words: [Word], roundLength: Double, audioManager: AudioManager) {
        self.words = words
        self.timeRemaining = roundLength
        self.audioManager = audioManager
        
        updateCurrentWord()
    }

    func startGame() {
        
        var roundLength = timeRemaining
        
        #if DEBUG
//        roundLength = 2
        #endif
        
        Timer.publish(every: roundLength, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.stopGame()
                self?.onTimerFinished?(self?.score ?? 0)
            }
            .store(in: &cancellables)
        
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
            .store(in: &cancellables)
    }
    
    func stopGame() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    func wordButtonAction(tag: Int) {
        audioManager.playSound(tag: tag)
        score += tag == 1 ? 1 : -1
        updateCurrentWord()
    }

    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
    }

    private func updateCurrentWord() {
        guard let word = shouldShowGeorgianWords ? words.popLast()?.wordKa : words.popLast()?.wordEn else {
            currentWord = L10n.Screen.Game.NoMoreWords.message
            return
        }
        currentWord = word
    }
}
