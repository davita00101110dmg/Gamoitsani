//
//  RecordingOverlay.swift
//  Gamoitsani
//
import AVFoundation
import GamoitsaniCapture
import GamoitsaniDesign
import QuartzCore
import UIKit

/// Builds the layer tree burned into a clip at export.
///
/// Deliberately a pure function of the timeline and the frame size: nothing here touches
/// the camera, the game or the file. That is what makes the overlay redesignable without
/// re-recording anything — the video on disk never contains it.
enum RecordingOverlay {

    /// A word card, and a tick or cross when it is answered. Nothing persists between
    /// words: the faces are the subject and every permanent element competes with them.
    static func layer(for timeline: RecordingTimeline, size: CGSize) -> CALayer {
        let overlay = CALayer()
        overlay.frame = CGRect(origin: .zero, size: size)
        // Core Animation's video coordinate space has its origin at the bottom left.
        // Flipping it once here means every position below reads like the rest of the app.
        overlay.isGeometryFlipped = true

        // Every animation spans the whole clip. See `visibility`.
        let clip = max(timeline.duration ?? 0, timeline.entries.map(\.start).max() ?? 0) + 0.5

        for entry in timeline.entries {
            overlay.addSublayer(card(for: entry, size: size, clip: clip))
            if let flash = flash(for: entry, size: size, clip: clip) {
                overlay.addSublayer(flash)
            }
        }
        return overlay
    }

    /// The overlay for a highlight reel.
    ///
    /// Each slice was cut from a different point in a different turn, so a word is drawn at
    /// the moment its slice plays rather than at the time it happened. `clipLength` is the
    /// whole reel, because every animation spans it — see `visibility`.
    static func reelLayer(
        placed: [(highlight: Highlight, start: TimeInterval)],
        size: CGSize,
        clipLength: TimeInterval
    ) -> CALayer {
        let overlay = CALayer()
        overlay.frame = CGRect(origin: .zero, size: size)
        overlay.isGeometryFlipped = true

        for (highlight, start) in placed {
            // One card for the slice, naming what was being guessed. A streak carries
            // several words and they are shown together — splitting them across the few
            // seconds they occupy would flicker.
            let text = highlight.words.joined(separator: " · ")
            guard !text.isEmpty else { continue }

            let card = card(
                text: text,
                size: size,
                from: start,
                to: start + highlight.duration,
                clip: clipLength
            )
            overlay.addSublayer(card)
        }
        return overlay
    }

    /// The score card, held over the last seconds of a reel.
    ///
    /// Full frame and opaque. The footage underneath is only there because a composition
    /// has to have media to have duration — none of it should be visible.
    static func endCardLayer(
        _ image: UIImage,
        size: CGSize,
        start: TimeInterval,
        clipLength: TimeInterval
    ) -> CALayer {
        let holder = CALayer()
        holder.frame = CGRect(origin: .zero, size: size)
        holder.isGeometryFlipped = true

        let card = CALayer()
        card.frame = holder.frame
        card.contents = fullFrameCard(image, size: size)?.cgImage
        card.opacity = 0
        card.add(visibility(from: start, to: clipLength, clip: clipLength), forKey: "visibility")

        holder.addSublayer(card)
        return holder
    }

    /// The share card centred on the app's own surface, filling the video's frame.
    private static func fullFrameCard(_ image: UIImage, size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            uiColor(Tokens.surface).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Inset, so the card reads as a card rather than as the whole screen.
            let available = CGSize(width: size.width * 0.86, height: size.height * 0.86)
            let scale = min(available.width / image.size.width, available.height / image.size.height)
            let fitted = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            image.draw(in: CGRect(
                x: (size.width - fitted.width) / 2,
                y: (size.height - fitted.height) / 2,
                width: fitted.width,
                height: fitted.height
            ))
        }
    }

    // MARK: - Word card

    private static func card(for entry: RecordingEntry, size: CGSize, clip: TimeInterval) -> CALayer {
        card(
            text: entry.word,
            size: size,
            from: entry.start,
            to: cardEnd(of: entry),
            clip: clip
        )
    }

    private static func card(
        text word: String,
        size: CGSize,
        from start: TimeInterval,
        to end: TimeInterval,
        clip: TimeInterval
    ) -> CALayer {
        let scale = size.width / 1080

        let card = CALayer()
        let width = size.width * 0.82
        let height = 150 * scale
        card.frame = CGRect(
            x: (size.width - width) / 2,
            y: size.height * 0.07,
            width: width,
            height: height
        )
        card.backgroundColor = cgColor(Tokens.cardFace)
        card.cornerRadius = 28 * scale
        card.cornerCurve = .continuous
        card.borderWidth = 2 * scale
        card.borderColor = cgColor(Tokens.cardEdge)
        card.shadowColor = UIColor.black.cgColor
        card.shadowOpacity = 0.35
        card.shadowRadius = 18 * scale
        card.shadowOffset = CGSize(width: 0, height: 6 * scale)

        // The word is drawn into an image rather than given to a `CATextLayer`.
        //
        // `CATextLayer` does not render at all inside
        // `AVVideoCompositionCoreAnimationTool` — the card, its border and its shadow all
        // composite correctly and the text is simply absent, with no error anywhere. That
        // was verified by exporting one clip carrying three variants of this layer: plain
        // `CATextLayer`, `CATextLayer` with an explicit `CTFont`, and this. Only this one
        // appears.
        let inset = CGRect(
            x: 24 * scale,
            y: (height - 78 * scale) / 2,
            width: width - 48 * scale,
            height: 78 * scale
        )
        let label = CALayer()
        label.frame = inset
        label.contents = wordImage(word, size: inset.size, pointSize: 64 * scale)?.cgImage
        label.contentsGravity = .resizeAspect
        card.addSublayer(label)

        card.opacity = 0
        card.add(visibility(from: start, to: end, clip: clip), forKey: "visibility")
        return card
    }

    /// The word, drawn once at export resolution.
    ///
    /// Shrinks to fit rather than truncating: a long Georgian compound is still the whole
    /// joke, and a clipped one is worse than a small one.
    private static func wordImage(_ word: String, size: CGSize, pointSize: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            var attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: uiColor(Tokens.onSurface)
            ]

            var point = pointSize
            var bounds = CGSize.zero
            // Six steps is enough to get from the design size down to something that fits
            // the longest word in the deck.
            for _ in 0..<6 {
                attributes[.font] = displayFont(point)
                bounds = (word as NSString).size(withAttributes: attributes)
                if bounds.width <= size.width && bounds.height <= size.height { break }
                point *= 0.85
            }

            (word as NSString).draw(
                at: CGPoint(
                    x: (size.width - bounds.width) / 2,
                    y: (size.height - bounds.height) / 2
                ),
                withAttributes: attributes
            )
        }
    }

    /// A zero-length entry — a word answered on the frame it appeared — would otherwise
    /// never render. It gets a minimum on-screen time so it is actually seen.
    private static func cardEnd(of entry: RecordingEntry) -> TimeInterval {
        guard let end = entry.end else { return .greatestFiniteMagnitude }
        return max(end, entry.start + minimumCardDuration)
    }

    // MARK: - Outcome flash

    private static func flash(for entry: RecordingEntry, size: CGSize, clip: TimeInterval) -> CALayer? {
        guard let outcome = entry.outcome, let end = entry.end else { return nil }
        // Nothing to celebrate when the clock simply ran out.
        guard outcome != .unanswered else { return nil }

        let scale = size.width / 1080
        let symbol = outcome == .correct ? "checkmark.circle.fill" : "xmark.circle.fill"
        let tint = outcome == .correct ? Tokens.success : Tokens.danger

        let mark = CALayer()
        let side = 190 * scale
        mark.frame = CGRect(
            x: (size.width - side) / 2,
            y: size.height * 0.34,
            width: side,
            height: side
        )
        mark.contents = image(named: symbol, tint: uiColor(tint), side: side)?.cgImage
        mark.contentsGravity = .resizeAspect
        mark.shadowColor = UIColor.black.cgColor
        mark.shadowOpacity = 0.4
        mark.shadowRadius = 14 * scale

        mark.opacity = 0
        mark.add(visibility(from: end, to: end + flashDuration, clip: clip), forKey: "visibility")
        mark.add(pop(at: end), forKey: "pop")
        return mark
    }

    private static func image(named symbol: String, tint: UIColor, side: CGFloat) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: side, weight: .bold)
        return UIImage(systemName: symbol, withConfiguration: configuration)?
            .withTintColor(tint, renderingMode: .alwaysOriginal)
    }

    // MARK: - Animations
    //
    // Every animation here obeys the same three rules, which is what
    // `AVVideoCompositionCoreAnimationTool` requires and what makes a layer that looks
    // right in a preview render as a blank frame in an export when they are missed:
    //
    //   · `beginTime` is offset from `AVCoreAnimationBeginTimeAtZero`, never 0 — a literal
    //     zero means "now", and in an export there is no now.
    //   · `isRemovedOnCompletion` is false, or the layer snaps back after its first pass.
    //   · `fillMode` is `.both`, so the value holds before and after the animation.

    /// A hard cut in, and a hard cut out, over the length of the whole clip.
    ///
    /// The span matters as much as the cut. An animation that ran only for the card's own
    /// window needed `fillMode = .both` to hold its value, and fill applies the *first*
    /// value to all time before `beginTime` — so every card was opaque from the first
    /// frame. Stacked in one place, that renders as a single word for the entire clip: the
    /// last one added, never changing. Verified by exporting a three-word clip and
    /// sampling frames.
    ///
    /// So each card gets one animation covering the clip, off until its start and off
    /// again after its end. No fill can leak it in early.
    ///
    /// No fade either. In the game a word is simply there the moment it is dealt.
    private static func visibility(
        from start: TimeInterval,
        to end: TimeInterval,
        clip: TimeInterval
    ) -> CAAnimation {
        let total = max(clip, end + 0.01)
        let onAt = min(max(start / total, 0), 1)
        let offAt = min(max(end / total, onAt + 0.0001), 1)

        let step = CAKeyframeAnimation(keyPath: "opacity")
        step.values = [0, 1, 0]
        step.keyTimes = [0, NSNumber(value: onAt), NSNumber(value: offAt)]
        step.calculationMode = .discrete
        step.duration = total
        return configured(step, at: 0)
    }

    private static func pop(at time: TimeInterval) -> CAAnimation {
        let scale = CAKeyframeAnimation(keyPath: "transform.scale")
        scale.values = [0.6, 1.12, 1]
        scale.keyTimes = [0, 0.45, 1]
        scale.duration = 0.32
        scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
        return configured(scale, at: time)
    }

    private static func configured(_ animation: CAAnimation, at time: TimeInterval) -> CAAnimation {
        animation.beginTime = AVCoreAnimationBeginTimeAtZero + time
        animation.isRemovedOnCompletion = false
        animation.fillMode = .both
        return animation
    }

    // MARK: - Design tokens, as Core Animation wants them

    /// The clip is always dark. A video does not follow the viewer's appearance setting,
    /// and the game's dark surface is the one the cards were designed against.
    private static func uiColor(_ token: DesignColor) -> UIColor {
        let rgb = token.value(for: .dark)
        return UIColor(red: rgb.r, green: rgb.g, blue: rgb.b, alpha: 1)
    }

    private static func cgColor(_ token: DesignColor) -> CGColor {
        uiColor(token).cgColor
    }

    /// The bundled display face, registered by `DesignSystem.registerFonts()`. Falls back
    /// rather than failing: a missing face should cost the clip its typography, not the
    /// word itself.
    private static func displayFont(_ size: CGFloat) -> UIFont {
        UIFont(name: Typography.displayFamily, size: size)
            ?? .systemFont(ofSize: size, weight: .heavy)
    }

    // MARK: - Constants

    private static let flashDuration: TimeInterval = 0.9
    private static let minimumCardDuration: TimeInterval = 0.6
}
