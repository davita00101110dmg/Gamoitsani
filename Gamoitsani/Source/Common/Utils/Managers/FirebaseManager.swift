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
    
    func fetchWords(quantity: Int = 1500, completion: @escaping ([String]) -> Void) {
        wordsRef.limit(to: quantity).getDocuments { [weak self] snapshot, error in
            guard let self else { return }
            
            if let error = error {
                print("Error fetching words: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var words: [String] = []
            
            for document in snapshot?.documents ?? [] {
                guard let word = document.get(self.wordField) as? String else { continue }
                words.append(word)
            }
            
            words.shuffle()
            completion(words)
        }
    }
    
    // TODO: Add categories and definitions.
    func addWords(_ words: [String]) {
        for word in words {
            suggestionsRef.whereField(wordField, isEqualTo: word).getDocuments { [weak self] (querySnapshot, error) in
                guard let self else { return }
                
                if let error = error {
                    print("Error checking for existing word: \(error)")
                } else {
                    if querySnapshot!.documents.isEmpty {
                        
                        var data: [String: Any] = [:]
                        data[AppConstants.Firebase.wordKa] = wordField == AppConstants.Firebase.wordKa ? word : .empty
                        data[AppConstants.Firebase.wordEn] = wordField == AppConstants.Firebase.wordEn ? word : .empty
                        data[AppConstants.Firebase.categories] = String.empty
                        data[AppConstants.Firebase.definitions] = String.empty
                        
                        self.suggestionsRef.addDocument(data: data) { (error) in
                            if let error = error {
                                print("Error adding document: \(error)")
                            } else {
                                print("Document added successfully")
                            }
                        }
                    } else {
                        print("Document with word \(word) already exists")
                    }
                }
            }
        }
    }
}
