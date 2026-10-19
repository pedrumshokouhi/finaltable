import XCTest
@testable import FTEngine

/// The §8 scoring formula: redistribution (C1), tiers, size bands, probability decay,
/// variable tags, the confidence table (C13), and stars (C3).
final class ScoringTests: XCTestCase {

    private let allComponents = Set(ScoreComponent.allCases)

    // MARK: Weight redistribution (C1)

    func testAllComponentsActiveUseBaseWeights() {
        let weights = ComponentWeights.redistributed(active: allComponents)
        XCTAssertEqual(weights[.decision], 400)
        XCTAssertEqual(weights[.size], 200)
        XCTAssertEqual(weights[.probability], 150)
        XCTAssertEqual(weights[.variables], 150)
        XCTAssertEqual(weights[.confidence], 100)
    }

    func testChapterOneRedistributionMatchesSpecExample() {
        // 01_SPEC §8.1: decision + variables + confidence → 615 / 231 / 154.
        let weights = ComponentWeights.redistributed(active: [.decision, .variables, .confidence])
        XCTAssertEqual(weights[.decision], 615)
        XCTAssertEqual(weights[.variables], 231)
        XCTAssertEqual(weights[.confidence], 154)
    }

    func testEverySubsetSumsToExactlyOneThousand() {
        let optional: [ScoreComponent] = [.size, .probability, .variables, .confidence]
        for mask in 0..<16 {
            var active: Set<ScoreComponent> = [.decision]
            for (bit, component) in optional.enumerated() where mask & (1 << bit) != 0 {
                active.insert(component)
            }
            let weights = ComponentWeights.redistributed(active: active)
            XCTAssertEqual(weights.values.reduce(0, +), 1000, "Subset \(active) must sum to 1000")
        }
    }

    // MARK: Decision component

    private func input(tier: DecisionTier, confidence: Confidence = .high) -> AttemptInput {
        AttemptInput(chosenTier: tier, confidence: confidence, activeComponents: [.decision, .confidence])
    }

    func testDecisionTierFractions() {
        XCTAssertEqual(DecisionTier.excellent.fraction, 1.0)
        XCTAssertEqual(DecisionTier.strong.fraction, 0.8)
        XCTAssertEqual(DecisionTier.defensible.fraction, 0.6)
        XCTAssertEqual(DecisionTier.weak.fraction, 0.3)
        XCTAssertEqual(DecisionTier.majorError.fraction, 0.0)
    }

    func testDecisionTierOrdering() {
        XCTAssertLessThan(DecisionTier.majorError, DecisionTier.weak)
        XCTAssertLessThan(DecisionTier.weak, DecisionTier.defensible)
        XCTAssertLessThan(DecisionTier.defensible, DecisionTier.strong)
        XCTAssertLessThan(DecisionTier.strong, DecisionTier.excellent)
    }

    func testFullScoreAtBaseWeights() {
        let result = PuzzleScorer.score(AttemptInput(
            chosenTier: .excellent,
            sizeFraction: 0.7, sizeBand: 0.65...1.0,
            probabilityEstimate: 35, probabilityTruth: 35,
            chosenVariables: ["a", "b"], variableKey: ["a", "b", "c"],
            confidence: .high,
            activeComponents: allComponents))
        XCTAssertEqual(result.components[.decision], 400)
        XCTAssertEqual(result.components[.size], 200)
        XCTAssertEqual(result.components[.probability], 150)
        XCTAssertEqual(result.components[.variables], 100)  // 2 of 3 correct: 100/150
        XCTAssertEqual(result.components[.confidence], 100)
        XCTAssertEqual(result.total, 950)
    }

    func testPerfectAttemptScoresExactlyOneThousand() {
        let result = PuzzleScorer.score(AttemptInput(
            chosenTier: .excellent,
            sizeFraction: 0.7, sizeBand: 0.65...1.0,
            probabilityEstimate: 35, probabilityTruth: 35,
            chosenVariables: ["a", "b", "c"], variableKey: ["a", "b", "c"],
            confidence: .high,
            activeComponents: allComponents))
        XCTAssertEqual(result.total, 1000)
        XCTAssertEqual(result.stars, 3)
    }

    // MARK: Size component (§8.3)

    func testSizeInsideBandFullCredit() {
        XCTAssertEqual(PuzzleScorer.sizeFraction(chosen: 0.7, band: 0.65...1.0), 1.0)
    }

    func testSizeAtBandEdgeFullCredit() {
        XCTAssertEqual(PuzzleScorer.sizeFraction(chosen: 0.65, band: 0.65...1.0), 1.0)
    }

    func testSizeOutsideBandDecaysLinearly() {
        // Band width 0.35; at distance 0.35 (one width) below: 1 − 0.35/0.70 = 0.5.
        XCTAssertEqual(PuzzleScorer.sizeFraction(chosen: 0.30, band: 0.65...1.0), 0.5, accuracy: 1e-9)
    }

    func testSizeFarOutsideBandIsZero() {
        // Distance ≥ 2× width → 0.
        XCTAssertEqual(PuzzleScorer.sizeFraction(chosen: 2.0, band: 0.65...1.0), 0, accuracy: 1e-9)
    }

    func testMissingSizeScoresZero() {
        XCTAssertEqual(PuzzleScorer.sizeFraction(chosen: nil, band: 0.65...1.0), 0)
    }

    // MARK: Probability component (§8.5)

    func testProbabilityWithinThreePointsFullCredit() {
        XCTAssertEqual(PuzzleScorer.probabilityFraction(estimate: 33, truth: 35), 1.0)
    }

    func testProbabilityLinearDecayMidpoint() {
        // Diff 11.5 → (20 − 11.5) / 17 = 0.5.
        XCTAssertEqual(PuzzleScorer.probabilityFraction(estimate: 46.5, truth: 35), 0.5, accuracy: 1e-9)
    }

    func testProbabilityBeyondTwentyPointsZero() {
        XCTAssertEqual(PuzzleScorer.probabilityFraction(estimate: 60, truth: 35), 0)
    }

    func testProbabilityMissingInputsScoreZero() {
        XCTAssertEqual(PuzzleScorer.probabilityFraction(estimate: nil, truth: 35), 0)
    }

    // MARK: Variables component (§8.4)

    func testVariablesAllCorrect() {
        XCTAssertEqual(PuzzleScorer.variablesFraction(chosen: ["a", "b", "c"], key: ["a", "b", "c"]), 1.0)
    }

    func testVariablesMixedPicks() {
        // 2 correct (+100), 1 wrong (−25) → 75/150.
        XCTAssertEqual(PuzzleScorer.variablesFraction(chosen: ["a", "b", "x"], key: ["a", "b", "c"]), 0.5)
    }

    func testVariablesFlooredAtZero() {
        XCTAssertEqual(PuzzleScorer.variablesFraction(chosen: ["x", "y", "z"], key: ["a", "b"]), 0)
    }

    func testVariablesEmptyPickScoresZero() {
        XCTAssertEqual(PuzzleScorer.variablesFraction(chosen: [], key: ["a", "b"]), 0)
    }

    func testTwoCorrectOfTwoKeyIsCapNormalized() {
        // 2 correct with a 2-tag key → 100/150 of the base (cap applies at 150).
        XCTAssertEqual(PuzzleScorer.variablesFraction(chosen: ["a", "b"], key: ["a", "b"]), 100.0 / 150.0, accuracy: 1e-9)
    }

    // MARK: Confidence table (C13)

    func testConfidenceTableMatchesSpec() {
        // Rows: high / medium / low. Columns: strong+ / defensible / weak-or-worse.
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.high, tier: .excellent), 1.0)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.high, tier: .strong), 1.0)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.high, tier: .defensible), 0.4)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.high, tier: .majorError), 0.0)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.medium, tier: .strong), 0.7)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.medium, tier: .defensible), 1.0)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.medium, tier: .weak), 0.4)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.low, tier: .excellent), 0.4)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.low, tier: .defensible), 0.7)
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.low, tier: .weak), 1.0)
    }

    func testOverconfidentMajorErrorIsWorstCell() {
        XCTAssertEqual(PuzzleScorer.confidenceFraction(.high, tier: .majorError), 0)
        XCTAssertGreaterThan(PuzzleScorer.confidenceFraction(.low, tier: .majorError), 0)
    }

    // MARK: Stars (C3 / §8.6)

    func testThreeStarsRequireExcellentAndHighTotal() {
        XCTAssertEqual(StarRule.stars(tier: .excellent, total: 850), 3)
        XCTAssertEqual(StarRule.stars(tier: .excellent, total: 849), 2)
        XCTAssertEqual(StarRule.stars(tier: .strong, total: 990), 2, "Strong can never reach 3 stars")
    }

    func testTwoStars() {
        XCTAssertEqual(StarRule.stars(tier: .strong, total: 650), 2)
        XCTAssertEqual(StarRule.stars(tier: .strong, total: 649), 1)
    }

    func testOneStar() {
        XCTAssertEqual(StarRule.stars(tier: .defensible, total: 400), 1)
        XCTAssertEqual(StarRule.stars(tier: .defensible, total: 900), 1, "Defensible caps at 1 star")
    }

    func testZeroStars() {
        XCTAssertEqual(StarRule.stars(tier: .majorError, total: 999), 0)
        XCTAssertEqual(StarRule.stars(tier: .weak, total: 500), 0)
        XCTAssertEqual(StarRule.stars(tier: .excellent, total: 700), 2, "Excellent below 850 but ≥650 earns 2")
        XCTAssertEqual(StarRule.stars(tier: .excellent, total: 399), 0, "Even Excellent needs ≥400 total for a star")
    }

    func testScoreBreakdownCarriesTierAndStars() {
        let result = PuzzleScorer.score(input(tier: .excellent))
        XCTAssertEqual(result.tier, .excellent)
        XCTAssertEqual(result.total, 1000)  // decision 800 + confidence 200 redistributed
        XCTAssertEqual(result.stars, 3)
    }

    func testWeakDecisionScoresLowRegardlessOfCalibration() {
        let result = PuzzleScorer.score(AttemptInput(
            chosenTier: .weak,
            probabilityEstimate: 35, probabilityTruth: 35,
            chosenVariables: ["a"], variableKey: ["a"],
            confidence: .low,
            activeComponents: [.decision, .probability, .variables, .confidence]))
        XCTAssertEqual(result.stars, 0)
        XCTAssertLessThan(result.total, 650)
    }
}
