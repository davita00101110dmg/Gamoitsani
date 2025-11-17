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
    func saveWordsFromFirebase(_ words: [WordFirebase]) async throws -> Int
    func fetchWordsFromCoreData(quantity: Int) async -> [Word]
}

final class CoreDataManager: CoreDataManaging {
    enum StorageError: Error {
        case insufficientStorage
        case saveFailed(Error)
    }

    static var shared = CoreDataManager()
    private let persistentContainer: NSPersistentContainer
    private let backgroundContext: NSManagedObjectContext

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private init() {
        persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    @discardableResult
    func saveWordsFromFirebase(_ words: [WordFirebase]) async throws -> Int {
        guard checkAvailableStorage() else {
            throw StorageError.insufficientStorage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            backgroundContext.perform {
                var savedCount = 0
                
                for firebaseWord in words {
                    let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "baseWord == %@", firebaseWord.baseWord)
                    
                    do {
                        let existingWords = try self.backgroundContext.fetch(fetchRequest)
                        let word = existingWords.first ?? Word(context: self.backgroundContext)
                        
                        word.baseWord = firebaseWord.baseWord
                        word.categories = firebaseWord.categories
                        word.last_updated = firebaseWord.lastUpdated
                        
                        if let existingTranslations = word.wordTranslations as? Set<Translation> {
                            for translation in existingTranslations {
                                word.removeFromWordTranslations(translation)
                                self.backgroundContext.delete(translation)
                            }
                        }
                        
                        for (langCode, translationData) in firebaseWord.translations {
                            let translation = Translation(context: self.backgroundContext)
                            translation.languageCode = langCode
                            translation.word = translationData.word
                            translation.difficulty = Int16(translationData.difficulty)
                            word.addToWordTranslations(translation)
                        }
                        
                        savedCount += 1
                    } catch {
                        log(.error, "Error saving word: \(error)")
                    }
                }
                
                do {
                    try self.backgroundContext.save()
                    continuation.resume(returning: savedCount)
                } catch {
                    continuation.resume(throwing: StorageError.saveFailed(error))
                }
            }
        }
    }
    
    func fetchWordsFromCoreData(quantity: Int = 1500) async -> [Word] {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            backgroundContext.perform {
                let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
                fetchRequest.fetchLimit = quantity
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: AppConstants.Firebase.Fields.lastUpdated, ascending: false)]
                
                do {
                    var fetchedWords = try self.backgroundContext.fetch(fetchRequest)
                    fetchedWords.shuffle()
                    continuation.resume(returning: fetchedWords)
                } catch {
                    log(.error, "Failed to fetch words from Core Data: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
    
    func checkAvailableStorage() -> Bool {
        let fileURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url
        let fileManager = FileManager.default
        
        guard let path = fileURL?.deletingLastPathComponent().path,
              let attrs = try? fileManager.attributesOfFileSystem(forPath: path),
              let freeSize = attrs[FileAttributeKey.systemFreeSize] as? NSNumber,
              let totalSize = attrs[FileAttributeKey.systemSize] as? NSNumber else {
            return true
        }
        
        let freeRatio = Double(freeSize.int64Value) / Double(totalSize.int64Value)
        return freeRatio > 0.001
    }
}
