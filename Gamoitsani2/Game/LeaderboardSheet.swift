//
//  LeaderboardSheet.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniEngine
import GamoitsaniL10n

/// Standings, on demand between turns.
struct LeaderboardSheet: View {
    let engine: GameEngine

    @Environment(Localization.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    private var standings: [Team] { engine.standings }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(standings.enumerated()), id: \.element.id) { rank, team in
                        row(rank: rank + 1, team: team)
                        if rank < standings.count - 1 {
                            Divider().overlay(Tokens.cardEdge.color)
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)
                .background(Tokens.surfaceRaised.color)
                .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
                .padding(Spacing.md)
            }
            .background(Tokens.surface.color.ignoresSafeArea())
            .navigationTitle(l10n("game.leaderboard"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n("common.done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.surface.color)
    }

    private func row(rank: Int, team: Team) -> some View {
        // Colour by the team's seat at the table, not by its current rank — a team's
        // colour has to stay the same as the standings move around.
        let seat = engine.state.teams.firstIndex(where: { $0.id == team.id }) ?? 0
        let isCurrent = engine.currentTeam?.id == team.id

        return HStack(spacing: Spacing.sm) {
            Text("\(rank)")
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .frame(width: 18, alignment: .leading)

            Circle()
                .fill(TeamPalette.color(at: seat).color)
                .frame(width: 10, height: 10)

            Text(team.name)
                .font(Typography.rowTitle)
                .foregroundStyle(Tokens.onSurface.color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if isCurrent {
                Text(l10n("game.upNow"))
                    .font(Typography.label)
                    .foregroundStyle(Tokens.accent.color)
            }

            Spacer()

            Text("\(team.score)")
                .font(Typography.numeral(22))
                .foregroundStyle(Tokens.onSurface.color)
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}
