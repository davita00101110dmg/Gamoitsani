//
//  HomeView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Title
            GMLabelView(
                text: L10n.App.title,
                fontType: .bold,
                fontSizeForPhone: 40,
                fontSizeForPad: 74
            )

            Spacer()

            // Buttons
            VStack(spacing: 20) {
                GMButtonView(text: L10n.Screen.Home.PlayButton.title) {
                    coordinator.push(.gameDetails)
                }

                GMButtonView(text: L10n.Screen.Home.RulesButton.title) {
                    coordinator.push(.rules)
                }

                GMButtonView(text: L10n.Screen.Home.AddWordButton.title) {
                    coordinator.push(.addWord)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .gradientBackground()
        .navigationBarSetup()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    coordinator.presentSheet(.settings)
                } label: {
                    Image(systemName: AppConstants.SFSymbol.gear)
                        .foregroundColor(.white)
                }
            }
        }
        .observeLanguageChanges()
        #if DEBUG
        .onLongPressGesture {
            viewModel.presentAdInspector()
        }
        #endif
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AppCoordinator())
    }
}
