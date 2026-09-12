//
//  RecordingExporter.swift
//  Gamoitsani
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

        // An asset from a process that died mid-write can still be opened and then fail
        // everything after, so this is asked first rather than inferred from a throw.
        guard (try? await asset.load(.isReadable)) == true,
              let track = try? await asset.loadTracks(withMediaType: .video).first,
              let duration = try? await asset.load(.duration),
              let naturalSize = try? await track.load(.naturalSize),
              let transform = try? await track.load(.preferredTransform)
        else {
            RecordingLog.note("    asset unreadable")
            return nil
        }

        // The rendered frame is the *displayed* size. A portrait clip's natural size is
        // landscape with a rotation transform, and composing at the natural size produces
        // a sideways video with the overlay in the wrong place.
        let rendered = naturalSize.applying(transform)
        let size = CGSize(width: abs(rendered.width), height: abs(rendered.height))
        RecordingLog.note("    asset \(Int(size.width))x\(Int(size.height)) \(duration.seconds)s")
        guard size.width > 0, size.height > 0, duration.seconds > 0 else {
            RecordingLog.note("    bad dimensions or duration")
            return nil
        }

        guard let composition = try? await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset) else {
            RecordingLog.note("    composition failed")
            return nil
        }
        composition.renderSize = size
        composition.animationTool = animationTool(for: timeline, size: size)

        // `highestQuality` rather than a fixed 1920x1080 preset: a dimensioned preset
        // constrains the output box, and the render size here is portrait. The video
        // composition is what decides the frame.
        guard let session = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            RecordingLog.note("    no export session")
            return nil
        }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("gamoitsani-\(Int(Date().timeIntervalSince1970)).mp4")
        try? FileManager.default.removeItem(at: output)

        session.videoComposition = composition
        session.timeRange = CMTimeRange(start: .zero, duration: duration)

        do {
            try await session.export(to: output, as: .mp4)
            let size = (try? FileManager.default.attributesOfItem(atPath: output.path)[.size] as? Int) ?? 0
            RecordingLog.note("    exported \((size ?? 0) / 1024)KB")
            return output
        } catch {
            RecordingLog.note("    export threw: \(error)")
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
