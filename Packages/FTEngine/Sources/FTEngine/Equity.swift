import Foundation

/// Win/tie/loss tally for the hero across enumerated or simulated deals.
/// `equity` credits ties at the hero's pool share (integer tallies; division happens once — C9).
public struct EquityResult: Sendable, Equatable {
    public let trials: Int
    /// Hero pool share accumulated in fixed-point units of 1/2520 per trial
    /// (2520 = LCM of 1…9, so any split among up to 9 players is exact).
    public let shareUnits: Int
    public let wins: Int
    public let ties: Int
    public let basis: CalculationBasis

    public static let unitScale = 2520

    public var equity: Double { Double(shareUnits) / Double(trials * EquityResult.unitScale) }
    public var losses: Int { trials - wins - ties }
}

/// Exact head-to-head equity by enumerating every completion of the shared cards.
public enum EquityCalculator {

    /// Both hands known; 3, 4, or 5 shared cards. Fully exact.
    public static func exactHeadsUp(hero: [Card], villain: [Card], shared: [Card]) -> EquityResult {
        precondition(hero.count == 2 && villain.count == 2)
        precondition((3...5).contains(shared.count))
        precondition(CardSet.allUnique(hero + villain + shared), "Duplicate card in scenario")

        var trials = 0
        var shareUnits = 0
        var wins = 0
        var ties = 0

        func settle(_ board: [Card]) {
            trials += 1
            let heroRank = Evaluator.best(hero + board)
            let villainRank = Evaluator.best(villain + board)
            if heroRank > villainRank {
                wins += 1
                shareUnits += EquityResult.unitScale
            } else if heroRank == villainRank {
                ties += 1
                shareUnits += EquityResult.unitScale / 2
            }
        }

        switch shared.count {
        case 5:
            settle(shared)
        case 4:
            for card in CardSet(hero + villain + shared).complement {
                settle(shared + [card])
            }
        default:
            let unseen = CardSet(hero + villain + shared).complement
            for i in 0..<(unseen.count - 1) {
                for j in (i + 1)..<unseen.count {
                    settle(shared + [unseen[i], unseen[j]])
                }
            }
        }

        return EquityResult(trials: trials, shareUnits: shareUnits, wins: wins, ties: ties, basis: .exactEnumeration)
    }
}

/// SplitMix64 — the engine's only randomness source. Deterministic, seedable, portable (C9).
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform value in 0..<bound without modulo bias (rejection sampling; deterministic).
    public mutating func uniform(_ bound: Int) -> Int {
        precondition(bound > 0)
        let b = UInt64(bound)
        let limit = UInt64.max - (UInt64.max % b)
        while true {
            let value = next()
            if value < limit { return Int(value % b) }
        }
    }
}

/// Seeded Monte Carlo equity vs. one or more random hands. Fixed iteration order and
/// integer tallies make results bit-identical for a given seed on every device (C9).
public enum MonteCarloEquity {

    public static func equity(
        hero: [Card],
        randomOpponents: Int,
        shared: [Card] = [],
        trials: Int,
        seed: UInt64
    ) -> EquityResult {
        precondition(hero.count == 2)
        precondition((1...8).contains(randomOpponents))
        precondition(shared.count <= 5)
        precondition(CardSet.allUnique(hero + shared), "Duplicate card in scenario")
        precondition(trials > 0)

        let baseUnseen = CardSet(hero + shared).complement
        let boardNeeded = 5 - shared.count
        let cardsNeeded = randomOpponents * 2 + boardNeeded

        var rng = SplitMix64(seed: seed)
        var pool = baseUnseen
        var trialsRun = 0
        var shareUnits = 0
        var wins = 0
        var ties = 0

        for _ in 0..<trials {
            // Partial Fisher–Yates: draw exactly the cards this trial needs.
            for slot in 0..<cardsNeeded {
                let pick = slot + rng.uniform(pool.count - slot)
                pool.swapAt(slot, pick)
            }
            let board = shared + pool[(cardsNeeded - boardNeeded)..<cardsNeeded]
            let heroRank = Evaluator.best(hero + board)

            var heroBeaten = false
            var tiedCount = 1  // players sharing the top rank, hero included
            for opp in 0..<randomOpponents {
                let oppRank = Evaluator.best([pool[opp * 2], pool[opp * 2 + 1]] + board)
                if oppRank > heroRank { heroBeaten = true; break }
                if oppRank == heroRank { tiedCount += 1 }
            }

            trialsRun += 1
            if !heroBeaten {
                if tiedCount == 1 {
                    wins += 1
                    shareUnits += EquityResult.unitScale
                } else {
                    ties += 1
                    shareUnits += EquityResult.unitScale / tiedCount
                }
            }
        }

        return EquityResult(
            trials: trialsRun,
            shareUnits: shareUnits,
            wins: wins,
            ties: ties,
            basis: .seededSimulation(trials: trialsRun)
        )
    }
}
