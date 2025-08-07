//
//  WordReviewModels.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation

struct WordReviewStats: Codable {
    let positiveCount: Int
    let negativeCount: Int
    let totalReviews: Int
    let qualityScore: Int // positive - negative
    let lastReviewed: Date?
    let reviewedBy: [String]
    
    init(positiveCount: Int = 0, negativeCount: Int = 0, totalReviews: Int = 0, qualityScore: Int = 0, lastReviewed: Date? = nil, reviewedBy: [String] = []) {
        self.positiveCount = positiveCount
        self.negativeCount = negativeCount
        self.totalReviews = totalReviews
        self.qualityScore = qualityScore
        self.lastReviewed = lastReviewed
        self.reviewedBy = reviewedBy
    }
    
    enum CodingKeys: String, CodingKey {
        case positiveCount = "positive_count"
        case negativeCount = "negative_count"
        case totalReviews = "total_reviews"
        case qualityScore = "quality_score"
        case lastReviewed = "last_reviewed"
        case reviewedBy = "reviewed_by"
    }
}

struct WordForReview: Identifiable, Equatable {
    let id: String
    let baseWord: String
    let categories: [String]
    let reviewStats: WordReviewStats?
    let lastUpdated: Date
    let displayWord: String // Georgian translation or fallback to baseWord
    var isSelected: Bool = true
    
    static func == (lhs: WordForReview, rhs: WordForReview) -> Bool {
        lhs.id == rhs.id
    }
}

enum ReviewAction {
    case positive
    case negative
    
    var value: Int {
        switch self {
        case .positive: return 1
        case .negative: return -1
        }
    }
}

struct ReviewBatch {
    let goodWords: [String] // Document IDs
    let badWords: [String]  // Document IDs
    let reviewerID: String
    let timestamp: Date
    
    init(goodWords: [String], badWords: [String], reviewerID: String) {
        self.goodWords = goodWords
        self.badWords = badWords
        self.reviewerID = reviewerID
        self.timestamp = Date()
    }
}

struct ReviewProgress {
    let todayReviewed: Int
    let dailyGoal: Int
    let totalUnreviewed: Int
    
    var completionPercentage: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todayReviewed) / Double(dailyGoal), 1.0)
    }
    
    var isGoalReached: Bool {
        todayReviewed >= dailyGoal
    }
}
