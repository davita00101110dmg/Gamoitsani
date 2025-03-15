//
//  RandomChallengeToggleRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct RandomChallengeToggleRow: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            GMLabelView(
                text: L10n.Screen.GameDetails.RandomChallenge.description,
                textAlignment: .leading
            )
            
            Spacer()
            
            Toggle(String.empty, isOn: $isEnabled)
                .toggleStyle(CheckToggleStyle())
        }
        .animation(.easeInOut, value: isEnabled)
    }
}
