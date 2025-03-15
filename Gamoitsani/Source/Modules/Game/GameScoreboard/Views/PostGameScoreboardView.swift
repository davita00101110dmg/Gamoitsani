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
    let isWinner: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            headerSection
                .padding(.top)
            
            mainStatsSection
            
            performanceStatsSection
            
            Spacer(minLength: 24)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 36))
                .foregroundColor(isWinner ? Asset.gmPrimary.swiftUIColor : .gray)
                .opacity(isWinner ? 1 : 0.5)
            
            VStack(spacing: 8) {
                GMLabelView(text: team.name)
                    .font(F.Mersad.bold.swiftUIFont(size: 24))
                
                GMLabelView(text: L10n.Screen.GameScoreboard.PostGameScoreboard.finalScore(team.score.toString))
                    .font(F.Mersad.bold.swiftUIFont(size: 32))
                    .foregroundColor(Asset.gmPrimary.swiftUIColor)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Asset.gmSecondary.swiftUIColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isWinner ? Asset.gmPrimary.swiftUIColor : Color.white.opacity(0.5),
                                lineWidth: isWinner ? 2 : 1)
                )
        )
        .padding(.horizontal)
    }
    
    private var mainStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: L10n.Screen.GameScoreboard.PostGameScoreboard.wordsGuessed,
                value: "\(team.totalWordsGuessed)",
                icon: "checkmark.circle.fill",
                color: .white
            )
            
            Divider()
                .frame(width: 1, height: 80)
                .background(Color.white.opacity(0.5))
            
            StatCard(
                title: L10n.Screen.GameScoreboard.PostGameScoreboard.wordsSkipped,
                value: "\(team.wordsSkipped)",
                icon: "xmark.circle.fill",
                color: Asset.gmRed.swiftUIColor
            )
        }
        .padding(.horizontal)
    }
    
    private var performanceStatsSection: some View {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Asset.gmSecondary.swiftUIColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

#Preview {
    PostGameScoreboardView(team: .init(name: "Team 1"), isWinner: true)
}
