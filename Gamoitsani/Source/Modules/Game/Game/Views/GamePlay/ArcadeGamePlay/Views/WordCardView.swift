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
                Spacer()
                GMLabelView(text: word, fontType: .bold, fontSizeForPhone: ViewConstants.wordFontSize)
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
    }
    
    private enum ViewConstants {
        static let wordFontSize: CGFloat = 18
        static let cardHeight: CGFloat = 44
        static let cardCornerRadius: CGFloat = 12
    }
}

#Preview {
    Group {
        WordCardView(word: "სიტყვა1", isGuessed: false, action: {})
        WordCardView(word: "ძალიანგრძელისიტყვავნახოთთუდაეტევაძალიანგრძელისიტყვავნახოთთუდაეტევა", isGuessed: true, action: {})
        WordCardView(word: "სიტყვა3", isGuessed: true, action: {})
        WordCardView(word: "სიტყვა4", isGuessed: false, action: {})
        WordCardView(word: "სიტყვა5", isGuessed: false, action: {})
    }
}
