//
//  WordReviewViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import Combine

final class WordReviewViewModel: ObservableObject {
    @Published var words: [WordForReview] = []
    @Published var isLoading: Bool = false
    @Published var progress: ReviewProgress = ReviewProgress(todayReviewed: 0, dailyGoal: 100, totalUnreviewed: 0)
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var lastReviewedBatch: ReviewBatch?
    private let firebaseManager = FirebaseManager.shared
    
    private let wordsPerBatch = 20
    
    init() {
        loadInitialData()
    }
    
    private func loadInitialData() {
        loadNextBatch()
        loadProgress()
    }
    
    func loadNextBatch() {
        guard !isLoading else { return }
        
        isLoading = true
        log(.info, "Loading next batch of words for review...")
        
        firebaseManager.fetchWordsForReviewPublisher(limit: wordsPerBatch)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        log(.error, "Failed to load words: \(error.localizedDescription)")
                        self?.showError("Failed to load words: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] words in
                    log(.info, "Loaded \(words.count) words for review")
                    
                    // Log some details about what words we got
                    let reviewedCount = words.filter { word in
                        guard let stats = word.reviewStats else { return false }
                        return stats.reviewedBy.contains(DeviceIDManager.shared.deviceID)
                    }.count
                    
                    let unreviewedCount = words.count - reviewedCount
                    log(.info, "Words breakdown: \(unreviewedCount) unreviewed, \(reviewedCount) already reviewed")
                    
                    self?.words = words.map { word in
                        var mutableWord = word
                        mutableWord.isSelected = true // All words start as "good"
                        return mutableWord
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func toggleWordSelection(wordID: String) {
        if let index = words.firstIndex(where: { $0.id == wordID }) {
            words[index].isSelected.toggle()
        }
    }
    
    func submitCurrentBatch() {
        guard !words.isEmpty else {
            loadNextBatch()
            return
        }
        
        let goodWords = words.filter { $0.isSelected }.map { $0.id }
        let badWords = words.filter { !$0.isSelected }.map { $0.id }
        
        log(.info, "Submitting batch: \(goodWords.count) good words, \(badWords.count) bad words")
        
        let batch = ReviewBatch(
            goodWords: goodWords,
            badWords: badWords,
            reviewerID: DeviceIDManager.shared.deviceID
        )
        
        lastReviewedBatch = batch
        
        isLoading = true
        
        firebaseManager.submitReviewBatchPublisher(batch)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        log(.error, "Review submission failed: \(error.localizedDescription)")
                        self?.showError("Failed to submit reviews: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] success in
                    if success {
                        log(.info, "Review batch submitted successfully")
                        self?.handleSuccessfulSubmission(reviewCount: goodWords.count + badWords.count)
                    } else {
                        log(.error, "Review batch submission returned false")
                        self?.showError("Some reviews failed to submit. Please try again.")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleSuccessfulSubmission(reviewCount: Int) {
        // Update local progress
        AppSettings.incrementTodayReviewCount(by: reviewCount)
        
        // Show completion feedback
        showSuccess("Reviewed \(reviewCount) words! 🎉")
        
        // Clear current words immediately and load next batch
        words.removeAll()
        
        // Small delay to show success message, then load new batch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.loadNextBatch()
        }
        
        // Update progress
        loadProgress()
    }
    
    func loadProgress() {
        firebaseManager.getReviewProgressPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        log(.error, "Failed to load progress: \(error)")
                    }
                },
                receiveValue: { [weak self] progress in
                    self?.progress = progress
                }
            )
            .store(in: &cancellables)
    }
    
    func resetSelection() {
        words = words.map { word in
            var mutableWord = word
            mutableWord.isSelected = true
            return mutableWord
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func showSuccess(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    // MARK: - Computed Properties
    
    var selectedWordsCount: Int {
        words.filter { $0.isSelected }.count
    }
    
    var unselectedWordsCount: Int {
        words.count - selectedWordsCount
    }
    
    var progressText: String {
        "\(progress.todayReviewed)/\(progress.dailyGoal) reviewed today"
    }
    
    var progressPercentage: Double {
        progress.completionPercentage
    }
    
    var canSubmit: Bool {
        !words.isEmpty && !isLoading
    }
}
