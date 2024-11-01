//
//  AddWordView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI
import GoogleMobileAds

struct AddWordView: View {
    @StateObject private var viewModel = AddWordViewModel()
    @EnvironmentObject private var coordinator: AddWordCoordinator
    @Environment(\.dismiss) private var dismiss
    
    @State private var word: String = .empty
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                GMLabelView(text: L10n.Screen.AddWord.title, textAlignment: .leading)
                    .font(SwiftUI.Font.appFont(type: .semiBold, size: Constants.titleFontSize))
                    .foregroundStyle(.white)
                    .padding(Constants.verticalSpacing)
                
                
                HStack {
                    GMLabelView(text: L10n.Screen.AddWord.hint, textAlignment: .leading)
                    Spacer()
                }
                
                LanguagePickerRow(viewModel: viewModel.languagePickerViewModel, title: L10n.Screen.AddWord.languagePickerTitle)

                GMTextFieldView(text: $word, placeholder: L10n.Screen.AddWord.textfieldPlaceholder, textLimit: 20)
                    .focused($isTextFieldFocused)
                    .padding()
                
                GMButtonView(text: L10n.Screen.AddWord.send) {
                    addWord()
                }
                
                Spacer()
                
                BannerAdView()
                    .frame(maxWidth: Constants.bannerWidth, maxHeight: Constants.bannerHeight)
            }
            .padding()
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                dismissButton: .default(Text(L10n.ok))
            )
        }
    }
    
    private func addWord() {
        guard !word.isEmpty else { return }
        viewModel.addWord(word.removeExtraSpaces())
        word = .empty
        isTextFieldFocused = false
    }
}

extension AddWordView {
    enum Constants {
        static let verticalSpacing: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let bannerWidth: CGFloat = 320
        static let bannerHeight: CGFloat = 50
    }
}

#Preview {
    AddWordView()
}
