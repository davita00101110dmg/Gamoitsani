//
//  GameScoreboardTeamTableViewCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameScoreboardTeamTableViewCell: UITableViewCell {
    
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color
        layer.cornerRadius = 10
        [teamLabel, scoreLabel].forEach { $0.textColor = Asset.tintColor.color }
    }
    
    func configure(with model: GameScoreboardTeamTableViewModel) {
        teamLabel.text = model.name
        scoreLabel.text = "\(model.score) \(L10n.point)"
    }
}
