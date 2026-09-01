//
//  GamoitsaniApp.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniDesign

/// The 2.0 entry point and composition root.
///
/// Dependencies are constructed here and injected downward. v1 reached for `.shared` from
/// inside view models, which is what made its tests need a real AppDelegate and a real
/// Core Data stack just to run.
@main
struct GamoitsaniApp: App {
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(router)
                .tint(Tokens.accent.color)
        }
    }
}

struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .gameSetup:
                        PlaceholderScreen(title: "Game setup")
                    case .rules:
                        PlaceholderScreen(title: "Rules")
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
            Text(title)
                .font(Typography.title)
                .foregroundStyle(Tokens.onSurface.color)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
