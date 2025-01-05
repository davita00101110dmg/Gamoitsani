//
//  GameShareViewModel.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 27/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

final class GameShareViewModel {
    
    func shareStickerImage(on platform: GameShareModels.Socials, with image: UIImage) {
        let appID = AppConstants.Meta.appId
        
        let urlString: String
        
        switch platform {
        case .instagram:
            urlString = "\(platform.urlScheme)?source_application=\(appID)"
        case .facebook:
            urlString = platform.urlScheme
        }
        
        guard let urlScheme = URL(string: urlString),
              UIApplication.shared.canOpenURL(urlScheme) else {
            log(.error, "Error: Invalid URL scheme")
            return
        }
        
        var pasteboardItems: [String: Any] = [:]
        
        pasteboardItems[platform.pasteboardItemKey] = image
        pasteboardItems[platform.backgroundTopColor] = ViewModelConstants.backgroundTopColor
        pasteboardItems[platform.backgroundBottomColor] = ViewModelConstants.backgroundBottomColor
        
        if platform == .facebook {
            pasteboardItems[ViewModelConstants.PasteboardKeys.appId] = appID
        }

        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]
        
        UIPasteboard.general.setItems([pasteboardItems], options: pasteboardOptions)
        UIApplication.shared.open(urlScheme)
    }
}

extension GameShareViewModel {
    enum ViewModelConstants {
        enum PasteboardKeys {
            static let appId = "com.facebook.sharedSticker.appID"
        }
        
        static let backgroundTopColor = "#4D2E8D"
        static let backgroundBottomColor = "#001242"
    }
}
