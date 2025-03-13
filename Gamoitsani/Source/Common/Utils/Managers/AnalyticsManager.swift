//
//  AnalyticsManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 3/13/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseAnalytics

/// AnalyticsManager is a singleton class responsible for logging events to Firebase Analytics.
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Game Events
    
    /// Logs when a game session starts
    /// - Parameters:
    ///   - gameMode: The mode of the game (classic, arcade, etc.)
    ///   - teamsCount: Number of teams in the game
    ///   - roundsCount: Number of rounds configured for the game
    func logGameStart(gameMode: String, teamsCount: Int, roundsCount: Int) {
        Analytics.logEvent("game_started", parameters: [
            "game_mode": gameMode,
            "teams_count": teamsCount,
            "rounds_count": roundsCount
        ])
        log(.info, "Analytics: Game started - mode: \(gameMode), teams: \(teamsCount), rounds: \(roundsCount)")
    }
    
    /// Logs when a round is completed
    /// - Parameters:
    ///   - roundNumber: Current round number
    ///   - teamName: Name of the team that played
    ///   - score: Score achieved in this round
    ///   - wordsGuessed: Number of words guessed
    ///   - wordsSkipped: Number of words skipped
    func logRoundCompleted(roundNumber: Int, teamName: String, score: Int, wordsGuessed: Int, wordsSkipped: Int) {
        Analytics.logEvent("round_completed", parameters: [
            "round_number": roundNumber,
            "team_name": teamName,
            "score": score,
            "words_guessed": wordsGuessed,
            "words_skipped": wordsSkipped
        ])
        log(.info, "Analytics: Round completed - round: \(roundNumber), team: \(teamName), score: \(score)")
    }
    
    /// Logs when a game is completed
    /// - Parameters:
    ///   - gameMode: The mode of the game
    ///   - duration: Duration of the game in seconds
    ///   - winnerTeam: Name of the winning team (if any)
    ///   - isTie: Whether the game ended in a tie
    ///   - roundsPlayed: Total number of rounds played including extra rounds
    func logGameCompleted(gameMode: String, duration: TimeInterval, winnerTeam: String?, isTie: Bool, roundsPlayed: Int) {
        var parameters: [String: Any] = [
            "game_mode": gameMode,
            "duration": Int(duration),
            "is_tie": isTie,
            "rounds_played": roundsPlayed
        ]
        
        if let winnerTeam = winnerTeam {
            parameters["winner_team"] = winnerTeam
        }
        
        Analytics.logEvent("game_completed", parameters: parameters)
        log(.info, "Analytics: Game completed - mode: \(gameMode), winner: \(winnerTeam ?? "tie"), rounds: \(roundsPlayed)")
    }
    
    /// Logs when a word is guessed correctly
    /// - Parameters:
    ///   - difficulty: Difficulty level of the word (1-5)
    ///   - language: Language of the word
    func logWordGuessed(difficulty: Int, language: String) {
        Analytics.logEvent("word_guessed", parameters: [
            "difficulty": difficulty,
            "language": language
        ])
    }
    
    /// Logs when a word is skipped
    /// - Parameters:
    ///   - difficulty: Difficulty level of the word (1-5)
    ///   - language: Language of the word
    func logWordSkipped(difficulty: Int, language: String) {
        Analytics.logEvent("word_skipped", parameters: [
            "difficulty": difficulty,
            "language": language
        ])
    }
    
    // MARK: - Feature Usage Events
    
    /// Logs when a user adds a word suggestion
    /// - Parameter language: Language of the suggested word
    func logWordSuggested(language: String) {
        Analytics.logEvent("word_suggested", parameters: [
            "language": language
        ])
        log(.info, "Analytics: Word suggested in \(language)")
    }
    
    /// Logs when a user changes language
    /// - Parameter language: The new language selected
    func logLanguageChanged(language: String) {
        Analytics.logEvent("language_changed", parameters: [
            "language": language
        ])
        log(.info, "Analytics: Language changed to \(language)")
    }
    
    /// Logs when a user shares game results
    func logGameResultsShared() {
        Analytics.logEvent("game_results_shared", parameters: nil)
        log(.info, "Analytics: Game results shared")
    }
    
    /// Logs when a user views the rules screen
    func logRulesViewed() {
        Analytics.logEvent("rules_viewed", parameters: nil)
        log(.info, "Analytics: Rules viewed")
    }
    
    // MARK: - App Lifecycle Events
    
    /// Logs when the app is opened
    /// - Parameter source: Source of the app open (notification, deep link, normal)
    func logAppOpen(source: String = "normal") {
        Analytics.logEvent("app_opened", parameters: [
            "source": source
        ])
    }
    
    /// Logs when a user engages with an ad
    /// - Parameters:
    ///   - adType: Type of ad (interstitial, banner, etc.)
    ///   - placement: Where the ad was shown in the app
    ///   - action: Action taken (shown, clicked, etc.)
    func logAdEngagement(adType: String, placement: String, action: String) {
        Analytics.logEvent("ad_engagement", parameters: [
            "ad_type": adType,
            "placement": placement,
            "action": action
        ])
    }
}