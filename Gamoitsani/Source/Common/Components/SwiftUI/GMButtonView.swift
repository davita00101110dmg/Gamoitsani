//
//  GMButtonView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

// TODO: Add scale animation
struct GMButtonView: View {
    var text: String
    var fontSizeForPhone: CGFloat = Constants.buttonPhoneFontSize
    var fontSizeForPad: CGFloat = Constants.buttonPadFontSize
    var isCircle: Bool = false
    var backgroundColor: Color? = Asset.secondary.swiftUIColor
    var textColor: Color? = .white
    var height: CGFloat = Constants.buttonHeight
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(F.Mersad.bold.swiftUIFont(size: fontSize))
                .foregroundColor(textColor ?? .white)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, maxHeight: height)
        }
        .buttonStyle(GMButtonStyle(isCircle: isCircle, backgroundColor: backgroundColor, height: height))
    }

    private var fontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
    }
}

struct GMButtonStyle: ButtonStyle {
    var isCircle: Bool
    var backgroundColor: Color?
    var height: CGFloat

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: isCircle ? height : nil, height: height)
            .background(
                backgroundColor
                    .cornerRadius(isCircle ? height / 2 : 12)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension GMButtonView {
    enum Constants {
        static let buttonPhoneFontSize: CGFloat = 18
        static let buttonPadFontSize: CGFloat = 24
        static let buttonHeight: CGFloat = 44
    }
}
