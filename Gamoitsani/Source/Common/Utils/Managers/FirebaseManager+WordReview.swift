//
//  FirebaseManager+WordReview.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseFirestore
import Combine

extension FirebaseManager {
    
    // MARK: - Word Review Operations
    
    func fetchWordsForReview(limit: Int = 20, completion: @escaping ([WordForReview]) -> Void) {
        let deviceID = DeviceIDManager.shared.deviceID
        log(.info, "Fetching words for review, device ID: \(deviceID)")
        
        // Try multiple strategies to find unreviewed words
        tryFetchingUnreviewedWords(deviceID: deviceID, limit: limit, strategy: 1, completion: completion)
    }
    
    private func tryFetchingUnreviewedWords(deviceID: String, limit: Int, strategy: Int, completion: @escaping ([WordForReview]) -> Void) {
        let maxStrategies = 3
        
        log(.info, "Strategy \(strategy)/\(maxStrategies): Attempting to find unreviewed words")
        
        let fetchLimit = limit * 25 // Always fetch 500 words
        let query: Query
        
        // Use different ordering strategies to get different subsets of your database
        switch strategy {
        case 1:
            // Strategy 1: Order by last_updated (newest first)
            query = wordsRef.order(by: AppConstants.Firebase.Fields.lastUpdated, descending: true).limit(to: fetchLimit)
        case 2:
            // Strategy 2: Order by base_word alphabetically
            query = wordsRef.order(by: AppConstants.Firebase.Fields.baseWord, descending: false).limit(to: fetchLimit)
        case 3:
            // Strategy 3: Order by base_word reverse alphabetically
            query = wordsRef.order(by: AppConstants.Firebase.Fields.baseWord, descending: true).limit(to: fetchLimit)
        default:
            // Fallback: no ordering (Firestore's default)
            query = wordsRef.limit(to: fetchLimit)
        }
        
        query.getDocuments { [weak self] querySnapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                log(.error, "Strategy \(strategy) failed: \(error.localizedDescription)")
                if strategy < maxStrategies {
                    // Try next strategy
                    self.tryFetchingUnreviewedWords(deviceID: deviceID, limit: limit, strategy: strategy + 1, completion: completion)
                } else {
                    completion([])
                }
                return
            }
            
            var allWords = self.parseWordsForReview(from: querySnapshot?.documents ?? [])
            allWords.shuffle() // Add randomness
            
            let (unreviewed, reviewed) = self.separateWords(allWords: allWords, deviceID: deviceID)
            
            log(.info, "Strategy \(strategy): Found \(unreviewed.count) unreviewed, \(reviewed.count) reviewed")
            
            // If we found enough unreviewed words, return them
            if unreviewed.count >= limit {
                let finalWords = Array(unreviewed.prefix(limit))
                log(.info, "Strategy \(strategy): Success! Returning \(finalWords.count) unreviewed words")
                completion(finalWords)
                return
            }
            
            // If we don't have enough unreviewed words, try next strategy
            if strategy < maxStrategies {
                log(.info, "Strategy \(strategy): Not enough unreviewed words, trying strategy \(strategy + 1)")
                self.tryFetchingUnreviewedWords(deviceID: deviceID, limit: limit, strategy: strategy + 1) { moreWords in
                    // Combine unique unreviewed words from both strategies
                    var combinedUnreviewed = unreviewed
                    
                    // Add new unreviewed words that we haven't seen before
                    for newWord in moreWords {
                        if !combinedUnreviewed.contains(where: { $0.id == newWord.id }),
                           let newStats = newWord.reviewStats,
                           !newStats.reviewedBy.contains(deviceID) {
                            combinedUnreviewed.append(newWord)
                        }
                    }
                    
                    // Return up to limit words, prioritizing unreviewed
                    var finalWords = Array(combinedUnreviewed.prefix(limit))
                    
                    // Fill remaining slots with reviewed words if needed
                    if finalWords.count < limit {
                        let reviewedNeeded = limit - finalWords.count
                        finalWords.append(contentsOf: Array(reviewed.prefix(reviewedNeeded)))
                    }
                    
                    log(.info, "Combined strategies: Returning \(finalWords.count) words (\(min(combinedUnreviewed.count, limit)) unreviewed)")
                    completion(Array(finalWords.prefix(limit)))
                }
                return
            }
            
            // Last resort: return what we have
            var finalWords = unreviewed
            if finalWords.count < limit {
                let reviewedNeeded = limit - finalWords.count
                finalWords.append(contentsOf: Array(reviewed.prefix(reviewedNeeded)))
            }
            
            log(.info, "Strategy \(strategy): Final fallback - returning \(min(finalWords.count, limit)) words")
            completion(Array(finalWords.prefix(limit)))
        }
    }
    
    private func separateWords(allWords: [WordForReview], deviceID: String) -> (unreviewed: [WordForReview], reviewed: [WordForReview]) {
        var unreviewed: [WordForReview] = []
        var reviewed: [WordForReview] = []
        
        for word in allWords {
            if let reviewStats = word.reviewStats,
               reviewStats.reviewedBy.contains(deviceID) {
                reviewed.append(word)
            } else {
                unreviewed.append(word)
            }
        }
        
        return (unreviewed, reviewed)
    }
    
    private func parseWordsForReview(from documents: [QueryDocumentSnapshot]) -> [WordForReview] {
        return documents.compactMap { document in
            let data = document.data()
            
            guard let baseWord = data["base_word"] as? String,
                  let categories = data["categories"] as? [String],
                  let lastUpdated = (data["last_updated"] as? Timestamp)?.dateValue() else {
                return nil
            }
            
            // Extract Georgian translation or fallback to baseWord
            let displayWord: String
            if let translations = data["translations"] as? [String: [String: Any]],
               let georgianTranslation = translations[Language.georgian.rawValue],
               let georgianWord = georgianTranslation["word"] as? String,
               !georgianWord.isEmpty {
                displayWord = georgianWord
            } else {
                displayWord = baseWord
            }
            
            let reviewStats: WordReviewStats?
            if let reviewStatsData = data[AppConstants.Firebase.Fields.reviewStats] as? [String: Any] {
                reviewStats = parseReviewStats(from: reviewStatsData)
            } else {
                reviewStats = nil
            }
            
            return WordForReview(
                id: document.documentID,
                baseWord: baseWord,
                categories: categories,
                reviewStats: reviewStats,
                lastUpdated: lastUpdated,
                displayWord: displayWord
            )
        }
    }
    
    private func parseReviewStats(from data: [String: Any]) -> WordReviewStats {
        let positiveCount = data[AppConstants.Firebase.Fields.positiveCount] as? Int ?? 0
        let negativeCount = data[AppConstants.Firebase.Fields.negativeCount] as? Int ?? 0
        let totalReviews = data[AppConstants.Firebase.Fields.totalReviews] as? Int ?? 0
        let qualityScore = data[AppConstants.Firebase.Fields.qualityScore] as? Int ?? 0
        let lastReviewed = (data[AppConstants.Firebase.Fields.lastReviewed] as? Timestamp)?.dateValue()
        let reviewedBy = data[AppConstants.Firebase.Fields.reviewedBy] as? [String] ?? []
        
        return WordReviewStats(
            positiveCount: positiveCount,
            negativeCount: negativeCount,
            totalReviews: totalReviews,
            qualityScore: qualityScore,
            lastReviewed: lastReviewed,
            reviewedBy: reviewedBy
        )
    }
    
    func submitReviewBatch(_ batch: ReviewBatch, completion: @escaping (Bool) -> Void) {
        // Direct batch review without authentication since security rules handle it
        performBatchReview(batch, completion: completion)
    }
    
    private func performBatchReview(_ batch: ReviewBatch, completion: @escaping (Bool) -> Void) {
        let dispatchGroup = DispatchGroup()
        var hasError = false
        
        log(.info, "Starting batch review: \(batch.goodWords.count) good, \(batch.badWords.count) bad")
        
        // Submit positive reviews
        for wordID in batch.goodWords {
            dispatchGroup.enter()
            updateWordReview(wordID: wordID, action: .positive, reviewerID: batch.reviewerID) { success in
                if !success { hasError = true }
                dispatchGroup.leave()
            }
        }
        
        // Submit negative reviews
        for wordID in batch.badWords {
            dispatchGroup.enter()
            updateWordReview(wordID: wordID, action: .negative, reviewerID: batch.reviewerID) { success in
                if !success { hasError = true }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            log(.info, "Batch review completed. Success: \(!hasError)")
            completion(!hasError)
        }
    }
    
    private func updateWordReview(wordID: String, action: ReviewAction, reviewerID: String, completion: @escaping (Bool) -> Void) {
        let wordRef = wordsRef.document(wordID)
        
        log(.info, "Updating word review: \(wordID), action: \(action == .positive ? "positive" : "negative")")
        
        db.runTransaction({ [weak self] transaction, errorPointer in
            guard let self else {
                log(.error, "Self is nil in transaction")
                completion(false)
                return nil
            }
            
            let document: DocumentSnapshot
            do {
                document = try transaction.getDocument(wordRef)
            } catch let fetchError as NSError {
                log(.error, "Error fetching document in transaction: \(fetchError.localizedDescription)")
                errorPointer?.pointee = fetchError
                return nil
            }
            
            let data = document.data() ?? [:]
            var reviewStats = data[AppConstants.Firebase.Fields.reviewStats] as? [String: Any] ?? [:]
            
            // Check if user already reviewed this word
            let reviewedBy = reviewStats[AppConstants.Firebase.Fields.reviewedBy] as? [String] ?? []
            if reviewedBy.contains(reviewerID) {
                log(.info, "User \(reviewerID) already reviewed word \(wordID), skipping")
                return nil // Skip if already reviewed
            }
            
            let currentPositive = reviewStats[AppConstants.Firebase.Fields.positiveCount] as? Int ?? 0
            let currentNegative = reviewStats[AppConstants.Firebase.Fields.negativeCount] as? Int ?? 0
            let currentTotal = reviewStats[AppConstants.Firebase.Fields.totalReviews] as? Int ?? 0
            
            // Update counts based on action
            let newPositive = action == .positive ? currentPositive + 1 : currentPositive
            let newNegative = action == .negative ? currentNegative + 1 : currentNegative
            let newTotal = currentTotal + 1
            let newQualityScore = newPositive - newNegative
            
            // Update review stats
            reviewStats[AppConstants.Firebase.Fields.positiveCount] = newPositive
            reviewStats[AppConstants.Firebase.Fields.negativeCount] = newNegative
            reviewStats[AppConstants.Firebase.Fields.totalReviews] = newTotal
            reviewStats[AppConstants.Firebase.Fields.qualityScore] = newQualityScore
            reviewStats[AppConstants.Firebase.Fields.lastReviewed] = FieldValue.serverTimestamp()
            reviewStats[AppConstants.Firebase.Fields.reviewedBy] = FieldValue.arrayUnion([reviewerID])
            
            log(.info, "New stats for word \(wordID): +\(newPositive) -\(newNegative) score:\(newQualityScore)")
            
            // Check if word should be removed (3+ negative reviews with negative score)
            if newNegative >= 3 && newQualityScore < 0 {
                log(.info, "Deleting word \(wordID) due to poor quality")
                transaction.deleteDocument(wordRef)
            } else {
                transaction.updateData([AppConstants.Firebase.Fields.reviewStats: reviewStats], forDocument: wordRef)
            }
            
            return nil
            
        }) { result, error in
            if let error = error {
                log(.error, "Word review transaction failed: \(error.localizedDescription)")
                completion(false)
            } else {
                log(.info, "Word review transaction succeeded for \(wordID)")
                completion(true)
            }
        }
    }
    
    func getReviewProgress(completion: @escaping (ReviewProgress) -> Void) {
        AppSettings.checkAndResetDailyReviewCount()
        
        // Get count of unreviewed words
        let deviceID = DeviceIDManager.shared.deviceID
        
        wordsRef
            .whereField("review_stats.reviewed_by", arrayContains: deviceID)
            .getDocuments { [weak self] reviewedSnapshot, error in
                guard let self = self else { return }
                
                let reviewedCount = reviewedSnapshot?.documents.count ?? 0
                
                self.wordsRef.getDocuments { totalSnapshot, error in
                    let totalCount = totalSnapshot?.documents.count ?? 0
                    let unreviewedCount = max(0, totalCount - reviewedCount)
                    
                    let progress = ReviewProgress(
                        todayReviewed: AppSettings.todayReviewedCount,
                        dailyGoal: AppSettings.reviewDailyGoal,
                        totalUnreviewed: unreviewedCount
                    )
                    
                    completion(progress)
                }
            }
    }
}

// MARK: - Combine Publishers

extension FirebaseManager {
    func fetchWordsForReviewPublisher(limit: Int = 20) -> AnyPublisher<[WordForReview], Error> {
        Future { [weak self] promise in
            self?.fetchWordsForReview(limit: limit) { words in
                promise(.success(words))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func submitReviewBatchPublisher(_ batch: ReviewBatch) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            self?.submitReviewBatch(batch) { success in
                promise(.success(success))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getReviewProgressPublisher() -> AnyPublisher<ReviewProgress, Error> {
        Future { [weak self] promise in
            self?.getReviewProgress { progress in
                promise(.success(progress))
            }
        }
        .eraseToAnyPublisher()
    }
}
