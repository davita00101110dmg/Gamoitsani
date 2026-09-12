//
//  RecordingLog.swift
//  Gamoitsani
//
import Foundation
import os

/// A trail of what the recorder actually did, on disk and in Console.
///
/// The recording path spans four hops — a serial capture queue, an `AVFoundation`
/// delegate, an export and the photo library — and every one of them can fail by quietly
/// doing nothing. Three rounds of this were lost to inferring which hop had gone wrong
/// from the fact that no file appeared. This writes it down instead.
///
/// Debug only, and capped, so it cannot grow without bound on a device.
enum RecordingLog {

    // Read rather than hardcoded: a literal here silently kept pointing at the pre-cutover
    // bundle id, which routes the subsystem to a name nothing else uses.
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "davitikhvedelidze.Gamoitsani",
        category: "recording"
    )

    #if DEBUG
    private static let queue = DispatchQueue(label: "gamoitsani.recording.log")
    private static let maximumBytes = 256 * 1024

    static var fileURL: URL {
        PendingClipStore.directory.appendingPathComponent("recording.log")
    }
    #endif

    static func note(_ message: @autoclosure () -> String) {
        let text = message()
        logger.info("\(text, privacy: .public)")

        #if DEBUG
        let line = "\(Self.stamp()) \(text)\n"
        queue.async {
            guard let data = line.data(using: .utf8) else { return }
            let url = fileURL

            if let handle = try? FileHandle(forWritingTo: url) {
                defer { try? handle.close() }
                // Truncate rather than rotate: this is a debugging aid, and the recent end
                // is the useful end.
                if (try? handle.seekToEnd()).map({ $0 > maximumBytes }) == true {
                    try? handle.truncate(atOffset: 0)
                }
                try? handle.write(contentsOf: data)
            } else {
                try? data.write(to: url)
            }
        }
        #endif
    }

    #if DEBUG
    static func contents() -> String {
        (try? String(contentsOf: fileURL, encoding: .utf8)) ?? "(empty)"
    }

    static func clear() {
        queue.async { try? FileManager.default.removeItem(at: fileURL) }
    }

    /// Deliberately verbatim and not localised: a log is read against wall-clock time, and
    /// the format should not change with the phone's region. Built once — a `DateFormatter`
    /// per line is an expensive way to stamp something written on every camera event.
    private static let stampStyle = Date.VerbatimFormatStyle(
        format: """
            \(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\
            \(minute: .twoDigits):\(second: .twoDigits).\(secondFraction: .fractional(3))
            """,
        timeZone: .current,
        calendar: .current
    )

    private static func stamp() -> String {
        Date().formatted(stampStyle)
    }
    #endif
}
