//
//  RecordingTimeline.swift
//  GamoitsaniCapture
//
import Foundation

/// How a word left the screen.
public enum RecordingOutcome: String, Sendable, Hashable, Codable {
    case correct
    case skipped
    /// Still on the table when the clock ran out.
    case unanswered
}

/// One word's time on screen, in seconds from the start of the clip.
///
/// An interval rather than an instant because that is what the overlay needs: at export
/// time it asks "what was on screen at t?" and gets back everything still live. Classic
/// has one word live at a time and arcade has up to five, and neither needs a special
/// case.
public struct RecordingEntry: Sendable, Hashable, Codable {
    public let word: String
    public let start: TimeInterval
    /// `nil` while the word is still on screen.
    public private(set) var end: TimeInterval?
    public private(set) var outcome: RecordingOutcome?

    public init(word: String, start: TimeInterval) {
        self.word = word
        self.start = start
    }

    public var isOpen: Bool { end == nil }

    /// How long it was up. Zero-length entries are possible — a word answered on the same
    /// frame it appeared — and the overlay must not divide by this.
    public var duration: TimeInterval { (end ?? start) - start }

    fileprivate mutating func close(at time: TimeInterval, outcome: RecordingOutcome) {
        // Never before it started. A clip's clock and the game's clock are set from
        // different places, and one arriving late must not produce a negative interval.
        self.end = max(time, start)
        self.outcome = outcome
    }
}

/// What happened during one turn, as the overlay will need to replay it.
///
/// Built while the turn runs, then handed to the exporter. It holds no video and knows
/// nothing about files — it is the description of a clip, not the clip.
public struct RecordingTimeline: Sendable, Hashable, Codable {

    public let teamName: String
    public private(set) var entries: [RecordingEntry]
    /// Set when the turn ends. `nil` while it is still running.
    public private(set) var duration: TimeInterval?

    public init(teamName: String) {
        self.teamName = teamName
        self.entries = []
        self.duration = nil
    }

    public var isFinished: Bool { duration != nil }

    /// Words correct, for the overlay's running score.
    public var correctCount: Int {
        entries.count { $0.outcome == .correct }
    }

    public var skippedCount: Int {
        entries.count { $0.outcome == .skipped }
    }

    /// Everything on screen at `time`, in the order it appeared.
    ///
    /// The half-open interval matters: a word answered at 4.2s and its replacement shown
    /// at 4.2s must not both be returned, or the overlay flickers two cards for a frame.
    public func entries(at time: TimeInterval) -> [RecordingEntry] {
        entries.filter { entry in
            guard time >= entry.start else { return false }
            guard let end = entry.end else { return true }
            return time < end || entry.duration == 0
        }
    }

    // MARK: - Building

    public mutating func wordShown(_ word: String, at time: TimeInterval) {
        guard !isFinished else { return }
        entries.append(RecordingEntry(word: word, start: max(0, time)))
    }

    /// Closes the most recent open entry for that word.
    ///
    /// By word rather than by index because arcade answers out of order, and the same word
    /// can legitimately appear twice in one turn if a deck wraps.
    public mutating func wordAnswered(
        _ word: String,
        outcome: RecordingOutcome,
        at time: TimeInterval
    ) {
        guard !isFinished else { return }
        guard let index = entries.lastIndex(where: { $0.word == word && $0.isOpen }) else { return }
        entries[index].close(at: time, outcome: outcome)
    }

    /// Reopens a word taken back by mistake, so an undo does not leave a phantom score on
    /// the overlay.
    public mutating func undoAnswer(_ word: String) {
        guard !isFinished else { return }
        guard let index = entries.lastIndex(where: { $0.word == word && !$0.isOpen }) else { return }
        entries[index] = RecordingEntry(word: word, start: entries[index].start)
    }

    /// Ends the turn. Anything still on screen is closed as unanswered.
    public mutating func finish(at time: TimeInterval) {
        guard !isFinished else { return }
        let end = max(0, time)
        for index in entries.indices where entries[index].isOpen {
            entries[index].close(at: end, outcome: .unanswered)
        }
        duration = end
    }
}
