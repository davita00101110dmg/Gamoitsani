//
//  HighlightReel.swift
//  Gamoitsani2
//
import AVFoundation
import GamoitsaniCapture
import UIKit

/// One game's turns, cut into a single shareable video.
///
/// Turn clips are working files now: filmed, kept while the game runs, and consumed here.
/// Six separate videos of one evening is a folder nobody opens; one is a thing people send
/// to the group chat.
enum HighlightReel {

    /// A turn's footage and what happened during it.
    struct Source {
        let clip: URL
        let timeline: RecordingTimeline
    }

    /// Builds the reel and returns it, or `nil` if there was nothing to build from.
    /// The caller owns deleting the result.
    static func build(
        from sources: [Source],
        endCard: UIImage?,
        policy: HighlightPolicy = HighlightPolicy()
    ) async -> URL? {
        let highlights = policy.highlights(from: sources.map(\.timeline))
        guard !highlights.isEmpty else {
            RecordingLog.note("  reel: nothing to cut")
            return nil
        }

        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { return nil }
        // Added only once there is audio to put in it. An empty track in a composition
        // makes the export fail with -11838, "not supported for this media" — which names
        // the media rather than the empty track, and is not obviously about this at all.
        var audioTrack: AVMutableCompositionTrack?

        var size = CGSize.zero
        var transform = CGAffineTransform.identity
        /// Where each slice ends up in the finished reel, so the overlay can place its
        /// word at the right moment rather than at the time it happened in its own turn.
        var placed: [(highlight: Highlight, start: TimeInterval)] = []
        var cursor = CMTime.zero

        for highlight in highlights {
            guard sources.indices.contains(highlight.turnIndex) else { continue }
            let asset = AVURLAsset(url: sources[highlight.turnIndex].clip)

            guard let sourceVideo = try? await asset.loadTracks(withMediaType: .video).first,
                  let duration = try? await asset.load(.duration)
            else { continue }

            // Clamp to what the file actually holds. The timeline's clock and the file's
            // are close but not identical, and an over-long range fails the whole insert.
            let start = CMTime(seconds: max(0, highlight.start), preferredTimescale: 600)
            let end = min(
                CMTime(seconds: highlight.end, preferredTimescale: 600),
                duration
            )
            guard end > start else { continue }
            let range = CMTimeRange(start: start, end: end)

            do {
                try videoTrack.insertTimeRange(range, of: sourceVideo, at: cursor)
                if let sourceAudio = try? await asset.loadTracks(withMediaType: .audio).first {
                    if audioTrack == nil {
                        audioTrack = composition.addMutableTrack(
                            withMediaType: .audio,
                            preferredTrackID: kCMPersistentTrackID_Invalid
                        )
                    }
                    try audioTrack?.insertTimeRange(range, of: sourceAudio, at: cursor)
                }
            } catch {
                RecordingLog.note("  reel: could not insert a slice: \(error)")
                continue
            }

            if size == .zero {
                let natural = (try? await sourceVideo.load(.naturalSize)) ?? .zero
                transform = (try? await sourceVideo.load(.preferredTransform)) ?? .identity
                let rendered = natural.applying(transform)
                size = CGSize(width: abs(rendered.width), height: abs(rendered.height))
            }

            placed.append((highlight, cursor.seconds))
            cursor = cursor + range.duration
        }

        guard cursor > .zero, size.width > 0, size.height > 0 else {
            RecordingLog.note("  reel: no slices survived")
            return nil
        }

        // The score card needs real media underneath it. A composition's duration is its
        // media: an empty range at the end does not extend it, and exporting past the last
        // frame fails. So the final slice is held for the card's length and covered
        // completely by an opaque, full-frame layer.
        let cardStart = cursor.seconds
        if endCard != nil,
           let last = highlights.last,
           sources.indices.contains(last.turnIndex) {
            let asset = AVURLAsset(url: sources[last.turnIndex].clip)
            if let track = try? await asset.loadTracks(withMediaType: .video).first,
               let duration = try? await asset.load(.duration) {
                let from = CMTime(seconds: max(0, last.start), preferredTimescale: 600)
                let to = min(
                    CMTime(seconds: last.start + endCardDuration, preferredTimescale: 600),
                    duration
                )
                if to > from {
                    try? videoTrack.insertTimeRange(
                        CMTimeRange(start: from, end: to), of: track, at: cursor
                    )
                    cursor = cursor + (to - from)
                }
            }
        }
        let total = composition.duration.seconds

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = size
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        let instruction = AVMutableVideoCompositionInstruction()
        // The end card plays over a gap in the composition, and a gap renders as this.
        instruction.backgroundColor = UIColor.black.cgColor
        instruction.timeRange = CMTimeRange(
            start: .zero,
            duration: CMTime(seconds: total, preferredTimescale: 600)
        )
        let layer = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        // The clips are portrait with a rotation transform; the composition renders at the
        // displayed size, so the track has to be turned to match.
        layer.setTransform(orientationTransform(for: transform, size: size), at: .zero)
        instruction.layerInstructions = [layer]
        videoComposition.instructions = [instruction]

        videoComposition.animationTool = animationTool(
            placed: placed,
            endCard: endCard,
            cardStart: cardStart,
            clipLength: total,
            size: size
        )

        return await export(composition, videoComposition: videoComposition, duration: total)
    }

    /// How long the score card holds.
    private static let endCardDuration: TimeInterval = 2.5

    // MARK: - Rendering

    private static func orientationTransform(
        for preferred: CGAffineTransform,
        size: CGSize
    ) -> CGAffineTransform {
        // `preferredTransform` maps the natural size onto the displayed one, but around an
        // origin the composition does not share, so the result is translated back into
        // frame.
        let rendered = CGSize(width: size.width, height: size.height)
        var result = preferred
        result.tx = preferred.tx < 0 ? rendered.width : preferred.tx
        result.ty = preferred.ty < 0 ? rendered.height : preferred.ty
        return result
    }

    private static func animationTool(
        placed: [(highlight: Highlight, start: TimeInterval)],
        endCard: UIImage?,
        cardStart: TimeInterval,
        clipLength: TimeInterval,
        size: CGSize
    ) -> AVVideoCompositionCoreAnimationTool {
        let frame = CGRect(origin: .zero, size: size)

        let videoLayer = CALayer()
        videoLayer.frame = frame

        let parent = CALayer()
        parent.frame = frame
        parent.addSublayer(videoLayer)
        parent.addSublayer(
            RecordingOverlay.reelLayer(placed: placed, size: size, clipLength: clipLength)
        )

        if let endCard {
            parent.addSublayer(
                RecordingOverlay.endCardLayer(
                    endCard,
                    size: size,
                    start: cardStart,
                    clipLength: clipLength
                )
            )
        }

        return AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parent
        )
    }

    private static func export(
        _ composition: AVComposition,
        videoComposition: AVVideoComposition,
        duration: TimeInterval
    ) async -> URL? {
        guard let session = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            RecordingLog.note("  reel: no export session")
            return nil
        }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("gamoitsani-highlights-\(Int(Date().timeIntervalSince1970)).mp4")
        try? FileManager.default.removeItem(at: output)

        session.videoComposition = videoComposition
        session.timeRange = CMTimeRange(
            start: .zero,
            duration: CMTime(seconds: duration, preferredTimescale: 600)
        )

        do {
            try await session.export(to: output, as: .mp4)
            let size = (try? FileManager.default.attributesOfItem(atPath: output.path)[.size] as? Int) ?? 0
            RecordingLog.note("  reel: exported \((size ?? 0) / 1024)KB, \(Int(duration))s")
            return output
        } catch {
            RecordingLog.note("  reel: export threw: \(error)")
            try? FileManager.default.removeItem(at: output)
            return nil
        }
    }
}
