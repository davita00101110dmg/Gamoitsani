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
                          textAlignment: NSTextAlignment = .center) {
        
        let fontSize = UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
        
        switch fontType {
        case .regular:
            font = .appFont(type: .regular, size: fontSize)
        case .semiBold:
            font = .appFont(type: .semiBold, size: fontSize)
        case .bold:
            font = .appFont(type: .bold, size: fontSize)
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
