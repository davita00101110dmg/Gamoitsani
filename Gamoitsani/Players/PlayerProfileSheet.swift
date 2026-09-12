//
//  PlayerProfileSheet.swift
//  Gamoitsani
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// One player's record.
struct PlayerProfileSheet: View {
    let name: String

    @Environment(PlayerBook.self) private var players
    @Environment(Localization.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    private var record: PlayerRecord? { players.record(for: name) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    Text(name)
                        .font(Typography.display(34))
                        .foregroundStyle(Tokens.onSurface.color)
                        .padding(.top, Spacing.lg)

                    if let record, record.gamesPlayed > 0 {
                        SetupPanel(title: l10n("players.record")) {
                            stat(l10n("players.games"), "\(record.gamesPlayed)")
                            Divider().overlay(Tokens.cardEdge.color)
                            stat(l10n("players.won"), "\(record.gamesWon)")
                            Divider().overlay(Tokens.cardEdge.color)
                            stat(l10n("players.described"), "\(record.wordsDescribed)")
                            Divider().overlay(Tokens.cardEdge.color)
                            stat(l10n("players.bestTurn"), "\(record.bestTurn)")
                        }
                    } else {
                        // Somebody added to the roster who has not finished a game yet.
                        Text(l10n("players.none"))
                            .font(Typography.body)
                            .foregroundStyle(Tokens.onSurfaceMuted.color)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(Spacing.md)
            }
            .background(Tokens.surface.color.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n("common.done")) { dismiss() }
                        .tint(Tokens.onSurface.color)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.surface.color)
    }

    private func stat(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(Typography.rowTitle)
                .foregroundStyle(Tokens.onSurface.color)
            Spacer()
            Text(value)
                .font(Typography.numeral(28))
                .foregroundStyle(Tokens.accent.color)
                .monospacedDigit()
        }
        .padding(.vertical, Spacing.sm)
        .accessibilityElement(children: .combine)
    }
}

/// Everyone who has ever played on this device.
struct PlayersSheet: View {
    @Environment(PlayerBook.self) private var players
    @Environment(Localization.self) private var l10n
    @Environment(\.dismiss) private var dismiss
    @State private var selected: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                if players.all.isEmpty {
                    Text(l10n("players.none"))
                        .font(Typography.body)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                        .multilineTextAlignment(.center)
                        .padding(Spacing.xl)
                } else {
                    SetupPanel(title: l10n("players.title")) {
                        ForEach(Array(players.all.enumerated()), id: \.element.id) { index, record in
                            Button { selected = record.name } label: {
                                HStack {
                                    Text(record.name)
                                        .font(Typography.rowTitle)
                                        .foregroundStyle(Tokens.onSurface.color)
                                    Spacer()
                                    Text("\(record.gamesPlayed) · \(record.wordsDescribed)")
                                        .font(Typography.label)
                                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                                        .monospacedDigit()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                                }
                                .padding(.vertical, Spacing.sm)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .combine)

                            if index < players.all.count - 1 {
                                Divider().overlay(Tokens.cardEdge.color)
                            }
                        }
                    }
                    .padding(Spacing.md)
                }
            }
            .background(Tokens.surface.color.ignoresSafeArea())
            .navigationTitle(l10n("players.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n("common.done")) { dismiss() }
                        .tint(Tokens.onSurface.color)
                }
            }
        }
        .sheet(item: $selected) { name in
            // Handed the environment explicitly: presented content inherits from wherever
            // the sheet was attached, which is a trap this codebase has hit twice.
            PlayerProfileSheet(name: name)
                .environment(players)
                .environment(l10n)
        }
        .presentationBackground(Tokens.surface.color)
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
