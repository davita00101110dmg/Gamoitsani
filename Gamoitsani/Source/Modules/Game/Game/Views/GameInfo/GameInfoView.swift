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
        [roundCountLabel, teamNameLabel].forEach {
            $0.font = F.BPGNinoMtavruli.bold.font(size: 16)
            $0.textColor = Asset.tintColor.color
        }

        startButton.configure(text: "დაწყება", isCircle: true)
        scoreButton.configure(text: "ანგარიში")
    }
    
    func configure(with model: GameInfoViewModel, delegate: GameInfoViewDelegate) {
        self.delegate = delegate
        
        roundCountLabel.text = "რაუნდი \(model.currentRound)"
        teamNameLabel.text = model.teamName
    }
    
    @IBAction func startAction(_ sender: Any) {
        delegate?.didPressStart()
    }
    
    @IBAction func showScoreAction(_ sender: Any) {
        delegate?.didPressShowScoreboard()
    }
}
