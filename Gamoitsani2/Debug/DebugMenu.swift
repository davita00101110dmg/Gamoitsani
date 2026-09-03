//
//  DebugMenu.swift
//  Gamoitsani2
//

#if DEBUG

import SwiftUI
import Observation
import GamoitsaniAds
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
    let ads: any AdServing

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

                    SetupPanel(title: "Ads") {
                        ForEach(ads.debugSummary, id: \.0) { label, value in
                            info(label, value)
                        }

                        Divider().overlay(Tokens.cardEdge.color)

                        Toggle("Ignore frequency caps", isOn: Binding(
                            get: { AdDebug.showsAdsInstantly },
                            set: { AdDebug.showsAdsInstantly = $0 }
                        ))
                        .tint(Tokens.accent.color)
                        .padding(.vertical, Spacing.sm)

                        Divider().overlay(Tokens.cardEdge.color)
                        action("Show interstitial now", enabled: true) {
                            dismiss()
                            Task { _ = await ads.debugShowInterstitial() }
                        }
                        Divider().overlay(Tokens.cardEdge.color)
                        action("Show app open now", enabled: true) {
                            dismiss()
                            Task { _ = await ads.debugShowAppOpen() }
                        }
                        Divider().overlay(Tokens.cardEdge.color)
                        action("Reset ad cadence", enabled: true) {
                            ads.debugResetCadence()
                        }
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
    static let debugMenuRequested = Notification.Name("debugMenuRequested")
}

/// Reports shakes by becoming first responder, rather than overriding `motionEnded` in a
/// `UIWindow` extension — which is undefined behaviour even though it is the usual recipe.
///
/// Shake alone is not enough. `motionEnded` travels up the responder chain from whatever
/// is focused, and this controller is a sibling of the screen rather than an ancestor of
/// it — so the moment a text field takes first responder, shaking stops reaching here.
/// Typing a team name was enough to lose it, which is why the menu stopped opening.
private struct ShakeDetector: UIViewControllerRepresentable {
    final class Controller: UIViewController {
        override var canBecomeFirstResponder: Bool { true }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            becomeFirstResponder()
        }

        override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            guard motion == .motionShake else { return }
            NotificationCenter.default.post(name: .debugMenuRequested, object: nil)
        }
    }

    func makeUIViewController(context: Context) -> Controller { Controller() }
    func updateUIViewController(_ controller: Controller, context: Context) {}
}

/// A two-finger double tap, anywhere.
///
/// Installed on the window, so unlike shake it does not care what holds first responder.
/// This is the trigger that always works; shake stays because it is the habit.
private struct DebugGesture: UIViewRepresentable {
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func fire() {
            NotificationCenter.default.post(name: .debugMenuRequested, object: nil)
        }

        // Never swallows touches the app wanted.
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool { true }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        // The window does not exist yet during `makeUIView`.
        DispatchQueue.main.async {
            guard let window = view.window,
                  !(window.gestureRecognizers ?? []).contains(where: { $0.name == "debugMenu" })
            else { return }

            let tap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.fire)
            )
            tap.name = "debugMenu"
            tap.numberOfTouchesRequired = 2
            tap.numberOfTapsRequired = 2
            tap.cancelsTouchesInView = false
            tap.delaysTouchesEnded = false
            tap.delegate = context.coordinator
            window.addGestureRecognizer(tap)
        }
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {}
}

extension View {
    /// Presents the debug menu when the device is shaken.
    func debugMenuOnShake(
        debug: DebugSettings,
        session: GameSession,
        ads: any AdServing
    ) -> some View {
        modifier(DebugMenuOnShake(debug: debug, session: session, ads: ads))
    }
}

private struct DebugMenuOnShake: ViewModifier {
    let debug: DebugSettings
    let session: GameSession
    let ads: any AdServing

    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .background(ShakeDetector().allowsHitTesting(false))
            .background(DebugGesture().allowsHitTesting(false))
            .onReceive(NotificationCenter.default.publisher(for: .debugMenuRequested)) { _ in
                isPresented = true
            }
            .sheet(isPresented: $isPresented) {
                DebugMenuSheet(debug: debug, session: session, ads: ads)
            }
    }
}

#endif
