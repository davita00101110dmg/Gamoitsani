//
//  AppCoordinatorView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

struct AppCoordinatorView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
        .preferredColorScheme(.dark)
        .tint(.white)
        .sheet(item: $coordinator.presentedSheet) { destination in
            sheetView(for: destination)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { destination in
            fullScreenView(for: destination)
        }
    }

    // MARK: - Destination Views

    @ViewBuilder
    private func destinationView(for route: Route) -> some View {
        switch route {
        case .home:
            HomeView()

        case .rules:
            RulesView()

        case .gameDetails:
            GameDetailsView()

        case .game(let gameStory):
            GameView(gameStory: gameStory)

        case .addWord:
            AddWordView()
        }
    }

    @ViewBuilder
    private func sheetView(for destination: AppCoordinator.SheetDestination) -> some View {
        switch destination {
        case .settings:
            SettingsView()

        case .gameScoreboard(let gameStory):
            GameScoreboardView(gameStory: gameStory)

        case .gameShare(let gameStory):
            GameShareView(gameStory: gameStory)
        }
    }

    @ViewBuilder
    private func fullScreenView(for destination: AppCoordinator.FullScreenDestination) -> some View {
        switch destination {
        case .game(let gameStory):
            GameView(gameStory: gameStory)
        }
    }
}

// MARK: - Navigation Bar Styling

extension View {
    func setupNavigationBarAppearance() -> some View {
        self.onAppear {
            // Configure navigation bar appearance globally
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: F.Mersad.semiBold.font(size: 18)
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: UIColor.white,
                .font: F.Mersad.semiBold.font(size: 48)
            ]
            appearance.backgroundColor = .clear

            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().tintColor = .white
            UINavigationBar.appearance().barStyle = .black
            UINavigationBar.appearance().prefersLargeTitles = UIDevice.current.userInterfaceIdiom == .pad

            // Configure alert tint color
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = Asset.tintColor.color

            // Configure stepper appearance
            UIStepper.appearance().setDecrementImage(UIStepper().decrementImage(for: .normal), for: .normal)
            UIStepper.appearance().setIncrementImage(UIStepper().incrementImage(for: .normal), for: .normal)
            UIStepper.appearance().tintColor = .white
        }
    }
}
