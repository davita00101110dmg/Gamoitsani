//
//  GMLabelView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GMLabelView: View {
    var text: String?
    var fontType: AppConstants.FontType = .semiBold
    var fontSizeForPhone: CGFloat = Constants.labelPhoneFontSize
    var fontSizeForPad: CGFloat = Constants.labelPadFontSize
    var color: Color = .white
    var lineHeightMultiple: CGFloat = Constants.lineHeightMultipleConstant
    var textAlignment: TextAlignment = .center

    var body: some View {
        Text(text ?? .empty)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(textAlignment)
            .lineSpacing(lineHeight)
    }

    private var fontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
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

    private var lineHeight: CGFloat {
        (fontSize * lineHeightMultiple) - fontSize
    }
}

private extension GMLabelView {
    enum Constants {
        static let labelPhoneFontSize: CGFloat = 16
        static let labelPadFontSize: CGFloat = 24
        static let lineHeightMultipleConstant: CGFloat = 1.3
    }
}
