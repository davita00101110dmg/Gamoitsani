//
//  NavigationBarModifier.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

struct NavigationBarModifier: ViewModifier {
    var title: String?
    var displayMode: NavigationBarItem.TitleDisplayMode

    func body(content: Content) -> some View {
        content
            .navigationTitle(title ?? "")
            .navigationBarTitleDisplayMode(displayMode)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

extension View {
    func navigationBarSetup(title: String? = nil, displayMode: NavigationBarItem.TitleDisplayMode = .automatic) -> some View {
        self.modifier(NavigationBarModifier(title: title, displayMode: displayMode))
    }
}
