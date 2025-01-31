//
//  CoreDataManagerTests.swift
//  GamoitsaniTests
//
//  Created by Daviti Khvedelidze on 14/10/2024.
//  Copyright © 2024 Daviti Khvedelidze. All rights reserved.
//

import XCTest
import CoreData
@testable import Gamoitsani

final class CoreDataManagerTests: XCTestCase {
    
    var sut: CoreDataManager!
    var mockPersistentContainer: NSPersistentContainer!
    
    override func setUp() {
        super.setUp()
        mockPersistentContainer = MockPersistentContainer(name: "Gamoitsani")
        mockPersistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        sut = CoreDataManager.shared
        // No longer need to set context as it's private
    }
    
    override func tearDown() {
        sut = nil
        mockPersistentContainer = nil
        super.tearDown()
    }
    
    func testSaveWordsFromFirebase() async throws {
        // Given
        let firebaseWords = [
            WordFirebase(baseWord: "test",
                         categories: ["category"],
                         translations: ["en": WordFirebase.TranslationData(word: "test", difficulty: 1)],
                         lastUpdated: Date())
        ]
        
        // When
        let savedCount = try await sut.saveWordsFromFirebase(firebaseWords)
        
        // Then
        XCTAssertEqual(savedCount, 1)
        let words = await sut.fetchWordsFromCoreData(quantity: 10)
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.baseWord, "test")
    }
    
    func testFetchWordsFromCoreData() async {
        // Given
        let firebaseWords = [
            WordFirebase(baseWord: "test",
                         categories: ["category"],
                         translations: ["en": WordFirebase.TranslationData(word: "test", difficulty: 1)],
                         lastUpdated: Date())
        ]
        try? await sut.saveWordsFromFirebase(firebaseWords)
        
        // When
        let fetchedWords = await sut.fetchWordsFromCoreData()
        
        // Then
        XCTAssertEqual(fetchedWords.count, 1)
        XCTAssertEqual(fetchedWords.first?.baseWord, "test")
    }
}

@objc(MockPersistentContainer)
final class MockPersistentContainer: NSPersistentContainer, @unchecked Sendable {
    override class func defaultDirectoryURL() -> URL {
        return URL(fileURLWithPath: "/dev/null")
    }
}
