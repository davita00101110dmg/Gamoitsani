//
//  GMTextField.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMTextField: UITextField {
    
    enum PaddingSpace {
        case left(CGFloat)
        case right(CGFloat)
        case equalSpacing(CGFloat)
    }

    var cornerRadius: CGFloat = 8 {
        didSet {
            layer.cornerRadius = cornerRadius
        }
    }
    
    init() {
        super.init(frame: .zero)
        setupTextField()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTextField()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }

    func addPadding(padding: PaddingSpace) {

        leftViewMode = .always
        layer.masksToBounds = true

        switch padding {
        case .left(let spacing):
            let leftPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: frame.height))
            leftView = leftPaddingView
            leftViewMode = .always

        case .right(let spacing):
            let rightPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: frame.height))
            rightView = rightPaddingView
            rightViewMode = .always

        case .equalSpacing(let spacing):
            let equalPaddingView = UIView(frame: CGRect(x: 0, y: 0, width: spacing, height: frame.height))
            leftView = equalPaddingView
            leftViewMode = .always
            rightView = equalPaddingView
            rightViewMode = .always
        }
    }
    
    private func setupTextField() {
        backgroundColor = Asset.secondary.color
        font = F.Mersad.bold.font(size: 18)
        textColor = .white
    }
}
