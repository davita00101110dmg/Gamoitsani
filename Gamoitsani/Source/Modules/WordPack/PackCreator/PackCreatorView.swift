//
//  PackCreatorView.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct PackCreatorView: View {

    @ObservedObject var viewModel: PackCreatorViewModel

    var body: some View {
        ZStack {
            Asset.gmPrimary.swiftUIColor
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Pack Info Section
                    packInfoSection

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Entry Mode Picker
                    Picker("Entry Mode", selection: $viewModel.entryMode) {
                        ForEach(WordEntryMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // Entry Mode Content
                    switch viewModel.entryMode {
                    case .simple:
                        simpleEntrySection
                    case .bulk:
                        bulkEntrySection
                    case .browse:
                        browseSection
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))

                    // Words List
                    wordsListSection

                    // Save Button
                    VStack(spacing: 12) {
                        if viewModel.wordsNeeded > 0 {
                            Text("Add \(viewModel.wordsNeeded) more words to reach the minimum")
                                .font(.appFont(type: .regular, size: 14))
                                .foregroundColor(.yellow)
                        }

                        GMButtonView(
                            text: viewModel.isSaving ? "Saving..." : (viewModel.isEditMode ? "Update Pack" : "Create Pack"),
                            backgroundColor: viewModel.canSave ? Asset.gmSecondary.swiftUIColor : Color.gray
                        ) {
                            viewModel.savePack()
                        }
                        .disabled(!viewModel.canSave || viewModel.isSaving)
                    }
                }
                .padding()
            }
        }
        .alert("Info", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Pack Info Section

    private var packInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pack Information")
                .font(.appFont(type: .bold, size: 20))
                .foregroundColor(.white)

            GMTextFieldView(
                text: $viewModel.packName,
                placeholder: "Pack Name",
                fontSizeForPhone: 16,
                fontSizeForPad: 20
            )

            GMTextFieldView(
                text: $viewModel.packDescription,
                placeholder: "Description",
                fontSizeForPhone: 14,
                fontSizeForPad: 18
            )

            Toggle(isOn: $viewModel.isPublic) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Make Public")
                        .font(.appFont(type: .semiBold, size: 16))
                        .foregroundColor(.white)

                    Text(viewModel.isEditMode && viewModel.packToEdit?.status == .approved
                         ? "Editing will require re-approval"
                         : "Public packs require admin approval"
                    )
                    .font(.appFont(type: .regular, size: 12))
                    .foregroundColor(.white.opacity(0.6))
                }
            }
            .tint(Asset.gmSecondary.swiftUIColor)
        }
    }

    // MARK: - Simple Entry Section

    private var simpleEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Words")
                .font(.appFont(type: .bold, size: 18))
                .foregroundColor(.white)

            Text("Enter word in \(languageName(viewModel.currentLanguage))")
                .font(.appFont(type: .regular, size: 14))
                .foregroundColor(.white.opacity(0.7))

            HStack {
                GMTextFieldView(
                    text: $viewModel.currentWord,
                    placeholder: "Enter word",
                    fontSizeForPhone: 16,
                    fontSizeForPad: 20
                )

                GMButtonView(
                    text: "Add",
                    fontSizeForPhone: 14,
                    fontSizeForPad: 18,
                    backgroundColor: Asset.gmSecondary.swiftUIColor,
                    height: 44
                ) {
                    viewModel.addCurrentWord()
                }
                .frame(width: 80)
            }

            // Optional: Show translation fields for other languages
            Text("Optional: Add translations")
                .font(.appFont(type: .semiBold, size: 14))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
        }
    }

    // MARK: - Bulk Entry Section

    private var bulkEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bulk Entry")
                .font(.appFont(type: .bold, size: 18))
                .foregroundColor(.white)

            Text("Paste words, one per line")
                .font(.appFont(type: .regular, size: 14))
                .foregroundColor(.white.opacity(0.7))

            TextEditor(text: $viewModel.bulkText)
                .font(.appFont(type: .regular, size: 16))
                .frame(height: 150)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)

            GMButtonView(
                text: "Add All Words",
                backgroundColor: Asset.gmSecondary.swiftUIColor
            ) {
                viewModel.processBulkText()
            }
        }
    }

    // MARK: - Browse Section

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Word Library")
                .font(.appFont(type: .bold, size: 18))
                .foregroundColor(.white)

            Text("Select from 20,000+ existing words")
                .font(.appFont(type: .regular, size: 14))
                .foregroundColor(.white.opacity(0.7))

            GMButtonView(
                text: "Browse Words",
                backgroundColor: Asset.gmSecondary.swiftUIColor
            ) {
                viewModel.browseExistingWords()
            }
        }
    }

    // MARK: - Words List Section

    private var wordsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Words (\(viewModel.words.count))")
                    .font(.appFont(type: .bold, size: 18))
                    .foregroundColor(.white)

                Spacer()

                if viewModel.words.count >= 50 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 20))
                }
            }

            if viewModel.words.isEmpty {
                Text("No words added yet")
                    .font(.appFont(type: .regular, size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(viewModel.words.enumerated()), id: \.element.id) { index, word in
                    HStack {
                        Text("\(index + 1).")
                            .font(.appFont(type: .regular, size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 40, alignment: .leading)

                        Text(word.baseWord)
                            .font(.appFont(type: .regular, size: 16))
                            .foregroundColor(.white)

                        Spacer()

                        if word.translations.count > 1 {
                            Text("\(word.translations.count) langs")
                                .font(.appFont(type: .regular, size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(6)
                        }

                        Button {
                            viewModel.removeWord(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 16))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Asset.gmSecondary.swiftUIColor.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }

    private func languageName(_ code: String) -> String {
        switch code {
        case "ka": return "Georgian"
        case "en": return "English"
        case "ru": return "Russian"
        case "uk": return "Ukrainian"
        case "tr": return "Turkish"
        case "hy": return "Armenian"
        default: return code.uppercased()
        }
    }
}
