//
//  WordSyncTests.swift
//  GamoitsaniDataTests
//

import Testing
import Foundation
@testable import GamoitsaniData

/// A scriptable server. The whole reason RemoteWordSource is a protocol: the sync logic is
/// tested with no Firebase, no network and no waiting.
private actor FakeRemote: RemoteWordSource {
    private let all: [WordRecord]
    private(set) var requests: [(since: Date?, limit: Int)] = []
    private let failAfter: Int?

    init(all: [WordRecord], failAfter: Int? = nil) {
        self.all = all.sorted { $0.updatedAt < $1.updatedAt }
        self.failAfter = failAfter
    }

    struct Boom: Error {}

    func words(since: Date?, limit: Int) async throws -> WordPage {
        requests.append((since, limit))
        if let failAfter, requests.count > failAfter { throw Boom() }

        let newer = all.filter { record in
            guard let since else { return true }
            return record.updatedAt > since
        }
        let page = Array(newer.prefix(limit))
        return WordPage(records: page, hasMore: page.count < newer.count)
    }

    func requestCount() -> Int { requests.count }
    func allRequests() -> [(since: Date?, limit: Int)] { requests }
}

/// Serialized because each case builds its own in-memory `ModelContainer`, and creating
/// several concurrently crashes the SwiftData stack. Swift Testing runs cases in parallel
/// by default, which is right for the pure-domain suites but not here.
@Suite("Word sync", .serialized)
struct WordSyncTests {

    private let t0 = Date(timeIntervalSince1970: 1_000_000)

    private func records(_ n: Int) -> [WordRecord] {
        (0..<n).map {
            WordRecord(id: "w\($0)", baseWord: "ქ\($0)",
                       translations: ["en": "w\($0)"],
                       updatedAt: t0.addingTimeInterval(TimeInterval($0)))
        }
    }

    /// v1 downloaded the entire collection in one request with no limit, order or cursor —
    /// on a fresh install `since` was 1970. Dying at 90% lost everything.
    @Test("a large catalogue arrives in pages, not one request")
    func pagination() async throws {
        let remote = FakeRemote(all: records(1200))
        let store = try WordStoreFactory.makeInMemory()
        let sync = WordSync(remote: remote, store: store, pageSize: 500)

        let report = try await sync.run()

        #expect(report.completed)
        #expect(report.pagesFetched == 3, "1200 words at 500 a page")
        #expect(report.recordsWritten == 1200)
        #expect(try await store.count() == 1200)
    }

    @Test("each page resumes from what actually landed")
    func checkpointAdvances() async throws {
        let remote = FakeRemote(all: records(1000))
        let store = try WordStoreFactory.makeInMemory()
        try await WordSync(remote: remote, store: store, pageSize: 400).run()

        let requests = await remote.allRequests()
        #expect(requests.first?.since == nil, "first request has no checkpoint")
        // Later requests carry the newest updatedAt already imported.
        #expect(requests.dropFirst().allSatisfy { $0.since != nil })
        #expect(requests[1].since == t0.addingTimeInterval(399))
    }

    /// The important property: an interrupted sync keeps everything already written and
    /// resumes from there, rather than losing the lot.
    @Test("a failure part-way keeps what was already imported")
    func partialSyncSurvives() async throws {
        let remote = FakeRemote(all: records(1500), failAfter: 2)
        let store = try WordStoreFactory.makeInMemory()
        let sync = WordSync(remote: remote, store: store, pageSize: 500)

        await #expect(throws: FakeRemote.Boom.self) { try await sync.run() }
        #expect(try await store.count() == 1000, "two pages landed before the failure")

        // A later attempt against a healthy server resumes rather than restarting.
        let healthy = FakeRemote(all: records(1500))
        let resumed = try await WordSync(remote: healthy, store: store, pageSize: 500).run()
        #expect(resumed.completed)
        #expect(try await store.count() == 1500)
        let first = await healthy.allRequests().first
        #expect(first?.since == t0.addingTimeInterval(999), "resumed from the checkpoint")
    }

    @Test("a sync with nothing new writes nothing")
    func noOpSync() async throws {
        let remote = FakeRemote(all: records(50))
        let store = try WordStoreFactory.makeInMemory()
        try await WordSync(remote: remote, store: store, pageSize: 500).run()

        let second = try await WordSync(remote: remote, store: store, pageSize: 500).run()
        #expect(second.recordsWritten == 0)
        #expect(second.completed)
    }

    @Test("an empty server is handled without looping")
    func emptyServer() async throws {
        let remote = FakeRemote(all: [])
        let store = try WordStoreFactory.makeInMemory()
        let report = try await WordSync(remote: remote, store: store).run()
        #expect(report.completed)
        #expect(report.recordsReceived == 0)
        #expect(try await store.count() == 0)
    }

    @Test("maxPages bounds the work and reports the sync as unfinished")
    func maxPages() async throws {
        let remote = FakeRemote(all: records(1000))
        let store = try WordStoreFactory.makeInMemory()
        let report = try await WordSync(remote: remote, store: store, pageSize: 100).run(maxPages: 3)

        #expect(report.completed == false)
        #expect(report.pagesFetched == 3)
        #expect(try await store.count() == 300)
    }
}
