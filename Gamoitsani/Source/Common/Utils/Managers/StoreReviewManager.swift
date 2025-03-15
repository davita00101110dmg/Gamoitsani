//
//  StoreReviewManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import StoreKit

struct StoreReviewManager {
    static func incrementAppOpenedCount() {
        AppSettings.appOpenCount += 1
    }
    
    static func checkAndAskForReview() {
        let appOpenCount = AppSettings.appOpenCount
        let finishedGamesCountInSession = GameStory.shared.finishedGamesCountInSession
        
        if appOpenCount >= 20 && finishedGamesCountInSession >= 3 {
            StoreReviewManager().requestReview()
        } else {
            log(.info, "App run count is: \(appOpenCount), Finished Games Count In This Session is: \(finishedGamesCountInSession)")
        }
    }
    
    private func requestReview() {
        if #available(iOS 14.0, *) {
            if let scene = UIApplication.shared.currentScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }
}
