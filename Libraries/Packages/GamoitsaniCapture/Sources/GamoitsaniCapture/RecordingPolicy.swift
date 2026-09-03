//
//  RecordingPolicy.swift
//  GamoitsaniCapture
//
import Foundation

/// Why a clip was not produced.
public enum RecordingRefusal: Error, Sendable, Hashable {
    case disabled
    case cameraDenied
    case microphoneDenied
    case notEnoughDisk(freeBytes: Int64, needsBytes: Int64)
}

/// What the app knows when it is about to start recording a turn.
public struct RecordingConditions: Sendable, Hashable {
    public var isEnabled: Bool
    public var hasCamera: Bool
    public var hasMicrophone: Bool
    public var freeDiskBytes: Int64

    public init(
        isEnabled: Bool = false,
        hasCamera: Bool = false,
        hasMicrophone: Bool = false,
        freeDiskBytes: Int64 = 0
    ) {
        self.isEnabled = isEnabled
        self.hasCamera = hasCamera
        self.hasMicrophone = hasMicrophone
        self.freeDiskBytes = freeDiskBytes
    }
}

/// Whether a turn is worth recording, and whether the result is worth keeping.
///
/// v1 had none of this: it started on a 0.5s delay with no disk check, no duration cap and
/// no notion of a clip too dull to keep, then wrote every attempt to Documents and left it
/// there forever.
public struct RecordingPolicy: Sendable, Hashable {

    /// Headroom required before starting. A turn is bounded by the round length, so the
    /// worst case is knowable rather than guessed.
    public var reservedDiskBytes: Int64

    /// Roughly what a second of camera video costs, for the estimate above.
    public var bytesPerSecond: Int64

    /// Hard ceiling, so a stuck clock cannot fill the disk.
    public var maximumDuration: TimeInterval

    /// Below this, the clip is discarded rather than exported.
    public var minimumDuration: TimeInterval

    public init(
        reservedDiskBytes: Int64 = 200 * 1024 * 1024,
        bytesPerSecond: Int64 = 250_000,
        maximumDuration: TimeInterval = 180,
        minimumDuration: TimeInterval = 3
    ) {
        self.reservedDiskBytes = reservedDiskBytes
        self.bytesPerSecond = bytesPerSecond
        self.maximumDuration = maximumDuration
        self.minimumDuration = minimumDuration
    }

    /// Space needed for a turn of `roundLength`, plus the export, which writes a second
    /// copy before the original is deleted.
    public func requiredBytes(forRoundLength roundLength: TimeInterval) -> Int64 {
        let clamped = min(max(0, roundLength), maximumDuration)
        let clip = Int64(clamped) * bytesPerSecond
        return clip * 2 + reservedDiskBytes
    }

    /// Why this turn cannot be recorded, or `nil` if it can.
    ///
    /// An optional rather than `Result<Void, _>`, which is not `Equatable` because `Void`
    /// is not, and a rule this small should be comparable in one line of a test.
    ///
    /// Camera *and* microphone are both required — v1 checked only the microphone, so
    /// denying camera access produced a recording with no picture and no explanation.
    public func refusalToRecord(
        _ conditions: RecordingConditions,
        roundLength: TimeInterval
    ) -> RecordingRefusal? {
        guard conditions.isEnabled else { return .disabled }
        guard conditions.hasCamera else { return .cameraDenied }
        guard conditions.hasMicrophone else { return .microphoneDenied }

        let needed = requiredBytes(forRoundLength: roundLength)
        guard conditions.freeDiskBytes >= needed else {
            return .notEnoughDisk(freeBytes: conditions.freeDiskBytes, needsBytes: needed)
        }
        return nil
    }

    /// Whether a finished clip earns an export.
    ///
    /// A turn abandoned after two seconds is a file nobody wants, and exporting it costs
    /// more than recording it did.
    public func isWorthKeeping(_ timeline: RecordingTimeline) -> Bool {
        guard let duration = timeline.duration, duration >= minimumDuration else { return false }
        // Nothing happened. The clip is someone looking at a phone.
        return !timeline.entries.isEmpty
    }
}
