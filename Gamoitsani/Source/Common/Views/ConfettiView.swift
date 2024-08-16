//
//  ConfettiView.swift
//  Gamoitsani
//
//  Created by Daviti Khvedelidze on 16/08/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import SwiftUI

struct ConfettiView: View {
    @State var animate = false
    @State var xSpeed = Double.random(in: 0.7...2)
    @State var zSpeed = Double.random(in: 1...2)
    @State var anchor = CGFloat.random(in: 0...1).rounded()
    
    var body: some View {
        Rectangle()
            .fill(
                [
                    Asset.color1.swiftUIColor,
                    Asset.color2.swiftUIColor,
                    Asset.color3.swiftUIColor,
                    Asset.color4.swiftUIColor,
                    Asset.color5.swiftUIColor,
                    Asset.color6.swiftUIColor,
                    Asset.color7.swiftUIColor,
                    Asset.color8.swiftUIColor,
                    Asset.color9.swiftUIColor,
                    Asset.color10.swiftUIColor,
                ].randomElement() ?? Asset.primary.swiftUIColor
            )
            .frame(width: 20, height: 20)
            .onAppear(perform: { animate = true })
            .rotation3DEffect(.degrees(animate ? 360 : 0), axis: (x: 1, y: 0, z: 0))
            .animation(Animation.linear(duration: xSpeed).repeatForever(autoreverses: false), value: animate)
            .rotation3DEffect(.degrees(animate ? 360 : 0), axis: (x: 0, y: 0, z: 1), anchor: UnitPoint(x: anchor, y: anchor))
            .animation(Animation.linear(duration: zSpeed).repeatForever(autoreverses: false), value: animate)
    }
}

struct ConfettiContainerView: View {
    var count: Int = 200
    @State var yPosition: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { _ in
                ConfettiView()
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: yPosition != 0 ? CGFloat.random(in: 0...UIScreen.main.bounds.height) : yPosition
                    )
            }
        }
        .ignoresSafeArea()
        .onAppear {
            yPosition = CGFloat.random(in: 0...UIScreen.main.bounds.height)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

struct DisplayConfettiModifier: ViewModifier {
    @Binding var isActive: Bool {
        didSet {
            if !isActive {
                opacity = 1
            }
        }
    }
    @State private var opacity = 1.0 {
        didSet {
            if opacity == 0 {
                isActive = false
            }
        }
    }
    
    private let animationTime = 3.0
    private let fadeTime = 2.0

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .sensoryFeedback(.success, trigger: isActive)
                .task {
                    await handleAnimationSequence()
                }
        } else {
            content
                .overlay(isActive ? ConfettiContainerView().opacity(opacity) : nil)
                .task {
                    await handleAnimationSequence()
                }
        }
    }

    private func handleAnimationSequence() async {
        do {
            try await Task.sleep(nanoseconds: UInt64(animationTime * 1_000_000_000))
            withAnimation(.easeOut(duration: fadeTime)) {
                opacity = 0
            }
        } catch {}
    }
}

extension View {
    func displayConfetti(isActive: Binding<Bool>) -> some View {
        self.modifier(DisplayConfettiModifier(isActive: isActive))
    }
}

struct CelebrationView: View {
    @State private var showConfetti = false

    var body: some View {
        VStack {
            Button("Celebrate") {
                showConfetti = true
            }
        }
        .displayConfetti(isActive: $showConfetti)
    }
}

#Preview {
    CelebrationView()
}
