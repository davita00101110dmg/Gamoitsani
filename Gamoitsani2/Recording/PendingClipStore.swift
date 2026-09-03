//
//  PendingClipStore.swift
//  Gamoitsani2
//
import Foundation
import GamoitsaniCapture

/// Clips that have been filmed but not yet saved to Photos.
///
/// Recording writes here rather than to `temporaryDirectory`, and the timeline is written
/// beside the footage the moment the turn ends. Both survive the app being killed, so a
/// clip is never lost to a force-quit during the export — the next launch finds the pair
/// and finishes the job.
enum PendingClipStore {

    /// One filmed turn: the footage, and what was on screen during it.
    struct Pending {
        let clip: URL
        let timeline: RecordingTimeline
    }

    /// Not `temporaryDirectory`, which the system may purge, and not Documents, which the
    /// user can see through the Files app — a half-finished clip is not something to show
    /// anyone.
    static var directory: URL {
        let base = URL.applicationSupportDirectory.appendingPathComponent("Recordings", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func newClipURL() -> URL {
        directory.appendingPathComponent("turn-\(UUID().uuidString).mov")
    }

    /// Records what the clip contains, so an interrupted export can be resumed without the
    /// running game that produced it.
    static func write(_ timeline: RecordingTimeline, for clip: URL) {
        guard let data = try? JSONEncoder().encode(timeline) else { return }
        try? data.write(to: sidecar(for: clip), options: .atomic)
    }

    /// Every clip with a timeline beside it, oldest first so a backlog is cleared in the
    /// order it was filmed.
    static func pending() -> [Pending] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []

        return contents
            .filter { $0.pathExtension == "mov" }
            .compactMap { clip in
                guard let data = try? Data(contentsOf: sidecar(for: clip)),
                      let timeline = try? JSONDecoder().decode(RecordingTimeline.self, from: data)
                else {
                    // Footage with no timeline is from a turn that never finished. It has
                    // no words to overlay and nobody is waiting for it.
                    discard(clip)
                    return nil
                }
                return Pending(clip: clip, timeline: timeline)
            }
            .sorted { created($0.clip) < created($1.clip) }
    }

    /// Removes the footage and its timeline together.
    static func discard(_ clip: URL) {
        try? FileManager.default.removeItem(at: clip)
        try? FileManager.default.removeItem(at: sidecar(for: clip))
    }

    private static func sidecar(for clip: URL) -> URL {
        clip.deletingPathExtension().appendingPathExtension("json")
    }

    private static func created(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }
}
