//
//  GameScoreboardTeamTableViewCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameScoreboardTeamTableViewCell: UITableViewCell {
    
    @IBOutlet weak var teamLabel: GMLabel!
    @IBOutlet weak var scoreLabel: GMLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color
        layer.cornerRadius = 10
    }
    
    func configure(with model: GameScoreboardTeamTableViewModel) {
        teamLabel.configure(with: model.name)
        scoreLabel.configure(with: "\(model.score) \(L10n.point)")
    }
}
