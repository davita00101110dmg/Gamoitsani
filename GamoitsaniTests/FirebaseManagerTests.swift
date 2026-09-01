//
//  FirebaseManagerTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 19/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import XCTest
@testable import Gamoitsani
import FirebaseFirestore

final class FirebaseManagerTests: XCTestCase {

    var sut: FirebaseManager!
    var mockCoreDataManager: MockCoreDataManager!

    override func setUp() {
        super.setUp()
        sut = FirebaseManager.shared
        mockCoreDataManager = MockCoreDataManager()
        sut.coreDataManager = mockCoreDataManager

        // Default to a successful remote fetch. Previously there was no seam here at all,
        // so every case below went to the live Firestore database over the network: the
        // results depended on reachability, on the collection names in whichever
        // Config.xcconfig was present, and on the deployed security rules. On CI, which
        // builds from Config.xcconfig.template, the reads were denied and these tests
        // failed while passing locally.
        sut.remoteWordFetcher = { _ in [] }
    }

    override func tearDown() {
        sut.remoteWordFetcher = nil
        sut.coreDataManager = CoreDataManager.shared
        sut = nil
        mockCoreDataManager = nil
        super.tearDown()
    }

    private func makeWord(_ baseWord: String) -> WordFirebase {
        WordFirebase(
            baseWord: baseWord,
            categories: [],
            translations: [:],
            lastUpdated: Date(),
            isGeorgianOrigin: nil,
            formalityLevel: nil,
            isProperNoun: nil,
            wordType: nil,
            isAbstract: nil,
            ageAppropriateness: nil,
            relatedWords: nil
        )
    }

    // MARK: - Sync is skipped inside the interval

    func testFetchWordsIfNeeded_WithinOneWeek() {
        let initialDate = Date()
        sut.currentDate = initialDate
        AppSettings.lastWordSyncDate = initialDate.timeIntervalSince1970

        let expectation = self.expectation(description: "Fetch words within one week")

        sut.currentDate = initialDate.addingTimeInterval(.day * 6)
        sut.fetchWordsIfNeeded { words in
            XCTAssertFalse(words.isEmpty)
            XCTAssertEqual(AppSettings.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertFalse(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        } onStorageWarning: { }

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - A successful sync stamps the date

    func testFetchWordsIfNeeded_AfterOneWeek() {
        let initialDate = Date()
        sut.currentDate = initialDate
        AppSettings.lastWordSyncDate = initialDate.timeIntervalSince1970
        sut.remoteWordFetcher = { _ in [self.makeWord("test")] }

        let expectation = self.expectation(description: "Fetch words after one week")

        sut.currentDate = initialDate.addingTimeInterval(.week + .day)
        sut.fetchWordsIfNeeded { words in
            XCTAssertFalse(words.isEmpty)
            XCTAssertGreaterThan(AppSettings.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertTrue(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        } onStorageWarning: { }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testFetchWordsIfNeeded_ExactlyOneWeek() {
        let initialDate = Date()
        sut.currentDate = initialDate
        AppSettings.lastWordSyncDate = initialDate.timeIntervalSince1970

        let expectation = self.expectation(description: "Fetch words exactly one week later")

        sut.currentDate = initialDate.addingTimeInterval(7 * 24 * 60 * 60)
        sut.fetchWordsIfNeeded { words in
            XCTAssertFalse(words.isEmpty)
            XCTAssertGreaterThan(AppSettings.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertTrue(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        } onStorageWarning: { }

        waitForExpectations(timeout: 2, handler: nil)
    }

    // MARK: - A failed sync must not stamp the date

    /// The regression test for the bug this file previously asserted *into* existence.
    ///
    /// fetchWordsFromFirebase used to return [] both for "no words newer than this date"
    /// and for "the request failed after 3 retries". The caller could not tell them apart,
    /// so a total failure looked like a successful no-op sync, stamped lastWordSyncDate,
    /// and suppressed any retry for a week. The old versions of the two tests above
    /// asserted that the stamp happened regardless — they encoded the bug.
    func testFetchWordsIfNeeded_FailedFetchDoesNotStampSyncDate() {
        let initialDate = Date()
        sut.currentDate = initialDate
        AppSettings.lastWordSyncDate = initialDate.timeIntervalSince1970
        sut.remoteWordFetcher = { _ in nil }   // nil == the fetch failed

        let expectation = self.expectation(description: "Failed fetch leaves the sync date alone")

        sut.currentDate = initialDate.addingTimeInterval(.week + .day)
        sut.fetchWordsIfNeeded { words in
            XCTAssertEqual(
                AppSettings.lastWordSyncDate,
                initialDate.timeIntervalSince1970,
                "a failed sync must not stamp lastWordSyncDate, or the next attempt is suppressed for a week"
            )
            XCTAssertFalse(
                self.mockCoreDataManager.saveWordsFromFirebaseCalled,
                "nothing was fetched, so nothing should have been saved"
            )
            XCTAssertFalse(words.isEmpty, "cached words should still be served so the game stays playable")
            expectation.fulfill()
        } onStorageWarning: { }

        waitForExpectations(timeout: 2, handler: nil)
    }

    /// An empty-but-successful sync is a real no-op and *should* stamp, otherwise the app
    /// would re-query every launch once the catalogue stops changing.
    func testFetchWordsIfNeeded_EmptySuccessfulFetchStillStampsSyncDate() {
        let initialDate = Date()
        sut.currentDate = initialDate
        AppSettings.lastWordSyncDate = initialDate.timeIntervalSince1970
        sut.remoteWordFetcher = { _ in [] }

        let expectation = self.expectation(description: "Empty success stamps")

        sut.currentDate = initialDate.addingTimeInterval(.week + .day)
        sut.fetchWordsIfNeeded { _ in
            XCTAssertGreaterThan(AppSettings.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertTrue(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        } onStorageWarning: { }

        waitForExpectations(timeout: 2, handler: nil)
    }
}

final class MockCoreDataManager: CoreDataManaging {
    var saveWordsFromFirebaseCalled = false

    func saveWordsFromFirebase(_ words: [WordFirebase]) -> Int {
        saveWordsFromFirebaseCalled = true
        return words.count
    }

    func fetchWordsFromCoreData(quantity: Int = 1500) -> [Word] {
        let dummyWords: [Word] = .init(repeating: .init(), count: 5)
        return dummyWords
    }
}
