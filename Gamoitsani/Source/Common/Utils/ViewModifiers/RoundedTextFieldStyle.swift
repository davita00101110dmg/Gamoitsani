//
//  RoundedTextFieldStyle.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 21/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical)
            .padding(.horizontal, 24)
            .background(
                Asset.gmSecondary.swiftUIColor
            )
            .clipShape(Capsule(style: .continuous))
    }
}
