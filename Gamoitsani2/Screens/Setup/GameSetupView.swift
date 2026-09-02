//
//  GameSetupView.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniL10n

/// The app's front door.
///
/// There is no Home screen in 2.0: the app opens here, because setting up is what every
/// session starts with and a separate Home was one tap in the way. That makes this screen
/// carry the whole first impression, which is why it is illustrated rather than a form —
/// a card fan that collapses as you scroll, team colours, springy steppers, sections that
/// stagger in.
struct GameSetupView: View {
    @Environment(Router.self) private var router
    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = GameSetupModel()
    @State private var hasAppeared = false

    private let headerHeight: CGFloat = 168

    /// How far the screen has scrolled, driving the header collapse.
    ///
    /// `onScrollGeometryChange` rather than a `GeometryReader` reading a named coordinate
    /// space: the first attempt did the latter, referenced a space that was never declared,
    /// and silently collapsed nothing. This reports the real content offset.
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                CollapsingFanHeader(height: headerHeight, collapse: headerCollapse)

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
            router.push(.game)
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
