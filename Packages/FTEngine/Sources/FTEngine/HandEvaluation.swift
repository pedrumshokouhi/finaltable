import Foundation

/// The nine hand categories, ordered weakest to strongest. A royal flush is a straight flush
/// whose high card is an ace (see `HandRank.isRoyalFlush`) — display distinction only.
public enum HandCategory: Int, Comparable, CaseIterable, Hashable, Sendable, Codable {
    case highCard = 0
    case pair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush

    public static func < (lhs: HandCategory, rhs: HandCategory) -> Bool { lhs.rawValue < rhs.rawValue }

    public var displayName: String {
        switch self {
        case .highCard: return "High Card"
        case .pair: return "Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        }
    }
}

/// Totally ordered strength of a best-five hand.
/// Layout: category in bits 20–23, then five 4-bit rank nibbles in descending significance.
/// Equal values are exact ties (the hands split).
public struct HandRank: Comparable, Hashable, Sendable {
    public let value: UInt32

    init(category: HandCategory, significantRanks: [Int]) {
        precondition(significantRanks.count <= 5)
        var v = UInt32(category.rawValue) << 20
        var shift: UInt32 = 16
        for rank in significantRanks {
            v |= UInt32(rank) << shift
            shift = shift >= 4 ? shift - 4 : 0
        }
        value = v
    }

    public var category: HandCategory { HandCategory(rawValue: Int(value >> 20))! }

    /// The most significant rank nibble (e.g. the straight's high card, the pair's rank).
    public var primaryRank: Rank { Rank(rawValue: Int((value >> 16) & 0xF))! }

    public var isRoyalFlush: Bool { category == .straightFlush && primaryRank == .ace }

    public static func < (lhs: HandRank, rhs: HandRank) -> Bool { lhs.value < rhs.value }
}

/// Five-to-seven-card hand evaluation. Pure functions, no state.
public enum Evaluator {

    /// Evaluates exactly five cards.
    public static func evaluateFive(_ cards: [Card]) -> HandRank {
        precondition(cards.count == 5, "evaluateFive requires exactly 5 cards")

        var countsByRank: [Int: Int] = [:]
        for card in cards { countsByRank[card.rank.rawValue, default: 0] += 1 }

        let isFlush = Set(cards.map(\.suit)).count == 1
        let uniqueRanks = Set(countsByRank.keys)
        let straightHighCard = uniqueRanks.count == 5 ? straightHigh(uniqueRanks) : nil

        if let high = straightHighCard, isFlush {
            return HandRank(category: .straightFlush, significantRanks: [high])
        }

        // Groups sorted by count desc, then rank desc — drives every non-straight/flush category.
        let groups = countsByRank.sorted { ($0.value, $0.key) > ($1.value, $1.key) }
        let counts = groups.map(\.value)
        let ranks = groups.map(\.key)

        switch counts {
        case [4, 1]:
            return HandRank(category: .fourOfAKind, significantRanks: ranks)
        case [3, 2]:
            return HandRank(category: .fullHouse, significantRanks: ranks)
        default:
            break
        }
        if isFlush {
            return HandRank(category: .flush, significantRanks: ranks)
        }
        if let high = straightHighCard {
            return HandRank(category: .straight, significantRanks: [high])
        }
        switch counts {
        case [3, 1, 1]:
            return HandRank(category: .threeOfAKind, significantRanks: ranks)
        case [2, 2, 1]:
            return HandRank(category: .twoPair, significantRanks: ranks)
        case [2, 1, 1, 1]:
            return HandRank(category: .pair, significantRanks: ranks)
        default:
            return HandRank(category: .highCard, significantRanks: ranks)
        }
    }

    /// Best five-card hand selectable from 5, 6, or 7 cards.
    public static func best(_ cards: [Card]) -> HandRank {
        precondition((5...7).contains(cards.count), "best(_:) requires 5–7 cards")
        if cards.count == 5 { return evaluateFive(cards) }

        let combos = cards.count == 6 ? Combinatorics.choose6of5 : Combinatorics.choose7of5
        var bestRank = HandRank(category: .highCard, significantRanks: [])
        var hand = [Card](repeating: cards[0], count: 5)
        for combo in combos {
            for (slot, index) in combo.enumerated() { hand[slot] = cards[index] }
            let rank = evaluateFive(hand)
            if rank > bestRank { bestRank = rank }
        }
        return bestRank
    }

    /// The straight's high-card value for a set of 5 distinct rank values, or nil.
    /// Handles the wheel (A-2-3-4-5 → high card 5).
    static func straightHigh(_ ranks: Set<Int>) -> Int? {
        guard ranks.count == 5, let maxRank = ranks.max(), let minRank = ranks.min() else { return nil }
        if maxRank - minRank == 4 { return maxRank }
        if ranks == [14, 2, 3, 4, 5] { return 5 }
        return nil
    }
}

/// Precomputed index combinations and binomial coefficients.
public enum Combinatorics {
    static let choose6of5: [[Int]] = combinations(count: 6, choose: 5)
    static let choose7of5: [[Int]] = combinations(count: 7, choose: 5)

    /// All k-element index combinations of 0..<n, lexicographic.
    public static func combinations(count n: Int, choose k: Int) -> [[Int]] {
        guard k <= n, k >= 0 else { return [] }
        var result: [[Int]] = []
        var current: [Int] = []
        func recurse(from start: Int) {
            if current.count == k {
                result.append(current)
                return
            }
            let needed = k - current.count
            guard n - start >= needed else { return }
            for i in start...(n - needed) {
                current.append(i)
                recurse(from: i + 1)
                current.removeLast()
            }
        }
        recurse(from: 0)
        return result
    }

    /// Binomial coefficient C(n, k) in integer arithmetic.
    public static func binomial(_ n: Int, _ k: Int) -> Int {
        guard k >= 0, k <= n else { return 0 }
        let k = min(k, n - k)
        var result = 1
        for i in 0..<k {
            result = result * (n - i) / (i + 1)
        }
        return result
    }
}
