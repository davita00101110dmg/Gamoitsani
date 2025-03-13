//
//  AudioManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 09/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import AVFoundation

final class AudioManager {
    
    var correctSoundAudioPlayer: AVAudioPlayer?
    var superCorrectSoundAudioPlayer: AVAudioPlayer?
    var incorrectSoundAudioPlayer: AVAudioPlayer?
    var countdownTickAudioPlayer: AVAudioPlayer?
    var countdownGoAudioPlayer: AVAudioPlayer?
    
    func setupSounds() {
        let correctSoundUrl = Bundle.main.url(forResource: "correct", withExtension: "wav")
        let superCorrectSoundUrl = Bundle.main.url(forResource: "super-correct", withExtension: "mp3")
        let incorrectSoundUrl = Bundle.main.url(forResource: "incorrect", withExtension: "mp3")
        let countdownTickUrl = Bundle.main.url(forResource: "countdown_tick", withExtension: "wav")
        let countdownGoUrl = Bundle.main.url(forResource: "countdown_go", withExtension: "wav")
        
        do {
            if let correctSound = correctSoundUrl {
                correctSoundAudioPlayer = try AVAudioPlayer(contentsOf: correctSound)
            }
            
            if let superCorrectSound = superCorrectSoundUrl {
                superCorrectSoundAudioPlayer = try AVAudioPlayer(contentsOf: superCorrectSound)
            }
            
            if let incorrectSound = incorrectSoundUrl {
                incorrectSoundAudioPlayer = try AVAudioPlayer(contentsOf: incorrectSound)
            }
            
            if let tick = countdownTickUrl {
                countdownTickAudioPlayer = try AVAudioPlayer(contentsOf: tick)
            }
            
            if let go = countdownGoUrl {
                countdownGoAudioPlayer = try AVAudioPlayer(contentsOf: go)
            }
            
            correctSoundAudioPlayer?.prepareToPlay()
            incorrectSoundAudioPlayer?.prepareToPlay()
            countdownTickAudioPlayer?.prepareToPlay()
            countdownGoAudioPlayer?.prepareToPlay()
        } catch let error {
            log(.error, "Failed to setup sounds: \(error.localizedDescription)")
        }
    }
    
    private func play(audioPlayer: AVAudioPlayer?) {
        guard let player = audioPlayer else { return }
        player.currentTime = 0
        player.play()
    }
    
    func playSound(tag: Int) {
        switch tag {
        case 0:
            play(audioPlayer: incorrectSoundAudioPlayer)
        case 1:
            play(audioPlayer: correctSoundAudioPlayer)
        case 2:
            play(audioPlayer: superCorrectSoundAudioPlayer)
        default:
            return
        }
    }
    
    func playCountdownTick() {
        play(audioPlayer: countdownTickAudioPlayer)
    }
    
    func playCountdownGo() {
        play(audioPlayer: countdownGoAudioPlayer)
    }
    
    deinit {
        correctSoundAudioPlayer?.stop()
        superCorrectSoundAudioPlayer?.stop()
        incorrectSoundAudioPlayer?.stop()
        countdownTickAudioPlayer?.stop()
        countdownGoAudioPlayer?.stop()
        
        correctSoundAudioPlayer = nil
        superCorrectSoundAudioPlayer = nil
        incorrectSoundAudioPlayer = nil
        countdownTickAudioPlayer = nil
        countdownGoAudioPlayer = nil
    }
}
