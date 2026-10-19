import XCTest
@testable import FTEngine

/// Exact head-to-head equity, the seeded RNG, and Monte Carlo determinism (C9).
final class EquityAndRandomTests: XCTestCase {

    // MARK: Exact heads-up equity

    func testRiverIsFullyDecided() {
        let result = EquityCalculator.exactHeadsUp(
            hero: cs("Ah Kh"), villain: cs("Qs Qd"), shared: cs("Ac 2d 7h 9s 3c"))
        XCTAssertEqual(result.trials, 1)
        XCTAssertEqual(result.wins, 1)
        XCTAssertEqual(result.equity, 1.0)
        XCTAssertEqual(result.basis, .exactEnumeration)
    }

    func testTurnEnumerates44Cards() {
        // AA vs KK, no help on board: villain wins only on the 2 remaining kings.
        let result = EquityCalculator.exactHeadsUp(
            hero: cs("Ah As"), villain: cs("Kh Ks"), shared: cs("2c 7d 9h 4s"))
        XCTAssertEqual(result.trials, 44)
        XCTAssertEqual(result.wins, 42)
        XCTAssertEqual(result.ties, 0)
        XCTAssertEqual(result.equity, 42.0 / 44.0, accuracy: 1e-12)
    }

    func testFlopEnumerates990Boards() {
        let result = EquityCalculator.exactHeadsUp(
            hero: cs("Ah As"), villain: cs("Kh Ks"), shared: cs("2c 7d 9h"))
        XCTAssertEqual(result.trials, 990)
        XCTAssertGreaterThan(result.equity, 0.85)
    }

    func testExactTieSplitsPool() {
        // Both hole hands are dead; the board plays for both.
        let result = EquityCalculator.exactHeadsUp(
            hero: cs("2c 3c"), villain: cs("2d 3d"), shared: cs("As Ad Ks Kd Qh"))
        XCTAssertEqual(result.ties, 1)
        XCTAssertEqual(result.equity, 0.5)
    }

    func testLossesComputed() {
        let result = EquityCalculator.exactHeadsUp(
            hero: cs("Qs Qd"), villain: cs("Ah Kh"), shared: cs("Ac 2d 7h 9s 3c"))
        XCTAssertEqual(result.losses, 1)
        XCTAssertEqual(result.equity, 0)
    }

    // MARK: SplitMix64

    func testSplitMix64GoldenVectorsSeed42() {
        // Reference values computed with an independent SplitMix64 implementation.
        var rng = SplitMix64(seed: 42)
        XCTAssertEqual(rng.next(), 13679457532755275413)
        XCTAssertEqual(rng.next(), 2949826092126892291)
        XCTAssertEqual(rng.next(), 5139283748462763858)
        XCTAssertEqual(rng.next(), 6349198060258255764)
    }

    func testSplitMix64GoldenVectorsSeed1234567() {
        var rng = SplitMix64(seed: 1234567)
        XCTAssertEqual(rng.next(), 6457827717110365317)
        XCTAssertEqual(rng.next(), 3203168211198807973)
    }

    func testSplitMix64Deterministic() {
        var a = SplitMix64(seed: 987654321)
        var b = SplitMix64(seed: 987654321)
        for _ in 0..<100 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testSplitMix64SeedsDiffer() {
        var a = SplitMix64(seed: 1)
        var b = SplitMix64(seed: 2)
        XCTAssertNotEqual(a.next(), b.next())
    }

    func testUniformStaysInBounds() {
        var rng = SplitMix64(seed: 7)
        for _ in 0..<1000 {
            let value = rng.uniform(47)
            XCTAssertTrue((0..<47).contains(value))
        }
    }

    // MARK: Monte Carlo

    func testMonteCarloSameSeedIsBitIdentical() {
        let a = MonteCarloEquity.equity(hero: cs("As Js"), randomOpponents: 1, trials: 5000, seed: 42)
        let b = MonteCarloEquity.equity(hero: cs("As Js"), randomOpponents: 1, trials: 5000, seed: 42)
        XCTAssertEqual(a, b)
    }

    func testMonteCarloDifferentSeedsDiffer() {
        let a = MonteCarloEquity.equity(hero: cs("As Js"), randomOpponents: 1, trials: 5000, seed: 1)
        let b = MonteCarloEquity.equity(hero: cs("As Js"), randomOpponents: 1, trials: 5000, seed: 2)
        XCTAssertNotEqual(a.shareUnits, b.shareUnits)
    }

    func testAcesVsOneRandomHandNearKnownEquity() {
        // AA vs one random hand ≈ 85%.
        let result = MonteCarloEquity.equity(hero: cs("As Ah"), randomOpponents: 1, trials: 20000, seed: 42)
        XCTAssertEqual(result.equity, 0.85, accuracy: 0.02)
    }

    func testAceJackSuitedVsOneRandomHandNearKnownEquity() {
        // AJs vs one random hand ≈ 63–64% (S4's displayed 63.5%).
        let result = MonteCarloEquity.equity(hero: cs("As Js"), randomOpponents: 1, trials: 20000, seed: 42)
        XCTAssertEqual(result.equity, 0.635, accuracy: 0.02)
    }

    func testMultiwayEquityDropsWithMoreOpponents() {
        let headsUp = MonteCarloEquity.equity(hero: cs("As Ah"), randomOpponents: 1, trials: 10000, seed: 9)
        let fourWay = MonteCarloEquity.equity(hero: cs("As Ah"), randomOpponents: 3, trials: 10000, seed: 9)
        XCTAssertGreaterThan(headsUp.equity, fourWay.equity)
    }

    func testMonteCarloTrialCountAndBasis() {
        let result = MonteCarloEquity.equity(hero: cs("2c 7d"), randomOpponents: 1, trials: 500, seed: 3)
        XCTAssertEqual(result.trials, 500)
        XCTAssertEqual(result.basis, .seededSimulation(trials: 500))
        XCTAssertTrue(result.equity >= 0 && result.equity <= 1)
    }

    func testMonteCarloRespectsPartialBoard() {
        // Hero already flopped quads: equity must be near-certain.
        let result = MonteCarloEquity.equity(
            hero: cs("9s 9d"), randomOpponents: 1, shared: cs("9h 9c 2d"), trials: 5000, seed: 11)
        XCTAssertGreaterThan(result.equity, 0.99)
    }
}
