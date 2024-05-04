//
//  NSObjectExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import Foundation

extension NSObject {
    static var stringFromClass: String { return NSStringFromClass(self) }
    static var className: String { return self.stringFromClass.components(separatedBy: ".").last! }
}
