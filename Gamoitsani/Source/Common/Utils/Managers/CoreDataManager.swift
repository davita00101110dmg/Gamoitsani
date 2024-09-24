//
//  CoreDataManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 20/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import CoreData
import UIKit

final class CoreDataManager {
    static let shared = CoreDataManager()

    private init() { }
    
    var context: NSManagedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    func saveWordsFromFirebase(_ words: [WordFirebase]) -> Int {
        let context = self.context
        var savedCount = 0
        
        context.performAndWait {
            do {
                // First, count existing words
                let countFetchRequest = NSFetchRequest<NSNumber>(entityName: "Word")
                countFetchRequest.resultType = .countResultType
                let existingCount = try context.fetch(countFetchRequest).first?.intValue ?? 0
                
                // If we already have more words than the limit, delete the excess
                if existingCount > AppConstants.maxWordsToSaveInCoreData {
                    let excessCount = existingCount - AppConstants.maxWordsToSaveInCoreData
                    let oldestWordsFetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                    oldestWordsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "last_updated", ascending: true)]
                    oldestWordsFetchRequest.fetchLimit = excessCount
                    
                    let oldestWords = try context.fetch(oldestWordsFetchRequest)
                    for word in oldestWords {
                        context.delete(word)
                    }
                }
                
                // Determine how many new words we can add
                let spaceForNewWords = AppConstants.maxWordsToSaveInCoreData - existingCount
                let wordsToProcess = Array(words.suffix(max(0, min(spaceForNewWords, words.count))))
                
                for firebaseWord in wordsToProcess {
                    let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "baseWord == %@", firebaseWord.baseWord)
                    
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
                        let translationEntity = Translation(context: context)
                        translationEntity.languageCode = langCode
                        translationEntity.word = translationData.word
                        translationEntity.difficulty = Int16(translationData.difficulty)
                        word.addToWordTranslations(translationEntity)
                    }
                    
                    savedCount += 1
                }
                
                // Save the context
                if context.hasChanges {
                    try context.save()
                }
                
            } catch {
                print("Error processing words: \(error)")
            }
        }
        
        return savedCount
    }
    
    func fetchWordsFromCoreData(quantity: Int = 1500) -> [Word] {
        var fetchedWords: [Word] = []
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
            fetchRequest.fetchLimit = quantity
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "last_updated", ascending: false)]
            
            do {
                fetchedWords = try context.fetch(fetchRequest)
                print("Fetched \(fetchedWords.count) words from Core Data")
            } catch {
                print("Failed to fetch words from Core Data: \(error)")
            }
        }
        
        return fetchedWords
    }
}
