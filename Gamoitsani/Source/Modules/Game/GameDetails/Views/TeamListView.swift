//
//  TeamListView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct TeamListView: View {
    let teams: [GameDetailsTeam]
    let onEdit: (Int) -> Void
    let onDelete: (Int) -> Void
    let onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            teamsList
            Divider()
                .background(Color.white.opacity(Layout.dividerOpacity))
                .padding(.horizontal)
            addTeamButton
        }
    }
    
    private var teamsList: some View {
        ForEach(teams.indices, id: \.self) { index in
            VStack(spacing: 0) {
                TeamRowView(
                    team: teams[index],
                    onEdit: { onEdit(index) },
                    onDelete: { onDelete(index) }
                )
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                    removal: .scale(scale: 0.5).combined(with: .opacity)
                ))
                
                if index != teams.count - 1 {
                    Divider()
                        .background(Color.white.opacity(Layout.dividerOpacity))
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private var addTeamButton: some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: Layout.addButtonIcon)
                    .foregroundColor(.white)
                    .font(.system(size: Layout.iconSize))
                
                GMLabelView(text: L10n.Screen.GameDetails.Teams.add, fontSizeForPhone: Layout.fontSize)
                
                Spacer()
            }
            .padding(Layout.addButtonPadding)
        }
    }
}

private extension TeamListView {
    enum Layout {
        static let dividerOpacity: Double = 0.2
        static let addButtonIcon = "plus.circle.fill"
        static let iconSize: CGFloat = 16
        static let fontSize: CGFloat = 16
        static let addButtonPadding: EdgeInsets = .init(
            top: 12,
            leading: 16,
            bottom: 12,
            trailing: 16
        )
    }
}

#Preview("With Items") {
    TeamListView(
        teams: [
            .init(name: "გუნდი 1"),
            .init(name: "გუნდი 2"),
            .init(name: "გუნდი 3")
        ],
        onEdit: { _ in },
        onDelete: { _ in },
        onAdd: {}
    )
    .frame(height: 200)
    .padding()
    .background(Asset.gmSecondary.swiftUIColor)
}

#Preview("Single Row") {
    TeamRowView(
        team: .init(name: "გუნდი 1"),
        onEdit: {},
        onDelete: {}
    )
    .padding()
    .background(Asset.gmSecondary.swiftUIColor)
}

#Preview("Empty List") {
    ZStack {
        TeamListView(
            teams: [],
            onEdit: { _ in },
            onDelete: { _ in },
            onAdd: {}
        )
        .frame(height: 100)
    }
    .padding()
    .background(Asset.gmSecondary.swiftUIColor)
}
