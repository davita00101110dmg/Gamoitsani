//
//  LocalizationModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI
import Combine

struct LocalizationModifier: ViewModifier {
    @State private var languageDidChange = false

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .languageDidChange)) { _ in
                // Toggle to force view refresh
                languageDidChange.toggle()
            }
            .id(languageDidChange)
    }
}

extension View {
    func observeLanguageChanges() -> some View {
        self.modifier(LocalizationModifier())
    }
}
