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
    
    @IBOutlet weak var wordLabel: GMLabel!
    @IBOutlet weak var timerLabel: GMLabel!
    
    @IBOutlet weak var correctButton: GMButton!
    @IBOutlet weak var incorrectButton: GMButton!
    
    private var words: [Word] = []
    private var roundLength: Double = 0.0
    
    private var roundLengthTimer: Timer?
    private var countdownTimer: Timer?
    
    private var audioManager: AudioManager?
    
    private weak var delegate: GamePlayViewDelegate?
    
    private var viewModel: GamePlayViewModel?
    
    private var shouldShowGeorgianWords: Bool {
        UserDefaults.appLanguage == AppConstants.Language.georgian.identifier
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        invalidateTimers()
    }
    
    private func invalidateTimers() {
        roundLengthTimer?.invalidate()
        countdownTimer?.invalidate()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(Constants.backgroundColorAlpha)
        layer.cornerRadius = Constants.viewCornerRadius
        
        correctButton.configure(with: Constants.correctSymbol,
                                fontSizeForPhone: Constants.correctIncorrectButtonFontSizeForPhone,
                                fontSizeForPad: Constants.correctIncorrectButtonFontSizeForPad,
                                isCircle: true,
                                backgroundColor: Asset.green.color)
        incorrectButton.configure(with: Constants.incorrectSymbol,
                                  fontSizeForPhone: Constants.correctIncorrectButtonFontSizeForPhone,
                                  fontSizeForPad: Constants.correctIncorrectButtonFontSizeForPad,
                                  isCircle: true,
                                  backgroundColor: Asset.red.color)
    }

    func configure(with model: GamePlayViewModel, audioManager: AudioManager, delegate: GamePlayViewDelegate) {
        self.delegate = delegate
        self.audioManager = audioManager
        
        roundLengthTimer = Timer.scheduledTimer(withTimeInterval: model.roundLength, repeats: false, block: timerBlock(_:))
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: updateTimerLabel(timer:))
        
        viewModel = model
        words = model.words
        roundLength = model.roundLength
        
        wordLabel.configure(with: (shouldShowGeorgianWords ? words.popLast()?.wordKa : words.popLast()?.wordEn) ?? L10n.Screen.Game.NoMoreWords.message,
                            fontType: .bold,
                            fontSizeForPhone: Constants.wordLabelFontSizeForPhone,
                            fontSizeForPad: Constants.wordLabelFontSizeForPad)
        timerLabel.configure(with: roundLength.toString(),
                             fontSizeForPhone: Constants.timerLabelFontSizeForPhone,
                             fontSizeForPad: Constants.timerLabelFontSizeForPad)
    }
    
    private func timerBlock(_: Timer) -> Void {
        invalidateTimers()
        delegate?.timerDidFinished(roundScore: viewModel?.score ?? 0)
    }
    
    private func updateTimerLabel(timer: Timer) -> Void {
        roundLength -= 1
        if roundLength > 0 {
            timerLabel.text = roundLength.toString()
        }
    }
    
    private func updateWordLabel(with word: String?) {
        wordLabel.text = word ?? L10n.Screen.Game.NoMoreWords.message
    }
    
    private func wordButtonAction(tag: Int) { // Tag 1: Correct Tag 2: Incorrect
        audioManager?.playSound(tag: tag)
        
        updateWordLabel(with: shouldShowGeorgianWords ? words.popLast()?.wordKa : words.popLast()?.wordEn)
        viewModel?.score += tag == 1 ? 1 : -1
    }
    
    @IBAction func correctWordAction(_ sender: UIButton) {
        wordButtonAction(tag: sender.tag)
    }
    
    @IBAction func incorrectButtonAction(_ sender: UIButton) {
        wordButtonAction(tag: sender.tag)
    }
}

// MARK: - View Constants
extension GamePlayView {
    enum Constants {
        static let correctSymbol: String = "✓"
        static let incorrectSymbol: String = "✘"
        static let backgroundColorAlpha: CGFloat = 0.3
        static let viewCornerRadius: CGFloat = 10
        static let wordLabelFontSizeForPhone: CGFloat = 32
        static let wordLabelFontSizeForPad: CGFloat = 52
        static let timerLabelFontSizeForPhone: CGFloat = 100
        static let timerLabelFontSizeForPad: CGFloat = 150
        
        static let correctIncorrectButtonFontSizeForPhone: CGFloat = 30
        static let correctIncorrectButtonFontSizeForPad: CGFloat = 60
    }
}
