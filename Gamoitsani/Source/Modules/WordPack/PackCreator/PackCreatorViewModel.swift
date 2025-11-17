//
//  PackCreatorViewModel.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class PackCreatorViewModel: ObservableObject {

    @Published var packName = ""
    @Published var packDescription = ""
    @Published var isPublic = false
    @Published var words: [PackWord] = []
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isSaving = false
    @Published var entryMode: WordEntryMode = .simple
    @Published var bulkText = ""
    @Published var currentLanguage: String = LanguageManager.shared.currentLanguage.code

    // Simple mode
    @Published var currentWord = ""
    @Published var translations: [String: String] = [:]

    weak var coordinator: WordPackCoordinator?
    private let firebaseManager = FirebaseManager.shared
    private let deviceId = DeviceIDManager.shared.deviceID
    private let packToEdit: WordPackFirebase?

    private let minimumWords = 50

    init(packToEdit: WordPackFirebase? = nil) {
        self.packToEdit = packToEdit

        if let pack = packToEdit {
            self.packName = pack.packName
            self.packDescription = pack.description
            self.isPublic = pack.isPublic
            self.words = pack.words
        }
    }

    var isEditMode: Bool {
        packToEdit != nil
    }

    var canSave: Bool {
        !packName.isEmpty &&
        !packDescription.isEmpty &&
        words.count >= minimumWords
    }

    var wordsNeeded: Int {
        max(0, minimumWords - words.count)
    }

    // MARK: - Word Entry

    func addCurrentWord() {
        guard !currentWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError(message: "Word cannot be empty")
            return
        }

        let trimmedWord = currentWord.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for duplicates
        if words.contains(where: { $0.baseWord.lowercased() == trimmedWord.lowercased() }) {
            showError(message: "This word already exists in the pack")
            return
        }

        var translationData: [String: PackWord.TranslationData] = [:]

        // Add base word translation
        translationData[currentLanguage] = PackWord.TranslationData(word: trimmedWord)

        // Add any additional translations
        for (langCode, word) in translations where !word.isEmpty {
            translationData[langCode] = PackWord.TranslationData(word: word.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let newWord = PackWord(
            baseWord: trimmedWord,
            translations: translationData
        )

        words.append(newWord)
        currentWord = ""
        translations = [:]
    }

    func processBulkText() {
        let lines = bulkText.components(separatedBy: .newlines)
        var addedCount = 0
        var skippedCount = 0

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Skip if duplicate
            if words.contains(where: { $0.baseWord.lowercased() == trimmed.lowercased() }) {
                skippedCount += 1
                continue
            }

            let translationData = [currentLanguage: PackWord.TranslationData(word: trimmed)]
            let newWord = PackWord(baseWord: trimmed, translations: translationData)
            words.append(newWord)
            addedCount += 1
        }

        bulkText = ""

        if skippedCount > 0 {
            showError(message: "Added \(addedCount) words, skipped \(skippedCount) duplicates")
        } else {
            showError(message: "Added \(addedCount) words")
        }
    }

    func removeWord(at index: Int) {
        guard index < words.count else { return }
        words.remove(at: index)
    }

    func browseExistingWords() {
        coordinator?.navigateToWordBrowser { [weak self] selectedWords in
            self?.addWordsFromBrowser(selectedWords)
        }
    }

    private func addWordsFromBrowser(_ selectedWords: [Word]) {
        var addedCount = 0

        for word in selectedWords {
            guard let baseWord = word.baseWord else { continue }

            // Skip if duplicate
            if words.contains(where: { $0.baseWord.lowercased() == baseWord.lowercased() }) {
                continue
            }

            // Convert Word translations to PackWord format
            var translationData: [String: PackWord.TranslationData] = [:]

            if let translations = word.wordTranslations as? Set<Translation> {
                for translation in translations {
                    if let langCode = translation.languageCode,
                       let translatedWord = translation.word {
                        translationData[langCode] = PackWord.TranslationData(word: translatedWord)
                    }
                }
            }

            let newWord = PackWord(baseWord: baseWord, translations: translationData)
            words.append(newWord)
            addedCount += 1
        }

        showError(message: "Added \(addedCount) words from library")
    }

    // MARK: - Save Pack

    func savePack() {
        guard canSave else {
            if words.count < minimumWords {
                showError(message: "You need at least \(minimumWords) words. Add \(wordsNeeded) more.")
            } else {
                showError(message: "Please fill in all required fields")
            }
            return
        }

        isSaving = true

        // Determine status
        let status: WordPackStatus
        if isPublic {
            status = isEditMode && packToEdit?.status == .approved ? .pendingReview : .pendingReview
        } else {
            status = .private
        }

        // Get unique languages from all words
        let allLanguages = Set(words.flatMap { $0.translations.keys })

        let pack = WordPackFirebase(
            id: packToEdit?.id ?? UUID().uuidString,
            packName: packName,
            description: packDescription,
            creatorDeviceId: deviceId,
            creatorName: nil,
            words: words,
            languages: Array(allLanguages),
            isPublic: isPublic,
            status: status
        )

        if isEditMode {
            firebaseManager.updateWordPack(pack) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isSaving = false
                    switch result {
                    case .success:
                        self?.coordinator?.popViewController()
                    case .failure(let error):
                        self?.showError(message: "Failed to update pack: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            firebaseManager.createWordPack(pack) { [weak self] result in
                DispatchQueue.main.async {
                    self?.isSaving = false
                    switch result {
                    case .success:
                        self?.coordinator?.popViewController()
                    case .failure(let error):
                        self?.showError(message: "Failed to create pack: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - WordEntryMode

enum WordEntryMode: String, CaseIterable {
    case simple = "One by One"
    case bulk = "Bulk Entry"
    case browse = "Browse Library"
}
