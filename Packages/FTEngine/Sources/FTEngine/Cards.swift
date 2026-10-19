import Foundation

/// One of the four card suits. Raw value is the single-character code used in level JSON ("As", "Td").
public enum Suit: Character, CaseIterable, Hashable, Sendable, Codable {
    case clubs = "c"
    case diamonds = "d"
    case hearts = "h"
    case spades = "s"

    /// Stable 0-based index (alphabetical by code) used for card packing.
    public var index: Int {
        switch self {
        case .clubs: return 0
        case .diamonds: return 1
        case .hearts: return 2
        case .spades: return 3
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }
}

/// Card rank, two through ace. Raw value is the comparison value (ace high = 14).
public enum Rank: Int, CaseIterable, Hashable, Sendable, Codable, Comparable {
    case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace

    public static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    private static let characters: [Character] = ["2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A"]

    public var character: Character { Rank.characters[rawValue - 2] }

    public init?(character: Character) {
        guard let offset = Rank.characters.firstIndex(of: character) else { return nil }
        self.init(rawValue: offset + 2)
    }
}

/// A single playing card. Encodes/decodes as a two-character string ("As") to match level JSON.
public struct Card: Hashable, Sendable, CustomStringConvertible, Codable {
    public let rank: Rank
    public let suit: Suit

    public init(_ rank: Rank, _ suit: Suit) {
        self.rank = rank
        self.suit = suit
    }

    /// Parses "As", "Td", "9c"… Returns nil for anything else.
    public init?(_ string: String) {
        let chars = Array(string)
        guard chars.count == 2,
              let rank = Rank(character: chars[0]),
              let suit = Suit(rawValue: chars[1]) else { return nil }
        self.init(rank, suit)
    }

    /// Unique index 0…51.
    public var index: Int { (rank.rawValue - 2) * 4 + suit.index }

    public var description: String { "\(rank.character)\(suit.rawValue)" }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let card = Card(string) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid card code: \(string)")
        }
        self = card
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    /// All 52 cards, in index order.
    public static let fullDeck: [Card] = {
        var deck: [Card] = []
        for rank in Rank.allCases {
            for suit in Suit.allCases {
                deck.append(Card(rank, suit))
            }
        }
        return deck
    }()
}

/// A set of cards backed by a 52-bit mask — O(1) membership and duplicate detection.
public struct CardSet: Hashable, Sendable {
    public private(set) var mask: UInt64

    public init() { mask = 0 }

    public init(_ cards: some Sequence<Card>) {
        mask = 0
        for card in cards { mask |= 1 << UInt64(card.index) }
    }

    /// Inserts the card. Returns false (and leaves the set unchanged) if it was already present.
    @discardableResult
    public mutating func insert(_ card: Card) -> Bool {
        let bit: UInt64 = 1 << UInt64(card.index)
        guard mask & bit == 0 else { return false }
        mask |= bit
        return true
    }

    public func contains(_ card: Card) -> Bool {
        mask & (1 << UInt64(card.index)) != 0
    }

    public var count: Int { mask.nonzeroBitCount }

    /// All cards NOT in this set, in index order.
    public var complement: [Card] {
        Card.fullDeck.filter { !contains($0) }
    }

    /// True if the sequence contains no duplicate cards.
    public static func allUnique(_ cards: some Sequence<Card>) -> Bool {
        var set = CardSet()
        for card in cards where !set.insert(card) { return false }
        return true
    }
}

/// Parses a space-separated card list ("As Kd 9h"). Returns nil on any invalid or duplicate card.
public func parseCards(_ string: String) -> [Card]? {
    let tokens = string.split(separator: " ")
    var cards: [Card] = []
    cards.reserveCapacity(tokens.count)
    for token in tokens {
        guard let card = Card(String(token)) else { return nil }
        cards.append(card)
    }
    guard CardSet.allUnique(cards) else { return nil }
    return cards
}
