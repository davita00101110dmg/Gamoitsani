//
//  HomeView.swift
//  Gamoitsani2
//

import SwiftUI
import GamoitsaniDesign
import GamoitsaniL10n

/// The 2.0 home screen, built to the visual identity handoff.
///
/// Icon, then the wordmark with its accent rule, then a primary action in `accent` and
/// secondary actions in `surfaceRaised`. Every colour, space, radius, font and animation
/// comes from a token; there is not a literal in this file, which is the point of the
/// design package.
struct HomeView: View {
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            Tokens.surface.color.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                HStack {
                    Spacer()
                    Button {
                        router.push(.settings)
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundStyle(Tokens.onSurfaceMuted.color)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, Spacing.md)

                Spacer()

                VStack(spacing: Spacing.lg) {
                    AppMark()
                        .frame(width: 76, height: 76)
                        .accessibilityHidden(true)

                    Wordmark()
                }

                Spacer()

                VStack(spacing: Spacing.sm) {
                    HomeButton(title: L10n.string("home.play"), style: .primary) {
                        router.push(.gameSetup)
                    }
                    HomeButton(title: L10n.string("home.rules"), style: .secondary) {
                        router.push(.rules)
                    }
                    HomeButton(title: L10n.string("home.addWord"), style: .secondary) {
                        router.push(.addWord)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xl)
            }
        }
    }
}

/// The wordmark: the name over a full-width accent rule.
///
/// The rule's width is the wordmark's width and its height is ~11% of cap height, per the
/// identity. Georgian is the primary lockup, so the localised title sets the width and the
/// rule follows it rather than being a fixed size.
private struct Wordmark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs + 3) {
            Text(L10n.string("home.title"))
                .font(Typography.display())
                .foregroundStyle(Tokens.onSurface.color)
                .tracking(-1)

            Capsule()
                .fill(Tokens.accent.color)
                .frame(height: 4)
        }
        .fixedSize()
        .accessibilityElement()
        .accessibilityLabel(L10n.string("home.title"))
        .accessibilityAddTraits(.isHeader)
    }
}

/// The icon mark, drawn rather than rasterised.
///
/// Three cards fanned at ±19° with flat fills and no gradient, matching the app icon. It
/// is vector geometry either way, so drawing it keeps it crisp at any size and lets it
/// follow the tokens in both appearances instead of shipping two PNGs.
struct AppMark: View {
    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cardW = side * Brand.markCardWidthRatio
            let cardH = side * Brand.markCardHeightRatio
            let radius = cardW * Brand.markCardRadiusRatio

            ZStack {
                RoundedRectangle(cornerRadius: side * Brand.markFieldRadiusRatio, style: .continuous)
                    .fill(Brand.markField.color)

                ZStack {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Brand.markCardBack.color)
                        .frame(width: cardW, height: cardH)
                        .rotationEffect(.degrees(-Brand.markFanAngle))

                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Brand.markCardAccent.color)
                        .frame(width: cardW, height: cardH)
                        .rotationEffect(.degrees(Brand.markFanAngle))

                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(Brand.markCardFace.color)
                        .frame(width: cardW, height: cardH)
                        .overlay {
                            Text(verbatim: "?")
                                .font(.custom(Typography.displayFamily, size: cardH * Brand.markGlyphRatio).weight(.black))
                                .foregroundStyle(Brand.markInk.color)
                        }
                        .offset(y: -side * 0.0098)
                }
            }
        }
    }
}

private struct HomeButton: View {
    enum Style { case primary, secondary }

    let title: String
    let style: Style
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typography.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
        }
        .buttonStyle(HomeButtonStyle(style: style, reduceMotion: reduceMotion))
    }
}

private struct HomeButtonStyle: ButtonStyle {
    let style: HomeButton.Style
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(style == .primary ? Tokens.onAccent.color : Tokens.onSurface.color)
            .background(style == .primary ? Tokens.accent.color : Tokens.surfaceRaised.color)
            .clipShape(RoundedRectangle(cornerRadius: Radius.control, style: .continuous))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .strokeBorder(Tokens.cardEdge.color, lineWidth: 1)
                }
            }
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1)
            .animation(Motion.control(reduceMotion: reduceMotion), value: configuration.isPressed)
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
