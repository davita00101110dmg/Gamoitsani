//
//  Highlights.swift
//  GamoitsaniCapture
//
import Foundation

/// Why a moment was picked. Kept so the reel can be explained, and so the ordering rules
/// have something to sort on.
public enum HighlightKind: String, Sendable, Hashable, Codable {
    /// A word that hung there a long time and was then guessed.
    case struggle
    /// Guessed in the last seconds of the clock.
    case buzzerBeater
    /// Several in quick succession.
    case streak
    /// Nothing qualified, so the end of a turn was taken rather than showing nothing.
    case fallback
}

/// A slice of one turn's footage.
public struct Highlight: Sendable, Hashable {
    /// Which turn's clip this comes from.
    public let turnIndex: Int
    public let start: TimeInterval
    public let end: TimeInterval
    public let kind: HighlightKind
    /// The words on screen during the slice, for the overlay.
    public let words: [String]

    public var duration: TimeInterval { max(0, end - start) }

    public init(
        turnIndex: Int,
        start: TimeInterval,
        end: TimeInterval,
        kind: HighlightKind,
        words: [String]
    ) {
        self.turnIndex = turnIndex
        self.start = start
        self.end = end
        self.kind = kind
        self.words = words
    }
}

/// Picks the moments worth keeping out of a game's turns.
///
/// The timeline already records when every word appeared and how it left, so the
/// interesting moments can be found without anyone marking them: the word that took
/// forever and was then guessed, the one that landed as the clock ran out, and the run of
/// three in a few seconds.
///
/// Everything here is a pure function of the timelines. No video is opened, which is what
/// makes the choice of what is funny testable.
public struct HighlightPolicy: Sendable, Hashable {

    /// A word on screen at least this long, then guessed, is a struggle.
    public var struggleThreshold: TimeInterval
    /// How much of the run-up to a guess to include.
    public var leadIn: TimeInterval
    /// How long to hold after it.
    public var tail: TimeInterval
    /// A guess this close to the end of the turn is a buzzer-beater.
    public var buzzerWindow: TimeInterval
    /// How many quick answers make a streak, and how quickly.
    public var streakCount: Int
    public var streakWindow: TimeInterval
    /// Caps on the finished reel.
    public var maximumTotal: TimeInterval
    public var maximumCount: Int
    /// Below this a slice is too short to register as anything.
    public var minimumDuration: TimeInterval

    public init(
        struggleThreshold: TimeInterval = 8,
        leadIn: TimeInterval = 3,
        tail: TimeInterval = 1.2,
        buzzerWindow: TimeInterval = 3,
        streakCount: Int = 3,
        streakWindow: TimeInterval = 6,
        maximumTotal: TimeInterval = 30,
        maximumCount: Int = 5,
        minimumDuration: TimeInterval = 1.5
    ) {
        self.struggleThreshold = struggleThreshold
        self.leadIn = leadIn
        self.tail = tail
        self.buzzerWindow = buzzerWindow
        self.streakCount = streakCount
        self.streakWindow = streakWindow
        self.maximumTotal = maximumTotal
        self.maximumCount = maximumCount
        self.minimumDuration = minimumDuration
    }

    /// The reel, in the order it should play.
    ///
    /// `timelines` is one per turn, in the order they were filmed.
    public func highlights(from timelines: [RecordingTimeline]) -> [Highlight] {
        var candidates: [Highlight] = []
        for (index, timeline) in timelines.enumerated() {
            candidates += self.candidates(in: timeline, turnIndex: index)
        }

        // Nothing stood out — a short game, or one where nothing was guessed. A brief reel
        // beats an empty one.
        if candidates.isEmpty {
            candidates = timelines.enumerated().compactMap { index, timeline in
                fallback(in: timeline, turnIndex: index)
            }
        }

        let merged = merge(candidates)
        return take(from: merged)
    }

    // MARK: - Finding

    private func candidates(in timeline: RecordingTimeline, turnIndex: Int) -> [Highlight] {
        guard let turnLength = timeline.duration, turnLength > 0 else { return [] }
        let guessed = timeline.entries.filter { $0.outcome == .correct && $0.end != nil }
        var found: [Highlight] = []

        for entry in guessed {
            guard let end = entry.end else { continue }

            if entry.duration >= struggleThreshold {
                found.append(
                    Highlight(
                        turnIndex: turnIndex,
                        start: max(0, end - leadIn),
                        end: min(turnLength, end + tail),
                        kind: .struggle,
                        words: [entry.word]
                    )
                )
            }

            if turnLength - end <= buzzerWindow {
                found.append(
                    Highlight(
                        turnIndex: turnIndex,
                        start: max(0, end - leadIn),
                        end: min(turnLength, end + tail),
                        kind: .buzzerBeater,
                        words: [entry.word]
                    )
                )
            }
        }

        found += streaks(in: guessed, turnIndex: turnIndex, turnLength: turnLength)
        return found
    }

    /// Runs of `streakCount` answers inside `streakWindow`.
    private func streaks(
        in guessed: [RecordingEntry],
        turnIndex: Int,
        turnLength: TimeInterval
    ) -> [Highlight] {
        guard streakCount > 1, guessed.count >= streakCount else { return [] }
        let ordered = guessed.sorted { ($0.end ?? 0) < ($1.end ?? 0) }
        var found: [Highlight] = []

        for start in 0...(ordered.count - streakCount) {
            let run = Array(ordered[start..<(start + streakCount)])
            guard let first = run.first?.end, let last = run.last?.end else { continue }
            guard last - first <= streakWindow else { continue }

            found.append(
                Highlight(
                    turnIndex: turnIndex,
                    start: max(0, first - leadIn),
                    end: min(turnLength, last + tail),
                    kind: .streak,
                    words: run.map(\.word)
                )
            )
        }
        return found
    }

    /// The end of a turn, when nothing else qualified.
    private func fallback(in timeline: RecordingTimeline, turnIndex: Int) -> Highlight? {
        guard let turnLength = timeline.duration, turnLength >= minimumDuration else { return nil }
        let span = min(turnLength, leadIn + tail)
        let words = timeline.entries(at: max(0, turnLength - span / 2)).map(\.word)
        return Highlight(
            turnIndex: turnIndex,
            start: max(0, turnLength - span),
            end: turnLength,
            kind: .fallback,
            words: words
        )
    }

    // MARK: - Choosing

    /// Overlapping slices of the same turn become one. Two rules firing on the same guess
    /// is common — a buzzer-beater is often also a struggle — and cutting the same seconds
    /// twice makes the reel stutter.
    private func merge(_ candidates: [Highlight]) -> [Highlight] {
        let ordered = candidates.sorted {
            $0.turnIndex == $1.turnIndex ? $0.start < $1.start : $0.turnIndex < $1.turnIndex
        }

        var merged: [Highlight] = []
        for candidate in ordered {
            guard let last = merged.last,
                  last.turnIndex == candidate.turnIndex,
                  candidate.start <= last.end
            else {
                merged.append(candidate)
                continue
            }

            merged[merged.count - 1] = Highlight(
                turnIndex: last.turnIndex,
                start: last.start,
                end: max(last.end, candidate.end),
                kind: priority(last.kind) <= priority(candidate.kind) ? last.kind : candidate.kind,
                words: last.words + candidate.words.filter { !last.words.contains($0) }
            )
        }
        return merged
    }

    /// Best first, for deciding what survives the caps.
    private func priority(_ kind: HighlightKind) -> Int {
        switch kind {
        case .buzzerBeater: 0
        case .struggle: 1
        case .streak: 2
        case .fallback: 3
        }
    }

    /// Keeps the best few within the length cap, then puts them back in playing order.
    private func take(from merged: [Highlight]) -> [Highlight] {
        let ranked = merged
            .filter { $0.duration >= minimumDuration }
            .sorted {
                priority($0.kind) == priority($1.kind)
                    ? $0.duration > $1.duration
                    : priority($0.kind) < priority($1.kind)
            }

        var kept: [Highlight] = []
        var total: TimeInterval = 0
        for highlight in ranked {
            guard kept.count < maximumCount else { break }
            guard total + highlight.duration <= maximumTotal else { continue }
            kept.append(highlight)
            total += highlight.duration
        }

        // Chronological, so the reel replays the game rather than a ranking.
        return kept.sorted {
            $0.turnIndex == $1.turnIndex ? $0.start < $1.start : $0.turnIndex < $1.turnIndex
        }
    }
}
