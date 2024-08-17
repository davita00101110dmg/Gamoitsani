//
//  GameScoreboardTeamView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 15/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameScoreboardTeamView: View {
    let model: GameScoreboardTeamTableViewModel // TODO: Create own model here

    var body: some View {
        HStack {
            GMLabelView(text: model.name)
            Spacer()
            GMLabelView(text: "\(model.score) \(L10n.point)")
        }
        .padding()
        .background(Asset.secondary.swiftUIColor)
        .cornerRadius(10)
    }
}
