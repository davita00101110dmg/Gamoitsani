//
//  RecordingExporter.swift
//  Gamoitsani2
//
import AVFoundation
import GamoitsaniCapture
import UIKit

/// Burns the overlay into a recorded clip.
///
/// This is the whole reason capture stays dumb. Nothing is composited while the game is
/// running — the turn writes plain camera footage, and the words are added afterwards from
/// the timeline, on the turn-info screen while the phone is being handed over.
enum RecordingExporter {

    /// Returns the composed file, or `nil` if anything went wrong. The caller owns
    /// deleting it.
    static func export(clip url: URL, timeline: RecordingTimeline) async -> URL? {
        let asset = AVURLAsset(url: url)

        guard let track = try? await asset.loadTracks(withMediaType: .video).first,
              let duration = try? await asset.load(.duration),
              let naturalSize = try? await track.load(.naturalSize),
              let transform = try? await track.load(.preferredTransform)
        else { return nil }

        // The rendered frame is the *displayed* size. A portrait clip's natural size is
        // landscape with a rotation transform, and composing at the natural size produces
        // a sideways video with the overlay in the wrong place.
        let rendered = naturalSize.applying(transform)
        let size = CGSize(width: abs(rendered.width), height: abs(rendered.height))
        guard size.width > 0, size.height > 0 else { return nil }

        let composition = AVMutableVideoComposition(propertiesOf: asset)
        composition.renderSize = size
        composition.animationTool = animationTool(for: timeline, size: size)

        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPreset1920x1080
        ) else { return nil }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("gamoitsani-\(Int(Date().timeIntervalSince1970)).mp4")
        try? FileManager.default.removeItem(at: output)

        session.videoComposition = composition
        session.timeRange = CMTimeRange(start: .zero, duration: duration)

        do {
            try await session.export(to: output, as: .mp4)
            return output
        } catch {
            try? FileManager.default.removeItem(at: output)
            return nil
        }
    }

    /// The layer sandwich Core Animation wants: a parent holding the video and the overlay,
    /// both the full frame.
    ///
    /// The video layer must be a *sibling* of the overlay inside the parent, not its
    /// superlayer. Nesting them the other way renders the overlay under the footage, which
    /// looks exactly like it silently did nothing.
    private static func animationTool(
        for timeline: RecordingTimeline,
        size: CGSize
    ) -> AVVideoCompositionCoreAnimationTool {
        let frame = CGRect(origin: .zero, size: size)

        let videoLayer = CALayer()
        videoLayer.frame = frame

        let parent = CALayer()
        parent.frame = frame
        parent.addSublayer(videoLayer)
        parent.addSublayer(RecordingOverlay.layer(for: timeline, size: size))

        return AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parent
        )
    }
}
