//
//  LanguagePickerRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SettingsLanguagePickerRow: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        HStack {
            Text("screen.settings.language".localized())
            Spacer()
            Picker("", selection: $viewModel.selectedLanguage) {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    Text(language.flagEmoji).tag(language)
                }
            }
            .frame(width: 200)
        }
        .listRowBackground(Color(.secondary))
        .onChange(of: viewModel.selectedLanguage) { newValue in
            viewModel.updateLanguage(newValue)
        }
    }
}

