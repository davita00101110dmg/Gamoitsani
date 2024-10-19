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
    }

    override func tearDown() {
        sut = nil
        mockCoreDataManager = nil
        super.tearDown()
    }

    func testFetchWordsIfNeeded_WithinOneWeek() {
        // Given
        let initialDate = Date()
        sut.currentDate = initialDate
        UserDefaults.lastWordSyncDate = initialDate.timeIntervalSince1970
        
        let expectation = self.expectation(description: "Fetch words within one week")
        
        // When
        sut.currentDate = initialDate.addingTimeInterval(.day * 6)
        sut.fetchWordsIfNeeded { words in
            // Then
            XCTAssertFalse(words.isEmpty)
            XCTAssertEqual(UserDefaults.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertFalse(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchWordsIfNeeded_AfterOneWeek() {
        // Given
        let initialDate = Date()
        sut.currentDate = initialDate
        UserDefaults.lastWordSyncDate = initialDate.timeIntervalSince1970
        
        let expectation = self.expectation(description: "Fetch words after one week")
        
        // When
        sut.currentDate = initialDate.addingTimeInterval(.week + .day) // 8 days later
        sut.fetchWordsIfNeeded { words in
            // Then
            XCTAssertFalse(words.isEmpty) // Assuming no words fetched for this test
            XCTAssertGreaterThan(UserDefaults.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertTrue(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
    }

    func testFetchWordsIfNeeded_ExactlyOneWeek() {
        // Given
        let initialDate = Date()
        sut.currentDate = initialDate
        UserDefaults.lastWordSyncDate = initialDate.timeIntervalSince1970
        
        let expectation = self.expectation(description: "Fetch words exactly one week later")
        
        // When
        sut.currentDate = initialDate.addingTimeInterval(7 * 24 * 60 * 60) // Exactly 7 days later
        sut.fetchWordsIfNeeded { words in
            // Then
            XCTAssertFalse(words.isEmpty) // Assuming no words fetched for this test
            XCTAssertGreaterThan(UserDefaults.lastWordSyncDate, initialDate.timeIntervalSince1970)
            XCTAssertTrue(self.mockCoreDataManager.saveWordsFromFirebaseCalled)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1, handler: nil)
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
