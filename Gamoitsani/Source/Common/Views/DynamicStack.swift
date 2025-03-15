//
//  DynamicStack.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct DynamicStack<Content: View>: View {
    var horizontalAlignment = HorizontalAlignment.center
    var verticalAlignment = VerticalAlignment.center
    var spacing: CGFloat?
    var isPortrait: Binding<Bool>?
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        GeometryReader { proxy in
            Group {
                if proxy.size.width > proxy.size.height {
                    HStack(
                        alignment: verticalAlignment,
                        spacing: spacing,
                        content: content
                    )
                    .onAppear {
                        isPortrait?.wrappedValue = false
                    }
                } else {
                    VStack(
                        alignment: horizontalAlignment,
                        spacing: spacing,
                        content: content
                    )
                    .onAppear {
                        isPortrait?.wrappedValue = true
                    }
                }
            }
        }
    }
}
