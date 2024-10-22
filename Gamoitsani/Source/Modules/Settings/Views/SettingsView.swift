//
//  SettingsView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var coordinator: SettingsCoordinator
    @ObservedObject var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                GMLabelView(text: L10n.Screen.Settings.title)
                    .font(SwiftUI.Font.appFont(type: .semiBold, size: 18))
                    .foregroundStyle(.white)
                
                List {
                    Section {
                        LanguagePickerRow(viewModel: viewModel.languagePickerRowViewModel)
                    }
                    
                    Section {
                        if !viewModel.isRemoveAdsPurchased {
                            GMTableViewButton(title: L10n.Screen.Settings.removeAds) {
                                viewModel.purchaseProduct()
                            }
                        }
                        
                        GMTableViewButton(title: L10n.Screen.Settings.restorePurchase) {
                            viewModel.restoreProduct()
                        }
                        
                        GMTableViewButton(title: L10n.Screen.Settings.rateApp) {
                            viewModel.writeReviewAction()
                        }
                        
                        GMTableViewButton(title: L10n.Screen.Settings.feedback) {
                            viewModel.feedbackAction()
                        }
                        
                        if viewModel.shouldShowPrivacySettingsButton {
                            GMTableViewButton(title: L10n.Screen.Settings.privacySettings) {
                                coordinator.presentPrivacySettings()
                            }
                        }
                        
                        GMTableViewButton(title: L10n.Screen.Settings.shareApp) {
                            viewModel.isShareSheetPresented = true
                        }
                        .sheet(isPresented: $viewModel.isShareSheetPresented) {
                            ActivityViewController(activityItems: [URL(string: AppConstants.appStoreLink)!])
                                .presentationDetents([.medium])
                        }
                    }.listRowBackground(Asset.gmSecondary.swiftUIColor)
                }
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange), perform: { _ in
                    viewModel.languageChanged.toggle()
                })
                .environment(\.font, SwiftUI.Font.appFont(type: .semiBold, size: 16))
                .foregroundStyle(.white)
                .scrollContentBackground(.hidden)
                .alert(isPresented: $viewModel.showingAlert) {
                    Alert(
                        title: Text(L10n.Screen.Settings.CanNotWriteReview.title),
                        message: Text(L10n.Screen.Settings.CanNotWriteReview.message),
                        dismissButton: .default(Text(L10n.ok))
                    )
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
}
