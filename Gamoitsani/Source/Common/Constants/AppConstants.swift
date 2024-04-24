//
//  AppConstants.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 24/04/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

enum AppConstants {
    enum Language {
        case english
        case georgian
        
        var identifier: String {
            switch self {
            case .english: "en"
            case .georgian: "ka"
            }
        }
    }
    
    enum Resources {
        enum Fonts {
            static let mainFontBold = "BPGNinoMtavruli-Bold"
        }
    }
}
