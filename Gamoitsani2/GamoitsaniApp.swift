//
//  GamoitsaniApp.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The 2.0 entry point and composition root.
///
/// Dependencies are constructed here and injected downward. v1 reached for `.shared` from
/// inside view models, which is why its tests needed a real AppDelegate and a real Core
/// Data stack just to run.
@main
struct GamoitsaniApp: App {
    @State private var router = Router()
    @State private var localization = Localization()

    init() {
        // The display face ships inside GamoitsaniDesign, so it is not in the app bundle
        // and cannot be declared in UIAppFonts. Without this every Typography.display call
        // silently renders in the system font.
        DesignSystem.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .environment(localization)
                .tint(Tokens.accent.color)
        }
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
                        PlaceholderScreen(title: "Game")
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
