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
    let isSuperWord: Bool
    let action: () -> Void
    
    var body: some View {
        Group {
            if isSuperWord {
                 RainbowBorderCardView(word: word, isGuessed: isGuessed, action: action)
            } else {
                Button(action: action) {
                    GMLabelView(text: word, fontType: .bold)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Asset.gmSecondary.swiftUIColor)
                        )
                }
                .opacity(isGuessed ? 0.4 : 1)
            }
        }
        .animation(.easeOut(duration: 0.3), value: isGuessed)
    }
}
