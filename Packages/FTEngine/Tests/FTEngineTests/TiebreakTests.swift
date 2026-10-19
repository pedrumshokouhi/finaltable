import XCTest
@testable import FTEngine

/// Tie-break rules within each category, plus exact-tie detection.
final class TiebreakTests: XCTestCase {

    private func rank(_ s: String) -> HandRank { Evaluator.evaluateFive(cs(s)) }

    func testHigherPairWins() {
        XCTAssertGreaterThan(rank("As Ad 9h 5c 2s"), rank("Ks Kd 9h 5c 2h"))
    }

    func testPairKickerDecides() {
        XCTAssertGreaterThan(rank("As Ad Kh 5c 2s"), rank("Ac Ah Qh 5d 2h"))
    }

    func testPairThirdKickerDecides() {
        XCTAssertGreaterThan(rank("As Ad Kh 9c 3s"), rank("Ac Ah Kd 9d 2h"))
    }

    func testTwoPairHighPairDominates() {
        // Aces-and-twos beats kings-and-queens.
        XCTAssertGreaterThan(rank("As Ad 2h 2c 9s"), rank("Ks Kd Qh Qc 9h"))
    }

    func testTwoPairLowPairBreaksTie() {
        XCTAssertGreaterThan(rank("As Ad 9h 9c 2s"), rank("Ac Ah 5h 5c Kd"))
    }

    func testTwoPairKickerBreaksTie() {
        XCTAssertGreaterThan(rank("As Ad 9h 9c Ks"), rank("Ac Ah 9s 9d Qd"))
    }

    func testTripsRankDominatesKickers() {
        XCTAssertGreaterThan(rank("9s 9d 9h Ac 2s"), rank("8s 8d 8h Ad Kh"))
    }

    func testTripsKickersDecide() {
        XCTAssertGreaterThan(rank("9s 9d 9h Ac 3s"), rank("9c 9s 9d Kd Qh"))
    }

    func testStraightHighCardDecides() {
        XCTAssertGreaterThan(rank("Ts 9d 8h 7c 6s"), rank("9s 8d 7h 6c 5h"))
    }

    func testWheelLosesToSixHighStraight() {
        XCTAssertLessThan(rank("As 2d 3h 4c 5s"), rank("6s 5d 4h 3c 2h"))
    }

    func testFlushComparesAllFiveCards() {
        // A-K-9-5-3 flush beats A-K-9-5-2 flush on the last card.
        XCTAssertGreaterThan(rank("As Ks 9s 5s 3s"), rank("Ah Kh 9h 5h 2h"))
    }

    func testFullHouseTripsDominatePair() {
        // Threes-full-of-twos beats twos-full-of-aces.
        XCTAssertGreaterThan(rank("3s 3d 3h 2c 2s"), rank("2h 2d 2c As Ad"))
    }

    func testFullHousePairBreaksTie() {
        XCTAssertGreaterThan(rank("3s 3d 3h Ac As"), rank("3c 3s 3d 2d 2h"))
    }

    func testQuadsKickerDecides() {
        XCTAssertGreaterThan(rank("9s 9d 9h 9c As"), rank("9s 9d 9h 9c Ks"))
    }

    func testHighCardComparesAllFive() {
        XCTAssertGreaterThan(rank("As Kd 9h 5c 3s"), rank("Ah Kh 9d 5d 2h"))
    }

    func testExactTieAcrossSuits() {
        // Same ranks, different suits: identical HandRank.
        XCTAssertEqual(rank("As Kd 9h 5c 2s"), rank("Ad Kh 9c 5s 2d"))
    }

    func testBoardPlaysTieFromSeven() {
        // Both players' hole cards are dead: board A-A-K-K-Q outkicks 2-3 and 4-5.
        let board = cs("As Ad Ks Kd Qh")
        let hero = Evaluator.best(cs("2c 3c") + board)
        let villain = Evaluator.best(cs("4d 5d") + board)
        XCTAssertEqual(hero, villain)
    }

    func testKickerDoesNotPlayWhenBoardIsHigher() {
        // Hole 2 vs hole 3 kicker — irrelevant when the board provides all five better cards.
        let board = cs("As Ad Ks Kd Qh")
        let hero = Evaluator.best(cs("2c 7c") + board)
        let villain = Evaluator.best(cs("3d 6d") + board)
        XCTAssertEqual(hero, villain)
    }

    func testStraightFlushHighCardDecides() {
        XCTAssertGreaterThan(rank("9s 8s 7s 6s 5s"), rank("8h 7h 6h 5h 4h"))
    }
}
