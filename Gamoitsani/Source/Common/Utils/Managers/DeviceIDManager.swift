//
//  DeviceIDManager.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 07/08/2025.
//  Copyright © 2025 Daviti Khvedelidze. All rights reserved.
//

import Foundation
import UIKit

final class DeviceIDManager {
    static let shared = DeviceIDManager()
    
    private let deviceIDKey = "DEVICE_REVIEW_ID"
    
    private init() {}
    
    var deviceID: String {
        if let existingID = UserDefaults.standard.string(forKey: deviceIDKey) {
            return existingID
        }
        
        let newID = generateDeviceID()
        UserDefaults.standard.set(newID, forKey: deviceIDKey)
        return newID
    }
    
    private func generateDeviceID() -> String {
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString {
            return "vendor_\(vendorID)"
        }
        
        return "random_\(UUID().uuidString)"
    }
}
