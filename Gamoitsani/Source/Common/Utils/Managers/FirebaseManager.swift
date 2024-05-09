//
//  FirebaseManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 09/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit
import Firebase

final class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let database = Database.database(url: AppConstants.Database.url).reference()

    private init() { }
    
    func fetchWords(quantity: UInt = 1000, completion: @escaping ([String]) -> Void) {
        database.child(AppConstants.Database.tableName)
            .queryLimited(toFirst: quantity)
            .observe(.value) { snapshot in
            var words: [String] = []
            
            for child in snapshot.children {
                if let wordValue = child as? DataSnapshot,
                   let word = wordValue.value as? String {
                    words.append(word)
                }
            }
                
            words.shuffle()
            
            completion(words)
        }
    }
    
    func addWord(_ word: String) {
        let wordRef = database.child(AppConstants.Database.tableName).childByAutoId()
        wordRef.setValue(word)
    }
}
