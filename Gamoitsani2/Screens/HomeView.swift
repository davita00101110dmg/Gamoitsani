//
//  HomeView.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The 2.0 home screen.
///
/// Card-first, per the design direction: the app icon is already a fanned stack of word
/// cards, and that metaphor drives the layout instead of v1's full-bleed gradient behind
/// stacked rectangles. Every colour, space and font comes from a token — there are no
/// literals below, which is the point of the design package.
struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Tokens.surface.color.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer(minLength: Spacing.lg)

                FannedCards()
                    .frame(height: 190)
                    .accessibilityHidden(true)

                VStack(spacing: Spacing.xs) {
                    Text(L10n.string("home.title"))
                        .font(Typography.display)
                        .foregroundStyle(Tokens.onSurface.color)

                    Text(L10n.string("home.subtitle"))
                        .font(Typography.body)
                        .foregroundStyle(Tokens.onSurfaceMuted.color)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }

                Spacer()

                VStack(spacing: Spacing.sm) {
                    Button {
                        router.push(.gameSetup)
                    } label: {
                        Text(L10n.string("home.play"))
                            .font(Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    Button {
                        router.push(.rules)
                    } label: {
                        Text("Rules")
                            .font(Typography.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

/// The icon's fanned stack, as layout.
private struct FannedCards: View {
    private let angles: [Double] = [-16, -8, 0, 8, 16]

    var body: some View {
        ZStack {
            ForEach(Array(angles.enumerated()), id: \.offset) { index, angle in
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Tokens.cardFace.color)
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                            .strokeBorder(Tokens.cardEdge.color, lineWidth: 1.5)
                    }
                    .frame(width: 108, height: 152)
                    .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                    .rotationEffect(.degrees(angle))
                    .offset(x: CGFloat(index - angles.count / 2) * 26)
            }
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Tokens.onAccent.color)
            .background(Tokens.accent.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Tokens.onSurface.color)
            .background(Tokens.surfaceRaised.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(Tokens.cardEdge.color, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview("Home — dark") {
    HomeView()
        .environment(Router())
        .preferredColorScheme(.dark)
}

#Preview("Home — light") {
    HomeView()
        .environment(Router())
        .preferredColorScheme(.light)
}
