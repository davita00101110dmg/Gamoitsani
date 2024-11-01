//
//  TeamRowView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct TeamRowView: View {
    let team: GameDetailsTeam
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: Layout.iconTextSpacing) {
                Image(systemName: Layout.teamIcon)
                    .foregroundColor(Asset.gmPrimary.swiftUIColor)
                    .font(.system(size: Layout.iconSize))
                
                GMLabelView(text: team.name, fontSizeForPhone: Layout.fontSize, textAlignment: .leading)
                    .lineLimit(1)
            }
            
            Spacer()
            
            HStack(spacing: Layout.buttonSpacing) {
                actionButton(
                    icon: AppConstants.SFSymbol.squareAndPencil,
                    action: onEdit
                )
                
                actionButton(
                    icon: AppConstants.SFSymbol.trash,
                    action: onDelete
                )
            }
        }
        .padding(.horizontal, Layout.horizontalPadding)
        .frame(height: Layout.rowHeight)
    }
    
    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: Layout.iconSize))
        }
    }
}

private extension TeamRowView {
    enum Layout {
        static let iconTextSpacing: CGFloat = 8
        static let buttonSpacing: CGFloat = 16
        static let horizontalPadding: CGFloat = 16
        static let rowHeight: CGFloat = 44
        static let iconSize: CGFloat = 16
        static let fontSize: CGFloat = 16
        static let buttonOpacity: Double = 0.7
        static let teamIcon = "person.2.fill"
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
