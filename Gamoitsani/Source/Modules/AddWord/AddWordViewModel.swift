//
//  AddWordViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 11/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class AddWordViewModel: ObservableObject {
    @Published var showAlert: Bool = false
    @Published var selectedLanguage: Language = LanguageManager.shared.currentLanguage
    
    private(set) var isSuccess: Bool = false
    
    lazy var languagePickerViewModel: LanguagePickerRowViewModel = {
        LanguagePickerRowViewModel(initialLanguage: selectedLanguage) { [weak self] newLanguage in
            self?.selectedLanguage = newLanguage
        }
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.languagePickerViewModel = LanguagePickerRowViewModel()
    }
    
    func addWord(_ word: String) {
        FirebaseManager.shared.addWordToSuggestions(word, language: languagePickerViewModel.selectedLanguage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(_):
                    self?.isSuccess = false
                    self?.showAlert = true
                }
            } receiveValue: { [weak self] success in
                self?.isSuccess = success
                self?.showAlert = true
            }
            .store(in: &cancellables)
    }
    
    var alertTitle: String {
        isSuccess ? L10n.Screen.AddWord.successMessage : L10n.Screen.AddWord.errorMessage
    }
}

// Extension to FirebaseManager to return a Publisher
extension FirebaseManager {
    func addWordToSuggestions(_ word: String, language: Language) -> AnyPublisher<Bool, Error> {
        Future { promise in
            self.addWordToSuggestions(word, language: language) { success in
                promise(.success(success))
            }
        }
        .eraseToAnyPublisher()
    }
}
