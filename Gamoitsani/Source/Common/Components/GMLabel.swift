//
//  GMLabel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMLabel: UILabel {
    public func configure(with string: String?,
                          fontType: AppConstants.FontType = .semiBold,
                          fontSizeForPhone: CGFloat = Constants.labelPhoneFontSize,
                          fontSizeForPad: CGFloat = Constants.labelPadFontSize,
                          color: UIColor = .white) {
        
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
        
        switch fontType {
        case .regular:
            font = F.Mersad.regular.font(size: fontSize)
        case .semiBold:
            font = F.Mersad.semiBold.font(size: fontSize)
        case .bold:
            font = F.Mersad.bold.font(size: fontSize)
        }
        
        text = string ?? .empty
        textColor = color
    }
}

private extension GMLabel {
    enum Constants {
        static let labelPhoneFontSize: CGFloat = 16
        static let labelPadFontSize: CGFloat = 24
    }
}
