//
//  PlayerListView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PlayerListView: View {
    let players: [GameDetailsPlayer]
    let onAdd: () -> Void
    let onDelete: (Int) -> Void
    let onGenerateTeams: () -> Void
    
    var body: some View {
        VStack(spacing: Layout.spacing) {
            playersGrid
            
            VStack(spacing: Layout.buttonSpacing) {
                addButton
                createTeamsButton
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
    
    private var playersGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ],
            spacing: Layout.gridSpacing
        ) {
            ForEach(players.indices, id: \.self) { index in
                PlayerRowView(
                    name: players[index].name,
                    index: index,
                    onDelete: { onDelete(index) }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.5).combined(with: .opacity)
                ))
            }
        }
        .padding()
    }
    
    private var addButton: some View {
        GMButtonView(
            text: L10n.add,
            fontSizeForPhone: Layout.buttonFontSize,
            backgroundColor: Asset.gmPrimary.swiftUIColor,
            height: Layout.buttonHeight,
            action: onAdd
        )
    }
    
    private var createTeamsButton: some View {
        GMButtonView(
            text: L10n.Screen.GameDetails.createTeams,
            fontSizeForPhone: Layout.buttonFontSize,
            backgroundColor: Asset.gmPrimary.swiftUIColor,
            height: Layout.buttonHeight,
            action: onGenerateTeams
        )
    }
    
    private enum Layout {
        static let spacing: CGFloat = 16
        static let buttonSpacing: CGFloat = 12
        static let gridSpacing: CGFloat = 8
        static let buttonFontSize: CGFloat = 16
        static let buttonHeight: CGFloat = 44
    }
}
