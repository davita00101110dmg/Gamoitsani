//
//  RulesView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 13/11/2025.
//

import SwiftUI

struct RulesView: View {
    @StateObject private var viewModel = RulesViewModel()

    var body: some View {
        List {
            ForEach(Array(viewModel.rules.enumerated()), id: \.offset) { index, rule in
                RuleRow(rule: rule)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .gradientBackground()
        .navigationBarSetup(title: L10n.Screen.Rules.title, displayMode: .inline)
        .observeLanguageChanges()
    }
}

// MARK: - Rule Row View

struct RuleRow: View {
    let rule: String

    var body: some View {
        GMLabelView(
            text: rule,
            fontType: .semiBold,
            fontSizeForPhone: 16,
            fontSizeForPad: 24,
            textAlignment: .leading
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Asset.gmSecondary.swiftUIColor.opacity(0.3))
        )
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        RulesView()
    }
}
