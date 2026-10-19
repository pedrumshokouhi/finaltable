import SwiftUI
import FTEngine

/// A rendered playing card: corner pips top-left and bottom-right, a large
/// suit watermark in the center, and a soft drop shadow over the felt.
/// Color-blind-safe suit colors + VoiceOver labels.
struct CardView: View {
    let card: Card
    var large = false

    private var rankText: String { String(card.rank.character) }
    private var corner: CGFloat { large ? 9 : 7 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(LinearGradient(colors: [.white, FT.ivory],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(card.suit.symbol)
                .font(.system(size: large ? 34 : 22))
                .foregroundStyle(FT.suitColor(card.suit).opacity(0.15))
        }
        .overlay(alignment: .topLeading) {
            cornerPip.padding(large ? 5 : 3)
        }
        .overlay(alignment: .bottomTrailing) {
            cornerPip.rotationEffect(.degrees(180)).padding(large ? 5 : 3)
        }
        .overlay(RoundedRectangle(cornerRadius: corner).stroke(.black.opacity(0.2), lineWidth: 0.5))
        .frame(width: large ? 56 : 40, height: large ? 78 : 56)
        .shadow(color: .black.opacity(0.35), radius: large ? 4 : 2, y: 2)
        .accessibilityLabel(accessibilityName)
    }

    private var cornerPip: some View {
        VStack(spacing: -2) {
            Text(rankText)
                .font(.system(size: large ? 17 : 13, weight: .bold, design: .rounded))
            Text(card.suit.symbol)
                .font(.system(size: large ? 11 : 8))
        }
        .foregroundStyle(FT.suitColor(card.suit))
    }

    private var accessibilityName: String {
        let ranks = ["two","three","four","five","six","seven","eight","nine","ten","jack","queen","king","ace"]
        let suits: [Suit: String] = [.spades: "spades", .hearts: "hearts", .diamonds: "diamonds", .clubs: "clubs"]
        return "\(ranks[card.rank.rawValue - 2]) of \(suits[card.suit] ?? "")"
    }
}

/// A face-down card back for shared cards not yet revealed.
struct CardSlot: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 7)
            .fill(LinearGradient(colors: [FT.surface, FT.navyDeep],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                RoundedRectangle(cornerRadius: 4.5)
                    .strokeBorder(FT.ivory.opacity(0.16), lineWidth: 1)
                    .padding(3.5)
            )
            .overlay(
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(FT.ivory.opacity(0.12))
            )
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(.black.opacity(0.3), lineWidth: 0.5))
            .frame(width: 40, height: 56)
            .accessibilityLabel("card not yet revealed")
    }
}

/// A small table chip, used beside point counts.
struct ChipIcon: View {
    var color: Color = FT.emerald
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle()
                .strokeBorder(.white.opacity(0.85),
                              style: StrokeStyle(lineWidth: size * 0.1, dash: [size * 0.2, size * 0.18]))
                .padding(size * 0.08)
            Circle().strokeBorder(.black.opacity(0.25), lineWidth: 0.5)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
        .accessibilityHidden(true)
    }
}

struct StarsView: View {
    let stars: Int
    var max = 3
    var font: Font = .caption
    var animated = false
    @State private var shown = false

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<max, id: \.self) { i in
                Image(systemName: i < stars ? "star.fill" : "star")
                    .font(font)
                    .foregroundStyle(i < stars ? FT.gold : FT.ivory.opacity(0.25))
                    .shadow(color: i < stars && animated ? FT.gold.opacity(0.5) : .clear, radius: 5)
                    .scaleEffect(!animated || shown ? 1 : 0.2)
                    .opacity(!animated || shown ? 1 : 0)
                    .animation(.spring(response: 0.42, dampingFraction: 0.55)
                        .delay(0.25 + Double(i) * 0.12), value: shown)
            }
        }
        .onAppear { if animated { shown = true } }
        .accessibilityLabel("\(stars) of \(max) stars")
    }
}

struct TierBadge: View {
    let tier: DecisionTier
    var body: some View {
        Text(FT.tierLabel(tier))
            .font(.subheadline.weight(.bold))
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(Capsule().fill(FT.tierColor(tier).opacity(0.18)))
            .overlay(Capsule().stroke(FT.tierColor(tier).opacity(0.4), lineWidth: 1))
            .foregroundStyle(FT.tierColor(tier))
    }
}

extension FT {
    static func profileColor(_ p: OpponentProfile?) -> Color {
        switch p {
        case .cautious: return Color(red: 0.36, green: 0.52, blue: 0.68)
        case .balanced: return teal
        case .aggressive: return Color(red: 0.72, green: 0.40, blue: 0.34)
        case .unpredictable: return Color(red: 0.58, green: 0.44, blue: 0.70)
        case .overlyPassive: return Color(red: 0.48, green: 0.52, blue: 0.56)
        case nil: return emerald
        }
    }
}

/// One opponent seat: profile, position, stack, status, latest action.
struct SeatRow: View {
    let seat: PlayerSeat
    let lastAction: String?
    let pointUnit: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [FT.profileColor(seat.profile).opacity(seat.status == .active ? 0.9 : 0.35),
                                 FT.profileColor(seat.profile).opacity(seat.status == .active ? 0.55 : 0.2)],
                        startPoint: .top, endPoint: .bottom))
                Text(FT.profileLabel(seat.profile).prefix(1))
                    .font(.headline).foregroundStyle(FT.ivory)
            }
            .frame(width: 36, height: 36)
            .overlay(Circle().stroke(seat.status == .active ? FT.ivory.opacity(0.3) : .clear, lineWidth: 1))
            VStack(alignment: .leading, spacing: 1) {
                Text(FT.profileLabel(seat.profile))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
                Text("\(FT.positionLabel(seat.position)) seat")
                    .font(.caption).foregroundStyle(FT.ivoryDim)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 5) {
                    ChipIcon(color: FT.profileColor(seat.profile), size: 11)
                    Text("\(seat.stack) \(pointUnit)")
                        .font(.subheadline.weight(.bold)).monospacedDigit().foregroundStyle(FT.ivory)
                }
                if seat.status == .withdrawn {
                    Text("Withdrew").font(.caption).foregroundStyle(FT.danger)
                } else if let lastAction {
                    Text(lastAction).font(.caption.weight(.medium)).foregroundStyle(FT.emerald)
                }
            }
        }
        .padding(.vertical, 4)
        .opacity(seat.status == .withdrawn ? 0.45 : 1)
    }
}

struct DifficultyDots: View {
    let level: Int   // 1–10
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < (level + 1) / 2 ? FT.emerald : FT.ivory.opacity(0.15))
                    .frame(width: 6, height: 6)
            }
        }
        .accessibilityLabel("Difficulty \(level) of 10")
    }
}

/// Score component bar for the results screen. Fills with a spring when `animated`.
struct ComponentBar: View {
    let name: String
    let earned: Int
    let max: Int
    var animated = false
    var delay: Double = 0
    @State private var fill = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(name).font(.caption).foregroundStyle(FT.ivoryDim)
                Spacer()
                Text("\(earned)/\(max)").font(.caption.weight(.semibold)).monospacedDigit().foregroundStyle(FT.ivory)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(FT.navyDeep)
                    Capsule()
                        .fill(LinearGradient(colors: [FT.emerald, FT.teal],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: max > 0 ? geo.size.width * CGFloat(earned) / CGFloat(max) : 0)
                        .scaleEffect(x: fill ? 1 : 0.001, anchor: .leading)
                }
            }
            .frame(height: 6)
        }
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(delay)) { fill = true }
            } else {
                fill = true
            }
        }
    }
}

#Preview("Cards") {
    HStack {
        CardView(card: Card("As")!, large: true)
        CardView(card: Card("Kh")!, large: true)
        CardView(card: Card("Td")!)
        CardView(card: Card("9c")!)
        CardSlot()
    }
    .padding()
    .background(FT.navy)
}
