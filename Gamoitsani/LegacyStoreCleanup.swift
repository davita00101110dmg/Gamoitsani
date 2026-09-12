//
//  LegacyStoreCleanup.swift
//  Gamoitsani
//
import Foundation
import OSLog

/// Removes v1's Core Data store, orphaned by cutover.
///
/// Taking v1's bundle id also takes its container, and v1 left an `NSPersistentContainer`
/// named `Gamoitsani` in Application Support. 2.0 has no Core Data and will never open it,
/// so without this it sits on a user's device forever — it was only ever a disposable word
/// cache, and the words now ship in the bundle.
///
/// Self-terminating rather than flag-guarded: once the files are gone the existence checks
/// find nothing, so there is no extra key to reason about and nothing to migrate later if
/// the flag's meaning ever changed.
enum LegacyStoreCleanup {

    private static let log = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "davitikhvedelidze.Gamoitsani",
        category: "cutover"
    )

    /// v1's `NSPersistentContainer(name:)`, which is also the store's filename.
    private static let storeName = "Gamoitsani"

    /// SQLite keeps the write-ahead log and shared memory beside the store. Deleting only
    /// the `.sqlite` leaves two files behind that are individually useless.
    private static let suffixes = ["sqlite", "sqlite-wal", "sqlite-shm"]

    static func run(fileManager: FileManager = .default) {
        guard let support = try? fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: false
        ) else { return }

        var removed = 0
        for suffix in suffixes {
            let url = support.appendingPathComponent("\(storeName).\(suffix)")
            guard fileManager.fileExists(atPath: url.path) else { continue }
            do {
                try fileManager.removeItem(at: url)
                removed += 1
            } catch {
                // Not fatal: a file we cannot delete costs disk, not correctness.
                log.error("could not remove \(suffix, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        if removed > 0 {
            log.notice("removed \(removed, privacy: .public) v1 Core Data file(s)")
        }
    }
}
