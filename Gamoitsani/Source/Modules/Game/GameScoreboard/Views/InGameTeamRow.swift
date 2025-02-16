//
//  InGameTeamRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct InGameTeamRow: View {
    let team: Team
    let isCurrentTeam: Bool
    
    var body: some View {
        HStack {
            GMLabelView(text: team.name)
                .font(F.Mersad.regular.swiftUIFont(size: 16))
            
            Spacer()
            
            GMLabelView(text: "\(team.score) \(L10n.point)")
                .font(F.Mersad.semiBold.swiftUIFont(size: 16))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Asset.gmSecondary.swiftUIColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isCurrentTeam ? Asset.gmPrimary.swiftUIColor : .clear, lineWidth: 2)
                )
        )
        .foregroundColor(.white)
    }
}
