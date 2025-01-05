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
    var incorrectSoundAudioPlayer: AVAudioPlayer?
    
    func setupSounds() {
        guard let correctSoundUrl = Bundle.main.url(forResource: "correct", withExtension: "wav") else { return }
        guard let incorrectSoundUrl = Bundle.main.url(forResource: "incorrect", withExtension: "mp3") else { return }
        do {
            correctSoundAudioPlayer = try AVAudioPlayer(contentsOf: correctSoundUrl)
            incorrectSoundAudioPlayer = try AVAudioPlayer(contentsOf: incorrectSoundUrl)
            correctSoundAudioPlayer?.prepareToPlay()
            incorrectSoundAudioPlayer?.prepareToPlay()
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
        default:
            return
        }
    }
    
    deinit {
        correctSoundAudioPlayer?.stop()
        incorrectSoundAudioPlayer?.stop()
        correctSoundAudioPlayer = nil
        incorrectSoundAudioPlayer = nil
    }
}
