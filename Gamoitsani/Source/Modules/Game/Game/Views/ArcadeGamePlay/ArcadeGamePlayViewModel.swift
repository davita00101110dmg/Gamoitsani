//
//  ArcadeGamePlayViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import Combine

final class ArcadeGamePlayViewModel: ObservableObject {
    @Published var currentWords: [WordItem] = []
    @Published var timeRemaining: Double
    @Published var score: Int = 0
    @Published var isGameActive: Bool = false
    
    var audioManager: AudioManager
    var onTimerFinished: ((Int) -> Void)?
    
    private var words: [Word]
    private var cancellables = Set<AnyCancellable>()
    private var currentLanguage: Language {
        LanguageManager.shared.currentLanguage
    }
    
    struct WordItem: Identifiable {
        let id = UUID()
        let word: Word
        let translation: String
        var isGuessed: Bool = false
    }
    
    init(words: [Word], roundLength: Double, audioManager: AudioManager) {
        self.words = words
        self.timeRemaining = roundLength
        self.audioManager = audioManager
    }
    
    func startGame() {
        isGameActive = true
        updateCurrentWords()
        startTimer()
    }
    
    func stopGame() {
        isGameActive = false
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    func wordGuessed(id: UUID) {
        guard let index = currentWords.firstIndex(where: { $0.id == id }) else { return }
        
        audioManager.playSound(tag: 1)
        score += 1
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentWords[index].isGuessed = true
        }
        
        if currentWords.allSatisfy({ $0.isGuessed }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.updateCurrentWords()
            }
        }
    }
    
    func skipCurrentSet() {
        score += GameMode.arcade.skipPenalty
        audioManager.playSound(tag: 0)
        updateCurrentWords()
    }
    
    private func startTimer() {
        Timer.publish(every: timeRemaining, on: .main, in: .common)
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
    
    private func updateTimer() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
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
    
    private func getTranslation(for word: Word) -> String {
        guard let translations = word.wordTranslations as? Set<Translation>,
              let translation = translations.first(where: { $0.languageCode == currentLanguage.rawValue }) else {
            return word.baseWord ?? .empty
        }
        return translation.word ?? word.baseWord ?? .empty
    }
}
