//
//  GMButton.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMButton: UIButton {
    
    private var isCircle: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateCornerRadius()
    }
    
    public func configure(with text: String,
                          fontSizeForPhone: CGFloat = Constants.buttonPhoneFontSize,
                          fontSizeForPad: CGFloat = Constants.buttonPadFontSize,
                          isCircle: Bool = false,
                          backgroundColor: UIColor? = Asset.secondary.color,
                          textColor: UIColor? = .white) {
        
        self.isCircle = isCircle
        setTitle(text, for: .normal)
        setTitleColor(textColor, for: .normal)
        
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
        titleLabel?.font = F.Mersad.bold.font(size: fontSize)
        
        if isCircle {
            applyCircleStyle(backgroundColor: backgroundColor)
        } else {
            applyDefaultStyle(fontSize: fontSize, backgroundColor: backgroundColor)
        }
        
        layoutIfNeeded()
    }
    
    private func updateCornerRadius() {
        if isCircle {
            layer.cornerRadius = bounds.size.width / 2
        }
    }
    
    private func applyCircleStyle(backgroundColor: UIColor?) {
        self.backgroundColor = backgroundColor
        layer.cornerRadius = bounds.size.width / 2
    }
    
    private func applyDefaultStyle(fontSize: CGFloat, backgroundColor: UIColor?) {
        var configuration = UIButton.Configuration.filled()
        
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = F.Mersad.bold.font(size: fontSize)
            return outgoing
        }
        
        configuration.baseBackgroundColor = backgroundColor
        configuration.baseForegroundColor = .white
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 0, bottom: 0, trailing: 0)
        configuration.cornerStyle = .large
        self.configuration = configuration
    }
}

private extension GMButton {
    enum Constants {
        static let buttonPhoneFontSize: CGFloat = 18
        static let buttonPadFontSize: CGFloat = 24
    }
}
