//
//  WordReviewView.swift
//  Gamoitsani
//
//  Created by Claude on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct WordReviewView: View {
    @StateObject private var viewModel = WordReviewViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            GradientBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                    .padding(.horizontal)
                    .padding(.top)
                
                if viewModel.isLoading && viewModel.words.isEmpty {
                    loadingView
                } else {
                    ScrollView {
                        contentSection
                            .padding(.horizontal)
                    }
                }
                
                footerSection
                    .padding(.horizontal)
                    .padding(.bottom)
                
                BannerContainerView()
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Word Review"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Layout.headerSpacing) {
            HStack {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                GMLabelView(
                    text: "Word Review",
                    fontType: .bold,
                    fontSizeForPhone: Layout.titleFontSize
                )
                
                Spacer()
                
                Text("     ")
            }
            
            progressSection
        }
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                GMLabelView(
                    text: viewModel.progressText,
                    fontSizeForPhone: Layout.progressFontSize,
                    color: .white.opacity(0.8),
                    textAlignment: .leading
                )
                
                Spacer()
                
                if viewModel.progress.totalUnreviewed > 0 {
                    GMLabelView(
                        text: "\(viewModel.progress.totalUnreviewed) unreviewed",
                        fontSizeForPhone: Layout.progressFontSize,
                        color: .white.opacity(0.6),
                        textAlignment: .trailing
                    )
                }
            }
            
            ProgressView(value: viewModel.progressPercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Asset.gmPrimary.swiftUIColor))
                .scaleEffect(y: 2)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Asset.gmSecondary.swiftUIColor.opacity(0.3))
        )
        .padding(.bottom, Layout.headerSpacing)
    }
    
    private var contentSection: some View {
        VStack(spacing: Layout.contentSpacing) {
            instructionText
                .padding(.top, Layout.contentSpacing)
            
            selectionSummary
                .padding(.bottom, Layout.contentSpacing)
            
            wordGrid
        }
    }
    
    private var instructionText: some View {
        GMLabelView(
            text: "Tap bad words to deselect them. Selected words (highlighted) are considered good for the game.",
            fontSizeForPhone: Layout.instructionFontSize,
            color: .white.opacity(0.8),
            textAlignment: .center
        )
    }
    
    private var wordGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: Layout.gridSpacing), count: 2)
        
        return LazyVGrid(columns: columns, spacing: Layout.gridSpacing) {
            ForEach(viewModel.words) { word in
                WordReviewCard(
                    word: word,
                    isSelected: word.isSelected,
                    onTap: {
                        viewModel.toggleWordSelection(wordID: word.id)
                    }
                )
            }
        }
    }
    
    private var selectionSummary: some View {
        HStack {
            VStack {
                Text("\(viewModel.selectedWordsCount)")
                    .font(SwiftUI.Font.appFont(type: .bold, size: Layout.summaryNumberSize))
                    .foregroundColor(Asset.gmPrimary.swiftUIColor)
                
                GMLabelView(
                    text: "Good Words",
                    fontSizeForPhone: Layout.summaryLabelSize,
                    color: .white.opacity(0.8)
                )
            }
            
            Spacer()
            
            VStack {
                Text("\(viewModel.unselectedWordsCount)")
                    .font(SwiftUI.Font.appFont(type: .bold, size: Layout.summaryNumberSize))
                    .foregroundColor(.red.opacity(0.8))
                
                GMLabelView(
                    text: "Bad Words",
                    fontSizeForPhone: Layout.summaryLabelSize,
                    color: .white.opacity(0.8)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Layout.cornerRadius)
                .fill(Asset.gmSecondary.swiftUIColor.opacity(0.3))
        )
    }
    
    private var footerSection: some View {
        VStack(spacing: Layout.footerSpacing) {
            HStack(spacing: Layout.buttonSpacing) {
                GMButtonView(
                    text: "Reset All",
                    backgroundColor: .gray.opacity(0.6),
                    height: Layout.buttonHeight
                ) {
                    viewModel.resetSelection()
                }
                
                GMButtonView(
                    text: viewModel.isLoading ? "Submitting..." : "Submit & Next",
                    backgroundColor: viewModel.canSubmit ? Asset.gmPrimary.swiftUIColor : .gray.opacity(0.6),
                    height: Layout.buttonHeight
                ) {
                    viewModel.submitCurrentBatch()
                }
                .disabled(!viewModel.canSubmit)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            
            GMLabelView(
                text: "Loading words...",
                color: .white.opacity(0.8)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WordReviewCard: View {
    let word: WordForReview
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    GMLabelView(
                        text: word.displayWord,
                        fontType: .bold,
                        fontSizeForPhone: 16,
                        color: isSelected ? .white : .white.opacity(0.6),
                        textAlignment: .leading
                    )
                    
                    Spacer()
                    
                    if let reviewStats = word.reviewStats {
                        Text("\(reviewStats.qualityScore)")
                            .font(SwiftUI.Font.appFont(type: .semiBold, size: 14))
                            .foregroundColor(scoreColor(for: reviewStats.qualityScore))
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.0 : 0.95)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private var backgroundColor: Color {
        isSelected ? Asset.gmPrimary.swiftUIColor.opacity(0.2) : Asset.gmSecondary.swiftUIColor.opacity(0.3)
    }
    
    private var borderColor: Color {
        isSelected ? Asset.gmPrimary.swiftUIColor : .white.opacity(0.3)
    }
    
    private func scoreColor(for score: Int) -> Color {
        switch score {
        case let x where x > 0:
            return .green.opacity(0.8)
        case let x where x < 0:
            return .red.opacity(0.8)
        default:
            return .white.opacity(0.6)
        }
    }
}

private extension WordReviewView {
    enum Layout {
        static let mainSpacing: CGFloat = 20
        static let headerSpacing: CGFloat = 16
        static let contentSpacing: CGFloat = 20
        static let footerSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 12
        static let gridSpacing: CGFloat = 12
        static let buttonSpacing: CGFloat = 16
        
        static let titleFontSize: CGFloat = 24
        static let progressFontSize: CGFloat = 16
        static let instructionFontSize: CGFloat = 14
        static let summaryNumberSize: CGFloat = 28
        static let summaryLabelSize: CGFloat = 14
        static let buttonHeight: CGFloat = 44
    }
}

#Preview {
    WordReviewView()
}
