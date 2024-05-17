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
        backgroundColor = Asset.secondary.color.withAlphaComponent(0.3)
        layer.cornerRadius = 10
        startButton.configure(text: L10n.start, isCircle: true)
        scoreButton.configure(text: L10n.scoreboard)
    }
    
    func configure(with model: GameInfoViewModel, delegate: GameInfoViewDelegate) {
        self.delegate = delegate
        
        roundCountLabel.configure(with: L10n.Screen.Game.CurrentRound.message(model.currentRound.toString))
        teamNameLabel.configure(with: model.teamName)
    }
    
    @IBAction func startAction(_ sender: Any) {
        delegate?.didPressStart()
    }
    
    @IBAction func showScoreAction(_ sender: Any) {
        delegate?.didPressShowScoreboard()
    }
}
