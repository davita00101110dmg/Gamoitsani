//
//  FontExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

extension SwiftUI.Font {
    // Add language related fonts here
    static func appFont(type: AppConstants.FontType, size: CGFloat) -> SwiftUI.Font {
        if LanguageManager.shared.isAppInUkrainian {
            switch type {
            case .regular:
                return F.Ubuntu.medium.swiftUIFont(size: size)
            case .semiBold, .bold:
                return F.Ubuntu.bold.swiftUIFont(size: size)
            }
        } else {
            switch type {
            case .regular:
                return F.Mersad.regular.swiftUIFont(size: size)
            case .semiBold:
                return F.Mersad.semiBold.swiftUIFont(size: size)
            case .bold:
                return F.Mersad.bold.swiftUIFont(size: size)
            }
        }
    }
}
