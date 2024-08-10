//
//  SettingsChangeLanguageCell.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class SettingsChangeLanguageCell: UITableViewCell {

    @IBOutlet weak var title: GMLabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = Asset.secondary.color
        layer.cornerRadius = 10
        title.configure(with: "Change language", fontType: .regular, fontSizeForPhone: 12)
        segmentedControl.selectedSegmentIndex = 0 // TODO: user defaults
        
    }
    
    @IBAction func segmentChanged(_ sender: Any) {
        let languageIdentifier = segmentedControl.selectedSegmentIndex == 0 ? AppConstants.Language.georgian.identifier : AppConstants.Language.english.identifier

        UserDefaults.appLanguage = languageIdentifier
        
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}
