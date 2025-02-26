//
//  RainbowText.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct RainbowText: View {
    let text: String
    var fontType: AppConstants.FontType = .bold
    var fontSizeForPhone: CGFloat = Constants.wordLabelFontSizeForPhone
    var fontSizeForPad: CGFloat = Constants.wordLabelFontSizeForPad
    var textAlignment: TextAlignment = .center
    
    @State private var animationPhase: CGFloat = 0.0
    
    private let colors = [
        Asset.color11.swiftUIColor,
        Asset.color12.swiftUIColor,
        Asset.color13.swiftUIColor,
        Asset.color14.swiftUIColor,
        Asset.color11.swiftUIColor
    ]
    
    var body: some View {
        Text(text)
            .font(font)
            .bold()
            .multilineTextAlignment(textAlignment)
            .rainbowAnimation()
    }
    
    private var fontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? Constants.wordLabelFontSizeForPad : Constants.wordLabelFontSizeForPhone
    }
    
    private var font: SwiftUI.Font {
        switch fontType {
        case .regular:
            return F.Mersad.regular.swiftUIFont(size: fontSize)
        case .semiBold:
            return F.Mersad.semiBold.swiftUIFont(size: fontSize)
        case .bold:
            return F.Mersad.bold.swiftUIFont(size: fontSize)
        }
    }
}

private extension RainbowText {
    enum Constants {
        static let wordLabelFontSizeForPhone: CGFloat = 32
        static let wordLabelFontSizeForPad: CGFloat = 52
    }
}
