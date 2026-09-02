//
//  DebugMenu.swift
//  Gamoitsani2
//

#if DEBUG

import SwiftUI
import Observation
import GamoitsaniCore
import GamoitsaniDesign

/// Debug-only switches. Compiled out of release entirely.
@MainActor
@Observable
final class DebugSettings {
    /// New games start with the shortest legal round.
    ///
    /// The shortest *legal* one, not three seconds: `GameSettings` clamps to 15...75, and
    /// punching a hole in a validated rule so a debug menu can bypass it is how the rule
    /// stops meaning anything. "End turn now" is the faster route to the end anyway.
    var fastRounds = false

    /// One round, so a game ends after one pass round the table.
    var singleRound = true

    func apply(to settings: GameSettings) -> GameSettings {
        var result = settings
        if fastRounds { result.setRoundLength(TimeInterval(GameSettings.roundLengthRange.lowerBound)) }
        if singleRound { result.setRounds(1) }
        return result
    }
}

/// Shake to open.
struct DebugMenuSheet: View {
    // Handed in rather than read from the environment. Presented content inherits the
    // environment of whatever attached the `.sheet`, which makes it sensitive to where in
    // the modifier chain that happened — a debug tool should not be.
    let debug: DebugSettings
    let session: GameSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var debug = debug

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    SetupPanel(title: "New games") {
                        Toggle("Shortest round (15s)", isOn: $debug.fastRounds)
                            .tint(Tokens.accent.color)
                            .padding(.vertical, Spacing.sm)
                        Divider().overlay(Tokens.cardEdge.color)
                        Toggle("Single round", isOn: $debug.singleRound)
                            .tint(Tokens.accent.color)
                            .padding(.vertical, Spacing.sm)
                    }

                    SetupPanel(title: "Current game") {
                        action("End turn now", enabled: session.engine?.state.phase == .playing) {
                            session.engine?.send(.timeExpired)
                            dismiss()
                        }
                        Divider().overlay(Tokens.cardEdge.color)
                        action("End every turn", enabled: session.engine != nil) {
                            endAllTurns()
                            dismiss()
                        }
                        Divider().overlay(Tokens.cardEdge.color)
                        action("Clear saved game", enabled: session.canResume) {
                            session.discardSaved()
                            dismiss()
                        }
                    }

                    if let state = session.engine?.state {
                        SetupPanel(title: "State") {
                            info("phase", "\(state.phase)")
                            info("round", "\(state.round) / \(state.settings.rounds)")
                            info("team", state.currentTeam?.name ?? "—")
                            info("deck", "\(state.deck.count) left")
                            info("scores", state.teams.map { "\($0.score)" }.joined(separator: " · "))
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Tokens.surface.color.ignoresSafeArea())
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(Tokens.onSurface.color)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Tokens.surface.color)
    }

    /// Runs the game to its end by expiring every remaining turn.
    private func endAllTurns() {
        guard let engine = session.engine else { return }
        // Bounded: a tie adds rounds, so this could otherwise spin forever.
        for _ in 0..<200 where !engine.isFinished {
            switch engine.state.phase {
            case .turnInfo: engine.send(.beginTurn)
            case .challenge: engine.send(.acknowledgeChallenge)
            case .countdown: engine.send(.countdownFinished)
            case .playing: engine.send(.timeExpired)
            case .finished: return
            }
        }
    }

    private func action(_ title: String, enabled: Bool, run: @escaping () -> Void) -> some View {
        Button(action: run) {
            Text(title)
                .font(Typography.rowTitle)
                .foregroundStyle(enabled ? Tokens.accent.color : Tokens.onSurfaceMuted.color)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, Spacing.sm)
                .contentShape(Rectangle())
        }
        .disabled(!enabled)
    }

    private func info(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurfaceMuted.color)
            Spacer()
            Text(value)
                .font(Typography.label)
                .foregroundStyle(Tokens.onSurface.color)
        }
        .padding(.vertical, Spacing.xxs)
    }
}

// MARK: - Shake

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

/// Reports shakes by becoming first responder, rather than overriding `motionEnded` in a
/// `UIWindow` extension — which is undefined behaviour even though it is the usual recipe.
private struct ShakeDetector: UIViewControllerRepresentable {
    final class Controller: UIViewController {
        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else { return }
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
    }

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}
}

extension View {
    /// Presents the debug menu when the device is shaken.
    func debugMenuOnShake(debug: DebugSettings, session: GameSession) -> some View {
        modifier(DebugMenuOnShake(debug: debug, session: session))
    }
}

private struct DebugMenuOnShake: ViewModifier {
    let debug: DebugSettings
    let session: GameSession

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .background(ShakeDetector().allowsHitTesting(false))
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                DebugMenuSheet(debug: debug, session: session)
            }
    }
}

#endif
