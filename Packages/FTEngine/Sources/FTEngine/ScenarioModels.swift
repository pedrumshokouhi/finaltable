import Foundation

// Domain models mirroring the level JSON schema (02_SCHEMAS.md §1). Codable field names
// match the schema keys exactly so FTContent can decode level files without mapping.

public enum Position: String, CaseIterable, Hashable, Sendable, Codable {
    case early, middle, late, final
}

public enum OpponentProfile: String, CaseIterable, Hashable, Sendable, Codable {
    case cautious, balanced, aggressive, unpredictable, overlyPassive
}

public enum SeatStatus: String, Hashable, Sendable, Codable {
    case active, withdrawn
}

public enum GameActionType: String, CaseIterable, Hashable, Sendable, Codable {
    case pass, match, challenge, withdraw

    /// Default educational label; the terminology toggle (C7) maps to standard terms in the app layer.
    public var educationalLabel: String {
        switch self {
        case .pass: return "Pass"
        case .match: return "Match"
        case .challenge: return "Challenge"
        case .withdraw: return "Withdraw"
        }
    }
}

public enum Street: String, Hashable, Sendable, Codable {
    case preShared, threeShared, fourShared, fiveShared

    public var sharedCardCount: Int {
        switch self {
        case .preShared: return 0
        case .threeShared: return 3
        case .fourShared: return 4
        case .fiveShared: return 5
        }
    }
}

public struct PlayerSeat: Hashable, Sendable, Codable {
    public let seat: Int
    public let position: Position
    public let stack: Int
    public let profile: OpponentProfile?
    public let status: SeatStatus

    public init(seat: Int, position: Position, stack: Int, profile: OpponentProfile?, status: SeatStatus) {
        self.seat = seat
        self.position = position
        self.stack = stack
        self.profile = profile
        self.status = status
    }
}

public struct ActionRecord: Hashable, Sendable, Codable {
    public let seat: Int
    public let action: GameActionType
    public let size: Int?

    public init(seat: Int, action: GameActionType, size: Int? = nil) {
        self.seat = seat
        self.action = action
        self.size = size
    }
}

public struct DealState: Hashable, Sendable, Codable {
    public let playerCards: [Card]
    public let sharedCards: [Card]
    public let street: Street

    public init(playerCards: [Card], sharedCards: [Card], street: Street) {
        self.playerCards = playerCards
        self.sharedCards = sharedCards
        self.street = street
    }
}

public struct TableState: Hashable, Sendable, Codable {
    public let pointUnit: String
    public let seats: [PlayerSeat]
    public let pool: Int
    public let requirement: Int

    public init(pointUnit: String = "pts", seats: [PlayerSeat], pool: Int, requirement: Int) {
        self.pointUnit = pointUnit
        self.seats = seats
        self.pool = pool
        self.requirement = requirement
    }
}

public struct DecisionSpec: Hashable, Sendable, Codable {
    /// Legal actions only; the UI renders all four buttons and disables the rest with a reason (C15).
    public let options: [GameActionType]
    public let sizeStops: [Double]?
    public let activeComponents: [ScoreComponent]

    public init(options: [GameActionType], sizeStops: [Double]? = nil, activeComponents: [ScoreComponent]) {
        self.options = options
        self.sizeStops = sizeStops
        self.activeComponents = activeComponents
    }
}

public struct ProbabilityKey: Hashable, Sendable, Codable {
    public let question: String
    public let exactNumerator: Int?
    public let exactDenominator: Int?
    public let displayPercent: Double
    public let friendly: String
    public let basis: String            // "exactEnumeration" | "seededSimulation" | "behavioralAssumption"
    public let assumptions: [String]

    public init(question: String, exactNumerator: Int?, exactDenominator: Int?,
                displayPercent: Double, friendly: String, basis: String, assumptions: [String]) {
        self.question = question
        self.exactNumerator = exactNumerator
        self.exactDenominator = exactDenominator
        self.displayPercent = displayPercent
        self.friendly = friendly
        self.basis = basis
        self.assumptions = assumptions
    }
}

public struct RecommendedDecision: Hashable, Sendable, Codable {
    public let action: GameActionType
    public let sizeFraction: Double?

    public init(action: GameActionType, sizeFraction: Double? = nil) {
        self.action = action
        self.sizeFraction = sizeFraction
    }
}

public struct PuzzleSolution: Hashable, Sendable, Codable {
    public let recommended: RecommendedDecision
    /// Tier for every legal option, keyed by `GameActionType.rawValue`.
    public let tiers: [String: DecisionTier]
    /// Recommended size band [lo, hi] as fractions of the pool, when sizing is active.
    public let sizeBand: [Double]?
    public let probabilityKey: ProbabilityKey?
    public let variableKey: [String]
    public let distractorVariables: [String]

    public init(recommended: RecommendedDecision, tiers: [String: DecisionTier], sizeBand: [Double]?,
                probabilityKey: ProbabilityKey?, variableKey: [String], distractorVariables: [String]) {
        self.recommended = recommended
        self.tiers = tiers
        self.sizeBand = sizeBand
        self.probabilityKey = probabilityKey
        self.variableKey = variableKey
        self.distractorVariables = distractorVariables
    }
}

public struct Explanations: Hashable, Sendable, Codable {
    public let quick: String
    public let coach: String
    public let commonMistake: String
    public let takeaway: String

    public init(quick: String, coach: String, commonMistake: String, takeaway: String) {
        self.quick = quick
        self.coach = coach
        self.commonMistake = commonMistake
        self.takeaway = takeaway
    }
}

public struct ScenarioVariation: Hashable, Sendable, Codable {
    public let prompt: String
    public let explanation: String
    public let newRecommended: RecommendedDecision

    public init(prompt: String, explanation: String, newRecommended: RecommendedDecision) {
        self.prompt = prompt
        self.explanation = explanation
        self.newRecommended = newRecommended
    }
}

/// A complete playable scenario — handcrafted (from JSON) or generated (from a seed).
public struct Scenario: Hashable, Sendable, Codable {
    public let schemaVersion: Int
    public let id: String
    public let chapter: Int?
    public let title: String
    public let learningObjective: String
    public let difficulty: Int
    public let skillTags: [String]
    public let deal: DealState
    public let table: TableState
    public let actionHistory: [ActionRecord]
    public let objective: String
    public let decisionSpec: DecisionSpec
    public let solution: PuzzleSolution
    public let explanations: Explanations
    public let variation: ScenarioVariation?

    public init(schemaVersion: Int = 1, id: String, chapter: Int?, title: String,
                learningObjective: String, difficulty: Int, skillTags: [String],
                deal: DealState, table: TableState, actionHistory: [ActionRecord],
                objective: String, decisionSpec: DecisionSpec, solution: PuzzleSolution,
                explanations: Explanations, variation: ScenarioVariation?) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.chapter = chapter
        self.title = title
        self.learningObjective = learningObjective
        self.difficulty = difficulty
        self.skillTags = skillTags
        self.deal = deal
        self.table = table
        self.actionHistory = actionHistory
        self.objective = objective
        self.decisionSpec = decisionSpec
        self.solution = solution
        self.explanations = explanations
        self.variation = variation
    }
}

/// C6 — reproducible generated-scenario identity: `FT1-<templateID>-<seed base36>-<genVersion>`.
public struct ScenarioSeed: Hashable, Sendable, Codable {
    public let templateID: String
    public let seed: UInt64
    public let generatorVersion: Int

    public init(templateID: String, seed: UInt64, generatorVersion: Int) {
        self.templateID = templateID
        self.seed = seed
        self.generatorVersion = generatorVersion
    }

    public var code: String {
        "FT1-\(templateID)-\(String(seed, radix: 36, uppercase: true))-\(generatorVersion)"
    }

    public init?(code: String) {
        let parts = code.split(separator: "-")
        guard parts.count == 4, parts[0] == "FT1",
              let seed = UInt64(parts[2].lowercased(), radix: 36),
              let version = Int(parts[3]) else { return nil }
        self.init(templateID: String(parts[1]), seed: seed, generatorVersion: version)
    }
}
