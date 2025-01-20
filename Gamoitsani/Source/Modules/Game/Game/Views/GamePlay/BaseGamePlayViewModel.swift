//
//  BaseGamePlayViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

class BaseGamePlayViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var timeRemaining: Double
    @Published var score: Int = 0
    @Published var isGameActive: Bool = false
    
    // MARK: - Protected Properties
    var words: [Word]
    var audioManager: AudioManager
    var onTimerFinished: ((Int) -> Void)?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentLanguage: Language {
        LanguageManager.shared.currentLanguage
    }
    
    // MARK: - Initialization
    init(words: [Word], roundLength: Double, audioManager: AudioManager) {
        self.words = words
        self.timeRemaining = roundLength
        self.audioManager = audioManager
    }
    
    // MARK: - Game Control Methods
    func startGame() {
        isGameActive = true
        startTimer()
        onGameStart()
    }
    
    func stopGame() {
        isGameActive = false
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        onGameStop()
    }
    
    // MARK: - Timer Methods
    private func startTimer() {
#if DEBUG
        let shouldUseQuickTimer = UserDefaults.isQuickGameEnabled
        let timerDuration = shouldUseQuickTimer ? 2.0 : timeRemaining
#else
        let timerDuration = timeRemaining
#endif
        // End game timer
        Timer.publish(every: timerDuration, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.handleGameEnd()
            }
            .store(in: &cancellables)
        
        // Countdown timer
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
            .store(in: &cancellables)
    }
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
    }
    
    private func handleGameEnd() {
        stopGame()
        onTimerFinished?(score)
    }
    
    // MARK: - Utility Methods
    func getTranslation(for word: Word) -> String {
        guard let translations = word.wordTranslations as? Set<Translation>,
              let translation = translations.first(where: { $0.languageCode == currentLanguage.rawValue }) else {
            return word.baseWord ?? .empty
        }
        return translation.word ?? word.baseWord ?? .empty
    }
    
    func playSound(isCorrect: Bool) {
        audioManager.playSound(tag: isCorrect ? 1 : 0)
    }
    
    // MARK: - Template Methods (to be overridden by subclasses)
    func onGameStart() {
        // Override in subclass if needed
    }
    
    func onGameStop() {
        // Override in subclass if needed
    }
    
    func updateScore(points: Int) {
        score += points
    }
}
