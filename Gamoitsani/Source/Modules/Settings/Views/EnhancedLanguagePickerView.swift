//
//  EnhancedLanguagePickerView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 01/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct EnhancedLanguagePickerView: View {
    @Binding var selectedLanguage: Language
    @Environment(\.dismiss) private var dismiss
    
    private var sortedLanguages: [Language] {
        let georgian: [Language] = [.georgian]
        let otherLanguages = Language.allCases
            .filter { $0 != .georgian }
            .sorted { $0.displayName < $1.displayName }
        
        return georgian + otherLanguages
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: ViewConstants.buttonSpacing) {
                ForEach(sortedLanguages, id: \.self) { language in
                    languageButton(for: language)
                }
            }
            .padding(ViewConstants.mainPadding)
        }
        .scrollIndicators(.hidden)
    }
    
    private func languageButton(for language: Language) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                selectedLanguage = language
                dismiss()
            }
        } label: {
            HStack {
                HStack(spacing: ViewConstants.buttonContentSpacing) {
                    GMLabelView(text: language.flagEmoji)
                        .frame(width: ViewConstants.flagSize)
                    
                    GMLabelView(text: language.displayName)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if language == selectedLanguage {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: ViewConstants.checkmarkSize))
                }
            }
            .padding(ViewConstants.buttonPadding)
            .frame(height: ViewConstants.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .fill(language == selectedLanguage ?
                          Asset.gmPrimary.swiftUIColor.opacity(0.15) :
                          Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: ViewConstants.cornerRadius)
                    .strokeBorder(
                        language == selectedLanguage ?
                            Asset.gmPrimary.swiftUIColor :
                            Color.white.opacity(0.1),
                        lineWidth: ViewConstants.borderWidth
                    )
            )
        }
    }
    
    // MARK: - View Constants
    private enum ViewConstants {
        static let mainSpacing: CGFloat = 24
        static let gridSpacing: CGFloat = 6
        static let buttonSpacing: CGFloat = 12
        static let buttonContentSpacing: CGFloat = 12
        static let mainPadding: CGFloat = 16
        static let buttonPadding: CGFloat = 16
        static let buttonHeight: CGFloat = 54
        static let cornerRadius: CGFloat = 12
        static let borderWidth: CGFloat = 1
        
        static let flagSize: CGFloat = 24
        static let textSize: CGFloat = 16
        static let checkmarkSize: CGFloat = 20
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Asset.gmSecondary.swiftUIColor.ignoresSafeArea()
        EnhancedLanguagePickerView(
            selectedLanguage: .constant(.georgian)
        )
    }
}
