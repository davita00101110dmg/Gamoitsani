//
//  GameOverView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniEngine
import GamoitsaniL10n

/// The podium.
struct GameOverView: View {
    let engine: GameEngine
    let onFinish: () -> Void

    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SoundPlayer.self) private var sound
    @State private var barsGrown = false
    @State private var showStats = false
    @State private var card: UIImage?

    private var standings: [Team] { engine.standings }
    private var winner: Team? { engine.winner }
    /// Three at most, spread across teams — past that the card stops reading at
    /// thumbnail size.
    private var awards: [Award] { Awards.featured(for: engine.state.teams, limit: 3) }

    @ViewBuilder
    private var shareButton: some View {
        if let card {
            ShareLink(
                item: ShareableCard(image: card),
                preview: SharePreview(l10n("share.preview"), image: Image(uiImage: card))
            ) {
                Label(l10n("game.share"), systemImage: "square.and.arrow.up")
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(SecondaryButtonStyle(reduceMotion: reduceMotion))
        } else {
            // Placeholder holds the row's shape while the card renders.
            Text(l10n("game.share"))
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .opacity(0.4)
        }
    }

    /// Renders the card off-screen at 3x.
    @MainActor
    private func renderCard() -> UIImage? {
        let renderer = ImageRenderer(
            content: ShareCard(
                standings: standings,
                teams: engine.state.teams,
                awards: awards,
                mode: engine.state.settings.mode,
                rounds: engine.state.settings.rounds
            )
            // Nothing is inherited here — the card is rendered outside the view tree, so
            // anything it reads from the environment has to be handed to it.
            .environment(l10n)
        )
        renderer.scale = 3
        return renderer.uiImage
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Text(l10n("game.over"))
                    .font(Typography.display(36))
                    .foregroundStyle(Tokens.onSurface.color)

                if let winner {
                    Text("\(winner.name) · \(winner.score)")
                        .font(Typography.label)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                }
            }
            .padding(.top, Spacing.xl)

            Spacer(minLength: 0)

            Podium(standings: standings, teams: engine.state.teams, grown: barsGrown)
                .frame(height: 240)
                .padding(.horizontal, Spacing.md)

            Spacer(minLength: 0)

            VStack(spacing: Spacing.sm) {
                Button {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                        _ = engine.send(.rematch)
                    }
                } label: {
                    Text(l10n("game.rematch"))
                        .font(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
                .buttonStyle(PrimaryButtonStyle(reduceMotion: reduceMotion))

                HStack(spacing: Spacing.sm) {
                    Button { showStats = true } label: {
                        Text(l10n("game.stats"))
                            .font(Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(SecondaryButtonStyle(reduceMotion: reduceMotion))

                    shareButton
                }

                Button(action: onFinish) {
                    Text(l10n("game.finish"))
                        .font(Typography.headline)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .onAppear {
            sound.play(.gameOver)
            withAnimation(reduceMotion ? Motion.reduced : Motion.celebrate.delay(0.15)) {
                barsGrown = true
            }
        }
        .sensoryFeedback(.success, trigger: barsGrown)
        .sheet(isPresented: $showStats) {
            StatsSheet(engine: engine)
        }
        // Rendered up front so ShareLink has something to hand over the moment it is
        // tapped. It costs one frame here and would cost a visible stall there.
        .task { card = renderCard() }
    }
}

/// Per-team detail, out of the way of the result.
struct StatsSheet: View {
    let engine: GameEngine

    @Environment(Localization.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(engine.standings.enumerated()), id: \.element.id) { rank, team in
                        StatsRow(
                            rank: rank + 1,
                            team: team,
                            teams: engine.state.teams,
                            mode: engine.state.settings.mode
                        )
                        if rank < engine.standings.count - 1 {
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
            .navigationTitle(l10n("game.stats"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n("common.done")) { dismiss() }
                        .tint(Tokens.onSurface.color)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.surface.color)
    }
}

/// Bars sized by score, ordered 2nd · 1st · 3rd so the winner is centre and tallest.
private struct Podium: View {
    let standings: [Team]
    let teams: [Team]
    let grown: Bool

    /// Positions in display order. Missing places simply do not render, so a two-team game
    /// shows two bars rather than an empty third.
    private var ordered: [(place: Int, team: Team)] {
        var result: [(Int, Team)] = []
        if standings.count > 1 { result.append((2, standings[1])) }
        if let first = standings.first { result.append((1, first)) }
        if standings.count > 2 { result.append((3, standings[2])) }
        return result
    }

    /// Relative to the leader, with a floor so a zero or negative score still draws
    /// something. Scores can go negative, so a naive ratio would invert the podium.
    private func height(for team: Team) -> CGFloat {
        let best = max(1, standings.first?.score ?? 1)
        let ratio = Double(max(0, team.score)) / Double(best)
        return 60 + CGFloat(ratio) * 130
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.xs) {
            ForEach(ordered, id: \.team.id) { entry in
                let index = teams.firstIndex(where: { $0.id == entry.team.id }) ?? 0

                VStack(spacing: Spacing.xxs) {
                    if entry.place == 1 {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(TeamPalette.color(at: index).color)
                            .accessibilityHidden(true)
                    }
                    Text(entry.team.name)
                        .font(Typography.label)
                        .foregroundStyle(Tokens.onSurface.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("\(entry.team.score)")
                        .font(Typography.numeral(entry.place == 1 ? 26 : 20))
                        .foregroundStyle(TeamPalette.color(at: index).color)

                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .fill(TeamPalette.color(at: index).color)
                        .frame(height: grown ? height(for: entry.team) : 0)
                        .frame(maxWidth: .infinity)
                        // The bar's length is the score, which is already spoken.
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct StatsRow: View {
    let rank: Int
    let team: Team
    let teams: [Team]
    let mode: GameMode

    @Environment(Localization.self) private var l10n

    var body: some View {
        let index = teams.firstIndex(where: { $0.id == team.id }) ?? 0

        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.sm) {
                Circle()
                    .fill(TeamPalette.color(at: index).color)
                    .frame(width: 10, height: 10)
                Text(team.name)
                    .font(Typography.rowTitle)
                    .foregroundStyle(Tokens.onSurface.color)
                Spacer()
                Text("\(team.score)")
                    .font(Typography.numeral(20))
                    .foregroundStyle(Tokens.onSurface.color)
            }

            // Columns of equal width with the number above its label, rather than
            HStack(alignment: .top, spacing: Spacing.xs) {
                stat(l10n("stats.guessed"), "\(team.wordsGuessed)")
                stat(l10n("stats.skipped"), "\(team.wordsSkipped)")
                stat(l10n("stats.streak"), "\(team.bestStreak)")
                if mode == .arcade {
                    stat(l10n("stats.sets"), "\(team.setsSkipped)")
                }
            }
            .padding(.leading, Spacing.md + 2)
        }
        .padding(.vertical, Spacing.sm)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(Typography.numeral(17))
                .foregroundStyle(Tokens.onSurface.color)

            Text(label)
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                // Long compounds shrink rather than hyphenate or clip. Georgian and German
                // both need this.
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        // The number and its caption are one fact: "26, guessed", not two stray labels.
        .accessibilityElement(children: .combine)
    }
}
