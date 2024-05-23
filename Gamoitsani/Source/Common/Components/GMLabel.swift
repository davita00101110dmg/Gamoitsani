//
//  GMLabel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 05/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GMLabel: UILabel {
    public func configure(with text: String?,
                          fontType: AppConstants.FontType = .semiBold,
                          fontSizeForPhone: CGFloat = Constants.labelPhoneFontSize,
                          fontSizeForPad: CGFloat = Constants.labelPadFontSize,
                          color: UIColor = .white,
                          lineHeightMultiple: CGFloat = Constants.lineHeightMultipleConstant,
                          textAlignment: NSTextAlignment = .left) {
        
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
        
        switch fontType {
        case .regular:
            font = F.Mersad.regular.font(size: fontSize)
        case .semiBold:
            font = F.Mersad.semiBold.font(size: fontSize)
        case .bold:
            font = F.Mersad.bold.font(size: fontSize)
        }
        
        setLineSpacing(lineHeightMultiple: lineHeightMultiple, textAlignment: textAlignment)
        textColor = color
        self.text = text
    }
}

private extension GMLabel {
    enum Constants {
        static let labelPhoneFontSize: CGFloat = 16
        static let labelPadFontSize: CGFloat = 24
        static let lineHeightMultipleConstant: CGFloat = 1.3
    }
}
