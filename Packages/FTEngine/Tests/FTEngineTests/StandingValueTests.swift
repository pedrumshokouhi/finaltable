import XCTest
@testable import FTEngine

/// The Standing Value Model (C10) — Malmuth–Harville conversion of stacks to expected
/// ranking points.
final class StandingValueTests: XCTestCase {

    func testTwoPlayersWinnerTakeAllIsProportional() {
        let ev = StandingValueModel.expectedRankingPoints(stacks: [200, 100], payouts: [1, 0])
        XCTAssertEqual(ev[0], 2.0 / 3.0, accuracy: 1e-12)
        XCTAssertEqual(ev[1], 1.0 / 3.0, accuracy: 1e-12)
    }

    func testTotalEVEqualsTotalPayout() {
        let payouts: [Double] = [100, 60, 40, 25, 10]
        let ev = StandingValueModel.expectedRankingPoints(stacks: [3200, 5800, 900, 1100, 4000], payouts: payouts)
        XCTAssertEqual(ev.reduce(0, +), payouts.reduce(0, +), accuracy: 1e-9)
    }

    func testEqualStacksShareEqually() {
        let ev = StandingValueModel.expectedRankingPoints(stacks: [1000, 1000, 1000], payouts: [50, 30, 20])
        XCTAssertEqual(ev[0], ev[1], accuracy: 1e-9)
        XCTAssertEqual(ev[1], ev[2], accuracy: 1e-9)
        XCTAssertEqual(ev[0], 100.0 / 3.0, accuracy: 1e-9)
    }

    func testBiggerStackNeverWorthLess() {
        let ev = StandingValueModel.expectedRankingPoints(stacks: [5000, 3000, 1000], payouts: [100, 60, 40])
        XCTAssertGreaterThan(ev[0], ev[1])
        XCTAssertGreaterThan(ev[1], ev[2])
    }

    func testShortPayoutArrayIsZeroPadded() {
        // Only 1st place pays; three players.
        let ev = StandingValueModel.expectedRankingPoints(stacks: [100, 100, 200], payouts: [10])
        XCTAssertEqual(ev.reduce(0, +), 10, accuracy: 1e-9)
        XCTAssertEqual(ev[2], 5.0, accuracy: 1e-9)  // P(win) = 200/400
    }

    func testSinglePlayerTakesFirstPayout() {
        let ev = StandingValueModel.expectedRankingPoints(stacks: [500], payouts: [42, 7])
        XCTAssertEqual(ev, [42])
    }

    func testDoublingUpBeatsFoldingOnlyWithoutJumpPressure() {
        // S8's core claim: with two tiny stacks at the table, a stack-doubling coin flip
        // LOWERS expected ranking points versus standing pat.
        let payouts: [Double] = [100, 60, 40, 25, 10]
        let fold = StandingValueModel.expectedRankingPoints(
            stacks: [3200, 5800, 900, 1100, 4000], payouts: payouts)[0]
        // 50%: bust (worst remaining payout = 10). 50%: double to 6400 (leader shrinks to 2600).
        let winCase = StandingValueModel.expectedRankingPoints(
            stacks: [6400, 2600, 900, 1100, 4000], payouts: payouts)[0]
        let gamble = 0.5 * 10 + 0.5 * winCase
        XCTAssertGreaterThan(fold, gamble, "Standing pat must beat the coin flip near a reward jump")
    }

    func testEightPlayersComputesQuickly() {
        let stacks = [800, 1200, 3000, 4500, 900, 2200, 5100, 1600]
        let payouts: [Double] = [100, 60, 40, 25, 10, 5, 3, 2]
        let ev = StandingValueModel.expectedRankingPoints(stacks: stacks, payouts: payouts)
        XCTAssertEqual(ev.count, 8)
        XCTAssertEqual(ev.reduce(0, +), payouts.reduce(0, +), accuracy: 1e-6)
    }
}
