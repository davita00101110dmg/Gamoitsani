//
//  GMButtonView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GMButtonView: View {
    var text: String
    var fontSizeForPhone: CGFloat = Constants.buttonPhoneFontSize
    var fontSizeForPad: CGFloat = Constants.buttonPadFontSize
    var isCircle: Bool = false
    var backgroundColor: Color? = Asset.secondary.swiftUIColor
    var textColor: Color? = .white
    var height: CGFloat = Constants.buttonHeight
    var shouldLowerOpacityOnPress: Bool = true
    var shouldScaleOnPress: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(F.Mersad.bold.swiftUIFont(size: fontSize))
                .foregroundColor(textColor ?? .white)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, maxHeight: height)
        }
        .buttonStyle(
            GMButtonStyle(
                isCircle: isCircle,
                backgroundColor: backgroundColor,
                height: height,
                shouldLowerOpacityOnPress: shouldLowerOpacityOnPress,
                shouldScaleOnPress: shouldScaleOnPress
            )
        )
    }
    
    private var fontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? fontSizeForPad : fontSizeForPhone
    }
}

struct GMButtonStyle: ButtonStyle {
    var isCircle: Bool
    var backgroundColor: Color?
    var height: CGFloat
    var shouldLowerOpacityOnPress: Bool
    var shouldScaleOnPress: Bool
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(width: isCircle ? height : nil, height: height)
            .background(
                backgroundColor
                    .cornerRadius(isCircle ? height / 2 : 12)
            )
            .opacity(shouldLowerOpacityOnPress ? configuration.isPressed ? 0.7 : 1 : 1)
            .scaleEffect(shouldScaleOnPress ? configuration.isPressed ? 1.15 : 1 : 1)
    }
}

extension GMButtonView {
    enum Constants {
        static let buttonPhoneFontSize: CGFloat = 18
        static let buttonPadFontSize: CGFloat = 24
        static let buttonHeight: CGFloat = 44
    }
}
