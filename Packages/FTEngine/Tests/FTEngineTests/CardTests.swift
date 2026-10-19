import XCTest
@testable import FTEngine

/// Shared helper: parse a card string that tests assert is valid.
func c(_ s: String) -> Card {
    guard let card = Card(s) else { fatalError("Test fixture has invalid card: \(s)") }
    return card
}

/// Shared helper: parse a space-separated list of cards.
func cs(_ s: String) -> [Card] {
    guard let cards = parseCards(s) else { fatalError("Test fixture has invalid cards: \(s)") }
    return cards
}

final class CardTests: XCTestCase {

    func testParsesValidCard() {
        let card = Card("As")
        XCTAssertEqual(card?.rank, .ace)
        XCTAssertEqual(card?.suit, .spades)
    }

    func testParsesTenAsT() {
        XCTAssertEqual(Card("Td")?.rank, .ten)
    }

    func testRejectsInvalidRank() {
        XCTAssertNil(Card("1s"))
        XCTAssertNil(Card("Xs"))
    }

    func testRejectsInvalidSuit() {
        XCTAssertNil(Card("Ax"))
        XCTAssertNil(Card("A♠"))
    }

    func testRejectsWrongLength() {
        XCTAssertNil(Card("A"))
        XCTAssertNil(Card("Asd"))
        XCTAssertNil(Card(""))
    }

    func testDescriptionRoundTripsForAllCards() {
        for card in Card.fullDeck {
            XCTAssertEqual(Card(card.description), card)
        }
    }

    func testAllFiftyTwoIndicesUnique() {
        XCTAssertEqual(Card.fullDeck.count, 52)
        XCTAssertEqual(Set(Card.fullDeck.map(\.index)).count, 52)
        XCTAssertEqual(Card.fullDeck.map(\.index).min(), 0)
        XCTAssertEqual(Card.fullDeck.map(\.index).max(), 51)
    }

    func testRankComparable() {
        XCTAssertLessThan(Rank.two, Rank.three)
        XCTAssertLessThan(Rank.king, Rank.ace)
        XCTAssertGreaterThan(Rank.ten, Rank.nine)
    }

    func testRankCharacterRoundTripsForAllRanks() {
        for rank in Rank.allCases {
            XCTAssertEqual(Rank(character: rank.character), rank)
        }
    }

    func testCardSetRejectsDuplicates() {
        var set = CardSet()
        XCTAssertTrue(set.insert(c("As")))
        XCTAssertFalse(set.insert(c("As")))
        XCTAssertEqual(set.count, 1)
    }

    func testCardSetComplementCounts() {
        let set = CardSet(cs("As Kd 9h"))
        XCTAssertEqual(set.count, 3)
        XCTAssertEqual(set.complement.count, 49)
        XCTAssertFalse(set.complement.contains(c("As")))
    }

    func testAllUniqueDetectsDuplicates() {
        XCTAssertTrue(CardSet.allUnique(cs("As Kd 9h")))
        XCTAssertFalse(CardSet.allUnique([c("As"), c("Kd"), c("As")]))
    }

    func testParseCardsRejectsDuplicatesAndGarbage() {
        XCTAssertNil(parseCards("As Kd As"))
        XCTAssertNil(parseCards("As Zz"))
        XCTAssertEqual(parseCards("As Kd")?.count, 2)
    }

    func testCardCodableRoundTrip() throws {
        let cards = cs("As Td 2c")
        let data = try JSONEncoder().encode(cards)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"["As","Td","2c"]"#)
        let decoded = try JSONDecoder().decode([Card].self, from: data)
        XCTAssertEqual(decoded, cards)
    }

    func testCardDecodingRejectsInvalidString() {
        let data = Data(#"["Zz"]"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode([Card].self, from: data))
    }

    func testSuitSymbols() {
        XCTAssertEqual(Suit.spades.symbol, "♠")
        XCTAssertEqual(Suit.hearts.symbol, "♥")
        XCTAssertEqual(Suit.diamonds.symbol, "♦")
        XCTAssertEqual(Suit.clubs.symbol, "♣")
    }
}
