//
//  GameSettingsTeamTableViewCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameSettingsTeamTableViewCell: UITableViewCell {

    @IBOutlet weak var teamName: GMLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color
        layer.cornerRadius = 10
    }
    
    func configure(with team: String) {
        teamName.configure(with: team)
    }
}
