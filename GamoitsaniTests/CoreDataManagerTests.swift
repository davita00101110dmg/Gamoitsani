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
        sut.context = mockPersistentContainer.viewContext
    }

    override func tearDown() {
        sut = nil
        mockPersistentContainer = nil
        super.tearDown()
    }

    func testSaveWordsFromFirebase() {
        // Given
        let firebaseWords = [
            WordFirebase(baseWord: "test", categories: ["category"], translations: ["en": WordFirebase.TranslationData(word: "test", difficulty: 1)], lastUpdated: Date())
        ]

        // When
        let savedCount = sut.saveWordsFromFirebase(firebaseWords)

        // Then
        XCTAssertEqual(savedCount, 1)
        
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        let words = try? sut.context.fetch(fetchRequest)
        XCTAssertEqual(words?.count, 1)
        XCTAssertEqual(words?.first?.baseWord, "test")
    }

    func testFetchWordsFromCoreData() {
        // Given
        let word = Word(context: sut.context)
        word.baseWord = "test"
        word.categories = ["category"]
        word.last_updated = Date()
        try? sut.context.save()

        // When
        let fetchedWords = sut.fetchWordsFromCoreData()

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
