//
//  FontExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

extension SwiftUI.Font {
    static func appFont(type: AppConstants.FontType, size: CGFloat) -> SwiftUI.Font {
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
