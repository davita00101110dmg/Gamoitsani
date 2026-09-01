import XCTest
@testable import GamoitsaniCore

final class ScoringTests: XCTestCase {
    func testCorrectGuessScoresOne() {
        XCTAssertEqual(Scoring.points(for: .correct), 1)
    }

    func testSkipCostsAPoint() {
        XCTAssertEqual(Scoring.points(for: .skipped), -1)
    }

    func testTeamsAreIdentifiedByIdNotPosition() {
        // v1 keyed per-team state by array index, so reordering teams moved their data.
        let a = Team(name: "A")
        let b = Team(name: "A")
        XCTAssertNotEqual(a.id, b.id, "same name must not mean same team")
    }
}
