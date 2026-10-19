import XCTest
@testable import FTEngine

/// Exact probability machinery: binomials, the outs formula, and full enumeration —
/// checked against hand-counted combinatorics from the spec documents.
final class EnumerationTests: XCTestCase {

    // MARK: Binomial coefficients

    func testBinomialSmallValues() {
        XCTAssertEqual(Combinatorics.binomial(5, 2), 10)
        XCTAssertEqual(Combinatorics.binomial(6, 5), 6)
        XCTAssertEqual(Combinatorics.binomial(7, 5), 21)
    }

    func testBinomialSpecValues() {
        XCTAssertEqual(Combinatorics.binomial(47, 2), 1081)
        XCTAssertEqual(Combinatorics.binomial(38, 2), 703)
        XCTAssertEqual(Combinatorics.binomial(45, 2), 990)
        XCTAssertEqual(Combinatorics.binomial(46, 2), 1035)
    }

    func testBinomialEdgeCases() {
        XCTAssertEqual(Combinatorics.binomial(10, 0), 1)
        XCTAssertEqual(Combinatorics.binomial(10, 10), 1)
        XCTAssertEqual(Combinatorics.binomial(3, 5), 0)
    }

    func testCombinationsGeneratorCounts() {
        XCTAssertEqual(Combinatorics.combinations(count: 7, choose: 5).count, 21)
        XCTAssertEqual(Combinatorics.combinations(count: 6, choose: 5).count, 6)
        XCTAssertEqual(Combinatorics.combinations(count: 4, choose: 2), [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]])
    }

    // MARK: Outs formula (hypergeometric)

    func testFlushDrawTwoCards() {
        // 9 outs, 47 unseen, 2 draws → 378/1081 = 34.97% (S2).
        let p = ImprovementCalculator.atLeastOneOut(outs: 9, unseen: 47, draws: 2)
        XCTAssertEqual(p, Rational(378, 1081))
        XCTAssertEqual(p.percent, 34.967, accuracy: 0.001)
    }

    func testOpenEndedStraightDrawTwoCards() {
        // 8 outs → 340/1081 = 31.45%.
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 8, unseen: 47, draws: 2), Rational(340, 1081))
    }

    func testFiveOutsTwoCards() {
        // 5 outs → 220/1081 = 20.35% (S7).
        let p = ImprovementCalculator.atLeastOneOut(outs: 5, unseen: 47, draws: 2)
        XCTAssertEqual(p, Rational(220, 1081))
        XCTAssertEqual(p.percent, 20.35, accuracy: 0.01)
    }

    func testTwoOutsTwoCards() {
        // Set chase: 2 outs → 91/1081 = 8.4% (L016).
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 2, unseen: 47, draws: 2), Rational(91, 1081))
    }

    func testGutshotFourOutsTwoCards() {
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 4, unseen: 47, draws: 2), Rational(178, 1081))
    }

    func testNineOutsOneCard() {
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 9, unseen: 46, draws: 1), Rational(9, 46))
    }

    func testZeroOutsIsZero() {
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 0, unseen: 47, draws: 2).double, 0)
    }

    func testAllOutsIsCertain() {
        XCTAssertEqual(ImprovementCalculator.atLeastOneOut(outs: 47, unseen: 47, draws: 2).double, 1)
    }

    // MARK: Full enumeration

    func testFlushDrawEnumerationMatchesOutsFormula() {
        // S2: Q♥J♥ on 9♥4♥2♠ — flush-or-better by the river = exactly 378/1081.
        let p = ImprovementCalculator.probability(player: cs("Qh Jh"), shared: cs("9h 4h 2s")) {
            $0.category >= .flush
        }
        XCTAssertEqual(p, Rational(378, 1081))
    }

    func testOneCardFlushEnumeration() {
        // A♥K♥ on Q♥J♥2♠2♦ — 9 hearts of 46 complete flush-or-better (straights excluded by category).
        let p = ImprovementCalculator.probability(player: cs("Ah Kh"), shared: cs("Qh Jh 2s 2d")) {
            $0.category >= .flush
        }
        XCTAssertEqual(p, Rational(9, 46))
    }

    func testEnumerationSeesBackdoorRoutes() {
        // K♥T♥ on T♦8♣6♣: "two pair or better" via enumeration must exceed the 5-out
        // formula (220/1081), because board pairs and backdoor routes also qualify.
        let enumerated = ImprovementCalculator.probability(player: cs("Kh Th"), shared: cs("Td 8c 6c")) {
            $0.category >= .twoPair
        }
        let outsOnly = ImprovementCalculator.atLeastOneOut(outs: 5, unseen: 47, draws: 2)
        XCTAssertGreaterThan(enumerated.double, outsOnly.double)
    }

    func testEnumerationTotalIsBinomial() {
        // Denominator of a flop enumeration divides C(47,2) after reduction.
        let p = ImprovementCalculator.probability(player: cs("2c 7d"), shared: cs("Kh Qs 9d")) {
            $0.category >= .fourOfAKind
        }
        XCTAssertEqual(1081 % p.denominator, 0)
    }

    func testMadeHandProbabilityOfAtLeastCurrentIsOne() {
        // Already holding a flush: P(flush or better) = 1.
        let p = ImprovementCalculator.probability(player: cs("Ah Kh"), shared: cs("Qh 9h 2h")) {
            $0.category >= .flush
        }
        XCTAssertEqual(p.double, 1)
    }

    // MARK: Rational

    func testRationalReduces() {
        let r = Rational(378, 1081)  // gcd 1 — already reduced
        XCTAssertEqual(r.numerator, 378)
        let reduced = Rational(220, 1100)
        XCTAssertEqual(reduced.numerator, 1)
        XCTAssertEqual(reduced.denominator, 5)
    }

    func testRationalPercent() {
        XCTAssertEqual(Rational(1, 4).percent, 25, accuracy: 0.0001)
        XCTAssertEqual(Rational(0, 5).double, 0)
    }
}
