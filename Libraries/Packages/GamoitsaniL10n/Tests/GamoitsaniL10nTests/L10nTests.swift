import XCTest
@testable import GamoitsaniL10n

final class L10nTests: XCTestCase {
    func testResolvesAKeyFromThePackageCatalogue() {
        XCTAssertEqual(L10n.string("home.play"), "Game")
    }

    /// A missing key returns the key itself rather than crashing, which is what makes an
    /// untranslated string visible in the UI instead of silently blank.
    func testUnknownKeyReturnsTheKey() {
        XCTAssertEqual(L10n.string("no.such.key"), "no.such.key")
    }
}
