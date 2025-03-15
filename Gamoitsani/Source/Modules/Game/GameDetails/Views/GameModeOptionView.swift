//
//  GameModeOptionView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/01/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameModeOptionView: View {
    let mode: GameMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    GMLabelView(
                        text: mode.title,
                        fontType: .semiBold,
                        fontSizeForPhone: 16,
                        textAlignment: .leading
                    )
                    
                    GMLabelView(
                        text: mode.description,
                        fontSizeForPhone: 14,
                        color: .white.opacity(0.7),
                        textAlignment: .leading
                    )
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Asset.gmPrimary.swiftUIColor.opacity(0.15) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Asset.gmPrimary.swiftUIColor : .white.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}
