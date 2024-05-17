//
//  GMLabel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMLabel: UILabel {

    public func configure(with string: String?, fontSize: CGFloat = 16, color: UIColor = .white) {
        text = string
        font = F.BPGNinoMtavruli.bold.font(size: fontSize)
        textColor = color
    }
    
}

private extension GMLabel {
    enum Constants {
        
    }
}
