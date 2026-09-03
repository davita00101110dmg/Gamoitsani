//
//  GameFlowView.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniCore
import GamoitsaniDesign
import GamoitsaniEngine
import GamoitsaniL10n

/// The whole game, driven by the engine's phase.
struct GameFlowView: View {
    @Environment(GameSession.self) private var session
    @Environment(Router.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(Localization.self) private var l10n
    @Environment(\.scenePhase) private var scenePhase
    @Environment(SoundPlayer.self) private var sound
    @State private var showRules = false
    @State private var showLeaderboard = false

    var body: some View {
        ZStack {
            Tokens.surface.color.ignoresSafeArea()

            if let engine = session.engine {
                content(engine)
                    .transition(.opacity)
            } else {
                // Nothing to play — the session was cleared, or this was reached directly.
                ProgressView().tint(Tokens.accent.color)
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        // The system bar, not hand-drawn glyphs. Toolbar items get the platform's tap
        // targets, spacing and Dynamic Type for free — the custom ones were visibly small.
        .toolbar {
            if session.engine?.state.phase == .turnInfo {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showRules = true } label: { Image(systemName: "questionmark.circle") }
                        .tint(Tokens.onSurface.color)
                        .accessibilityLabel(l10n("game.howToPlay"))
                }
            }
        }
        .toolbarBackground(Tokens.surface.color, for: .navigationBar)
        .sheet(isPresented: $showRules) { RulesSheet() }
        .sheet(isPresented: $showLeaderboard) {
            if let engine = session.engine { LeaderboardSheet(engine: engine) }
        }
        // The deadline is wall-clock, so time passes while suspended. Re-checking on
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { session.engine?.checkExpiry() }
            if phase == .background { session.checkpoint() }
        }
        .onChange(of: session.engine?.state.phase) { was, now in
            session.checkpoint()
            // The buzzer marks a turn ending on the clock. Reaching .finished plays the
            // fanfare instead, so the two never stack.
            if was == .playing, let now, now != .finished { sound.play(.timeUp) }
        }
        // The system back button and the swipe gesture both pop without routing through
        // `leave()`, so the game is saved on the way out either way.
        .onDisappear { session.leave() }
    }

    /// The current team during play, so the name is legible without occupying the screen
    /// or moving when the clock ticks.
    private var navigationTitle: String {
        guard let engine = session.engine else { return "" }
        return engine.state.phase == .playing ? (engine.currentTeam?.name ?? "") : ""
    }

    @ViewBuilder
    private func content(_ engine: GameEngine) -> some View {
        switch engine.state.phase {
        case .turnInfo:
            TurnInfoView(engine: engine, showLeaderboard: { showLeaderboard = true })
        case .challenge:
            ChallengeView(engine: engine)
        case .countdown:
            CountdownView(engine: engine)
        case .playing:
            PlayView(engine: engine)
        case .finished:
            GameOverView(engine: engine, onFinish: leave)
        }
    }

    private func leave() {
        session.leave()
        router.pop()
    }
}

/// Between turns: whose turn it is, and how to play.
struct TurnInfoView: View {
    let engine: GameEngine
    let showLeaderboard: () -> Void

    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var teamColor: Color {
        TeamPalette.color(at: engine.state.currentTeamIndex).color
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.sm) {
                Text(roundLabel)
                    .font(Typography.label)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)

                Text(engine.currentTeam?.name ?? "")
                    .font(Typography.display(40))
                    .foregroundStyle(teamColor)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .scaleEffect(appeared || reduceMotion ? 1 : 0.94)
            .opacity(appeared ? 1 : 0)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    engine.send(.beginTurn)
                } label: {
                    Text(l10n("game.start"))
                        .font(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
                .buttonStyle(PrimaryButtonStyle(reduceMotion: reduceMotion))

                // A full button rather than a toolbar glyph: between rounds this is the
                // second thing anyone wants, and it deserves the width to say so.
                Button(action: showLeaderboard) {
                    Text(l10n("game.leaderboard"))
                        .font(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                }
                .buttonStyle(SecondaryButtonStyle(reduceMotion: reduceMotion))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            withAnimation(Motion.card(reduceMotion: reduceMotion)) { appeared = true }
        }
    }

    private var roundLabel: String {
        let state = engine.state
        if state.isExtraRound {
            return "\(l10n("game.extraRound")) \(state.extraRound)"
        }
        return "\(l10n("game.round")) \(state.round) / \(state.settings.rounds)"
    }
}

/// The full rules, on demand.
struct RulesSheet: View {
    @Environment(Localization.self) private var l10n
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(1...4, id: \.self) { index in
                    HStack(alignment: .top, spacing: Spacing.sm) {
                        Text("\(index)")
                            .font(Typography.word(15))
                            .foregroundStyle(Tokens.accent.color)
                            .frame(width: 20, alignment: .leading)
                        Text(l10n("rules.\(index)"))
                            .font(Typography.body)
                            .foregroundStyle(Tokens.onSurface.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, Spacing.xs)
                    .accessibilityElement(children: .combine)

                    // Rules read as one paragraph without these.
                    if index < 4 {
                        Divider().overlay(Tokens.cardEdge.color)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Tokens.surface.color.ignoresSafeArea())
            .navigationTitle(l10n("game.howToPlay"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(l10n("common.done")) { dismiss() }
                        .tint(Tokens.onSurface.color)
                }
            }
        }
        .presentationDetents([.fraction(0.42)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.surface.color)
    }
}

/// The optional per-team challenge.
struct ChallengeView: View {
    let engine: GameEngine

    @Environment(Localization.self) private var l10n
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text(l10n("game.challenge"))
                    .font(Typography.label)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)

                Text(l10n("game.challenge.placeholder"))
                    .font(Typography.word(26))
                    .foregroundStyle(Tokens.onSurface.color)
                    .multilineTextAlignment(.center)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(Tokens.cardFace.color)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .strokeBorder(Tokens.cardEdge.color, lineWidth: 2)
                    }
                    .padding(.horizontal, Spacing.lg)
            }
            .rotationEffect(.degrees(appeared || reduceMotion ? 0 : -4))
            .scaleEffect(appeared || reduceMotion ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)

            Spacer()

            Button { engine.send(.acknowledgeChallenge) } label: {
                Text(l10n("game.gotIt"))
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(PrimaryButtonStyle(reduceMotion: reduceMotion))
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.xl)
        }
        .onAppear {
            withAnimation(Motion.card(reduceMotion: reduceMotion)) { appeared = true }
        }
    }
}

/// 3 · 2 · 1.
struct CountdownView: View {
    let engine: GameEngine

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(SoundPlayer.self) private var sound
    @Environment(Localization.self) private var l10n
    @State private var value = 3

    /// Numerals shown, counting the first. Triggering on `value` skipped 3 entirely — it
    /// is the initial state, so it is never a change.
    @State private var beats = 0

    var body: some View {
        ZStack {
            Text("\(value)")
                .font(Typography.numeral(120))
                .foregroundStyle(Tokens.accent.color)
                .contentTransition(.numericText(countsDown: true))
                .id(value)
                .transition(.scale(scale: reduceMotion ? 1 : 1.6).combined(with: .opacity))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(l10n("a11y.startingIn"))
        .accessibilityValue("\(value)")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Centres on the screen rather than on the area left under the navigation bar,
        // which was pushing the numerals visibly low.
        .ignoresSafeArea(edges: .top)
        .haptics(.impact(weight: .medium), trigger: beats)
        .task {
            beat()
            for step in stride(from: 2, through: 0, by: -1) {
                try? await Task.sleep(for: .milliseconds(650))
                guard !Task.isCancelled else { return }
                guard step > 0 else {
                    engine.send(.countdownFinished)
                    return
                }
                withAnimation(Motion.control(reduceMotion: reduceMotion)) { value = step }
                beat()
            }
        }
    }

    /// One numeral: its sound and its haptic together.
    private func beat() {
        beats += 1
        sound.play(.tick)
    }
}
