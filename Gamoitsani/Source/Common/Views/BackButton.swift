//
//  BackButton.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 17/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct BackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "flag.checkered.2.crossed")
                .resizable()
                .frame(minWidth: 40, minHeight: 25)
        }
    }
}
