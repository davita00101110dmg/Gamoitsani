//
//  CustomSegmentedPickerStyle.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 26/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct CustomSegmentedPickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                let font = F.Mersad.bold.font(size: 14)
                UISegmentedControl.appearance().selectedSegmentTintColor = Asset.gmPrimary.color.withAlphaComponent(0.2)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor.white,
                    .font: font
                ], for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes([
                    .foregroundColor: UIColor.white,
                    .font: font
                ], for: .normal)
            }
    }
}
