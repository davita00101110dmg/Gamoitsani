//
//  ChallengesManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 14/03/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseFirestore

class ChallengesManager {
    static let shared = ChallengesManager()
    
    private init() {
        loadChallenges()
    }
    
    private var usedChallengeIndexes: Set<Int> = []
    private var challenges: [Challenge] = []
    private let fetchInterval: TimeInterval = 7 * 24 * 60 * 60
    
    struct Challenge: Codable {
        let id: String
        let text: [String: String]
        
        var localizedText: String {
            let language = LanguageManager.shared.currentLanguage.rawValue
            return text[language] ?? text["en"] ?? "Do something fun while guessing words!"
        }
    }
    
    // MARK: - Challenge Loading and Persistence
    private func loadChallenges() {
        if let cachedChallenges = loadCachedChallenges() {
            challenges = cachedChallenges
            log(.info, "Loaded \(cachedChallenges.count) challenges from cache")
        }
    }
    
    private func loadCachedChallenges() -> [Challenge]? {
        guard let data = UserDefaults.cachedChallenges else {
            return nil
        }
        
        do {
            let challenges = try JSONDecoder().decode([Challenge].self, from: data)
            return challenges
        } catch {
            log(.error, "Failed to decode cached challenges: \(error)")
            return nil
        }
    }
    
    private func saveChallenges(_ challenges: [Challenge]) {
        do {
            let data = try JSONEncoder().encode(challenges)
            UserDefaults.cachedChallenges = data
        } catch {
            log(.error, "Failed to encode challenges for caching: \(error)")
        }
    }
    
    func fetchChallengesIfNeeded(completion: @escaping () -> Void) {
        let lastSyncTimestamp = UserDefaults.lastChallengeSyncDate
        let currentTimestamp = Date().timeIntervalSince1970
        let shouldFetch = currentTimestamp - lastSyncTimestamp >= fetchInterval
        
        guard shouldFetch else {
            completion()
            return
        }
        
        let db = Firestore.firestore()
        db.collection("challenges").getDocuments { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot, error == nil else {
                log(.error, "Failed to fetch challenges: \(error?.localizedDescription ?? "Unknown error")")
                completion()
                return
            }
            
            var fetchedChallenges: [Challenge] = []
            for document in snapshot.documents {
                guard let data = try? document.data(as: Challenge.self) else {
                    continue
                }
                fetchedChallenges.append(data)
            }
            
            if !fetchedChallenges.isEmpty {
                self.challenges = fetchedChallenges
                self.saveChallenges(fetchedChallenges)
                UserDefaults.lastChallengeSyncDate = currentTimestamp
                log(.info, "Fetched \(fetchedChallenges.count) challenges from Firebase")
            }
            
            completion()
        }
    }
    
    func resetUsedChallenges() {
        usedChallengeIndexes.removeAll()
    }
    
    func getRandomChallengeForTeam(at teamIndex: Int) -> String {
        if let existingChallenge = GameStory.shared.getChallengeForTeam(at: teamIndex), !existingChallenge.isEmpty {
            return existingChallenge
        }
        
        if usedChallengeIndexes.count >= challenges.count {
            usedChallengeIndexes.removeAll()
        }
        
        let availableIndexes = Set(0..<challenges.count).subtracting(usedChallengeIndexes)
        
        guard let randomIndex = availableIndexes.randomElement() else {
            return "Every time you guess a word correctly, you must high-five all of your teammates."
        }
        
        usedChallengeIndexes.insert(randomIndex)
        
        let challenge = challenges[randomIndex].localizedText
        
        GameStory.shared.setChallengeForTeam(at: teamIndex, challenge: challenge)
        
        return challenge
    }
}
