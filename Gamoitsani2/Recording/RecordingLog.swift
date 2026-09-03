//
//  RecordingLog.swift
//  Gamoitsani2
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

    private static let logger = Logger(subsystem: "davitikhvedelidze.Gamoitsani2", category: "recording")

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

    private static func stamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    #endif
}
