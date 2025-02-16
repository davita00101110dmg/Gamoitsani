//
//  TeamTab.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct TeamTab: View {
    let team: Team
    let isSelected: Bool
    let isWinner: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GMLabelView(text: team.name)
                .font(F.Mersad.semiBold.swiftUIFont(size: 14))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Asset.gmPrimary.swiftUIColor : Asset.gmSecondary.swiftUIColor)
                )
                .overlay(
                    Capsule()
                        .stroke(isWinner ? Asset.gmPrimary.swiftUIColor : .clear, lineWidth: 2)
                )
        }
        .foregroundColor(.white)
    }
}
