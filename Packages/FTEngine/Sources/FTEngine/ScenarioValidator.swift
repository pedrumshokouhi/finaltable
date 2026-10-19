import Foundation

/// Validation failures for a scenario (02_SCHEMAS.md §1.2). A scenario is playable only
/// when `ScenarioValidator.errors` returns an empty array. The generator-profile rules
/// (opponent-behavior consistency) arrive with the generator in Phase 7.
public enum ValidationError: Error, Equatable, CustomStringConvertible {
    case duplicateCard(Card)
    case wrongPlayerCardCount(Int)
    case sharedCardCountMismatch(expected: Int, found: Int)
    case invalidSeatCount(Int)
    case nonConsecutiveSeats
    case playerNotSeatZero
    case nonPositiveStack(seat: Int)
    case unknownActingSeat(Int)
    case actionAfterWithdraw(seat: Int)
    case challengeExceedsStack(seat: Int)
    case challengeNotAboveRequirement(seat: Int)
    case challengeMissingSize(seat: Int)
    case passFacingRequirement(seat: Int)
    case tooFewActivePlayers(Int)
    case invalidDifficulty(Int)
    case noLegalOptions
    case missingTier(GameActionType)
    case noExcellentOption
    case degenerateTiers
    case invalidSizeBand

    public var description: String {
        switch self {
        case .duplicateCard(let card): return "Duplicate card: \(card)"
        case .wrongPlayerCardCount(let n): return "Player must hold exactly 2 cards, found \(n)"
        case .sharedCardCountMismatch(let expected, let found):
            return "Street expects \(expected) shared cards, found \(found)"
        case .invalidSeatCount(let n): return "Seat count must be 2–9, found \(n)"
        case .nonConsecutiveSeats: return "Seat indices must be consecutive from 0"
        case .playerNotSeatZero: return "The player must occupy seat 0"
        case .nonPositiveStack(let seat): return "Seat \(seat) has a non-positive stack"
        case .unknownActingSeat(let seat): return "Action by unknown seat \(seat)"
        case .actionAfterWithdraw(let seat): return "Seat \(seat) acted after withdrawing"
        case .challengeExceedsStack(let seat): return "Seat \(seat) challenged more than its stack"
        case .challengeNotAboveRequirement(let seat): return "Seat \(seat) challenged without raising the requirement"
        case .challengeMissingSize(let seat): return "Seat \(seat) challenged without a size"
        case .passFacingRequirement(let seat): return "Seat \(seat) passed while facing a requirement"
        case .tooFewActivePlayers(let n): return "At least 2 active players required, found \(n)"
        case .invalidDifficulty(let d): return "Difficulty must be 1–10, found \(d)"
        case .noLegalOptions: return "Scenario offers no legal options"
        case .missingTier(let action): return "Option \(action.rawValue) has no authored tier"
        case .noExcellentOption: return "No option is tiered Excellent"
        case .degenerateTiers: return "All options share one tier — no meaningful decision"
        case .invalidSizeBand: return "Size band must be [lo, hi] with 0 < lo ≤ hi"
        }
    }
}

public enum ScenarioValidator {

    public static func validate(_ scenario: Scenario) throws {
        let found = errors(scenario)
        if let first = found.first { throw first }
    }

    public static func errors(_ scenario: Scenario) -> [ValidationError] {
        var errors: [ValidationError] = []

        // Cards.
        if scenario.deal.playerCards.count != 2 {
            errors.append(.wrongPlayerCardCount(scenario.deal.playerCards.count))
        }
        let expectedShared = scenario.deal.street.sharedCardCount
        if scenario.deal.sharedCards.count != expectedShared {
            errors.append(.sharedCardCountMismatch(expected: expectedShared, found: scenario.deal.sharedCards.count))
        }
        var seen = CardSet()
        for card in scenario.deal.playerCards + scenario.deal.sharedCards where !seen.insert(card) {
            errors.append(.duplicateCard(card))
        }

        // Seats.
        let seats = scenario.table.seats
        if !(2...9).contains(seats.count) {
            errors.append(.invalidSeatCount(seats.count))
        }
        if seats.map(\.seat) != Array(0..<seats.count) {
            errors.append(.nonConsecutiveSeats)
        }
        if seats.first?.seat != 0 || seats.first?.profile != nil {
            errors.append(.playerNotSeatZero)
        }
        for seat in seats where seat.stack <= 0 {
            errors.append(.nonPositiveStack(seat: seat.seat))
        }
        let activeCount = seats.filter { $0.status == .active }.count
        if activeCount < 2 {
            errors.append(.tooFewActivePlayers(activeCount))
        }

        // Action sequence legality.
        errors.append(contentsOf: actionSequenceErrors(scenario))

        // Difficulty.
        if !(1...10).contains(scenario.difficulty) {
            errors.append(.invalidDifficulty(scenario.difficulty))
        }

        // Decision spec and tiers.
        if scenario.decisionSpec.options.isEmpty {
            errors.append(.noLegalOptions)
        }
        var tiers: [DecisionTier] = []
        for option in scenario.decisionSpec.options {
            if let tier = scenario.solution.tiers[option.rawValue] {
                tiers.append(tier)
            } else {
                errors.append(.missingTier(option))
            }
        }
        if !tiers.isEmpty {
            if !tiers.contains(.excellent) {
                errors.append(.noExcellentOption)
            }
            if tiers.count > 1 && Set(tiers).count == 1 {
                errors.append(.degenerateTiers)
            }
        }

        // Size band.
        if let band = scenario.solution.sizeBand {
            if band.count != 2 || band[0] <= 0 || band[0] > band[1] {
                errors.append(.invalidSizeBand)
            }
        }

        return errors
    }

    /// Replays the timeline: withdrawn seats stay silent, challenges must raise the requirement
    /// and fit the stack, and a pass is illegal while facing an unmatched requirement.
    private static func actionSequenceErrors(_ scenario: Scenario) -> [ValidationError] {
        var errors: [ValidationError] = []
        let seatsByIndex = Dictionary(uniqueKeysWithValues: scenario.table.seats.map { ($0.seat, $0) })

        var withdrawn: Set<Int> = []
        var requirement = 0
        var contribution: [Int: Int] = [:]

        for record in scenario.actionHistory {
            guard let seat = seatsByIndex[record.seat] else {
                errors.append(.unknownActingSeat(record.seat))
                continue
            }
            if withdrawn.contains(record.seat) {
                errors.append(.actionAfterWithdraw(seat: record.seat))
                continue
            }
            switch record.action {
            case .withdraw:
                withdrawn.insert(record.seat)
            case .pass:
                if contribution[record.seat, default: 0] < requirement {
                    errors.append(.passFacingRequirement(seat: record.seat))
                }
            case .match:
                contribution[record.seat] = requirement
            case .challenge:
                guard let size = record.size else {
                    errors.append(.challengeMissingSize(seat: record.seat))
                    continue
                }
                if size <= requirement {
                    errors.append(.challengeNotAboveRequirement(seat: record.seat))
                }
                if size > seat.stack {
                    errors.append(.challengeExceedsStack(seat: record.seat))
                }
                requirement = max(requirement, size)
                contribution[record.seat] = size
            }
        }
        return errors
    }
}
