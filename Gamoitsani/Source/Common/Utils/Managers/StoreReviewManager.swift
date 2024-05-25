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
        guard var appOpenCount = UserDefaults.standard.value(forKey: UserDefaults.Keys.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: UserDefaults.Keys.APP_OPENED_COUNT)
            return
        }
        appOpenCount += 1
        UserDefaults.standard.set(appOpenCount, forKey: UserDefaults.Keys.APP_OPENED_COUNT)
    }
    
    static func checkAndAskForReview() {
        guard let appOpenCount = UserDefaults.standard.value(forKey: UserDefaults.Keys.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: UserDefaults.Keys.APP_OPENED_COUNT)
            return
        }
        
        let finishedGamesCountInSession = GameStory.shared.finishedGamesCountInSession
        
        if appOpenCount >= 20 && finishedGamesCountInSession >= 3 {
            StoreReviewManager().requestReview()
        } else {
            dump("App run count is: \(appOpenCount), Finished Games Count In This Session is: \(finishedGamesCountInSession)")
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
