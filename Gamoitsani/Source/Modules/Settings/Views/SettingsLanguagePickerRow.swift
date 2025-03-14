//
//  SettingsLanguagePickerRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 01/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SettingsLanguagePickerRow: View {
    @State private var showLanguagePicker = false
    @State private var selectedLanguage: Language
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        Button {
            showLanguagePicker = true
        } label: {
            HStack {
                GMLabelView(text: L10n.Screen.Settings.language)
                    .foregroundStyle(.white)
                
                Spacer()
                
                HStack(spacing: 8) {
                    GMLabelView(text: (selectedLanguage.flagEmoji))
                    GMLabelView(text: (selectedLanguage.displayName))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showLanguagePicker) {
            NavigationStack {
                ZStack {
                    GradientBackground()
                        .ignoresSafeArea()
                    
                    EnhancedLanguagePickerView(selectedLanguage: $selectedLanguage)
                        .onChange(of: selectedLanguage) { newLanguage in
                            LanguageManager.shared.setLanguage(newLanguage)
                        }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showLanguagePicker = false
                        } label: {
                            GMLabelView(text: L10n.close)
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .listRowBackground(Asset.gmSecondary.swiftUIColor)
    }
}
