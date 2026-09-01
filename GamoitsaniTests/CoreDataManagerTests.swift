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
    var container: NSPersistentContainer!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // A private, in-memory store per test. The previous version of this file built a
        // MockPersistentContainer, never injected it, and pointed `sut` at
        // CoreDataManager.shared — so it read and wrote the app's real word database.
        let model = try XCTUnwrap(
            NSManagedObjectModel.mergedModel(from: [Bundle(for: CoreDataManager.self)]),
            "could not load the Gamoitsani managed object model from the app bundle"
        )
        container = NSPersistentContainer(name: "Gamoitsani", managedObjectModel: model)

        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }

        sut = CoreDataManager(container: container)
    }

    override func tearDown() {
        sut = nil
        container = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Builds a WordFirebase without spelling out all 11 fields at every call site.
    /// Adding a field to the struct used to break every construction in this file — that
    /// is exactly how these tests stopped compiling.
    private func makeWord(
        baseWord: String = "test",
        categories: [String] = ["category"],
        translations: [String: WordFirebase.TranslationData] = ["en": .init(word: "test", difficulty: 1)],
        lastUpdated: Date = Date(),
        isGeorgianOrigin: Bool? = nil,
        formalityLevel: Int? = nil,
        isProperNoun: Bool? = nil,
        wordType: String? = nil,
        isAbstract: Bool? = nil,
        ageAppropriateness: String? = nil,
        relatedWords: [String]? = nil
    ) -> WordFirebase {
        WordFirebase(
            baseWord: baseWord,
            categories: categories,
            translations: translations,
            lastUpdated: lastUpdated,
            isGeorgianOrigin: isGeorgianOrigin,
            formalityLevel: formalityLevel,
            isProperNoun: isProperNoun,
            wordType: wordType,
            isAbstract: isAbstract,
            ageAppropriateness: ageAppropriateness,
            relatedWords: relatedWords
        )
    }

    // MARK: - Tests

    func testSaveWordsFromFirebaseReturnsSavedCount() async throws {
        let savedCount = try await sut.saveWordsFromFirebase([makeWord()])

        XCTAssertEqual(savedCount, 1)

        let words = await sut.fetchWordsFromCoreData(quantity: 10)
        XCTAssertEqual(words.count, 1)
        XCTAssertEqual(words.first?.baseWord, "test")
    }

    func testFetchWordsFromCoreDataReturnsSavedWords() async throws {
        try await sut.saveWordsFromFirebase([makeWord()])

        let fetchedWords = await sut.fetchWordsFromCoreData(quantity: 10)

        XCTAssertEqual(fetchedWords.count, 1)
        XCTAssertEqual(fetchedWords.first?.baseWord, "test")
    }

    func testSaveWordsFromFirebaseUpdatesRatherThanDuplicating() async throws {
        try await sut.saveWordsFromFirebase([makeWord(categories: ["first"])])
        try await sut.saveWordsFromFirebase([makeWord(categories: ["second"])])

        let words = await sut.fetchWordsFromCoreData(quantity: 10)

        XCTAssertEqual(words.count, 1, "same baseWord should update in place, not insert a second row")
        XCTAssertEqual(words.first?.categories, ["second"])
    }

    func testSaveWordsFromFirebasePersistsMetadataFields() async throws {
        try await sut.saveWordsFromFirebase([
            makeWord(
                isGeorgianOrigin: true,
                formalityLevel: 3,
                isProperNoun: true,
                wordType: "noun",
                isAbstract: true,
                ageAppropriateness: "all"
            )
        ])

        let words = await sut.fetchWordsFromCoreData(quantity: 10)
        let word = try XCTUnwrap(words.first)

        XCTAssertTrue(word.isGeorgianOrigin)
        XCTAssertEqual(word.formalityLevel, 3)
        XCTAssertTrue(word.isProperNoun)
        XCTAssertEqual(word.wordType, "noun")
        XCTAssertTrue(word.isAbstract)
        XCTAssertEqual(word.ageAppropriateness, "all")
    }

    func testSaveWordsFromFirebaseAppliesDefaultsForMissingMetadata() async throws {
        try await sut.saveWordsFromFirebase([makeWord()])

        let words = await sut.fetchWordsFromCoreData(quantity: 10)
        let word = try XCTUnwrap(words.first)

        XCTAssertFalse(word.isGeorgianOrigin)
        XCTAssertEqual(word.formalityLevel, 2, "formalityLevel should default to 2 when absent")
        XCTAssertFalse(word.isProperNoun)
    }

    func testFetchWordsFromCoreDataRespectsQuantityLimit() async throws {
        let words = (0..<10).map { makeWord(baseWord: "word-\($0)") }
        try await sut.saveWordsFromFirebase(words)

        let fetched = await sut.fetchWordsFromCoreData(quantity: 4)

        XCTAssertEqual(fetched.count, 4)
    }

    func testFetchWordsFromEmptyStoreReturnsNothing() async {
        let fetched = await sut.fetchWordsFromCoreData(quantity: 10)

        XCTAssertTrue(fetched.isEmpty)
    }
}
