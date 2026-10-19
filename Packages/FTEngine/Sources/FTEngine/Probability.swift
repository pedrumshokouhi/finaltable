import Foundation

/// An exact probability as a reduced fraction. Keeps enumeration results lossless (C9).
public struct Rational: Hashable, Sendable, CustomStringConvertible {
    public let numerator: Int
    public let denominator: Int

    public init(_ numerator: Int, _ denominator: Int) {
        precondition(denominator > 0, "Rational denominator must be positive")
        precondition(numerator >= 0, "Rational is used for probabilities; numerator must be ≥ 0")
        let divisor = Rational.gcd(numerator, denominator)
        self.numerator = numerator / divisor
        self.denominator = denominator / divisor
    }

    public var double: Double { Double(numerator) / Double(denominator) }
    public var percent: Double { double * 100 }
    public var description: String { "\(numerator)/\(denominator)" }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var a = a, b = b
        while b != 0 { (a, b) = (b, a % b) }
        return a == 0 ? 1 : a
    }
}

/// Where a displayed number comes from — rendered as a label in the UI. The engine never
/// presents assumption-based numbers as exact (§9 honesty rule).
public enum CalculationBasis: Hashable, Sendable {
    case exactEnumeration
    case seededSimulation(trials: Int)
    case behavioralAssumption

    public var label: String {
        switch self {
        case .exactEnumeration: return "Exact — counted over every possible card"
        case .seededSimulation(let trials): return "Estimated — \(trials) simulated deals"
        case .behavioralAssumption: return "Assumption — depends on how opponents behave"
        }
    }
}

/// A probability plus everything the UI must display alongside it (§ Hand-Strength Lab):
/// exact value, friendly approximation, method, and assumptions.
public struct ProbabilityResult: Sendable {
    public let exact: Rational?
    public let estimate: Double
    public let basis: CalculationBasis
    public let assumptions: [String]

    public init(exact: Rational, basis: CalculationBasis, assumptions: [String]) {
        self.exact = exact
        self.estimate = exact.double
        self.basis = basis
        self.assumptions = assumptions
    }

    public init(estimate: Double, basis: CalculationBasis, assumptions: [String]) {
        self.exact = nil
        self.estimate = estimate
        self.basis = basis
        self.assumptions = assumptions
    }

    public var friendly: String { FriendlyProbability.describe(estimate) }
}

/// Deterministic plain-language rendering of a probability ("about 1 in 3",
/// "slightly better than a coin flip", "just under 2 in 3").
public enum FriendlyProbability {
    public static func describe(_ p: Double) -> String {
        if p <= 0.005 { return "virtually never" }
        if p >= 0.995 { return "virtually certain" }

        // Coin-flip band.
        if p > 0.42 && p < 0.58 {
            if abs(p - 0.5) < 0.02 { return "about a coin flip" }
            return p > 0.5 ? "slightly better than a coin flip" : "slightly worse than a coin flip"
        }

        // Low band: "1 in n".
        if p <= 0.42 {
            var bestN = 2
            var bestDiff = Double.greatestFiniteMagnitude
            for n in 2...200 {
                let diff = abs(p - 1.0 / Double(n))
                if diff < bestDiff { bestDiff = diff; bestN = n }
            }
            let target = 1.0 / Double(bestN)
            if abs(p - target) < 0.02 { return "about 1 in \(bestN)" }
            return p > target ? "a bit over 1 in \(bestN)" : "a bit under 1 in \(bestN)"
        }

        // High band: nearest common fraction.
        let fractions: [(Double, String)] = [
            (3.0 / 5.0, "3 in 5"), (2.0 / 3.0, "2 in 3"), (7.0 / 10.0, "7 in 10"),
            (3.0 / 4.0, "3 in 4"), (4.0 / 5.0, "4 in 5"), (5.0 / 6.0, "5 in 6"), (9.0 / 10.0, "9 in 10")
        ]
        let (value, name) = fractions.min { abs($0.0 - p) < abs($1.0 - p) }!
        if abs(p - value) < 0.02 { return "about \(name)" }
        return p > value ? "just over \(name)" : "just under \(name)"
    }
}

/// Improvement-probability calculations: the exact outs formula and full enumeration.
public enum ImprovementCalculator {

    /// P(at least one of `outs` helpful cards arrives in `draws` draws from `unseen` cards).
    /// Exact hypergeometric; valid whenever hitting any out achieves the goal ("sticky" outs).
    public static func atLeastOneOut(outs: Int, unseen: Int, draws: Int) -> Rational {
        precondition(draws == 1 || draws == 2, "Only 1 or 2 remaining draws are supported")
        precondition(outs >= 0 && outs <= unseen)
        let total = Combinatorics.binomial(unseen, draws)
        let misses = Combinatorics.binomial(unseen - outs, draws)
        return Rational(total - misses, total)
    }

    /// Exact enumeration over every completion of the shared cards: the probability that the
    /// player's final best-five hand satisfies `goal`. Counts backdoor routes the outs formula
    /// can't see. Requires 3 or 4 shared cards (pre-shared enumeration is a simulator concern).
    public static func probability(
        player: [Card],
        shared: [Card],
        satisfies goal: (HandRank) -> Bool
    ) -> Rational {
        precondition(player.count == 2, "Player holds exactly 2 cards")
        precondition(shared.count == 3 || shared.count == 4, "Enumeration requires 3 or 4 shared cards")
        precondition(CardSet.allUnique(player + shared), "Duplicate card in scenario")

        let unseen = CardSet(player + shared).complement
        var successes = 0
        var total = 0

        if shared.count == 4 {
            for card in unseen {
                total += 1
                if goal(Evaluator.best(player + shared + [card])) { successes += 1 }
            }
        } else {
            for i in 0..<(unseen.count - 1) {
                for j in (i + 1)..<unseen.count {
                    total += 1
                    if goal(Evaluator.best(player + shared + [unseen[i], unseen[j]])) { successes += 1 }
                }
            }
        }
        return Rational(successes, total)
    }
}
