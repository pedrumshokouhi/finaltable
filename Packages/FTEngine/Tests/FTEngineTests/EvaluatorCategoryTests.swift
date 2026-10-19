import XCTest
@testable import FTEngine

/// Every hand category is detected from five cards, and from the best five of seven.
final class EvaluatorCategoryTests: XCTestCase {

    // MARK: Five-card categories

    func testHighCard() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Kd 9h 5c 2s")).category, .highCard)
    }

    func testPair() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ad 9h 5c 2s")).category, .pair)
    }

    func testTwoPair() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ad 9h 9c 2s")).category, .twoPair)
    }

    func testThreeOfAKind() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ad Ah 5c 2s")).category, .threeOfAKind)
    }

    func testStraight() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("9s 8d 7h 6c 5s")).category, .straight)
    }

    func testWheelStraight() {
        let rank = Evaluator.evaluateFive(cs("As 2d 3h 4c 5s"))
        XCTAssertEqual(rank.category, .straight)
        XCTAssertEqual(rank.primaryRank, .five, "Wheel plays as five-high")
    }

    func testBroadwayStraight() {
        let rank = Evaluator.evaluateFive(cs("As Kd Qh Jc Ts"))
        XCTAssertEqual(rank.category, .straight)
        XCTAssertEqual(rank.primaryRank, .ace)
    }

    func testFlush() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ks 9s 5s 2s")).category, .flush)
    }

    func testFullHouse() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ad Ah 2c 2s")).category, .fullHouse)
    }

    func testFourOfAKind() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Ad Ah Ac 2s")).category, .fourOfAKind)
    }

    func testStraightFlush() {
        let rank = Evaluator.evaluateFive(cs("9s 8s 7s 6s 5s"))
        XCTAssertEqual(rank.category, .straightFlush)
        XCTAssertFalse(rank.isRoyalFlush)
    }

    func testSteelWheelStraightFlush() {
        let rank = Evaluator.evaluateFive(cs("As 2s 3s 4s 5s"))
        XCTAssertEqual(rank.category, .straightFlush)
        XCTAssertEqual(rank.primaryRank, .five)
    }

    func testRoyalFlush() {
        let rank = Evaluator.evaluateFive(cs("As Ks Qs Js Ts"))
        XCTAssertEqual(rank.category, .straightFlush)
        XCTAssertTrue(rank.isRoyalFlush)
    }

    func testFourGapIsNotAStraight() {
        XCTAssertEqual(Evaluator.evaluateFive(cs("As Kd Qh Jc 9s")).category, .highCard)
    }

    func testAroundTheCornerIsNotAStraight() {
        // Q-K-A-2-3 does not wrap.
        XCTAssertEqual(Evaluator.evaluateFive(cs("Qs Kd Ah 2c 3s")).category, .highCard)
    }

    // MARK: Best five from six and seven

    func testPairFromSeven() {
        XCTAssertEqual(Evaluator.best(cs("As Ad 9h 5c 2s Jd 7h")).category, .pair)
    }

    func testBestTwoPairOfThreeFromSeven() {
        // Pairs of A, 9, and 5 available — best five uses aces and nines.
        let rank = Evaluator.best(cs("As Ad 9h 9c 5s 5d Kh"))
        XCTAssertEqual(rank.category, .twoPair)
        XCTAssertEqual(rank.primaryRank, .ace)
    }

    func testStraightFromSeven() {
        XCTAssertEqual(Evaluator.best(cs("9s 8d 7h 6c 5s Ad Kh")).category, .straight)
    }

    func testFlushBeatsStraightFromSeven() {
        // Both a straight and a flush are available; flush must win.
        let rank = Evaluator.best(cs("9s 8s 7h 6s 5s 2s Kh"))
        XCTAssertEqual(rank.category, .flush)
    }

    func testTwoTripsFromSevenMakeFullHouse() {
        let rank = Evaluator.best(cs("As Ad Ah 2c 2s 2d Kh"))
        XCTAssertEqual(rank.category, .fullHouse)
        XCTAssertEqual(rank.primaryRank, .ace)
    }

    func testQuadsFromSeven() {
        XCTAssertEqual(Evaluator.best(cs("As Ad Ah Ac 2s 9d Kh")).category, .fourOfAKind)
    }

    func testStraightFlushFromSeven() {
        XCTAssertEqual(Evaluator.best(cs("9s 8s 7s 6s 5s Ad Ah")).category, .straightFlush)
    }

    func testBestFromSixCards() {
        XCTAssertEqual(Evaluator.best(cs("As Ks 9s 5s 2s Ad")).category, .flush)
    }

    func testThreePairIllusionScoresAsTwoPair() {
        // S1 / L005: A♥9♥ on A♦9♣K♠K♥... best five is A A K K 9 — two pair, aces and kings.
        let rank = Evaluator.best(cs("Ah 9h Ad 9c Ks Kd 2d"))
        XCTAssertEqual(rank.category, .twoPair)
        XCTAssertEqual(rank.primaryRank, .ace)
        // Second pair must be the kings, not the nines: nibble 2 is the low pair.
        XCTAssertEqual((rank.value >> 12) & 0xF, UInt32(Rank.king.rawValue))
        // Kicker nibble is the nine.
        XCTAssertEqual((rank.value >> 8) & 0xF, UInt32(Rank.nine.rawValue))
    }

    func testCategoryOrderingIsTotal() {
        let exemplars: [HandRank] = [
            Evaluator.evaluateFive(cs("As Kd 9h 5c 2s")),   // high card
            Evaluator.evaluateFive(cs("2s 2d 9h 5c 3s")),   // pair
            Evaluator.evaluateFive(cs("2s 2d 3h 3c 4s")),   // two pair
            Evaluator.evaluateFive(cs("2s 2d 2h 5c 3s")),   // trips
            Evaluator.evaluateFive(cs("As 2d 3h 4c 5s")),   // straight (wheel)
            Evaluator.evaluateFive(cs("2s 7s 9s 5s 3s")),   // flush
            Evaluator.evaluateFive(cs("2s 2d 2h 3c 3s")),   // full house
            Evaluator.evaluateFive(cs("2s 2d 2h 2c 3s")),   // quads
            Evaluator.evaluateFive(cs("2s 3s 4s 5s 6s"))    // straight flush
        ]
        for i in 0..<(exemplars.count - 1) {
            XCTAssertLessThan(exemplars[i], exemplars[i + 1],
                              "Category \(exemplars[i].category) must lose to \(exemplars[i + 1].category)")
        }
    }
}
