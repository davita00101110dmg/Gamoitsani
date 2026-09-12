//
//  PendingClipStore.swift
//  Gamoitsani
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
        /// Which game it belongs to. Clips are cut into one reel per game, so a turn from
        /// an abandoned game must not end up in the next game's reel.
        let gameID: String
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
        var gameID: String?
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
    static func write(_ timeline: RecordingTimeline, gameID: String, for clip: URL) {
        write(Record(timeline: timeline, attempts: 0, gameID: gameID), for: clip)
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

    /// Every clip with a timeline beside it, oldest first — which is also the order the
    /// turns were played, and therefore the order a reel should replay them.
    ///
    /// Pure. It used to delete footage it could not pair with a timeline, and a clip being
    /// recorded *right now* has no timeline yet — the sidecar is written when the turn
    /// ends. So every call during a turn destroyed the file being written, including the
    /// one behind the debug menu's "pending clips" count. A query does not delete.
    static func pending() -> [Pending] {
        clips().compactMap { clip -> Pending? in
            guard let record = read(clip) else { return nil }
            // A clip written before games were identified belongs to no game, and is left
            // to the orphan sweep rather than folded into an unrelated reel.
            return Pending(
                clip: clip,
                timeline: record.timeline,
                gameID: record.gameID ?? ""
            )
        }
    }

    /// Footage with no timeline beside it: a turn that never finished, from a previous
    /// launch. It has no words to overlay and nobody is waiting for it.
    ///
    /// Only safe when nothing is being recorded, which is why it is called once at startup
    /// and nowhere else. `inProgress` is belt and braces for the case where a turn begins
    /// before startup finishes.
    static func removeOrphans(excluding inProgress: URL?) {
        for clip in clips() where clip != inProgress && read(clip) == nil {
            discard(clip)
        }
    }

    private static func clips() -> [URL] {
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey]
        )) ?? []
        return contents
            .filter { $0.pathExtension == "mov" }
            .sorted { created($0) < created($1) }
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
        return Record(timeline: timeline, attempts: 0, gameID: nil)
    }

    private static func sidecar(for clip: URL) -> URL {
        clip.deletingPathExtension().appendingPathExtension("json")
    }

    private static func created(_ url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
    }
}
