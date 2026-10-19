import SwiftUI
import FTEngine

// Design tokens: deep navy, emerald/teal accents, warm ivory type, gold for achievements.

enum FT {
    static let navy = Color(red: 0.043, green: 0.078, blue: 0.141)        // #0B1424 background
    static let navyDeep = Color(red: 0.027, green: 0.055, blue: 0.106)    // deeper wells
    static let surface = Color(red: 0.082, green: 0.133, blue: 0.216)     // #152237 cards/panels
    static let surfaceHi = Color(red: 0.118, green: 0.180, blue: 0.278)   // raised panels
    static let emerald = Color(red: 0.180, green: 0.760, blue: 0.494)     // #2EC27E primary accent
    static let teal = Color(red: 0.227, green: 0.486, blue: 0.455)        // muted teal
    static let ivory = Color(red: 0.949, green: 0.929, blue: 0.894)       // #F2EDE4 text
    static let ivoryDim = Color(red: 0.949, green: 0.929, blue: 0.894).opacity(0.62)
    static let gold = Color(red: 0.788, green: 0.635, blue: 0.153)        // achievements only
    static let danger = Color(red: 0.804, green: 0.361, blue: 0.322)      // withdraw/error
    static let felt = Color(red: 0.051, green: 0.180, blue: 0.145)        // table felt green-navy

    static func tierColor(_ tier: DecisionTier) -> Color {
        switch tier {
        case .excellent: return emerald
        case .strong: return Color(red: 0.42, green: 0.72, blue: 0.50)
        case .defensible: return Color(red: 0.72, green: 0.68, blue: 0.38)
        case .weak: return Color(red: 0.82, green: 0.55, blue: 0.30)
        case .majorError: return danger
        }
    }

    static func tierLabel(_ tier: DecisionTier) -> String {
        switch tier {
        case .excellent: return "Excellent"
        case .strong: return "Strong"
        case .defensible: return "Defensible"
        case .weak: return "Weak"
        case .majorError: return "Major Error"
        }
    }

    /// Color-blind-safe four-color suits.
    static func suitColor(_ suit: Suit) -> Color {
        switch suit {
        case .spades: return Color(red: 0.13, green: 0.15, blue: 0.19)
        case .hearts: return Color(red: 0.78, green: 0.22, blue: 0.24)
        case .diamonds: return Color(red: 0.16, green: 0.38, blue: 0.75)
        case .clubs: return Color(red: 0.17, green: 0.52, blue: 0.32)
        }
    }

    static func profileLabel(_ p: OpponentProfile?) -> String {
        switch p {
        case .cautious: return "Cautious"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        case .unpredictable: return "Unpredictable"
        case .overlyPassive: return "Passive"
        case nil: return "You"
        }
    }

    static func positionLabel(_ pos: Position) -> String {
        switch pos {
        case .early: return "Early"
        case .middle: return "Middle"
        case .late: return "Late"
        case .final: return "Final"
        }
    }

    /// Maps action labels through the terminology toggle (C7).
    static func actionLabel(_ a: GameActionType, standard: Bool) -> String {
        guard standard else { return a.educationalLabel }
        switch a {
        case .pass: return "Check"
        case .match: return "Call"
        case .challenge: return "Raise"
        case .withdraw: return "Fold"
        }
    }

    static func poolLabel(standard: Bool) -> String { standard ? "POT" : "POOL" }
    static func toMatchLabel(standard: Bool) -> String { standard ? "TO CALL" : "TO MATCH" }

    /// Per-action accent colors for the decision buttons.
    static func actionColor(_ a: GameActionType) -> Color {
        switch a {
        case .pass: return Color(red: 0.42, green: 0.52, blue: 0.66)
        case .match: return Color(red: 0.22, green: 0.62, blue: 0.62)
        case .challenge: return emerald
        case .withdraw: return Color(red: 0.72, green: 0.38, blue: 0.36)
        }
    }

    static func actionIcon(_ a: GameActionType) -> String {
        switch a {
        case .pass: return "hand.tap"
        case .match: return "equal.circle"
        case .challenge: return "chevron.up.2"
        case .withdraw: return "xmark"
        }
    }

    /// Deep felt for the table surface.
    static var feltGradient: RadialGradient {
        RadialGradient(
            colors: [Color(red: 0.075, green: 0.26, blue: 0.20),
                     Color(red: 0.045, green: 0.16, blue: 0.13),
                     Color(red: 0.03, green: 0.10, blue: 0.085)],
            center: .init(x: 0.5, y: 0.35), startRadius: 20, endRadius: 420)
    }
}

extension View {
    func ftPanel() -> some View {
        padding(14)
            .background(RoundedRectangle(cornerRadius: 14).fill(FT.surface))
    }
    func ftTitle() -> some View {
        font(.title2.weight(.semibold)).fontDesign(.serif).foregroundStyle(FT.ivory)
    }
}
