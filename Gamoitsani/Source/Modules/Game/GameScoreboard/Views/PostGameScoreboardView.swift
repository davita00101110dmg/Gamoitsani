//
//  PostGameScoreboardView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PostGameScoreboardView: View {
    let team: Team
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                GMLabelView(text: team.name)
                    .font(F.Mersad.bold.swiftUIFont(size: 24))
                
                GMLabelView(text: L10n.Screen.GameScoreboard.PostGameScoreboard.finalScore(team.score.toString))
                    .font(F.Mersad.semiBold.swiftUIFont(size: 20))
            }
            .foregroundColor(.white)
            .padding(.top, 24)
            
            HStack(spacing: 20) {
                StatCard(
                    title: L10n.Screen.GameScoreboard.PostGameScoreboard.wordsGuessed,
                    value: "\(team.totalWordsGuessed)",
                    icon: "checkmark.circle.fill",
                    color: Asset.gmGreen.swiftUIColor
                )
                
                StatCard(
                    title: L10n.Screen.GameScoreboard.PostGameScoreboard.wordsSkipped,
                    value: "\(team.wordsSkipped)",
                    icon: "xmark.circle.fill",
                    color: Asset.gmRed.swiftUIColor
                )
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                PerformanceStatRow(
                    title: L10n.Screen.GameScoreboard.PostGameScoreboard.bestStreak,
                    value: "\(team.bestStreak)",
                    icon: "flame.fill"
                )
                
                PerformanceStatRow(
                    title: L10n.Screen.GameScoreboard.PostGameScoreboard.averageTime,
                    value: team.formattedAverageTime,
                    icon: "timer"
                )
                
                if GameStory.shared.gameMode == .arcade {
                    PerformanceStatRow(
                        title: L10n.Screen.GameScoreboard.PostGameScoreboard.setsSkipped,
                        value: "\(team.skippedSets)",
                        icon: "arrow.right.circle.fill"
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Asset.gmSecondary.swiftUIColor)
            )
            .padding(.horizontal)
            
            Spacer(minLength: 24) 
        }
    }
}
