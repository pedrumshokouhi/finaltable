import Foundation

/// Decision-quality tiers (§8.2). Fractions map to the base 400-point component:
/// 400 / 320 / 240 / 120 / 0.
public enum DecisionTier: String, CaseIterable, Hashable, Sendable, Codable, Comparable {
    case majorError
    case weak
    case defensible
    case strong
    case excellent

    public var fraction: Double {
        switch self {
        case .excellent: return 1.0
        case .strong: return 0.8
        case .defensible: return 0.6
        case .weak: return 0.3
        case .majorError: return 0.0
        }
    }

    private var order: Int {
        switch self {
        case .majorError: return 0
        case .weak: return 1
        case .defensible: return 2
        case .strong: return 3
        case .excellent: return 4
        }
    }

    public static func < (lhs: DecisionTier, rhs: DecisionTier) -> Bool { lhs.order < rhs.order }
}

public enum Confidence: String, CaseIterable, Hashable, Sendable, Codable {
    case low, medium, high
}

/// The five score components and their base weights (sum 1,000).
public enum ScoreComponent: String, CaseIterable, Hashable, Sendable, Codable {
    case decision, size, probability, variables, confidence

    public var baseWeight: Int {
        switch self {
        case .decision: return 400
        case .size: return 200
        case .probability: return 150
        case .variables: return 150
        case .confidence: return 100
        }
    }
}

/// C1: inactive components redistribute their weight pro-rata over active ones,
/// largest-remainder rounding, total always exactly 1,000.
public enum ComponentWeights {
    public static func redistributed(active: Set<ScoreComponent>) -> [ScoreComponent: Int] {
        precondition(active.contains(.decision), "Decision quality is always scored")
        let ordered = ScoreComponent.allCases.filter { active.contains($0) }
        let baseSum = ordered.reduce(0) { $0 + $1.baseWeight }

        var floors: [ScoreComponent: Int] = [:]
        var remainders: [(component: ScoreComponent, remainder: Double, order: Int)] = []
        var floorSum = 0
        for (order, component) in ordered.enumerated() {
            let quota = Double(component.baseWeight) * 1000.0 / Double(baseSum)
            let floor = Int(quota)
            floors[component] = floor
            floorSum += floor
            remainders.append((component, quota - Double(floor), order))
        }
        // Hand out the missing points to the largest remainders; ties break by declaration
        // order so the result is identical on every device and OS version (C9).
        let missing = 1000 - floorSum
        let ranked = remainders.sorted {
            $0.remainder != $1.remainder ? $0.remainder > $1.remainder : $0.order < $1.order
        }
        for entry in ranked.prefix(missing) {
            floors[entry.component]! += 1
        }
        return floors
    }
}

/// Everything the scorer needs about one locked-in attempt.
public struct AttemptInput: Sendable {
    public let chosenTier: DecisionTier
    /// Chosen size as a fraction of the pool; nil when the size component is inactive
    /// or the chosen action carries no size.
    public let sizeFraction: Double?
    /// Authored recommended band [lo, hi] as fractions of the pool.
    public let sizeBand: ClosedRange<Double>?
    /// Player estimate and engine truth, both in percent (0–100).
    public let probabilityEstimate: Double?
    public let probabilityTruth: Double?
    public let chosenVariables: Set<String>
    public let variableKey: Set<String>
    public let confidence: Confidence
    public let activeComponents: Set<ScoreComponent>

    public init(
        chosenTier: DecisionTier,
        sizeFraction: Double? = nil,
        sizeBand: ClosedRange<Double>? = nil,
        probabilityEstimate: Double? = nil,
        probabilityTruth: Double? = nil,
        chosenVariables: Set<String> = [],
        variableKey: Set<String> = [],
        confidence: Confidence,
        activeComponents: Set<ScoreComponent>
    ) {
        self.chosenTier = chosenTier
        self.sizeFraction = sizeFraction
        self.sizeBand = sizeBand
        self.probabilityEstimate = probabilityEstimate
        self.probabilityTruth = probabilityTruth
        self.chosenVariables = chosenVariables
        self.variableKey = variableKey
        self.confidence = confidence
        self.activeComponents = activeComponents
    }
}

public struct ScoreBreakdown: Sendable, Equatable {
    public let components: [ScoreComponent: Int]
    public let total: Int
    public let tier: DecisionTier
    public let stars: Int

    public init(components: [ScoreComponent: Int], total: Int, tier: DecisionTier, stars: Int) {
        self.components = components
        self.total = total
        self.tier = tier
        self.stars = stars
    }
}

/// The §8 scoring formula. Pure function of the attempt input.
public enum PuzzleScorer {

    public static func score(_ input: AttemptInput) -> ScoreBreakdown {
        let weights = ComponentWeights.redistributed(active: input.activeComponents)
        var components: [ScoreComponent: Int] = [:]

        for (component, weight) in weights {
            let fraction: Double
            switch component {
            case .decision:
                fraction = input.chosenTier.fraction
            case .size:
                fraction = sizeFraction(chosen: input.sizeFraction, band: input.sizeBand)
            case .probability:
                fraction = probabilityFraction(estimate: input.probabilityEstimate, truth: input.probabilityTruth)
            case .variables:
                fraction = variablesFraction(chosen: input.chosenVariables, key: input.variableKey)
            case .confidence:
                fraction = confidenceFraction(input.confidence, tier: input.chosenTier)
            }
            components[component] = Int((fraction * Double(weight)).rounded())
        }

        let total = components.values.reduce(0, +)
        return ScoreBreakdown(
            components: components,
            total: total,
            tier: input.chosenTier,
            stars: StarRule.stars(tier: input.chosenTier, total: total)
        )
    }

    /// §8.3 — inside the band = 1.0; outside decays linearly to 0 at 2× band-width distance.
    /// Choosing a size-less action against a sized recommendation scores 0 unless Excellent.
    static func sizeFraction(chosen: Double?, band: ClosedRange<Double>?) -> Double {
        guard let band else { return 0 }
        guard let chosen else { return 0 }
        if band.contains(chosen) { return 1.0 }
        let width = max(band.upperBound - band.lowerBound, 0.05)
        let distance = chosen < band.lowerBound ? band.lowerBound - chosen : chosen - band.upperBound
        return max(0, 1.0 - distance / (2.0 * width))
    }

    /// §8.5 — full credit within ±3 percentage points, linear to 0 at ±20.
    static func probabilityFraction(estimate: Double?, truth: Double?) -> Double {
        guard let estimate, let truth else { return 0 }
        let diff = abs(estimate - truth)
        if diff <= 3 { return 1.0 }
        if diff >= 20 { return 0.0 }
        return (20.0 - diff) / 17.0
    }

    /// §8.4 — +50 per correct tag, −25 per incorrect tag, floored at 0, capped at 150;
    /// expressed as a fraction of the base 150.
    static func variablesFraction(chosen: Set<String>, key: Set<String>) -> Double {
        let correct = chosen.intersection(key).count
        let incorrect = chosen.subtracting(key).count
        let raw = min(max(correct * 50 - incorrect * 25, 0), 150)
        return Double(raw) / 150.0
    }

    /// §8.5 confidence table (C13). Honest uncertainty is rewarded; confident errors are not.
    static func confidenceFraction(_ confidence: Confidence, tier: DecisionTier) -> Double {
        let strong = tier >= .strong
        let defensible = tier == .defensible
        switch confidence {
        case .high: return strong ? 1.0 : (defensible ? 0.4 : 0.0)
        case .medium: return strong ? 0.7 : (defensible ? 1.0 : 0.4)
        case .low: return strong ? 0.4 : (defensible ? 0.7 : 1.0)
        }
    }
}

/// §8.6 / C3 — stars key on the decision tier first, total score second. Never on outcomes.
public enum StarRule {
    public static func stars(tier: DecisionTier, total: Int) -> Int {
        if tier == .excellent && total >= 850 { return 3 }
        if tier >= .strong && total >= 650 { return 2 }
        if tier >= .defensible && total >= 400 { return 1 }
        return 0
    }
}

/// C10 — the Standing Value Model: converts point stacks into expected ranking points
/// (Malmuth–Harville). Labeled everywhere as "assumes equal skill; a simplification."
public enum StandingValueModel {

    /// `payouts[i]` = ranking points for finishing in place i (descending). Shorter payout
    /// arrays are zero-padded. Supports up to 12 players (subset-mask memoization).
    public static func expectedRankingPoints(stacks: [Int], payouts: [Double]) -> [Double] {
        precondition(!stacks.isEmpty && stacks.count <= 12)
        precondition(stacks.allSatisfy { $0 > 0 }, "Stacks must be positive")

        let count = stacks.count
        var paddedPayouts = payouts
        if paddedPayouts.count < count {
            paddedPayouts += Array(repeating: 0, count: count - paddedPayouts.count)
        }
        let doubleStacks = stacks.map(Double.init)
        var memo: [Int: [Double]] = [:]

        // EV vector for the players in `mask`, competing for payouts starting at `place`.
        func ev(mask: Int) -> [Double] {
            if let cached = memo[mask] { return cached }
            var result = [Double](repeating: 0, count: count)
            let members = (0..<count).filter { mask & (1 << $0) != 0 }
            let place = count - members.count
            if members.count == 1 {
                result[members[0]] = paddedPayouts[place]
                memo[mask] = result
                return result
            }
            let total = members.reduce(0.0) { $0 + doubleStacks[$1] }
            for winner in members {
                let p = doubleStacks[winner] / total
                result[winner] += p * paddedPayouts[place]
                let sub = ev(mask: mask & ~(1 << winner))
                for j in members where j != winner {
                    result[j] += p * sub[j]
                }
            }
            memo[mask] = result
            return result
        }

        return ev(mask: (1 << count) - 1)
    }
}
