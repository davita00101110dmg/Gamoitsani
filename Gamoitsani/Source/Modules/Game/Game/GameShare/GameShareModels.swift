//
//  GameShareModels.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 27/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum GameShareModels {
    enum Socials {
        case instagram, facebook
        
        var urlScheme: String {
            switch self {
            case .instagram:
                return "instagram-stories://share"
            case .facebook:
                return "facebook-stories://share"
            }
        }
        
        var pasteboardItemKey: String {
            switch self {
            case .instagram:
                return "com.instagram.sharedSticker.stickerImage"
            case .facebook:
                return "com.facebook.sharedSticker.stickerImage"
            }
        }
        
        var backgroundTopColor: String {
            switch self {
            case .instagram:
                return "com.instagram.sharedSticker.backgroundTopColor"
            case .facebook:
                return "com.facebook.sharedSticker.backgroundTopColor"
            }
        }
        
        var backgroundBottomColor: String {
            switch self {
            case .instagram:
                return "com.instagram.sharedSticker.backgroundBottomColor"
            case .facebook:
                return "com.facebook.sharedSticker.backgroundBottomColor"
            }
        }
    }
}
