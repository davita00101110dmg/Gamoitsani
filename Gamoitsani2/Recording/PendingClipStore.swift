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

    /// After this many failed attempts a clip is thrown away.
    ///
    /// The point is not the number. Recovery that runs at launch and crashes on what it is
    /// recovering bricks the app — every launch retries the same file and dies the same
    /// way, which is exactly what happened. Counting attempts *before* each one, on disk,
    /// makes that impossible whatever the underlying fault turns out to be.
    private static let maximumAttempts = 3

    /// What is stored beside the footage.
    private struct Record: Codable {
        var timeline: RecordingTimeline
        var attempts: Int
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
        write(Record(timeline: timeline, attempts: 0), for: clip)
    }

    private static func write(_ record: Record, for clip: URL) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: sidecar(for: clip), options: .atomic)
    }

    /// Records that an attempt is about to happen, and says whether to make it.
    ///
    /// Written before the work, not after. A crash during the attempt still leaves the
    /// count incremented, which is the whole point — a clip that kills the app is out of
    /// chances by the third launch instead of killing it forever.
    static func beginAttempt(for clip: URL) -> Bool {
        guard var record = read(clip) else {
            discard(clip)
            return false
        }
        guard record.attempts < maximumAttempts else {
            discard(clip)
            return false
        }
        record.attempts += 1
        write(record, for: clip)
        return true
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
                guard let record = read(clip) else {
                    // Footage with no timeline is from a turn that never finished. It has
                    // no words to overlay and nobody is waiting for it.
                    discard(clip)
                    return nil
                }
                return Pending(clip: clip, timeline: record.timeline)
            }
            .sorted { created($0.clip) < created($1.clip) }
    }

    /// Removes the footage and its timeline together.
    static func discard(_ clip: URL) {
        try? FileManager.default.removeItem(at: clip)
        try? FileManager.default.removeItem(at: sidecar(for: clip))
    }

    private static func read(_ clip: URL) -> Record? {
        guard let data = try? Data(contentsOf: sidecar(for: clip)) else { return nil }
        if let record = try? JSONDecoder().decode(Record.self, from: data) { return record }
        // A sidecar written before attempts were counted.
        guard let timeline = try? JSONDecoder().decode(RecordingTimeline.self, from: data) else {
            return nil
        }
        return Record(timeline: timeline, attempts: 0)
    }

    private static func sidecar(for clip: URL) -> URL {
        clip.deletingPathExtension().appendingPathExtension("json")
    }

    private static func created(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }
}
