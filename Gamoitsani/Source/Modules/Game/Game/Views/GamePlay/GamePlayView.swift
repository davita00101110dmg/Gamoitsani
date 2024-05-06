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
    
    private weak var delegate: GamePlayViewDelegate?
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
        
        correctButton.configure(text: "✅", isCircle: true)
        incorrectButton.configure(text: "❌", isCircle: true)
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
    
    @IBAction func correctWordAction(_ sender: Any) {
        updateWordLabel(with: words.popLast())
        viewModel.score += 1
    }
    
    @IBAction func incorrectButtonAction(_ sender: Any) {
        updateWordLabel(with: words.popLast())
        viewModel.score -= 1
    }
}
