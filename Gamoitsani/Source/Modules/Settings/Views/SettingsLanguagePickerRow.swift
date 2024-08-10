//
//  LanguagePickerRow.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct SettingsLanguagePickerRow: View {
    @AppStorage(UserDefaults.Keys.APP_LANGUAGE) private var appLanguage: String = ""
    @Binding var selectedSegment: Int

    var body: some View {
        HStack {
            Text("screen.settings.language".localized())
            Spacer()
            Picker("", selection: $selectedSegment) {
                Text("🇬🇪").tag(0)
                Text("🇺🇸").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
        .listRowBackground(Color(.secondary))
        .onAppear {
            selectedSegment = appLanguage == AppConstants.Language.georgian.identifier ? 0 : 1
        }
        .onChange(of: selectedSegment) { newValue in
            updateLanguage(newValue)
        }
    }

    private func updateLanguage(_ segment: Int) {
        appLanguage = segment == 0 ? AppConstants.Language.georgian.identifier : AppConstants.Language.english.identifier
        NotificationCenter.default.post(name: .languageDidChange, object: nil)
    }
}
