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
public protocol RemoteWordSource: Sendable {
    /// Words changed since `since`, at most `limit` of them, oldest first.
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
            if !page.hasMore || page.records.isEmpty {
                return WordSyncReport(pagesFetched: pages, recordsReceived: received,
                                      recordsWritten: written, completed: true)
            }
        }

        return WordSyncReport(pagesFetched: pages, recordsReceived: received,
                              recordsWritten: written, completed: false)
    }
}
