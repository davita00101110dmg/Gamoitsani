//
//  GMTableViewButton.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GMTableViewButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title) {
            action()
        }
        .buttonStyle(GMTappableButtonStyle())
        .listRowBackground(Color(.secondary))
    }
}


#Preview {
    GMTableViewButton(title: "Button", action: {
        
    })
}
