//
//  GameSettingsTeamTableViewCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameSettingsTeamTableViewCell: UITableViewCell {

    @IBOutlet weak var teamName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    func configure(with model: GameSettingsTeamTableViewCellModel) {
        teamName.text = "\(model.firstMemberName) \(L10n.and) \(model.secondMemberName)"
    }

    private func setupUI() {
        backgroundColor = Asset.secondary.color
    }
}
