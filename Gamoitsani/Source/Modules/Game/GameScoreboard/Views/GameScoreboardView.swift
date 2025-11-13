//
//  GameScoreboardView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 08/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameScoreboardView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel = GameScoreboardViewModel()
    var gameStory: GameStory
    
    private var isGameInProgress: Bool {
        GameStory.shared.isGameInProgress
    }
    
    var body: some View {
        ZStack {
            Asset.gmSecondary.swiftUIColor.ignoresSafeArea()
            
            if GameStory.shared.isGameFinished  {
                postGameScoreboard
            } else {
                inGameScoreboard
            }
        }
    }
    
    private var inGameScoreboard: some View {
        VStack(spacing: 16) {
            GMLabelView(text: L10n.scoreboard)
                .font(F.Mersad.semiBold.swiftUIFont(size: 20))
                .foregroundColor(.white)
                .padding(.top)
            
            ForEach(viewModel.teams) { team in
                InGameTeamRow(
                    team: team,
                    isCurrentTeam: team.id == GameStory.shared.currentTeam?.id
                )
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var postGameScoreboard: some View {
        VStack(spacing: 0) {
            if let selectedTeam = viewModel.teams.first(where: { $0.id == viewModel.selectedTeamId }) {
                ScrollView(showsIndicators: false) {
                    PostGameScoreboardView(team: selectedTeam, isWinner: viewModel.winningTeam?.id == selectedTeam.id)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.teams) { team in
                        TeamTab(
                            team: team,
                            isSelected: team.id == viewModel.selectedTeamId,
                            isWinner: team.id == viewModel.winningTeam?.id
                        ) {
                            withAnimation {
                                viewModel.selectTeam(team.id)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}
