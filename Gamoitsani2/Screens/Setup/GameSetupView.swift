//
//  GameSetupView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// The app's front door.
struct GameSetupView: View {
    @Environment(Router.self) private var router
    @Environment(Localization.self) private var l10n
    @Environment(GameSession.self) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = GameSetupModel()
    @State private var hasAppeared = false

    private let headerHeight: CGFloat = 168

    /// How far the screen has scrolled, driving the header collapse.
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                CollapsingFanHeader(height: headerHeight, collapse: headerCollapse)

                if let saved = session.saved {
                    resumeCard(saved)
                }

                section(index: 0) { roundSection }
                section(index: 1) { modeSection }
                section(index: 2) { extrasSection }
                section(index: 3) { teamsSection }
                section(index: 4) { playButton }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.bottom, Spacing.lg)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { _, offset in
            scrollOffset = offset
        }
        .background(Tokens.surface.color.ignoresSafeArea())
        .navigationTitle(l10n("home.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { router.push(.settings) } label: {
                    Image(systemName: "gearshape")
                }
                .tint(Tokens.onSurfaceMuted.color)
                .accessibilityLabel(l10n("settings.title"))
            }
        }
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
        }
        .onChange(of: l10n.language) { _, language in
            withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                model.applyLanguage(language)
            }
        }
    }

    /// An unfinished game, offered before the setup form.
    private func resumeCard(_ saved: GameState) -> some View {
        SetupPanel(title: l10n("setup.inProgress")) {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(saved.currentTeam?.name ?? "")
                        .font(Typography.rowTitle)
                        .foregroundStyle(Tokens.onSurface.color)
                    Text("\(l10n("game.round")) \(saved.round) / \(saved.settings.rounds)")
                        .font(Typography.caption)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                }

                Spacer()

                Button(l10n("setup.discard")) {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                        session.discardSaved()
                    }
                }
                .font(Typography.caption)
                .foregroundStyle(Tokens.danger.color)

                Button(l10n("setup.resume")) {
                    session.resume()
                    router.push(.game)
                }
                .font(Typography.headline)
                .foregroundStyle(Tokens.accent.color)
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    /// Builds the deck and hands the engine a game to run.
    private func startGame() {
        let settings = model.settings
        let teams = model.resolvedTeams
        let language = l10n.language.rawValue

        Task {
            let provider = SampleWordProvider()
            // Enough for the whole game: every team, every round, plus tie-breaks.
            let wanted = max(60, teams.count * settings.rounds * 40)
            let deck = (try? await provider.deck(language: language, count: wanted)) ?? Deck(words: [])
            session.start(settings: settings, teams: teams, deck: deck)
            router.push(.game)
        }
    }

    /// 0 while the header is fully shown, 1 once it has scrolled away.
    private var headerCollapse: CGFloat {
        min(1, max(0, scrollOffset / headerHeight))
    }

    /// Sections stagger in on first appearance. Reduce Motion collapses the stagger to
    /// zero and the movement to a crossfade — substitution, not deletion.
    private func section<Content: View>(index: Int, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 18)
            .animation(
                reduceMotion
                    ? Motion.reduced
                    : Motion.card.delay(Double(index) * 0.06),
                value: hasAppeared
            )
    }

    // MARK: - Round

    private var roundSection: some View {
        SetupPanel(title: l10n("setup.round")) {
            StepperRow(
                label: l10n("setup.rounds"),
                value: "\(model.settings.rounds)",
                canDecrease: model.canDecreaseRounds,
                canIncrease: model.canIncreaseRounds,
                decrease: { model.adjustRounds(by: -1) },
                increase: { model.adjustRounds(by: 1) }
            )
            Divider().overlay(Tokens.cardEdge.color)
            StepperRow(
                label: l10n("setup.length"),
                value: "\(model.roundLengthSeconds)s",
                canDecrease: model.canDecreaseLength,
                canIncrease: model.canIncreaseLength,
                decrease: { model.adjustRoundLength(by: -1) },
                increase: { model.adjustRoundLength(by: 1) }
            )
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        SetupPanel(title: l10n("setup.mode")) {
            VStack(spacing: Spacing.sm) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: model.settings.mode == mode,
                        reduceMotion: reduceMotion
                    ) {
                        withAnimation(Motion.control(reduceMotion: reduceMotion)) {
                            model.settings.mode = mode
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Extras

    private var extrasSection: some View {
        SetupPanel(title: l10n("setup.extras")) {
            ToggleRow(
                title: l10n("setup.superWord"),
                subtitle: l10n("setup.superWord.detail"),
                isOn: $model.settings.superWordsEnabled,
                reduceMotion: reduceMotion
            )
            Divider().overlay(Tokens.cardEdge.color)
            ToggleRow(
                title: l10n("setup.challenge"),
                subtitle: l10n("setup.challenge.detail"),
                isOn: $model.settings.challengesEnabled,
                reduceMotion: reduceMotion
            )
        }
    }

    // MARK: - Teams

    private var teamsSection: some View {
        SetupPanel(title: l10n("setup.teams")) {
            ForEach(Array(model.teams.enumerated()), id: \.element.id) { index, team in
                TeamRow(
                    index: index,
                    team: team,
                    name: Binding(
                        get: { model.draftNames[team.id] ?? team.name },
                        set: { model.setName($0, for: team) }
                    ),
                    problem: model.problem(for: team),
                    canRemove: model.canRemoveTeam,
                    remove: {
                        withAnimation(Motion.card(reduceMotion: reduceMotion)) {
                            model.removeTeam(team)
                        }
                    }
                )
                if index < model.teams.count - 1 {
                    Divider().overlay(Tokens.cardEdge.color)
                }
            }

            if model.canAddTeam {
                Divider().overlay(Tokens.cardEdge.color)
                Button {
                    withAnimation(Motion.card(reduceMotion: reduceMotion)) { model.addTeam() }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text(l10n("setup.addTeam"))
                    }
                    .font(Typography.headline)
                    .foregroundStyle(Tokens.accent.color)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
    }

    // MARK: - Play

    private var playButton: some View {
        Button {
            startGame()
        } label: {
            Text(l10n("setup.play"))
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .buttonStyle(PrimaryButtonStyle(reduceMotion: reduceMotion))
        .disabled(!model.canStart)
        .opacity(model.canStart ? 1 : 0.5)
        .animation(Motion.control(reduceMotion: reduceMotion), value: model.canStart)
        .padding(.top, Spacing.xs)
    }
}

#Preview("Setup — dark") {
    NavigationStack { GameSetupView().environment(Router()) }
        .preferredColorScheme(.dark)
}

#Preview("Setup — light") {
    NavigationStack { GameSetupView().environment(Router()) }
        .preferredColorScheme(.light)
}
