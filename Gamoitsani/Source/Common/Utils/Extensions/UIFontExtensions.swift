//
//  UIFontExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UIFont {
    // Add language related fonts here
    static func appFont(type: AppConstants.FontType, size: CGFloat) -> UIFont {
        if LanguageManager.shared.isAppInUkrainian {
            switch type {
            case .regular:
                return F.Ubuntu.medium.font(size: size)
            case .semiBold, .bold:
                return F.Ubuntu.bold.font(size: size)
            }
        } else {
            switch type {
            case .regular:
                return F.Mersad.regular.font(size: size)
            case .semiBold:
                return F.Mersad.semiBold.font(size: size)
            case .bold:
                return F.Mersad.bold.font(size: size)
            }
        }
    }
}
