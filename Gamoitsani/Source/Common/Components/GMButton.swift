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
    
    public func configure(text: String, fontSize: CGFloat = 18, isCircle: Bool = false) {
        
        if isCircle {
            cornerRadius = frame.width / 2
            titleLabel?.font = F.BPGNinoMtavruli.bold.font(size: fontSize)
            backgroundColor = Asset.secondary.color
        } else {
            var configuration = UIButton.Configuration.filled()
            
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = F.BPGNinoMtavruli.bold.font(size: fontSize)
                return outgoing
            }
            
            configuration.baseBackgroundColor = Asset.secondary.color
            configuration.baseForegroundColor = UIColor.white
            configuration.contentInsets = NSDirectionalEdgeInsets.init(top: 5, leading: 0, bottom: 0, trailing: 0)
            configuration.cornerStyle = .large
            self.configuration = configuration
        }
        
        setTitle(text, for: .normal)
        layoutIfNeeded()
    }

}

private extension GMButton {
    enum Constants {
        static let cornerRadius: CGFloat = 12
    }
}
