//
//  GMTappableButtonSty.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 10/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct GMTappableButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
