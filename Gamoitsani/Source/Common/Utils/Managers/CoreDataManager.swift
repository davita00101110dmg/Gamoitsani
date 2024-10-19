//
//  CoreDataManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import CoreData
import UIKit

protocol CoreDataManaging {
    @discardableResult
    func saveWordsFromFirebase(_ words: [WordFirebase]) -> Int
    func fetchWordsFromCoreData(quantity: Int) -> [Word]
}

final class CoreDataManager: CoreDataManaging {
    static var shared = CoreDataManager()
    
    private init() { }
    
    var context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @discardableResult
    func saveWordsFromFirebase(_ words: [WordFirebase]) -> Int {
        var savedCount = 0
        
        context.performAndWait {
            for firebaseWord in words {
                let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "baseWord == %@", firebaseWord.baseWord)
                
                do {
                    let existingWords = try context.fetch(fetchRequest)
                    let word = existingWords.first ?? Word(context: context)
                    
                    word.baseWord = firebaseWord.baseWord
                    word.categories = firebaseWord.categories
                    word.last_updated = firebaseWord.lastUpdated
                    
                    if let existingTranslations = word.wordTranslations as? Set<Translation> {
                        for translation in existingTranslations {
                            word.removeFromWordTranslations(translation)
                            context.delete(translation)
                        }
                    }
                    
                    for (langCode, translationData) in firebaseWord.translations {
                        let translation = Translation(context: context)
                        translation.languageCode = langCode
                        translation.word = translationData.word
                        translation.difficulty = Int16(translationData.difficulty)
                        word.addToWordTranslations(translation)
                    }
                    
                    savedCount += 1
                } catch {
                    dump("Error saving word: \(error)")
                }
            }
            
            do {
                try context.save()
            } catch {
                dump("Error saving context: \(error)")
            }
        }
        
        return savedCount
    }
    
    func fetchWordsFromCoreData(quantity: Int = 1500) -> [Word] {
        var fetchedWords: [Word] = []
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
            fetchRequest.fetchLimit = quantity
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: AppConstants.Firebase.Fields.lastUpdated, ascending: false)]
            
            do {
                fetchedWords = try context.fetch(fetchRequest)
                dump("Fetched \(fetchedWords.count) words from Core Data")
            } catch {
                dump("Failed to fetch words from Core Data: \(error)")
            }
        }
        
        return fetchedWords
    }
}
