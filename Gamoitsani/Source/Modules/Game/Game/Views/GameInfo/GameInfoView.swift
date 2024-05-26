//
//  GameInfoView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

protocol GameInfoViewDelegate: AnyObject {
    func didPressStart()
    func didPressShowScoreboard()
}

final class GameInfoView: UIView {
    
    @IBOutlet weak var roundCountLabel: GMLabel!
    @IBOutlet weak var teamNameLabel: GMLabel!
    
    @IBOutlet weak var startButton: GMButton!
    @IBOutlet weak var scoreButton: GMButton!
    
    private weak var delegate: GameInfoViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color.withAlphaComponent(Constants.backgroundColorAlpha)
        layer.cornerRadius = Constants.viewCornerRadius
        startButton.configure(with: L10n.start, fontSizeForPad: Constants.buttonFontSizeForPad, isCircle: true)
        scoreButton.configure(with: L10n.scoreboard)
    }
    
    func configure(with model: GameInfoViewModel, delegate: GameInfoViewDelegate) {
        self.delegate = delegate
        
        var roundCountLabelText = L10n.Screen.Game.CurrentRound.message(model.currentRound.toString)
        if let currentExtraRound = model.currentExtraRound, currentExtraRound > 0 {
            roundCountLabelText.append(String.whitespace)
            roundCountLabelText.append(L10n.Screen.Game.CurrentExtraRound.message(currentExtraRound.toString))
        }
        
        roundCountLabel.configure(with: roundCountLabelText,
                                  fontSizeForPad: Constants.labelFontSizeForPad)
        teamNameLabel.configure(with: model.teamName,
                                fontSizeForPad: Constants.labelFontSizeForPad)
    }
    
    @IBAction func startAction(_ sender: Any) {
        delegate?.didPressStart()
    }
    
    @IBAction func showScoreAction(_ sender: Any) {
        delegate?.didPressShowScoreboard()
    }
}

// MARK: - View Constants
extension GameInfoView {
    enum Constants {
        static let backgroundColorAlpha: CGFloat = 0.3
        static let viewCornerRadius: CGFloat = 10
        static let labelFontSizeForPad: CGFloat = 32
        static let buttonFontSizeForPad: CGFloat = 32
    }
}
