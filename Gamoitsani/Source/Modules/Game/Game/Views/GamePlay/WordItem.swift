//
//  WordItem.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 25/02/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import UIKit

struct WordItem: Identifiable, Equatable {
    let id = UUID()
    let word: Word
    let translation: String
    var isGuessed: Bool = false
    let isSuperWord: Bool
    
    var points: Int {
        if isGuessed {
            return isSuperWord ? Constants.superWordPoints : Constants.regularPoints
        } else {
            return isSuperWord ? Constants.skippedSuperWordPoints : Constants.skippedRegularPoints
        }
    }
    
    init(word: Word, translation: String, isGuessed: Bool = false, isSuperWord: Bool = false) {
        self.word = word
        self.translation = translation
        self.isGuessed = isGuessed
        self.isSuperWord = isSuperWord
    }
    
    enum Constants {
        static let superWordPoints = 3
        static let regularPoints = 1
        static let skippedSuperWordPoints = -3
        static let skippedRegularPoints = -1
    }
}
