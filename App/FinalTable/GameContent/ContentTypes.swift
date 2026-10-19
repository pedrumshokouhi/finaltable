import Foundation
import FTEngine

// Compact level-authoring layer. Levels are Scenario values (FTEngine), validated by
// ScenarioValidator both in DEBUG at load and by the ftcontent CLI check.
// Content-as-code for the offline test build; the JSON export pipeline (02_SCHEMAS.md)
// serializes these same values for release.

/// Variable tags shown on the "what mattered most" step. Every puzzle shows 6.
enum V {
    static let position = "Position"
    static let poolOdds = "Pool odds"
    static let stackDepth = "Stack depth"
    static let profile = "Opponent profile"
    static let standing = "Standing value"
    static let removal = "Card removal"
    static let category = "Hand category"
    static let multiway = "Multi-player field"
    static let all: [String] = [position, poolOdds, stackDepth, profile, standing, removal, category, multiway]
}

/// Seat shorthand for authoring. Seat indices are assigned by array order; index 0 is the player.
struct St {
    let pos: Position
    let stack: Int
    let prof: OpponentProfile?
    let out: Bool

    init(_ pos: Position, _ stack: Int, _ prof: OpponentProfile? = nil, out: Bool = false) {
        self.pos = pos
        self.stack = stack
        self.prof = prof
        self.out = out
    }
}

/// Action shorthand for authoring timelines.
struct Act {
    let seat: Int
    let action: GameActionType
    let size: Int?

    static func w(_ seat: Int) -> Act { Act(seat: seat, action: .withdraw, size: nil) }
    static func p(_ seat: Int) -> Act { Act(seat: seat, action: .pass, size: nil) }
    static func m(_ seat: Int) -> Act { Act(seat: seat, action: .match, size: nil) }
    static func ch(_ seat: Int, _ size: Int) -> Act { Act(seat: seat, action: .challenge, size: size) }
}

struct ChapterInfo: Identifiable {
    let num: Int
    let title: String
    let skill: String
    let primer: String
    var id: Int { num }
}

/// Builds one campaign level. Street is derived from the board; active score components
/// derive from which inputs the level authors (C1/C2).
func lvl(
    _ id: String, ch: Int, t: String, d: Int,
    obj: String, learn: String, skill: String,
    hole: String, board: String = "",
    seats: [St], pool: Int, req: Int, hist: [Act],
    opts: [GameActionType], tiers: [GameActionType: DecisionTier],
    rec: GameActionType, recSize: Double? = nil,
    band: ClosedRange<Double>? = nil, stops: [Double]? = nil,
    probQ: String? = nil, probN: Int? = nil, probD: Int? = nil, probPct: Double? = nil,
    probBasis: String = "exactEnumeration", assume: [String] = [],
    vars: [String],
    quick: String, coach: String, mistake: String, take: String,
    varyP: String? = nil, varyE: String? = nil, varyR: GameActionType? = nil
) -> Scenario {
    let player = parseCards(hole)!
    let shared = board.isEmpty ? [] : parseCards(board)!
    let street: Street
    switch shared.count {
    case 0: street = .preShared
    case 3: street = .threeShared
    case 4: street = .fourShared
    default: street = .fiveShared
    }

    let seatModels = seats.enumerated().map { index, s in
        PlayerSeat(seat: index, position: s.pos, stack: s.stack,
                   profile: index == 0 ? nil : s.prof,
                   status: s.out ? .withdrawn : .active)
    }

    var active: [ScoreComponent] = [.decision, .variables, .confidence]
    if probQ != nil { active.insert(.probability, at: 1) }
    if band != nil { active.insert(.size, at: 1) }

    var probabilityKey: ProbabilityKey?
    if let probQ, let probPct {
        probabilityKey = ProbabilityKey(
            question: probQ, exactNumerator: probN, exactDenominator: probD,
            displayPercent: probPct,
            friendly: FriendlyProbability.describe(probPct / 100.0),
            basis: probBasis, assumptions: assume)
    }

    let distractors = V.all.filter { !vars.contains($0) }.prefix(6 - vars.count)

    var variation: ScenarioVariation?
    if let varyP, let varyE, let varyR {
        variation = ScenarioVariation(
            prompt: varyP, explanation: varyE,
            newRecommended: RecommendedDecision(action: varyR))
    }

    return Scenario(
        id: id, chapter: ch, title: t,
        learningObjective: learn, difficulty: d, skillTags: [skill],
        deal: DealState(playerCards: player, sharedCards: shared, street: street),
        table: TableState(seats: seatModels, pool: pool, requirement: req),
        actionHistory: hist.map { ActionRecord(seat: $0.seat, action: $0.action, size: $0.size) },
        objective: obj,
        decisionSpec: DecisionSpec(
            options: opts, sizeStops: stops,
            activeComponents: active),
        solution: PuzzleSolution(
            recommended: RecommendedDecision(action: rec, sizeFraction: recSize),
            tiers: Dictionary(uniqueKeysWithValues: tiers.map { ($0.key.rawValue, $0.value) }),
            sizeBand: band.map { [$0.lowerBound, $0.upperBound] },
            probabilityKey: probabilityKey,
            variableKey: vars, distractorVariables: Array(distractors)),
        explanations: Explanations(quick: quick, coach: coach, commonMistake: mistake, takeaway: take),
        variation: variation)
}

enum ContentLibrary {
    static let chapters: [ChapterInfo] = [
        ChapterInfo(num: 1, title: "Foundations", skill: "Hand recognition",
                    primer: "Ranks, hand categories, and the one rule that governs everything: only five cards count. Learn to name your true hand before you act on it."),
        ChapterInfo(num: 2, title: "Probability", skill: "Probability",
                    primer: "Count the cards that help you, turn the count into a percentage, and compare it to the price. The ×4 and ×2 shortcuts get you close; the engine shows you exactly."),
        ChapterInfo(num: 3, title: "Position", skill: "Position",
                    primer: "Acting last means acting informed. The same cards change value with your seat — often more than the cards themselves."),
        ChapterInfo(num: 4, title: "Resource Depth", skill: "Resource management",
                    primer: "A deep stack buys patience; a short stack demands decisiveness. Learn the commitment thresholds that keep you from dribbling points away."),
        ChapterInfo(num: 5, title: "Action Sizing", skill: "Action sizing",
                    primer: "A challenge's size is a price you set for your opponents. Wet boards charge more; dry boards charge less; the slider is a message."),
        ChapterInfo(num: 6, title: "Opponent Profiles", skill: "Opponent modeling",
                    primer: "The same action means different things from different players. Five profiles — cautious, balanced, aggressive, unpredictable, overly passive — and what each one's pressure is really saying."),
        ChapterInfo(num: 7, title: "Multi-Player Decisions", skill: "Multi-player reasoning",
                    primer: "Every extra opponent raises the bar your hand must clear. Standards, prices, and reads all shift when the table gets crowded."),
        ChapterInfo(num: 8, title: "Tournament Pressure", skill: "Tournament pressure",
                    primer: "Game points and ranking points are different currencies. The Standing Value Model shows when survival is worth more than a profitable gamble. All rewards here are fictional points and badges."),
        ChapterInfo(num: 9, title: "Advanced Reasoning", skill: "Advanced reasoning",
                    primer: "Sequences tell stories, the cards you hold remove hands your opponents can claim, and sometimes the answer is deliberately mixed."),
        ChapterInfo(num: 10, title: "Final Table Mastery", skill: "Mastery",
                    primer: "Position, depth, probability, profiles, sizing, and standing pressure — weighed at once. The capstone table.")
    ]

    static func allLevels() -> [Scenario] {
        levelsChapter1() + levelsChapter2() + levelsChapter3() + levelsChapter4()
            + levelsChapter5() + levelsChapter6() + levelsChapter7() + levelsChapter8()
            + levelsChapter9() + levelsChapter10()
    }

    static func levels(chapter: Int) -> [Scenario] {
        allLevels().filter { $0.chapter == chapter }
    }
}
