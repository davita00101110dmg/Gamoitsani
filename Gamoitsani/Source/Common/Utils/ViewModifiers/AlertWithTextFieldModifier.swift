//
//  AlertWithTextFieldModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct AlertWithTextFieldModifier: ViewModifier {
    @Binding var alertType: AlertType?
    let viewModel: GameDetailsViewModel
    @State private var textFieldText: String = String.empty
    
    private var isTeamMode: Bool {
        viewModel.teamSectionMode == .teams
    }
    
    private var maxLength: Int {
        isTeamMode ?
        GameDetailsConstants.Validation.maxTeamNameLength :
        GameDetailsConstants.Validation.maxPlayerNameLength
    }
    
    func body(content: Content) -> some View {
        content.alert(
            getAlertTitle(),
            isPresented: Binding(
                get: { alertType != nil },
                set: { if !$0 { dismissAlert() } }
            )
        ) {
            if let alertType = alertType {
                alertActions(for: alertType)
            }
        } message: {
            if case .info(_, let message) = alertType {
                Text(message)
            }
        }
    }
    
    private func getAlertTitle() -> String {
        guard let alertType = alertType else { return .empty }
        
        switch alertType {
        case .add:
            return isTeamMode ?
            L10n.Screen.GameDetails.Teams.add :
            L10n.Screen.GameDetails.Players.add
        case .edit:
            return isTeamMode ?
            L10n.Screen.GameDetails.Teams.edit :
            L10n.Screen.GameDetails.Players.edit
        case .remove(_, _):
            return isTeamMode ?
            L10n.Screen.GameDetails.Teams.deleteConfirmation :
            L10n.Screen.GameDetails.Players.deleteConfirmation
        case .info(let title, _):
            return title
        }
    }
    
    @ViewBuilder
    private func alertActions(for alertType: AlertType) -> some View {
        switch alertType {
        case .info:
            Button(L10n.ok, role: .cancel) {
                dismissAlert()
            }
            
        case .add:
            Group {
                TextField(
                    isTeamMode
                    ? L10n.Screen.GameDetails.Teams.namePlaceholder
                    : L10n.Screen.GameDetails.Players.namePlaceholder,
                    text: $textFieldText
                )
                .onChange(of: textFieldText) { newValue in
                    if newValue.count > maxLength {
                        textFieldText = String(newValue.prefix(maxLength))
                    }
                }
                .onAppear { textFieldText = .empty }
                
                Button(L10n.cancel, role: .cancel) {
                    dismissAlert()
                }
                
                Button(L10n.add) {
                    handleSubmission(for: alertType)
                }
            }
        case .edit(let name, _):
            Group {
                TextField(
                    isTeamMode
                    ? L10n.Screen.GameDetails.Teams.namePlaceholder
                    : L10n.Screen.GameDetails.Players.namePlaceholder,
                    text: $textFieldText
                )
                .onChange(of: textFieldText) { newValue in
                    if newValue.count > maxLength {
                        textFieldText = String(newValue.prefix(maxLength))
                    }
                }
                .onAppear { textFieldText = name }
                
                Button(L10n.cancel, role: .cancel) {
                    dismissAlert()
                }
                
                Button(L10n.ok) {
                    handleSubmission(for: alertType)
                }
            }
        case .remove(_, _):
            Button(L10n.cancel, role: .cancel) {
                dismissAlert()
            }
            
            Button(L10n.yesPolite, role: .destructive) {
                handleSubmission(for: alertType)
            }
        }
    }
    
    private func handleSubmission(for alertType: AlertType) {
        switch alertType {
        case .add, .edit:
            handleTextInputSubmission(for: alertType)
        case .remove(_, let index):
            viewModel.remove(at: index)
            dismissAlert()
        case .info:
            dismissAlert()
        }
    }
    
    private func handleTextInputSubmission(for alertType: AlertType) {
        let text = textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else {
            self.alertType = .info(
                L10n.Screen.GameDetails.Alert.invalidParameter,
                L10n.Screen.GameDetails.Alert.emptyName
            )
            return
        }
        
        guard text.count <= maxLength else {
            let errorMessage = isTeamMode ?
                L10n.Screen.GameDetails.Teams.nameTooLong(maxLength.toString) :
                L10n.Screen.GameDetails.Players.nameTooLong(maxLength.toString)
            
            self.alertType = .info(
                L10n.Screen.GameDetails.Alert.invalidParameter,
                errorMessage
            )
            return
        }
        
        switch alertType {
        case .add:
            viewModel.add(with: text)
        case .edit(_, let index):
            viewModel.update(at: index, with: text)
        default:
            break
        }
        
        dismissAlert()
    }
    
    private func dismissAlert() {
        textFieldText = .empty
        alertType = nil
    }
}
