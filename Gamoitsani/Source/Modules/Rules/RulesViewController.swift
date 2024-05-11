//
//  RulesViewController.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class RulesViewController: BaseViewController<RulesCoordinator> {
    
    @IBOutlet weak var textView: UITextView!
    
    override func setupUI() {
        super.setupUI()
        
        textView.backgroundColor = Asset.secondary.color.withAlphaComponent(0.5)
        
        textView.layer.cornerRadius = 10
        textView.textColor = .white
    }
    
    override func setupLocalizedTexts() {
        super.setupLocalizedTexts()
        
        title = L10n.Screen.Rules.title
        
        let style = NSMutableParagraphStyle()
        let text = NSAttributedString(string: L10n.Screen.Rules.rules,
                                      attributes: [
                                        .paragraphStyle: style,
                                        .font: F.BPGNinoMtavruli.bold.font(size: 18)])
        
        style.alignment = .left
        style.lineSpacing = 5
        
        textView.attributedText = text
    }
}
