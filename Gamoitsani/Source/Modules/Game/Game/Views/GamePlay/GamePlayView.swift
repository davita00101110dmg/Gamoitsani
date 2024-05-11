//
//  GamePlayView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

protocol GamePlayViewDelegate: AnyObject {
    func timerDidFinished(roundScore: Int)
}

final class GamePlayView: UIView {
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var timerLabel: UILabel!
    
    @IBOutlet weak var correctButton: GMButton!
    @IBOutlet weak var incorrectButton: GMButton!
    
    private var words: [String] = []
    private var roundLength: Double = 0.0
    
    private var roundLengthTimer: Timer?
    private var countdownTimer: Timer?
    
    private let audioManager: AudioManager = {
        let manager = AudioManager()
        manager.setupSounds()
        return manager
    }()
    
    private weak var delegate: GamePlayViewDelegate?
    //TODO: Review this
    var viewModel: GamePlayViewModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(0.3)
        layer.cornerRadius = 10
        [wordLabel, timerLabel].forEach {
            $0.textColor = Asset.tintColor.color
        }
        wordLabel.font = F.BPGNinoMtavruli.bold.font(size: 32)
        timerLabel.font = F.BPGNinoMtavruli.bold.font(size: 100)
        
        correctButton.configure(text: .empty, isCircle: true)
        correctButton.backgroundColor = Asset.green.color
        incorrectButton.configure(text: .empty, isCircle: true)
        incorrectButton.backgroundColor = Asset.red.color
    }
    
    func configure(with model: GamePlayViewModel, delegate: GamePlayViewDelegate) {
        self.delegate = delegate
        roundLengthTimer = Timer.scheduledTimer(withTimeInterval: model.roundLength, repeats: false, block: timerBlock(_:))
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: updateTimerLabel(timer:))
        
        viewModel = model
        words = model.words
        roundLength = model.roundLength
        
        timerLabel.text = roundLength.toString()
        wordLabel.text = words.popLast()
    }
    
    private func timerBlock(_: Timer) -> Void {
        countdownTimer?.invalidate()
        roundLengthTimer?.invalidate()
        delegate?.timerDidFinished(roundScore: viewModel.score)
    }
    
    private func updateTimerLabel(timer: Timer) -> Void {
        roundLength -= 1
        if roundLength > 0 {
            timerLabel.text = roundLength.toString()
        }
    }
    
    private func updateWordLabel(with word: String?) {
        wordLabel.text = word
    }
    
    private func wordButtonAction(tag: Int) { // Tag 1: Correct Tag 2: Incorrect
        audioManager.playSound(tag: tag)
        updateWordLabel(with: words.popLast())
        viewModel.score += tag == 1 ? 1 : -1
    }
    
    @IBAction func correctWordAction(_ sender: UIButton) {
        wordButtonAction(tag: sender.tag)
    }
    
    @IBAction func incorrectButtonAction(_ sender: UIButton) {
        wordButtonAction(tag: sender.tag)
    }
}
