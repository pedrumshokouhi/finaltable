import XCTest
@testable import FTEngine

/// The deterministic plain-language probability renderer — asserted against the exact
/// phrases used in the sample scenarios (04_SAMPLE_SCENARIOS.md).
final class FriendlyProbabilityTests: XCTestCase {

    func testAboutOneInThree() {
        XCTAssertEqual(FriendlyProbability.describe(0.3497), "about 1 in 3")   // S2
    }

    func testABitOverOneInThree() {
        XCTAssertEqual(FriendlyProbability.describe(0.364), "a bit over 1 in 3")  // S5
    }

    func testAboutOneInFive() {
        XCTAssertEqual(FriendlyProbability.describe(0.204), "about 1 in 5")    // S7
    }

    func testAboutOneInTwentyThree() {
        XCTAssertEqual(FriendlyProbability.describe(0.044), "about 1 in 23")   // S3
    }

    func testAboutOneInTwentyNine() {
        XCTAssertEqual(FriendlyProbability.describe(0.0348), "about 1 in 29")  // S9
    }

    func testSlightlyBetterThanCoinFlip() {
        XCTAssertEqual(FriendlyProbability.describe(0.55), "slightly better than a coin flip")  // S6
    }

    func testAboutACoinFlip() {
        XCTAssertEqual(FriendlyProbability.describe(0.505), "about a coin flip")
    }

    func testSlightlyWorseThanCoinFlip() {
        XCTAssertEqual(FriendlyProbability.describe(0.45), "slightly worse than a coin flip")
    }

    func testJustUnderTwoInThree() {
        XCTAssertEqual(FriendlyProbability.describe(0.635), "just under 2 in 3")  // S4
    }

    func testExtremes() {
        XCTAssertEqual(FriendlyProbability.describe(0.001), "virtually never")
        XCTAssertEqual(FriendlyProbability.describe(0.999), "virtually certain")
    }

    func testBasisLabels() {
        XCTAssertTrue(CalculationBasis.exactEnumeration.label.contains("Exact"))
        XCTAssertTrue(CalculationBasis.seededSimulation(trials: 1000).label.contains("1000"))
        XCTAssertTrue(CalculationBasis.behavioralAssumption.label.contains("Assumption"))
    }

    func testProbabilityResultCarriesAssumptions() {
        let result = ProbabilityResult(
            exact: Rational(378, 1081),
            basis: .exactEnumeration,
            assumptions: ["Counts only your flush."]
        )
        XCTAssertEqual(result.estimate, 378.0 / 1081.0, accuracy: 1e-12)
        XCTAssertEqual(result.friendly, "about 1 in 3")
        XCTAssertEqual(result.assumptions.count, 1)
    }
}
