//
//  SplashView.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniDesign

extension EnvironmentValues {
    /// True while the splash owns the screen. Entrance animations wait on it, or they run
    /// unseen behind the splash and the screen is revealed already settled.
    @Entry var isLaunching = false
}

/// The cards dealing out, immediately after launch.
///
/// Launch screens are static, so this hands off from one whose first frame matches:
/// `LaunchBackground` carries the same values as `Tokens.surface`, and
/// `scripts/verify-launch-background` fails the build if they drift.
struct SplashView: View {
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dealt = false
    @State private var swept = false

    /// The spread each card settles at.
    private let angles: [Double] = [-17, -8.5, 0, 8.5, 17]

    /// Long enough for the fan to be read as a picture, not glimpsed mid-deal.
    private var hold: Duration { .milliseconds(reduceMotion ? 200 : 1150) }

    private var sweep: Duration { .milliseconds(reduceMotion ? 160 : 480) }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Opaque throughout: nothing underneath is uncovered until the splash goes.
                Tokens.surface.color.ignoresSafeArea()

                ZStack {
                    ForEach(Array(angles.enumerated()), id: \.offset) { index, angle in
                        let offset = CGFloat(index - angles.count / 2)

                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .fill(Tokens.cardFace.color)
                            .overlay {
                                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                    .strokeBorder(Tokens.cardEdge.color, lineWidth: 1.5)
                            }
                            .frame(width: 104, height: 146)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 6)
                            .rotationEffect(.degrees(dealt ? angle : 0))
                            .offset(x: dealt ? offset * 25 : 0, y: dealt ? 0 : 18)
                            .opacity(dealt ? 1 : 0)
                            .animation(
                                reduceMotion
                                    ? Motion.reduced
                                    : Motion.card.delay(Double(index) * 0.07),
                                value: dealt
                            )
                    }
                }
                .accessibilityHidden(true)
                // Lifts as one piece. Staggering the exit read as the deal running backwards.
                .offset(y: swept && !reduceMotion ? -(geo.size.height / 2 + 160) : 0)
                .opacity(swept && reduceMotion ? 0 : 1)
                .animation(reduceMotion ? Motion.reduced : Motion.card, value: swept)
            }
        }
        // One thing at a time: deal, hold, cards out, splash gone, screen in. Overlapping
        // the last two read as two movements competing.
        .task {
            dealt = true
            try? await Task.sleep(for: hold)
            swept = true
            try? await Task.sleep(for: sweep)
            onFinish()
        }
    }
}

#Preview {
    SplashView(onFinish: {})
}
