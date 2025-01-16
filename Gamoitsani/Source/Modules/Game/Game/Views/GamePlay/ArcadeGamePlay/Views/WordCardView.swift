//
//  WordCardView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct WordCardView: View {
    let word: String
    let isGuessed: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(word)
                    .font(F.Mersad.bold.swiftUIFont(size: ViewConstants.wordFontSize))
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Spacer()
            }
            .frame(height: ViewConstants.cardHeight)
            .background(
                RoundedRectangle(cornerRadius: ViewConstants.cardCornerRadius)
                    .fill(Asset.gmSecondary.swiftUIColor)
            )
        }
        .opacity(isGuessed ? 0.4 : 1)
        .animation(.easeOut(duration: 0.3), value: isGuessed)
        .disabled(isGuessed)
    }
    
    private enum ViewConstants {
        static let wordFontSize: CGFloat = 18
        static let cardHeight: CGFloat = 56
        static let cardCornerRadius: CGFloat = 12
    }
}

