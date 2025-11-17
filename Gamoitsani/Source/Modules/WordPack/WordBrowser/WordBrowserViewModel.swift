//
//  WordBrowserViewModel.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class WordBrowserViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var allWords: [Word] = []
    @Published var filteredWords: [Word] = []
    @Published var selectedWords: Set<String> = []
    @Published var isLoading = false

    weak var coordinator: WordPackCoordinator?
    private let onWordsSelected: ([Word]) -> Void
    private let coreDataManager = CoreDataManager.shared
    private var cancellables = Set<AnyCancellable>()

    init(onWordsSelected: @escaping ([Word]) -> Void) {
        self.onWordsSelected = onWordsSelected
        setupSearchDebounce()
        loadWords()
    }

    private func setupSearchDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.filterWords(query: query)
            }
            .store(in: &cancellables)
    }

    func loadWords() {
        isLoading = true

        Task {
            let words = await coreDataManager.fetchWordsFromCoreData(quantity: 1000)
            await MainActor.run {
                self.allWords = words
                self.filteredWords = words
                self.isLoading = false
            }
        }
    }

    private func filterWords(query: String) {
        if query.isEmpty {
            filteredWords = allWords
        } else {
            let lowercaseQuery = query.lowercased()
            filteredWords = allWords.filter { word in
                word.baseWord?.lowercased().contains(lowercaseQuery) ?? false
            }
        }
    }

    func toggleSelection(_ word: Word) {
        guard let baseWord = word.baseWord else { return }

        if selectedWords.contains(baseWord) {
            selectedWords.remove(baseWord)
        } else {
            selectedWords.insert(baseWord)
        }
    }

    func isSelected(_ word: Word) -> Bool {
        guard let baseWord = word.baseWord else { return false }
        return selectedWords.contains(baseWord)
    }

    func confirmSelection() {
        let selected = allWords.filter { word in
            guard let baseWord = word.baseWord else { return false }
            return selectedWords.contains(baseWord)
        }

        onWordsSelected(selected)
        coordinator?.popViewController()
    }

    func clearSelection() {
        selectedWords.removeAll()
    }
}
