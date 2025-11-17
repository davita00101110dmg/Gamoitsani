//
//  WordBrowserView.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct WordBrowserView: View {

    @ObservedObject var viewModel: WordBrowserViewModel

    var body: some View {
        ZStack {
            Asset.gmPrimary.swiftUIColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    GMTextFieldView(
                        text: $viewModel.searchText,
                        placeholder: "Search words...",
                        fontSizeForPhone: 16,
                        fontSizeForPad: 20
                    )

                    if !viewModel.selectedWords.isEmpty {
                        Button {
                            viewModel.clearSelection()
                        } label: {
                            Text("Clear")
                                .font(.appFont(type: .semiBold, size: 14))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()

                // Selected Count
                if !viewModel.selectedWords.isEmpty {
                    HStack {
                        Text("\(viewModel.selectedWords.count) selected")
                            .font(.appFont(type: .semiBold, size: 14))
                            .foregroundColor(.white)

                        Spacer()

                        GMButtonView(
                            text: "Add to Pack",
                            fontSizeForPhone: 14,
                            fontSizeForPad: 18,
                            backgroundColor: Asset.gmSecondary.swiftUIColor,
                            height: 36
                        ) {
                            viewModel.confirmSelection()
                        }
                        .frame(width: 120)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                // Words List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Spacer()
                } else if viewModel.filteredWords.isEmpty {
                    Spacer()
                    Text("No words found")
                        .font(.appFont(type: .regular, size: 16))
                        .foregroundColor(.white.opacity(0.6))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.filteredWords, id: \.objectID) { word in
                                WordRowView(
                                    word: word,
                                    isSelected: viewModel.isSelected(word)
                                ) {
                                    viewModel.toggleSelection(word)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Word Row View

struct WordRowView: View {

    let word: Word
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .green : .white.opacity(0.3))
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 4) {
                Text(word.baseWord ?? "")
                    .font(.appFont(type: .semiBold, size: 16))
                    .foregroundColor(.white)

                // Show translations preview
                if let translations = word.wordTranslations as? Set<Translation>,
                   let firstTranslation = translations.first {
                    Text(firstTranslation.word ?? "")
                        .font(.appFont(type: .regular, size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Translation count
            if let translations = word.wordTranslations as? Set<Translation> {
                Text("\(translations.count) langs")
                    .font(.appFont(type: .regular, size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(
            isSelected
            ? Asset.gmSecondary.swiftUIColor.opacity(0.4)
            : Asset.gmSecondary.swiftUIColor.opacity(0.2)
        )
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}
