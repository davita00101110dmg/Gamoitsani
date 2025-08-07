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
    @State private var tapCount: Int = 0
    @State private var showWordReview: Bool = false
    @State private var lastTapTime: Date = Date()
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: Layout.mainSpacing) {
                VStack(alignment: .center, spacing: Layout.headerSpacing) {
                    GMLabelView(
                        text: L10n.Screen.AddWord.title,
                        fontType: .bold,
                        fontSizeForPhone: Layout.titleFontSize,
                        textAlignment: .center
                    )
                    .onTapGesture {
                        handleTitleTap()
                    }
                    
                    GMLabelView(
                        text: L10n.Screen.AddWord.hint,
                        fontSizeForPhone: Layout.subtitleFontSize,
                        color: .white.opacity(0.8),
                        textAlignment: .center
                    )
                }
                .padding(.top)
                
                VStack(spacing: Layout.contentSpacing) {
                    LanguagePickerRow(
                        viewModel: viewModel.languagePickerViewModel,
                        title: L10n.Screen.AddWord.languagePickerTitle
                    )
                    .padding(.horizontal)
                    
                    GMTextFieldView(
                        text: $word,
                        placeholder: L10n.Screen.AddWord.textfieldPlaceholder,
                        textLimit: Constants.textLimit
                    )
                    .focused($isTextFieldFocused)
                }
                .padding(.vertical)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .fill(Asset.gmSecondary.swiftUIColor)
                )
                
                GMButtonView(
                    text: L10n.Screen.AddWord.send,
                    backgroundColor: Asset.gmPrimary.swiftUIColor
                ) {
                    addWord()
                }
                
                Spacer()
                
                BannerContainerView()
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
        .fullScreenCover(isPresented: $showWordReview) {
            NavigationView {
                WordReviewView()
            }
        }
    }
    
    private func addWord() {
        guard !word.isEmpty else { return }
        viewModel.addWord(word.removeExtraSpaces())
        word = .empty
        isTextFieldFocused = false
    }
    
    private func handleTitleTap() {
        let now = Date()
        let timeSinceLastTap = now.timeIntervalSince(lastTapTime)
        
        if timeSinceLastTap > 2.0 {
            tapCount = 1
        } else {
            tapCount += 1
        }
        
        lastTapTime = now
        
        if tapCount >= 5 {
            tapCount = 0
            showWordReview = true
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
    }
}

private extension AddWordView {
    enum Layout {
        static let mainSpacing: CGFloat = 24
        static let headerSpacing: CGFloat = 8
        static let contentSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 12
        static let titleFontSize: CGFloat = 24
        static let subtitleFontSize: CGFloat = 16
    }
    
    enum Constants {
        static let textLimit: Int = 20
    }
}

#Preview {
    AddWordView()
}
