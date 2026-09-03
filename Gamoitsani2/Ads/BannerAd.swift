//
//  BannerAd.swift
//  Gamoitsani2
//
import GoogleMobileAds
import SwiftUI
import GamoitsaniAds
import GamoitsaniDesign

/// The banner, as a footer bar.
///
/// Only ever placed on the setup screen. It never appears during a round: the word and the
/// clock are the screen, and anything competing for attention there is a bug.
struct BannerAd: View {
    @Environment(\.adService) private var ads

    /// The bar's real width, measured. This sits inside a safe-area inset, so it is not
    /// the screen's width.
    @State private var width: CGFloat = 0

    /// Sized to the card, capped at 60pt.
    ///
    /// Not a stock size. `AdSizeBanner` is a fixed 320pt, which leaves a gap either side
    /// of a white creative — a slab floating in the card. `anchoredAdaptiveBanner` fits
    /// the width but returns 100pt tall. The inline form takes a maximum, so the creative
    /// fills the card exactly and the card stays short.
    private var adSize: AdSize {
        width > 0 ? inlineAdaptiveBanner(width: width, maxHeight: 60) : AdSizeBanner
    }

    var body: some View {
        if ads.isBannerAllowed, !AdUnits.banner.isEmpty {
            VStack(spacing: 0) {
                // Full width, unlike the card below it. This is the line between what
                // scrolls and what does not — content passing under the footer is cut by
                // it instead of just disappearing.
                Divider().overlay(Tokens.cardEdge.color)

                // A panel, with the same radius, border and margins as Round, Mode and
                // Extras. Edge to edge it read as something bolted to the app; inset it
                // reads as part of the screen.
                BannerRepresentable(adSize: adSize)
                    // Exactly the ad's own size. Without this the representable is stretched
                // to the container and the creative is drawn distorted.
                    .frame(width: adSize.size.width, height: adSize.size.height)
                    // A creative larger than the slot is not hypothetical: Google's own
                    // test unit returns 468x60, 320x100 and 728x90 at random for a
                    // 320x50 request, and mediation partners are no more disciplined.
                    .clipped()
                    .frame(maxWidth: .infinity)
                    .background(Tokens.surfaceRaised.color)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.panel, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.panel, style: .continuous)
                            .strokeBorder(Tokens.cardEdge.color.opacity(0.6), lineWidth: 1)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.top, Spacing.sm)
                    .padding(.bottom, Spacing.xs)
            }
            .background(Tokens.surface.color)
            .onGeometryChange(for: CGFloat.self) { $0.size.width - Spacing.md * 2 } action: {
                width = max(0, $0)
            }
            .accessibilityHidden(true)
        }
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: adSize)
        view.adUnitID = AdUnits.banner
        view.rootViewController = AdMobAds.rootViewController
        view.load(Request())
        return view
    }

    func updateUIView(_ view: BannerView, context: Context) {
        guard view.adSize.size != adSize.size else { return }
        // Rotation changes the size, and an ad loaded for the old one does not rescale —
        // it has to be requested again.
        view.adSize = adSize
        view.load(Request())
    }

    /// Lets SwiftUI lay the banner out at its real size rather than proposing one.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        uiView.adSize.size
    }
}
