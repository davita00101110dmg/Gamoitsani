//
//  GameDetailsView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 22/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GameDetailsView: View {
    @EnvironmentObject private var coordinator: GameDetailsCoordinator
    @StateObject var viewModel = GameDetailsViewModel()
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var showStorageAlert = false
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            if viewModel.areWordsLoading {
                LoadingView(text: L10n.Screen.GameDetails.LoadingWords.message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else {
                VStack {
                    ScrollView {
                        VStack(spacing: GameDetailsConstants.Layout.sectionSpacing) {
#if DEBUG
                            debugButtons
#endif
                            roundManagementSection
                            gameModeSection
                            teamManagementSection
                            Spacer()
                        }
                        .padding()
                    }
                    
                    bottomSection
                }
            }
        }
        .onAppear {
            handleOnAppear()
        }
        .gameDetailsAlert(alertType: $viewModel.currentAlert, viewModel: viewModel)
    }
    
    private var roundManagementSection: some View {
        VStack(spacing: GameDetailsConstants.Layout.managementSpacing) {
            HStack {
                GMLabelView(
                    text: L10n.Screen.GameDetails.RoundsSettings.title,
                    fontType: .semiBold,
                    textAlignment: .leading
                )
                Spacer()
            }
            roundsRow
            roundsLengthRow
            superWordToggleRow
            randomChallengeToggleRow
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: GameDetailsConstants.Layout.cornerRadius)
                .fill(Asset.gmSecondary.swiftUIColor)
        )
    }
    
    private var roundsRow: some View {
        HStack {
            GMLabelView(
                text: L10n.Screen.GameDetails.RoundsAmount.title(viewModel.roundsAmount.toString()),
                textAlignment: .leading
            )
            Spacer()
            Stepper(String.empty,
                    value: $viewModel.roundsAmount,
                    in: GameDetailsConstants.Game.roundsRange,
                    step: 1)
            .labelsHidden()
        }
    }
    
    private var roundsLengthRow: some View {
        HStack {
            GMLabelView(
                text: L10n.Screen.GameDetails.RoundsLength.title(viewModel.roundsLength.toString()),
                textAlignment: .leading
            )
            Spacer()
            Stepper(String.empty,
                    value: $viewModel.roundsLength,
                    in: GameDetailsConstants.Game.roundsLengthRange,
                    step: GameDetailsConstants.Game.roundsLengthStep)
            .labelsHidden()
        }
    }
    
    private var superWordToggleRow: some View {
        SuperWordToggleRow(isEnabled: $viewModel.isSuperWordEnabled)
    }

    private var randomChallengeToggleRow: some View {
        RandomChallengeToggleRow(isEnabled: $viewModel.isRandomChallengeEnabled)
    }
    
    private var teamManagementSection: some View {
        VStack(spacing: GameDetailsConstants.Layout.managementSpacing) {
            setupModePicker
            
            if viewModel.teamSectionMode == .teams {
                teamsContent
            } else {
                playersContent
            }
        }
    }
    
    private var gameModeSection: some View {
        VStack(alignment: .leading, spacing: GameDetailsConstants.Layout.managementSpacing) {
            GMLabelView(
                text: L10n.Screen.GameDetails.GameMode.title,
                fontType: .semiBold,
                textAlignment: .leading
            )
            
            GameModePickerView(selectedMode: $viewModel.selectedGameMode)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: GameDetailsConstants.Layout.cornerRadius)
                .fill(Asset.gmSecondary.swiftUIColor)
        )
    }
    
    private var setupModePicker: some View {
        Picker(String.empty, selection: $viewModel.teamSectionMode) {
            Text(L10n.Screen.GameDetails.Section.teams)
                .tag(GameDetailsTeamSectionMode.teams)
            Text(L10n.Screen.GameDetails.Section.players)
                .tag(GameDetailsTeamSectionMode.players)
        }
        .pickerStyle(.segmented)
        .customSegmentedPickerStyle()
    }
    
    private var teamsContent: some View {
        Group {
            if viewModel.teams.isEmpty {
                emptyTeamsView
            } else {
                filledTeamsView
            }
        }
        .background(backgroundShape)
    }
    
    private var playersContent: some View {
        Group {
            if viewModel.players.isEmpty {
                emptyPlayersView
            } else {
                filledPlayersView
            }
        }
        .background(backgroundShape)
    }
    
    private var emptyTeamsView: some View {
        PlaceholderView(
            imageName: "person.2",
            title: L10n.Screen.GameDetails.Teams.addPlaceholder,
            addButtonAction: { viewModel.showAlert(.add) }
        )
    }
    
    private var filledTeamsView: some View {
        TeamListView(
            teams: viewModel.teams,
            onEdit: { handleTeamEdit($0) },
            onDelete: { handleTeamDelete($0) },
            onAdd: { viewModel.showAlert(.add) }
        )
    }
    
    private var emptyPlayersView: some View {
        PlaceholderView(
            imageName: "person.fill.questionmark",
            title: L10n.Screen.GameDetails.Players.addPlaceholder,
            addButtonAction: { viewModel.showAlert(.add) }
        )
    }
    
    private var filledPlayersView: some View {
        PlayerListView(
            players: viewModel.players,
            onAdd: { viewModel.showAlert(.add) },
            onDelete: { handlePlayerDelete($0) },
            onGenerateTeams: viewModel.createRandomTeams
        )
    }
    
    private var bottomSection: some View {
        VStack(spacing: GameDetailsConstants.Layout.bottomSpacing) {
            startGameButton
            BannerContainerView()
        }
        .padding()
    }
    
    private var startGameButton: some View {
        GMButtonView(text: L10n.Screen.GameDetails.StartGame.title) {
            handleStartGame()
        }
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: GameDetailsConstants.Layout.cornerRadius)
            .fill(Asset.gmSecondary.swiftUIColor)
    }
    
#if DEBUG
    private var debugButtons: some View {
        HStack {
            GMButtonView(text: "Add Random Team", height: 32) {
                viewModel.addRandomTeam()
            }
            
            GMButtonView(text: "Add 2 Teams", height: 32) {
                viewModel.addRandomTeam()
                viewModel.addRandomTeam()
            }
        }
    }
#endif
}

// MARK: - Actions
private extension GameDetailsView {
    func handleOnAppear() {
        GameStory.shared.reset()
        viewModel.fetchWordsFromServer()
        ChallengesManager.shared.fetchChallengesIfNeeded {
            log(.info, "Challenges fetched successfully")
        }
        StoreReviewManager.checkAndAskForReview()
    }
    
    func handleTeamEdit(_ index: Int) {
        viewModel.currentAlert = .edit(viewModel.teams[index].name, index)
    }
    
    func handleTeamDelete(_ index: Int) {
        viewModel.currentAlert = .remove(viewModel.teams[index].name, index)
    }
    
    func handlePlayerDelete(_ index: Int) {
        viewModel.remove(at: index)
    }
    
    func handleStartGame() {
        if viewModel.teams.count < GameDetailsConstants.Game.minimumTeams {
            viewModel.showInfoAlert(
                title: L10n.Screen.GameDetails.Alert.invalidParameter,
                message: L10n.Screen.GameDetails.Alert.notEnoughTeams
            )
        } else if !viewModel.teamsAreUnique() {
            viewModel.showInfoAlert(
                title: L10n.Screen.GameDetails.Alert.invalidParameter,
                message: L10n.Screen.GameDetails.Alert.notUniqueTeams
            )
        } else {
            viewModel.updateGameStory()
            coordinator.navigateToGame()
        }
    }
}

#Preview {
    return GameDetailsView()
}
