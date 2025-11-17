//
//  WordPackExtensions.swift
//  Gamoitsani
//
//  Created by Claude Code on 17/11/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import CoreData

extension WordPackFirebase {

    /// Converts pack words to Core Data Word objects for game use
    func toGameWords(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) -> [Word] {
        return words.compactMap { packWord in
            packWord.toWord(context: context)
        }
    }
}

extension PackWord {

    /// Converts a PackWord to a Core Data Word object
    func toWord(context: NSManagedObjectContext) -> Word? {
        let word = Word(context: context)
        word.baseWord = baseWord
        word.last_updated = Date()
        word.categories = [] // Pack words don't have categories

        // Convert translations
        for (langCode, translationData) in translations {
            let translation = Translation(context: context)
            translation.word = translationData.word
            translation.languageCode = langCode
            translation.difficulty = 3 // Default difficulty
            translation.originalWord = word
            word.addToWordTranslations(translation)
        }

        return word
    }
}
