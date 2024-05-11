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
    
    private lazy var wordsRef = Firestore.firestore().collection(AppConstants.Firebase.wordsCollectionName)
    private lazy var suggestionsRef = Firestore.firestore().collection(AppConstants.Firebase.suggestedWordsCollectionName)

    private init() { }

    func fetchWords(quantity: Int = 1000, completion: @escaping ([String]) -> Void) {
        wordsRef.limit(to: quantity).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching words: \(error.localizedDescription)")
                completion([])
                return
            }
            
            var words: [String] = []
            
            for document in snapshot?.documents ?? [] {
                let word = document.documentID
                words.append(word)
            }
            
            words.shuffle()
            completion(words)
        }
    }
    
    func addWords(_ words: [String]) {
        for word in words {
            suggestionsRef.document(word).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error checking word: \(error.localizedDescription)")
                    return
                }
                
                if snapshot?.exists == true {
                    print("Word '\(word)' already exists in the database.")
                } else {
                    self.suggestionsRef.document(word).setData([:]) { (error) in
                        if let error = error {
                            print("Error adding word: \(error.localizedDescription)")
                        } else {
                            print("Added word: \(word)")
                        }
                    }
                }
            }
        }
    }
}
