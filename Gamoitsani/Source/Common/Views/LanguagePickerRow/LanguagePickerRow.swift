//
//  LanguagePickerRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct LanguagePickerRow: View {
    @ObservedObject var viewModel: LanguagePickerRowViewModel
    var title: String = L10n.Screen.Settings.language

    var body: some View {
        HStack {
            GMLabelView(text: title)
            Spacer()
            Picker("", selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    Text(language.flagEmoji).tag(language)
                }
            }
            .tint(.white)
        }
        .listRowBackground(Asset.gmSecondary.swiftUIColor)
        .onChange(of: viewModel.selectedLanguage) { newValue in
            viewModel.languageChanged(newValue)
        }
    }
}

#Preview {
    LanguagePickerRow(viewModel: LanguagePickerRowViewModel(initialLanguage: .georgian, onLanguageChange: { _ in
        
    }))
}

