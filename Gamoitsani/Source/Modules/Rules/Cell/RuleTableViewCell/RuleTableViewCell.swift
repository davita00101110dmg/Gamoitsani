//
//  RuleTableViewCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class RuleTableViewCell: UITableViewCell {

    @IBOutlet weak var ruleLabel: GMLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        layer.masksToBounds = true
        backgroundColor = Asset.secondary.color
        layer.cornerRadius = 10
    }
    
    func configure(with text: String?) {
        ruleLabel.configure(with: text, textAlignment: .left)
    }
}
