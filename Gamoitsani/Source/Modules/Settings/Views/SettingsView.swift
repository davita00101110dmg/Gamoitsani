//
//  SettingsView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel = SettingsViewModel()
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                Text(L10n.Screen.Settings.title.localized())
                    .font(.custom(F.Mersad.semiBold, size: 18))
                    .foregroundStyle(.white)
                
                List {
                    Section {
                        SettingsLanguagePickerRow(selectedSegment: $viewModel.selectedSegment)
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
                        GMTableViewButton(title: L10n.Screen.Settings.shareApp) {
                            viewModel.isShareSheetPresented = true
                        }
                        .sheet(isPresented: $viewModel.isShareSheetPresented) {
                            ActivityViewController(activityItems: [URL(string: AppConstants.appStoreLink)!])
                                .presentationDetents([.medium])
                        }
                    }.listRowBackground(Color(.secondary))
                }
                .onReceive(NotificationCenter.default.publisher(for: .languageDidChange), perform: { _ in
                    viewModel.languageChanged.toggle()
                })
                .environment(\.font, .custom(F.Mersad.semiBold, size: 16))
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
    SettingsView()
}
