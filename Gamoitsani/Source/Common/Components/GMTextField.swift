//
//  GMTextField.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMTextField: UITextField {
    
    var cornerRadius: CGFloat {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }

    init() {
        self.cornerRadius = Constants.cornerRadius
        super.init(frame: .zero)
        setupTextField()
    }
    
    
    required init?(coder: NSCoder) {
        self.cornerRadius = Constants.cornerRadius
        super.init(coder: coder)
        setupTextField()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }
    
    
    private func setupTextField() {
        cornerRadius = 12
        backgroundColor = Asset.secondary.color
        font = F.BPGNinoMtavruli.bold.font(size: 18)
        textColor = .white
    }
}

private extension GMTextField {
    enum Constants {
        static let cornerRadius: CGFloat = 12
    }
}
