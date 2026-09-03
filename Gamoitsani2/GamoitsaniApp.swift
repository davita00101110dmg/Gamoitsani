//
//  GamoitsaniApp.swift
//  Gamoitsani2
//
import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The 2.0 entry point and composition root.
@main
struct GamoitsaniApp: App {
    @State private var router = Router()
    @State private var localization = Localization()
    @State private var session = GameSession()
    #if DEBUG
    @State private var debugSettings = DebugSettings()
    #endif

    /// Cold start only — `@State` here is created once per process, so resuming never
    /// replays it. Doubles as the `isLaunching` signal.
    @State private var showSplash = true

    init() {
        // The display face ships inside GamoitsaniDesign, so it is not in the app bundle
        DesignSystem.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                root

                if showSplash {
                    // No transition: the cards have already left, so both sides are a
                    // bare surface and there is nothing to fade.
                    SplashView { showSplash = false }
                        .zIndex(1)
                }
            }
        }
    }

    @ViewBuilder
    private var root: some View {
        let base = RootView()
            .environment(router)
            .environment(localization)
            .environment(session)
            .environment(\.isLaunching, showSplash)
            .tint(Tokens.accent.color)

        #if DEBUG
        base
            .environment(debugSettings)
            .debugMenuOnShake(debug: debugSettings, session: session)
        #else
        base
        #endif
    }
}

/// There is no Home screen. The app opens on setup, because that is what every session
/// starts with and a separate Home was a tap in the way.
struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            GameSetupView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .game:
                        GameFlowView()
                    case .addWord:
                        PlaceholderScreen(title: "Add word")
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}

/// Phase 7 replaces these with the real screens, in dependency order.
struct PlaceholderScreen: View {
    let title: String

    var body: some View {
        ZStack {
            Tokens.surface.color.ignoresSafeArea()
            VStack(spacing: Spacing.sm) {
                Text(title)
                    .font(Typography.title)
                    .foregroundStyle(Tokens.onSurface.color)
                Text("Coming next")
                    .font(Typography.caption)
                    .foregroundStyle(Tokens.onSurfaceMuted.color)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
