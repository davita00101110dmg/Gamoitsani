//
//  FirebaseManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 09/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private lazy var wordsRef = db.collection(AppConstants.Firebase.wordsCollectionName)
    private lazy var suggestionsRef = db.collection(AppConstants.Firebase.suggestedWordsCollectionName)
    
    private var wordField: String {
        UserDefaults.appLanguage == AppConstants.Language.georgian.identifier ? AppConstants.Firebase.wordKa : AppConstants.Firebase.wordEn
    }

    private init() { }
    
    func fetchWords(quantity: Int = 1500) {
        guard let randomField = [AppConstants.Firebase.wordKa, AppConstants.Firebase.wordEn].randomElement() else { return }
    
        wordsRef.order(by: randomField, descending: Bool.random()).limit(to: quantity).getDocuments { snapshot, error in
            if let error = error {
                dump("Error fetching words: \(error.localizedDescription)")
                return
            }
            
            dump("Fetching words")
            
            var wordsToSave: [(wordKa: String, wordEn: String, categories: [String]?, definitions: [String]?)] = []
            
            for document in snapshot?.documents ?? [] {
                guard let wordKa = document.get(AppConstants.Firebase.wordKa) as? String,
                      let wordEn = document.get(AppConstants.Firebase.wordEn) as? String,
                      let categories = document.get(AppConstants.Firebase.categories) as? [String],
                      let definitions = document.get(AppConstants.Firebase.definitions) as? [String] else { continue }
                
                wordsToSave.append((wordKa, wordEn, categories, definitions))
            }
            
            CoreDataManager.shared.saveWordsFromFirebase(wordsToSave)
        }
    }
    
    func addWordToSuggestions(_ words: String...) {
        for word in words {
            suggestionsRef.whereField(wordField, isEqualTo: word).getDocuments { querySnapshot, error in
                if let error = error {
                    dump("Error checking for existing word: \(error.localizedDescription)")
                    return
                }
                
                guard let snapshot = querySnapshot else { return }
                
                if snapshot.isEmpty {
                    var data: [String: Any] = [:]
                    data[AppConstants.Firebase.wordKa] = self.wordField == AppConstants.Firebase.wordKa ? word : ""
                    data[AppConstants.Firebase.wordEn] = self.wordField == AppConstants.Firebase.wordEn ? word : ""
                    data[AppConstants.Firebase.categories] = []
                    data[AppConstants.Firebase.definitions] = []
                    
                    self.suggestionsRef.addDocument(data: data) { error in
                        if let error = error {
                            dump("Error adding document: \(error.localizedDescription)")
                        } else {
                            dump("Document added successfully")
                        }
                    }
                }
            }
        }
    }
}
