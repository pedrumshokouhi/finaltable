import XCTest
@testable import FTEngine

/// Codable fidelity against the level JSON schema (02_SCHEMAS.md) and scenario-code
/// reproducibility (C6).
final class ScenarioModelTests: XCTestCase {

    // MARK: Level JSON decoding

    private let levelJSON = """
    {
      "schemaVersion": 1,
      "id": "L027",
      "chapter": 3,
      "title": "The Late Seat Advantage",
      "learningObjective": "Recognize how acting last increases the value of a medium-strength holding.",
      "difficulty": 4,
      "skillTags": ["position", "opponentModeling"],
      "deal": {
        "playerCards": ["Kh", "Th"],
        "sharedCards": ["Qs", "Jh", "4d"],
        "street": "threeShared"
      },
      "table": {
        "pointUnit": "pts",
        "seats": [
          { "seat": 0, "position": "final", "stack": 4200, "profile": null, "status": "active" },
          { "seat": 1, "position": "early", "stack": 3100, "profile": "cautious", "status": "withdrawn" },
          { "seat": 2, "position": "middle", "stack": 5600, "profile": "aggressive", "status": "active" }
        ],
        "pool": 900,
        "requirement": 300
      },
      "actionHistory": [
        { "seat": 1, "action": "withdraw" },
        { "seat": 2, "action": "challenge", "size": 300 }
      ],
      "objective": "Decide against an aggressive challenger while holding the last-action advantage.",
      "decisionSpec": {
        "options": ["withdraw", "match", "challenge"],
        "sizeStops": [0.5, 0.75, 1.0],
        "activeComponents": ["decision", "probability", "variables", "confidence"]
      },
      "solution": {
        "recommended": { "action": "match" },
        "tiers": { "match": "excellent", "withdraw": "defensible", "challenge": "weak" },
        "sizeBand": null,
        "probabilityKey": {
          "question": "Chance your hand improves to a straight or better by the last card",
          "exactNumerator": 340,
          "exactDenominator": 1081,
          "displayPercent": 31.5,
          "friendly": "about 1 in 3",
          "basis": "exactEnumeration",
          "assumptions": ["Only your improvement is counted."]
        },
        "variableKey": ["position", "opponentProfile", "poolOdds"],
        "distractorVariables": ["stackDepth", "standingValue", "cardRemoval"]
      },
      "explanations": {
        "quick": "Acting last with a strong draw and good pool odds, matching keeps every option open.",
        "coach": "One paragraph.",
        "commonMistake": "Re-challenging a draw out of position habit.",
        "takeaway": "Position converts uncertain hands into playable ones."
      },
      "variation": {
        "prompt": "What changes the answer?",
        "explanation": "Acting first, the same requirement buys far less information.",
        "newRecommended": { "action": "withdraw" }
      }
    }
    """

    func testDecodesSchemaExampleLevel() throws {
        let scenario = try JSONDecoder().decode(Scenario.self, from: Data(levelJSON.utf8))
        XCTAssertEqual(scenario.id, "L027")
        XCTAssertEqual(scenario.deal.playerCards, cs("Kh Th"))
        XCTAssertEqual(scenario.deal.street, .threeShared)
        XCTAssertEqual(scenario.table.seats.count, 3)
        XCTAssertEqual(scenario.table.seats[1].profile, .cautious)
        XCTAssertEqual(scenario.actionHistory[1].size, 300)
        XCTAssertEqual(scenario.solution.tiers["match"], .excellent)
        XCTAssertEqual(scenario.solution.probabilityKey?.exactDenominator, 1081)
        XCTAssertEqual(scenario.variation?.newRecommended.action, .withdraw)
    }

    func testDecodedSchemaExampleValidatesCleanly() throws {
        let scenario = try JSONDecoder().decode(Scenario.self, from: Data(levelJSON.utf8))
        XCTAssertEqual(ScenarioValidator.errors(scenario), [])
    }

    func testScenarioRoundTripsThroughCodable() throws {
        let scenario = try JSONDecoder().decode(Scenario.self, from: Data(levelJSON.utf8))
        let reencoded = try JSONEncoder().encode(scenario)
        let decoded = try JSONDecoder().decode(Scenario.self, from: reencoded)
        XCTAssertEqual(decoded, scenario)
    }

    func testMalformedCardInLevelFailsToDecode() {
        let bad = levelJSON.replacingOccurrences(of: "\"Kh\"", with: "\"K♥\"")
        XCTAssertThrowsError(try JSONDecoder().decode(Scenario.self, from: Data(bad.utf8)))
    }

    func testMalformedTierFailsToDecode() {
        let bad = levelJSON.replacingOccurrences(of: "\"excellent\"", with: "\"perfect\"")
        XCTAssertThrowsError(try JSONDecoder().decode(Scenario.self, from: Data(bad.utf8)))
    }

    // MARK: Scenario codes (C6)

    func testScenarioCodeFormat() {
        let seed = ScenarioSeed(templateID: "T217", seed: 8114213377, generatorVersion: 3)
        XCTAssertTrue(seed.code.hasPrefix("FT1-T217-"))
        XCTAssertTrue(seed.code.hasSuffix("-3"))
    }

    func testScenarioCodeRoundTrips() {
        let original = ScenarioSeed(templateID: "T217", seed: 8114213377, generatorVersion: 3)
        let parsed = ScenarioSeed(code: original.code)
        XCTAssertEqual(parsed, original)
    }

    func testScenarioCodeRoundTripsExtremeSeeds() {
        for seed in [UInt64(0), 1, UInt64.max] {
            let original = ScenarioSeed(templateID: "T001", seed: seed, generatorVersion: 1)
            XCTAssertEqual(ScenarioSeed(code: original.code), original)
        }
    }

    func testInvalidScenarioCodesRejected() {
        XCTAssertNil(ScenarioSeed(code: "FT2-T1-ABC-1"))       // wrong prefix
        XCTAssertNil(ScenarioSeed(code: "FT1-T1-ABC"))         // missing version
        XCTAssertNil(ScenarioSeed(code: "FT1-T1-!!!-1"))       // bad base36
        XCTAssertNil(ScenarioSeed(code: ""))
    }

    func testStreetSharedCardCounts() {
        XCTAssertEqual(Street.preShared.sharedCardCount, 0)
        XCTAssertEqual(Street.threeShared.sharedCardCount, 3)
        XCTAssertEqual(Street.fourShared.sharedCardCount, 4)
        XCTAssertEqual(Street.fiveShared.sharedCardCount, 5)
    }

    func testEducationalLabels() {
        XCTAssertEqual(GameActionType.pass.educationalLabel, "Pass")
        XCTAssertEqual(GameActionType.match.educationalLabel, "Match")
        XCTAssertEqual(GameActionType.challenge.educationalLabel, "Challenge")
        XCTAssertEqual(GameActionType.withdraw.educationalLabel, "Withdraw")
    }
}
