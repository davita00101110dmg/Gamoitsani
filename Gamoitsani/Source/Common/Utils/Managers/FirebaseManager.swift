//
//  FirebaseManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 09/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import FirebaseFirestore

struct WordFirebase: Codable {
    let baseWord: String
    let categories: [String]
    let translations: [String: TranslationData]
    let lastUpdated: Date
    
    enum CodingKeys: String, CodingKey {
        case baseWord = "base_word"
        case categories
        case translations
        case lastUpdated = "last_updated"
    }
    
    struct TranslationData: Codable {
        let word: String
        let difficulty: Int
    }
}

final class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private lazy var wordsRef = db.collection(AppConstants.Firebase.wordsCollectionName)
    private lazy var suggestionsRef = db.collection(AppConstants.Firebase.suggestedWordsCollectionName)

    private init() { }
    
    func fetchWords(limit: Int = 1500, completion: @escaping ([WordFirebase]) -> Void) {
        db.collection(AppConstants.Firebase.wordsCollectionName)
            .order(by: "last_updated", descending: true)
            .limit(to: limit)
            .getDocuments { querySnapshot, error in
                if let error {
                    dump("Error fetching words: \(error.localizedDescription)")
                    return
                }
                
                let words = querySnapshot?.documents.compactMap { document -> WordFirebase? in
                    try? document.data(as: WordFirebase.self)
                } ?? []
                
                completion(words)
            }
    }
//    
//    func addWordToSuggestions(_ words: String...) {
//        for word in words {
//            suggestionsRef.whereField(wordField, isEqualTo: word).getDocuments { querySnapshot, error in
//                if let error = error {
//                    dump("Error checking for existing word: \(error.localizedDescription)")
//                    return
//                }
//                
//                guard let snapshot = querySnapshot else { return }
//                
//                if snapshot.isEmpty {
//                    var data: [String: Any] = [:]
//                    data[AppConstants.Firebase.wordKa] = self.wordField == AppConstants.Firebase.wordKa ? word : ""
//                    data[AppConstants.Firebase.wordEn] = self.wordField == AppConstants.Firebase.wordEn ? word : ""
//                    data[AppConstants.Firebase.categories] = []
//                    data[AppConstants.Firebase.definitions] = []
//                    
//                    self.suggestionsRef.addDocument(data: data) { error in
//                        if let error = error {
//                            dump("Error adding document: \(error.localizedDescription)")
//                        } else {
//                            dump("Document added successfully")
//                        }
//                    }
//                }
//            }
//        }
//    }
}
