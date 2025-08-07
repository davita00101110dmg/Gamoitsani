//
//  FirebaseAuthHelper.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import FirebaseAuth

final class FirebaseAuthHelper {
    static let shared = FirebaseAuthHelper()
    
    private init() {}
    
    func ensureAnonymousAuth(completion: @escaping (Bool) -> Void) {
        if Auth.auth().currentUser != nil {
            completion(true)
            return
        }
        
        Auth.auth().signInAnonymously { result, error in
            if let error = error {
                log(.error, "Anonymous auth failed: \(error.localizedDescription)")
                completion(false)
            } else {
                log(.info, "Anonymous auth successful")
                completion(true)
            }
        }
    }
}
