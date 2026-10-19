import XCTest
@testable import FTEngine

/// Scenario validation rules (02_SCHEMAS.md §1.2) — including malformed-data cases.
final class ValidatorTests: XCTestCase {

    /// A minimal valid scenario (based on L027, the schema's worked example).
    private func makeScenario(
        playerCards: [Card] = cs("Kh Th"),
        sharedCards: [Card] = cs("Qs Jh 4d"),
        street: Street = .threeShared,
        seats: [PlayerSeat]? = nil,
        actionHistory: [ActionRecord]? = nil,
        difficulty: Int = 4,
        options: [GameActionType] = [.withdraw, .match, .challenge],
        tiers: [String: DecisionTier]? = nil,
        sizeBand: [Double]? = nil
    ) -> Scenario {
        Scenario(
            id: "TEST",
            chapter: 3,
            title: "Test",
            learningObjective: "Test objective",
            difficulty: difficulty,
            skillTags: ["position"],
            deal: DealState(playerCards: playerCards, sharedCards: sharedCards, street: street),
            table: TableState(
                seats: seats ?? [
                    PlayerSeat(seat: 0, position: .final, stack: 4200, profile: nil, status: .active),
                    PlayerSeat(seat: 1, position: .early, stack: 3100, profile: .cautious, status: .withdrawn),
                    PlayerSeat(seat: 2, position: .middle, stack: 5600, profile: .aggressive, status: .active)
                ],
                pool: 900,
                requirement: 300),
            actionHistory: actionHistory ?? [
                ActionRecord(seat: 1, action: .withdraw),
                ActionRecord(seat: 2, action: .challenge, size: 300)
            ],
            objective: "Decide.",
            decisionSpec: DecisionSpec(options: options, activeComponents: [.decision, .confidence]),
            solution: PuzzleSolution(
                recommended: RecommendedDecision(action: .match),
                tiers: tiers ?? ["match": .excellent, "withdraw": .defensible, "challenge": .weak],
                sizeBand: sizeBand,
                probabilityKey: nil,
                variableKey: ["position"],
                distractorVariables: ["stackDepth"]),
            explanations: Explanations(quick: "Q", coach: "C", commonMistake: "M", takeaway: "T"),
            variation: nil)
    }

    func testValidScenarioPasses() {
        XCTAssertEqual(ScenarioValidator.errors(makeScenario()), [])
        XCTAssertNoThrow(try ScenarioValidator.validate(makeScenario()))
    }

    func testDuplicateCardDetected() {
        let scenario = makeScenario(playerCards: cs("Kh Th"), sharedCards: [c("Kh"), c("Jh"), c("4d")])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.duplicateCard(c("Kh"))))
    }

    func testWrongPlayerCardCount() {
        let scenario = makeScenario(playerCards: cs("Kh"))
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.wrongPlayerCardCount(1)))
    }

    func testStreetSharedCountMismatch() {
        let scenario = makeScenario(sharedCards: cs("Qs Jh 4d 2c"), street: .threeShared)
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.sharedCardCountMismatch(expected: 3, found: 4)))
    }

    func testSeatCountBounds() {
        let one = makeScenario(seats: [PlayerSeat(seat: 0, position: .final, stack: 100, profile: nil, status: .active)],
                               actionHistory: [])
        XCTAssertTrue(ScenarioValidator.errors(one).contains(.invalidSeatCount(1)))
    }

    func testNonConsecutiveSeatsDetected() {
        let scenario = makeScenario(seats: [
            PlayerSeat(seat: 0, position: .final, stack: 100, profile: nil, status: .active),
            PlayerSeat(seat: 2, position: .early, stack: 100, profile: .balanced, status: .active)
        ], actionHistory: [])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.nonConsecutiveSeats))
    }

    func testPlayerMustBeSeatZeroWithNoProfile() {
        let scenario = makeScenario(seats: [
            PlayerSeat(seat: 0, position: .final, stack: 100, profile: .balanced, status: .active),
            PlayerSeat(seat: 1, position: .early, stack: 100, profile: .cautious, status: .active)
        ], actionHistory: [])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.playerNotSeatZero))
    }

    func testNonPositiveStackDetected() {
        let scenario = makeScenario(seats: [
            PlayerSeat(seat: 0, position: .final, stack: 0, profile: nil, status: .active),
            PlayerSeat(seat: 1, position: .early, stack: 100, profile: .cautious, status: .active)
        ], actionHistory: [])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.nonPositiveStack(seat: 0)))
    }

    func testTooFewActivePlayers() {
        let scenario = makeScenario(seats: [
            PlayerSeat(seat: 0, position: .final, stack: 100, profile: nil, status: .active),
            PlayerSeat(seat: 1, position: .early, stack: 100, profile: .cautious, status: .withdrawn)
        ], actionHistory: [ActionRecord(seat: 1, action: .withdraw)])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.tooFewActivePlayers(1)))
    }

    func testActionAfterWithdrawDetected() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 1, action: .withdraw),
            ActionRecord(seat: 1, action: .match),
            ActionRecord(seat: 2, action: .challenge, size: 300)
        ])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.actionAfterWithdraw(seat: 1)))
    }

    func testChallengeExceedingStackDetected() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 1, action: .withdraw),
            ActionRecord(seat: 2, action: .challenge, size: 99999)
        ])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.challengeExceedsStack(seat: 2)))
    }

    func testChallengeMustRaiseRequirement() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 2, action: .challenge, size: 300),
            ActionRecord(seat: 1, action: .challenge, size: 300)
        ])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.challengeNotAboveRequirement(seat: 1)))
    }

    func testChallengeWithoutSizeDetected() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 1, action: .withdraw),
            ActionRecord(seat: 2, action: .challenge, size: nil)
        ])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.challengeMissingSize(seat: 2)))
    }

    func testPassFacingRequirementDetected() {
        // C15's teaching rule, enforced in data: no pass while facing an unmatched requirement.
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 2, action: .challenge, size: 300),
            ActionRecord(seat: 1, action: .pass)
        ])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.passFacingRequirement(seat: 1)))
    }

    func testPassWithNoRequirementIsLegal() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 1, action: .pass),
            ActionRecord(seat: 2, action: .challenge, size: 300)
        ])
        XCTAssertFalse(ScenarioValidator.errors(scenario).contains(.passFacingRequirement(seat: 1)))
    }

    func testMatchThenPassIsLegal() {
        let scenario = makeScenario(actionHistory: [
            ActionRecord(seat: 2, action: .challenge, size: 300),
            ActionRecord(seat: 1, action: .match),
            ActionRecord(seat: 1, action: .pass)
        ])
        XCTAssertEqual(ScenarioValidator.errors(scenario), [])
    }

    func testUnknownActingSeatDetected() {
        let scenario = makeScenario(actionHistory: [ActionRecord(seat: 9, action: .withdraw)])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.unknownActingSeat(9)))
    }

    func testDifficultyBounds() {
        XCTAssertTrue(ScenarioValidator.errors(makeScenario(difficulty: 0)).contains(.invalidDifficulty(0)))
        XCTAssertTrue(ScenarioValidator.errors(makeScenario(difficulty: 11)).contains(.invalidDifficulty(11)))
        XCTAssertEqual(ScenarioValidator.errors(makeScenario(difficulty: 10)), [])
    }

    func testMissingTierDetected() {
        let scenario = makeScenario(tiers: ["match": .excellent, "withdraw": .defensible])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.missingTier(.challenge)))
    }

    func testNoExcellentOptionDetected() {
        let scenario = makeScenario(tiers: ["match": .strong, "withdraw": .defensible, "challenge": .weak])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.noExcellentOption))
    }

    func testDegenerateTiersDetected() {
        // "Meaningful decision" rule: all options sharing one tier is not a puzzle.
        let scenario = makeScenario(tiers: ["match": .excellent, "withdraw": .excellent, "challenge": .excellent])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.degenerateTiers))
    }

    func testMixedDecisionLevelsWithTwoExcellentOptionsAreValid() {
        // Chapter 9 authors two Excellent options — legal as long as some tier differs.
        let scenario = makeScenario(tiers: ["match": .excellent, "challenge": .excellent, "withdraw": .weak])
        XCTAssertEqual(ScenarioValidator.errors(scenario), [])
    }

    func testInvalidSizeBandDetected() {
        let scenario = makeScenario(sizeBand: [0.8, 0.5])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.invalidSizeBand))
    }

    func testValidSizeBandAccepted() {
        let scenario = makeScenario(sizeBand: [0.65, 1.0])
        XCTAssertEqual(ScenarioValidator.errors(scenario), [])
    }

    func testNoLegalOptionsDetected() {
        let scenario = makeScenario(options: [])
        XCTAssertTrue(ScenarioValidator.errors(scenario).contains(.noLegalOptions))
    }
}
