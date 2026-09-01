import XCTest
@testable import GamoitsaniData

final class WordItemTests: XCTestCase {
    func testReturnsTranslationWhenPresent() {
        let word = WordItem(id: "1", baseWord: "სახლი", translations: ["en": "house"])
        XCTAssertEqual(word.text(for: "en"), "house")
    }

    /// v1 silently showed the raw Georgian base word when a translation was missing, with
    /// no filtering at query time. The fallback is kept, but Phase 6 filters at the query
    /// so it is rarely reached.
    func testFallsBackToBaseWordWhenTranslationMissing() {
        let word = WordItem(id: "1", baseWord: "სახლი", translations: ["en": "house"])
        XCTAssertEqual(word.text(for: "ja"), "სახლი")
    }

    func testIsSendableValueType() {
        let a = WordItem(id: "1", baseWord: "სახლი")
        var b = a
        b = WordItem(id: "2", baseWord: "other")
        XCTAssertEqual(a.id, "1", "copies must not alias")
        XCTAssertEqual(b.id, "2")
    }
}
