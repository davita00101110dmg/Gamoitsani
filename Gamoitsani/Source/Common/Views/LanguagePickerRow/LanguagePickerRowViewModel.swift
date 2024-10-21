//
//  LanguagePickerViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//


import SwiftUI

final class LanguagePickerRowViewModel: ObservableObject {
    @Published var selectedLanguage: Language
    let availableLanguages: [Language] = Language.allCases
    
    var onLanguageChange: ((Language) -> Void)?
    
    init(initialLanguage: Language = LanguageManager.shared.currentLanguage,
         onLanguageChange: ((Language) -> Void)? = nil) {
        self.selectedLanguage = initialLanguage
        self.onLanguageChange = onLanguageChange
    }
    
    func languageChanged(_ newLanguage: Language) {
        selectedLanguage = newLanguage
        onLanguageChange?(newLanguage)
    }
}
