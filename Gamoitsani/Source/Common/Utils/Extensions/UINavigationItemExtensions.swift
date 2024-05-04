//
//  UINavigationItemExtensions.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 04/05/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import UIKit

extension UINavigationItem {
   func enableMultilineTitle() {
      setValue(true, forKey: "__largeTitleTwoLineMode")
   }
}
