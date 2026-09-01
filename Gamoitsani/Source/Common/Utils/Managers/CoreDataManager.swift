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
    
    private init() {
        persistentContainer = (UIApplication.shared.delegate as! AppDelegate).persistentContainer
        backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Injects a container so tests can run against an in-memory store.
    ///
    /// Without this there is no seam at all: the designated initialiser reaches through
    /// `UIApplication.shared.delegate` for the app's on-disk container, so any test of
    /// this type would read and write the user's real word database.
    init(container: NSPersistentContainer) {
        persistentContainer = container
        backgroundContext = container.newBackgroundContext()
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
                        word.isGeorgianOrigin = firebaseWord.isGeorgianOrigin ?? false
                        word.formalityLevel = Int16(firebaseWord.formalityLevel ?? 2)
                        word.isProperNoun = firebaseWord.isProperNoun ?? false
                        word.wordType = firebaseWord.wordType
                        word.isAbstract = firebaseWord.isAbstract ?? false
                        word.ageAppropriateness = firebaseWord.ageAppropriateness ?? "all_ages"
                        word.relatedWords = firebaseWord.relatedWords ?? []
                        
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
    
    /// Absolute floor of free space required before importing words.
    ///
    /// Deliberately an absolute number rather than a fraction of the volume. The previous
    /// check required `free / total > 0.001`, which means something different on every
    /// device — 512 MB on a 512 GB disk, 64 MB on a 64 GB phone — and on a nearly-full
    /// disk it sits close enough to the threshold to flip between consecutive runs. That
    /// is exactly how it behaved on the dev machine: 0.001094 against a 0.001 threshold,
    /// so word imports failed intermittently with `insufficientStorage`.
    private static let minimumFreeBytes = 50_000_000

    func checkAvailableStorage() -> Bool {
        guard let store = persistentContainer.persistentStoreCoordinator.persistentStores.first else {
            return true
        }

        // An in-memory store has no disk footprint, so there is nothing to check. Its URL
        // is /dev/null, and devfs reports a capacity of 0 rather than nil — which would
        // otherwise read as "disk full" and reject every save.
        guard store.type != NSInMemoryStoreType, let storeURL = store.url else {
            return true
        }

        // volumeAvailableCapacityForImportantUsage, not systemFreeSize: it accounts for
        // purgeable space the system will reclaim on demand, so it reflects what is
        // actually obtainable rather than what is free right now.
        guard let capacity = try? storeURL
            .resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            .volumeAvailableCapacityForImportantUsage else {
            // Unavailable on this volume — an in-memory store under test, for instance.
            // Fail open: refusing to save is worse than trying and handling the error.
            return true
        }

        return capacity > Self.minimumFreeBytes
    }
}
