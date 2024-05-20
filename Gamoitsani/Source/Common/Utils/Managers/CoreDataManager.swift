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

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var context: NSManagedObjectContext {
        return appDelegate.persistentContainer.viewContext
    }
    
    func saveWordsFromFirebase(_ words: [(wordKa: String, wordEn: String, categories: [String]?, definitions: [String]?)]) {
        let existingGeorgianWords = Set(fetchWordsFromCoreData().map { $0.wordKa })
        
        guard existingGeorgianWords.count < AppConstants.maxWordsToSaveInCoreData else {
            dump("Max limit of entries reached. Not saving new words.")
            return
        }
        
        for fetchedWord in words {
            if existingGeorgianWords.contains(fetchedWord.wordKa) { continue }
            let newWord = Word(context: context)
            newWord.wordKa = fetchedWord.wordKa
            newWord.wordEn = fetchedWord.wordEn
            newWord.categories = fetchedWord.categories
            newWord.definitions = fetchedWord.definitions
        }
        
        appDelegate.saveContext()
    }
    
    func fetchWordsFromCoreData(quantity: Int = 1500) -> [Word] {
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        fetchRequest.fetchLimit = quantity
        
        do {
            var words = try context.fetch(fetchRequest)
            words.shuffle()
            return words
        } catch {
            dump("Failed to fetch words from Core Data: \(error)")
            return []
        }
    }
}
