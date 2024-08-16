//
//  GameShareView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

// TODO: Test this view when i will implement this feature
struct GameShareView: View {
    var viewModel: GameOverViewModel

    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                GMLabelView(
                    text: L10n.Screen.Game.GameShareView.title(viewModel.teamName, viewModel.score.toString),
                    fontType: .bold,
                    fontSizeForPhone: Constants.appNameLabelFontSizeForPhone,
                    fontSizeForPad: Constants.appNameLabelFontSizeForPad
                )
                
                tableView
                
                HStack {
                    Image(.logo)
                        .resizable()
                        .frame(maxWidth: 56, maxHeight: 56)
                    
                    appNameLabel
                    Spacer()
                }
            }
            .padding(.bottom, 8)
        }
    }
    
    private var appNameLabel: some View {
        GMLabelView(
            text: L10n.App.title,
            textAlignment: .leading
        )
    }
    
    private var tableView: some View {
        List {
            ForEach(teams, id: \.name) { team in
                GameScoreboardTeamView(model: team)
                    .listRowSeparatorTint(Color.white)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
        }
        .listStyle(.plain)
        .background(Asset.secondary.swiftUIColor)
        .cornerRadius(Constants.tableViewCornerRadius)
    }
    
    private var teams: [GameScoreboardTeamTableViewModel] {
        #if DEBUG
        [
            .init(name: "ხვიჩა და გოჩა", score: 12),
            .init(name: "123", score: 132),
            .init(name: "123", score: 132),
            .init(name: "123", score: 132),
            .init(name: "123", score: 132),
        ]
        #else
        GameStory.shared.teams
            .sorted { $0.value > $1.value }
            .map { GameScoreboardTeamTableViewModel(name: $0.key, score: $0.value) }
        #endif
    }
}

// MARK: - View Constants
extension GameShareView {
    enum Constants {
        static let appNameLabelFontSizeForPhone: CGFloat = 18
        static let appNameLabelFontSizeForPad: CGFloat = 36
        static let tableViewCornerRadius: CGFloat = 8
        static let backgroundColorAlpha: CGFloat = 0.3
        static let viewCornerRadius: CGFloat = 10
    }
}

#Preview {
    GameShareView(viewModel: GameOverViewModel(teamName: "ხვიჩა და გოჩა", score: 10))
}
