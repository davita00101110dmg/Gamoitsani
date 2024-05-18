//
//  GMButton.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMButton: UIButton {
    
    var cornerRadius: CGFloat {
        didSet {
            layer.cornerRadius = self.cornerRadius
        }
    }
    
    init() {
        self.cornerRadius = Constants.cornerRadius
        super.init(frame: .zero)
    }

    required public init?(coder: NSCoder) {
        self.cornerRadius = Constants.cornerRadius
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = self.cornerRadius
    }
    
    public func configure(with text: String,
                          fontSizeForPhone: CGFloat = Constants.buttonPhoneFontSize,
                          fontSizeForPad: CGFloat = Constants.buttonPadFontSize,
                          isCircle: Bool = false,
                          backgroundColor: UIColor? = Asset.secondary.color,
                          textColor: UIColor? = .white) {
                
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
        
        setTitle(text, for: .normal)
        setTitleColor(textColor, for: .normal)
        titleLabel?.font = F.Mersad.bold.font(size: fontSize)
        
        if isCircle {
            applyCircleStyle(backgroundColor: backgroundColor)
        } else {
            applyDefaultStyle(fontSize: fontSize, backgroundColor: backgroundColor)
        }
        
        layoutIfNeeded()
    }
    
    private func applyCircleStyle(backgroundColor: UIColor?) {
        cornerRadius = frame.width / 2
        self.backgroundColor = backgroundColor
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
        static let cornerRadius: CGFloat = 12
        static let buttonPhoneFontSize: CGFloat = 18
        static let buttonPadFontSize: CGFloat = 24
    }
}
