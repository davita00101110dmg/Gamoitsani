//
//  WordSync.swift
//  GamoitsaniData
//

import Foundation

/// One page of words from the server.
public struct WordPage: Sendable, Hashable {
    public let records: [WordRecord]
    /// Whether the server has more after this page.
    public let hasMore: Bool

    public init(records: [WordRecord], hasMore: Bool) {
        self.records = records
        self.hasMore = hasMore
    }
}

/// Where words come from.
///
/// A protocol, so this package never imports Firebase. The Firestore implementation lives
/// in the app, which keeps the data layer testable with a fake and keeps the SDK out of a
/// package that is otherwise pure Foundation and SwiftData.
public protocol RemoteWordSource: Sendable {
    /// Words changed since `since`, at most `limit` of them, oldest first.
    ///
    /// Ordering matters: pages must be ordered by `updatedAt` ascending so that an
    /// interrupted sync leaves a coherent checkpoint. v1 ordered by nothing at all.
    func words(since: Date?, limit: Int) async throws -> WordPage
}

public enum WordSyncError: Error, Sendable {
    case cancelled
}

/// Result of a sync attempt.
public struct WordSyncReport: Sendable, Hashable {
    public let pagesFetched: Int
    public let recordsReceived: Int
    public let recordsWritten: Int
    public let completed: Bool

    public init(pagesFetched: Int, recordsReceived: Int, recordsWritten: Int, completed: Bool) {
        self.pagesFetched = pagesFetched
        self.recordsReceived = recordsReceived
        self.recordsWritten = recordsWritten
        self.completed = completed
    }
}

/// Pulls words from the server into the cache.
///
/// Fixes the two worst things about v1's sync:
///
/// - **It was unbounded.** `fetchWordsFromFirebase` issued
///   `whereField("last_updated", isGreaterThan: date)` with no `limit`, no `order` and no
///   cursor. On a fresh install `lastWordSyncDate` was `0.0`, so `since` was 1970 and the
///   *entire* collection was downloaded, decoded and imported in a single request. If it
///   died at 90% everything was lost.
/// - **A failure could look like success.** The checkpoint was a UserDefaults timestamp
///   stamped by the caller; here it is derived from what is actually in the cache, so an
///   interrupted sync resumes from the last row that genuinely landed.
public struct WordSync: Sendable {

    public static let defaultPageSize = 500

    private let remote: RemoteWordSource
    private let store: WordStore
    private let pageSize: Int

    public init(remote: RemoteWordSource, store: WordStore, pageSize: Int = defaultPageSize) {
        self.remote = remote
        self.store = store
        self.pageSize = pageSize
    }

    /// Syncs until the server has nothing newer.
    ///
    /// Each page is written before the next is requested, so cancelling or losing the
    /// network keeps everything already imported. Cooperative cancellation is honoured
    /// between pages.
    @discardableResult
    public func run(maxPages: Int = .max) async throws -> WordSyncReport {
        var pages = 0
        var received = 0
        var written = 0

        while pages < maxPages {
            try Task.checkCancellation()

            let checkpoint = try await store.latestUpdatedAt()
            let page = try await remote.words(since: checkpoint, limit: pageSize)

            pages += 1
            received += page.records.count

            if !page.records.isEmpty {
                written += try await store.upsert(page.records)
            }

            // Stop when the server says there is no more, or when a page brought nothing
            // new — the latter guards against a server that keeps returning the same rows
            // and would otherwise loop forever.
            if !page.hasMore || page.records.isEmpty {
                return WordSyncReport(pagesFetched: pages, recordsReceived: received,
                                      recordsWritten: written, completed: true)
            }
        }

        return WordSyncReport(pagesFetched: pages, recordsReceived: received,
                              recordsWritten: written, completed: false)
    }
}
