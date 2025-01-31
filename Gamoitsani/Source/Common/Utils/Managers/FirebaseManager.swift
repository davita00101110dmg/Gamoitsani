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

    var coreDataManager: CoreDataManaging = CoreDataManager.shared
    var currentDate: Date = Date()
    
    private init() { }
    
    func fetchWordsIfNeeded(completion: @escaping ([Word]) -> Void, onStorageWarning: @escaping () -> Void) {
        Task {
            let lastSyncTimestamp = UserDefaults.lastWordSyncDate
            let currentTimestamp = currentDate.timeIntervalSince1970
            
            if currentTimestamp - lastSyncTimestamp >= .week {
                let firebaseWords = await fetchWordsFromFirebase(since: Date(timeIntervalSince1970: lastSyncTimestamp))
                do {
                    try await coreDataManager.saveWordsFromFirebase(firebaseWords)
                    await MainActor.run { UserDefaults.lastWordSyncDate = currentTimestamp }
                    let words = await coreDataManager.fetchWordsFromCoreData(quantity: 1500)
                    await MainActor.run { completion(words) }
                } catch CoreDataManager.StorageError.insufficientStorage {
                    await MainActor.run {
                        onStorageWarning()
                        completion([])
                    }
                } catch {
                    log(.error, "Error saving words: \(error)")
                    await MainActor.run { completion([]) }
                }
            } else {
                let words = await coreDataManager.fetchWordsFromCoreData(quantity: 1500)
                await MainActor.run { completion(words) }
            }
        }
    }
    
    private func fetchWordsFromFirebase(since date: Date, retries: Int = 3) async -> [WordFirebase] {
        return await withCheckedContinuation { continuation in
            wordsRef
                .whereField(AppConstants.Firebase.Fields.lastUpdated, isGreaterThan: date)
                .getDocuments { querySnapshot, error in
                    if let error = error {
                        log(.error, "Error fetching words: \(error.localizedDescription)")
                        
                        if retries > 0 {
                            Task {
                                let retryResult = await self.fetchWordsFromFirebase(since: date, retries: retries - 1)
                                continuation.resume(returning: retryResult)
                            }
                        } else {
                            continuation.resume(returning: [])
                        }
                        return
                    }
                    
                    let words = querySnapshot?.documents.compactMap { document -> WordFirebase? in
                        try? document.data(as: WordFirebase.self)
                    } ?? []
                    
                    continuation.resume(returning: words)
                }
        }
    }

    func fetchWords(limit: Int = 1500, completion: @escaping ([WordFirebase]) -> Void) {
        db.collection(AppConstants.Firebase.wordsCollectionName)
            .order(by: AppConstants.Firebase.Fields.lastUpdated, descending: true)
            .limit(to: limit)
            .getDocuments { querySnapshot, error in
                if let error {
                    log(.error, "Error fetching words: \(error.localizedDescription)")
                    return
                }
                
                let words = querySnapshot?.documents.compactMap { document -> WordFirebase? in
                    try? document.data(as: WordFirebase.self)
                } ?? []
                
                completion(words)
            }
    }
    
    func addWordToSuggestions(_ word: String, language: Language = .georgian, completion: @escaping (Bool) -> Void) {
        let query = suggestionsRef.whereField(AppConstants.Firebase.Fields.baseWord, isEqualTo: word)
        
        query.getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                log(.error, "Error checking for existing word: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let querySnapshot = querySnapshot, !querySnapshot.isEmpty {
                log(.error, "Word already exists in suggestions")
                completion(false)
                return
            }
            
            let newSuggestion: [String: Any] = [
                AppConstants.Firebase.Fields.baseWord: word,
                AppConstants.Firebase.Fields.language: language.rawValue,
                AppConstants.Firebase.Fields.lastUpdated: FieldValue.serverTimestamp(),
            ]
            
            self.suggestionsRef.addDocument(data: newSuggestion) { error in
                if let error = error {
                    log(.error, "Error adding word suggestion: \(error.localizedDescription)")
                    completion(false)
                } else {
                    log(.info, "Word suggestion added successfully")
                    completion(true)
                }
            }
        }
    }
}
