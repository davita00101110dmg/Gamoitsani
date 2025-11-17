//
//  FirebaseManager+WordPack.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseFirestore

extension FirebaseManager {

    var wordPacksRef: CollectionReference {
        db.collection(AppConstants.Firebase.wordPacksCollectionName)
    }

    // MARK: - Create/Save Pack

    func createWordPack(
        _ pack: WordPackFirebase,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        do {
            let documentRef = wordPacksRef.document(pack.id)
            try documentRef.setData(from: pack) { error in
                if let error = error {
                    log(.error, "Error creating word pack: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    log(.info, "Word pack created successfully: \(pack.id)")
                    completion(.success(pack.id))
                }
            }
        } catch {
            log(.error, "Error encoding word pack: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    // MARK: - Fetch Packs

    func fetchUserPacks(
        deviceId: String,
        completion: @escaping ([WordPackFirebase]) -> Void
    ) {
        wordPacksRef
            .whereField(AppConstants.Firebase.Fields.creatorDeviceId, isEqualTo: deviceId)
            .order(by: AppConstants.Firebase.Fields.createdAt, descending: true)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    log(.error, "Error fetching user packs: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let packs = querySnapshot?.documents.compactMap { document -> WordPackFirebase? in
                    try? document.data(as: WordPackFirebase.self)
                } ?? []

                completion(packs)
            }
    }

    func fetchPublicPacks(
        limit: Int = 50,
        sortBy: PackSortOption = .mostDownloaded,
        completion: @escaping ([WordPackFirebase]) -> Void
    ) {
        var query: Query = wordPacksRef
            .whereField(AppConstants.Firebase.Fields.isPublic, isEqualTo: true)
            .whereField(AppConstants.Firebase.Fields.status, isEqualTo: WordPackStatus.approved.rawValue)

        // Apply sorting
        switch sortBy {
        case .mostDownloaded:
            query = query.order(by: AppConstants.Firebase.Fields.downloadCount, descending: true)
        case .highestRated:
            query = query.order(by: AppConstants.Firebase.Fields.ratingStats + ".\(AppConstants.Firebase.Fields.averageRating)", descending: true)
        case .mostRecent:
            query = query.order(by: AppConstants.Firebase.Fields.createdAt, descending: true)
        case .mostPlayed:
            query = query.order(by: AppConstants.Firebase.Fields.playCount, descending: true)
        }

        query.limit(to: limit).getDocuments { querySnapshot, error in
            if let error = error {
                log(.error, "Error fetching public packs: \(error.localizedDescription)")
                completion([])
                return
            }

            let packs = querySnapshot?.documents.compactMap { document -> WordPackFirebase? in
                try? document.data(as: WordPackFirebase.self)
            } ?? []

            completion(packs)
        }
    }

    func fetchFeaturedPacks(
        limit: Int = 10,
        completion: @escaping ([WordPackFirebase]) -> Void
    ) {
        wordPacksRef
            .whereField(AppConstants.Firebase.Fields.isFeatured, isEqualTo: true)
            .whereField(AppConstants.Firebase.Fields.status, isEqualTo: WordPackStatus.approved.rawValue)
            .order(by: AppConstants.Firebase.Fields.downloadCount, descending: true)
            .limit(to: limit)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    log(.error, "Error fetching featured packs: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let packs = querySnapshot?.documents.compactMap { document -> WordPackFirebase? in
                    try? document.data(as: WordPackFirebase.self)
                } ?? []

                completion(packs)
            }
    }

    func fetchPackById(
        _ packId: String,
        completion: @escaping (WordPackFirebase?) -> Void
    ) {
        wordPacksRef.document(packId).getDocument { document, error in
            if let error = error {
                log(.error, "Error fetching pack by ID: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let document = document, document.exists else {
                log(.warning, "Pack not found: \(packId)")
                completion(nil)
                return
            }

            let pack = try? document.data(as: WordPackFirebase.self)
            completion(pack)
        }
    }

    func searchPacks(
        query: String,
        limit: Int = 30,
        completion: @escaping ([WordPackFirebase]) -> Void
    ) {
        let lowercaseQuery = query.lowercased()

        wordPacksRef
            .whereField(AppConstants.Firebase.Fields.isPublic, isEqualTo: true)
            .whereField(AppConstants.Firebase.Fields.status, isEqualTo: WordPackStatus.approved.rawValue)
            .limit(to: 100) // Get more to filter client-side
            .getDocuments { querySnapshot, error in
                if let error = error {
                    log(.error, "Error searching packs: \(error.localizedDescription)")
                    completion([])
                    return
                }

                let packs = querySnapshot?.documents.compactMap { document -> WordPackFirebase? in
                    try? document.data(as: WordPackFirebase.self)
                }.filter { pack in
                    pack.packName.lowercased().contains(lowercaseQuery) ||
                    pack.description.lowercased().contains(lowercaseQuery)
                }.prefix(limit) ?? []

                completion(Array(packs))
            }
    }

    // MARK: - Update Pack

    func updateWordPack(
        _ pack: WordPackFirebase,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let documentRef = wordPacksRef.document(pack.id)
            try documentRef.setData(from: pack, merge: true) { error in
                if let error = error {
                    log(.error, "Error updating word pack: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    log(.info, "Word pack updated successfully: \(pack.id)")
                    completion(.success(()))
                }
            }
        } catch {
            log(.error, "Error encoding word pack: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func incrementPackDownloadCount(
        packId: String,
        completion: @escaping (Bool) -> Void
    ) {
        wordPacksRef.document(packId).updateData([
            AppConstants.Firebase.Fields.downloadCount: FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                log(.error, "Error incrementing download count: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func incrementPackPlayCount(
        packId: String,
        completion: @escaping (Bool) -> Void
    ) {
        wordPacksRef.document(packId).updateData([
            AppConstants.Firebase.Fields.playCount: FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                log(.error, "Error incrementing play count: \(error.localizedDescription)")
                completion(false)
            } else {
                completion(true)
            }
        }
    }

    func rateWordPack(
        packId: String,
        rating: Int,
        completion: @escaping (Bool) -> Void
    ) {
        guard (1...5).contains(rating) else {
            log(.error, "Invalid rating value: \(rating)")
            completion(false)
            return
        }

        fetchPackById(packId) { [weak self] pack in
            guard let self = self, let pack = pack else {
                completion(false)
                return
            }

            let updatedStats = pack.ratingStats.withNewRating(rating)

            self.wordPacksRef.document(packId).updateData([
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.averageRating)": updatedStats.averageRating,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.totalRatings)": updatedStats.totalRatings,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.fiveStar)": updatedStats.fiveStar,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.fourStar)": updatedStats.fourStar,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.threeStar)": updatedStats.threeStar,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.twoStar)": updatedStats.twoStar,
                "\(AppConstants.Firebase.Fields.ratingStats).\(AppConstants.Firebase.Fields.oneStar)": updatedStats.oneStar
            ]) { error in
                if let error = error {
                    log(.error, "Error rating pack: \(error.localizedDescription)")
                    completion(false)
                } else {
                    log(.info, "Pack rated successfully: \(packId)")
                    completion(true)
                }
            }
        }
    }

    // MARK: - Delete Pack

    func deleteWordPack(
        packId: String,
        completion: @escaping (Bool) -> Void
    ) {
        wordPacksRef.document(packId).delete { error in
            if let error = error {
                log(.error, "Error deleting word pack: \(error.localizedDescription)")
                completion(false)
            } else {
                log(.info, "Word pack deleted successfully: \(packId)")
                completion(true)
            }
        }
    }

    // MARK: - Report Pack

    func reportWordPack(
        packId: String,
        completion: @escaping (Bool) -> Void
    ) {
        wordPacksRef.document(packId).updateData([
            AppConstants.Firebase.Fields.reportedCount: FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                log(.error, "Error reporting pack: \(error.localizedDescription)")
                completion(false)
            } else {
                log(.info, "Pack reported successfully: \(packId)")
                completion(true)
            }
        }
    }
}

// MARK: - PackSortOption

enum PackSortOption: String, CaseIterable {
    case mostDownloaded = "Most Downloaded"
    case highestRated = "Highest Rated"
    case mostRecent = "Most Recent"
    case mostPlayed = "Most Played"
}
