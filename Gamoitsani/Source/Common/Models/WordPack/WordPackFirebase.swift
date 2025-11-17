//
//  WordPackFirebase.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseFirestore

// MARK: - WordPackFirebase

struct WordPackFirebase: Codable, Identifiable {
    let id: String
    let packName: String
    let description: String
    let creatorDeviceId: String
    let creatorName: String?
    let createdAt: Date
    let lastUpdated: Date
    let words: [PackWord]
    let wordCount: Int
    let languages: [String]
    let downloadCount: Int
    let playCount: Int
    let ratingStats: RatingStats
    let isPublic: Bool
    let isFeatured: Bool
    let status: WordPackStatus
    let reportedCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "pack_id"
        case packName = "pack_name"
        case description
        case creatorDeviceId = "creator_device_id"
        case creatorName = "creator_name"
        case createdAt = "created_at"
        case lastUpdated = "last_updated"
        case words
        case wordCount = "word_count"
        case languages
        case downloadCount = "download_count"
        case playCount = "play_count"
        case ratingStats = "rating_stats"
        case isPublic = "is_public"
        case isFeatured = "is_featured"
        case status
        case reportedCount = "reported_count"
    }

    init(
        id: String = UUID().uuidString,
        packName: String,
        description: String,
        creatorDeviceId: String,
        creatorName: String? = nil,
        createdAt: Date = Date(),
        lastUpdated: Date = Date(),
        words: [PackWord],
        languages: [String],
        isPublic: Bool,
        isFeatured: Bool = false,
        status: WordPackStatus = .private
    ) {
        self.id = id
        self.packName = packName
        self.description = description
        self.creatorDeviceId = creatorDeviceId
        self.creatorName = creatorName
        self.createdAt = createdAt
        self.lastUpdated = lastUpdated
        self.words = words
        self.wordCount = words.count
        self.languages = languages
        self.downloadCount = 0
        self.playCount = 0
        self.ratingStats = RatingStats()
        self.isPublic = isPublic
        self.isFeatured = isFeatured
        self.status = status
        self.reportedCount = 0
    }
}

// MARK: - PackWord

struct PackWord: Codable, Identifiable {
    let id: String
    let baseWord: String
    let translations: [String: TranslationData]

    enum CodingKeys: String, CodingKey {
        case id
        case baseWord = "base_word"
        case translations
    }

    struct TranslationData: Codable {
        let word: String

        init(word: String) {
            self.word = word
        }
    }

    init(
        id: String = UUID().uuidString,
        baseWord: String,
        translations: [String: TranslationData] = [:]
    ) {
        self.id = id
        self.baseWord = baseWord
        self.translations = translations
    }
}

// MARK: - RatingStats

struct RatingStats: Codable {
    let averageRating: Double
    let totalRatings: Int
    let fiveStar: Int
    let fourStar: Int
    let threeStar: Int
    let twoStar: Int
    let oneStar: Int

    enum CodingKeys: String, CodingKey {
        case averageRating = "average_rating"
        case totalRatings = "total_ratings"
        case fiveStar = "five_star"
        case fourStar = "four_star"
        case threeStar = "three_star"
        case twoStar = "two_star"
        case oneStar = "one_star"
    }

    init(
        averageRating: Double = 0.0,
        totalRatings: Int = 0,
        fiveStar: Int = 0,
        fourStar: Int = 0,
        threeStar: Int = 0,
        twoStar: Int = 0,
        oneStar: Int = 0
    ) {
        self.averageRating = averageRating
        self.totalRatings = totalRatings
        self.fiveStar = fiveStar
        self.fourStar = fourStar
        self.threeStar = threeStar
        self.twoStar = twoStar
        self.oneStar = oneStar
    }

    func withNewRating(_ rating: Int) -> RatingStats {
        var newFiveStar = fiveStar
        var newFourStar = fourStar
        var newThreeStar = threeStar
        var newTwoStar = twoStar
        var newOneStar = oneStar

        switch rating {
        case 5: newFiveStar += 1
        case 4: newFourStar += 1
        case 3: newThreeStar += 1
        case 2: newTwoStar += 1
        case 1: newOneStar += 1
        default: break
        }

        let newTotalRatings = totalRatings + 1
        let sum = (newFiveStar * 5) + (newFourStar * 4) + (newThreeStar * 3) + (newTwoStar * 2) + (newOneStar * 1)
        let newAverageRating = newTotalRatings > 0 ? Double(sum) / Double(newTotalRatings) : 0.0

        return RatingStats(
            averageRating: newAverageRating,
            totalRatings: newTotalRatings,
            fiveStar: newFiveStar,
            fourStar: newFourStar,
            threeStar: newThreeStar,
            twoStar: newTwoStar,
            oneStar: newOneStar
        )
    }
}

// MARK: - WordPackStatus

enum WordPackStatus: String, Codable {
    case `private` = "private"
    case pendingReview = "pending_review"
    case approved = "approved"
    case rejected = "rejected"
    case banned = "banned"
}
