import SwiftUI
import SwiftData
import FTEngine

/// The core puzzle screen: study → estimate → decide → size → confidence → lock in →
/// (optional variables step) → results. No answer information leaks before lock-in (C4).
struct PuzzleView: View {
    let scenario: Scenario

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("standardTerms") private var standardTerms = true
    @AppStorage("variablesStep") private var variablesStep = false

    @State private var probEstimate: Double = 50
    @State private var selectedAction: GameActionType?
    @State private var selectedSize: Double?
    @State private var confidence: Confidence = .medium
    @State private var pickingVariables = false
    @State private var chosenVariables: Set<String> = []
    @State private var result: ScoreBreakdown?
    @State private var timelineOpen = false
    @State private var dealt = false

    private var probabilityActive: Bool {
        scenario.decisionSpec.activeComponents.contains(.probability)
            && scenario.solution.probabilityKey != nil
    }

    private var sizeStops: [Double] { scenario.decisionSpec.sizeStops ?? [] }

    private func illegalReason(_ action: GameActionType) -> String? {
        guard !scenario.decisionSpec.options.contains(action) else { return nil }
        switch action {
        case .pass: return "You can't pass while facing a requirement."
        case .match: return "There is nothing to match right now."
        case .challenge: return "Matching already commits your whole stack."
        case .withdraw: return "Withdrawing isn't available here."
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                header
                opponents
                board
                timeline
                playerHand
                inputs
            }
            .padding()
        }
        .background(FT.navy)
        .navigationTitle(scenario.id)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $pickingVariables) { variablesSheet }
        .sheet(item: $result) { breakdown in
            ResultsView(scenario: scenario, breakdown: breakdown,
                        chosenAction: selectedAction ?? .withdraw) {
                dismiss()
            }
        }
        .task {
            guard !dealt else { return }
            if reduceMotion {
                dealt = true
            } else {
                try? await Task.sleep(nanoseconds: 80_000_000)
                dealt = true
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }

    /// Staggered deal-in for card views.
    @ViewBuilder
    private func dealIn(_ view: some View, index: Int) -> some View {
        view
            .opacity(dealt ? 1 : 0)
            .scaleEffect(dealt ? 1 : 0.5)
            .offset(y: dealt ? 0 : -16)
            .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.72)
                .delay(Double(index) * 0.07), value: dealt)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(scenario.title).ftTitle()
                Spacer()
                DifficultyDots(level: scenario.difficulty)
            }
            Text(scenario.objective)
                .font(.subheadline).foregroundStyle(FT.ivoryDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ftPanel()
    }

    private var opponents: some View {
        VStack(spacing: 0) {
            ForEach(scenario.table.seats.filter { $0.seat != 0 }, id: \.seat) { seat in
                SeatRow(seat: seat,
                        lastAction: lastActionLabel(seat: seat.seat),
                        pointUnit: scenario.table.pointUnit)
            }
        }
        .ftPanel()
    }

    private func lastActionLabel(seat: Int) -> String? {
        guard let record = scenario.actionHistory.last(where: { $0.seat == seat }) else { return nil }
        let name = FT.actionLabel(record.action, standard: standardTerms)
        if let size = record.size { return "\(name) \(size)" }
        return name
    }

    private var board: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(Array(scenario.deal.sharedCards.enumerated()), id: \.element) { i, card in
                    dealIn(CardView(card: card), index: i)
                }
                ForEach(0..<(5 - scenario.deal.sharedCards.count), id: \.self) { i in
                    dealIn(CardSlot(), index: scenario.deal.sharedCards.count + i)
                }
            }
            HStack(spacing: 28) {
                VStack(spacing: 3) {
                    Text(FT.poolLabel(standard: standardTerms))
                        .font(.caption2.weight(.bold)).tracking(1).foregroundStyle(FT.ivoryDim)
                    HStack(spacing: 6) {
                        ChipIcon(color: FT.gold, size: 14)
                        Text("\(scenario.table.pool)")
                            .font(.title3.bold()).monospacedDigit().foregroundStyle(FT.ivory)
                    }
                }
                if scenario.table.requirement > 0 {
                    VStack(spacing: 3) {
                        Text(FT.toMatchLabel(standard: standardTerms))
                            .font(.caption2.weight(.bold)).tracking(1).foregroundStyle(FT.ivoryDim)
                        HStack(spacing: 6) {
                            ChipIcon(color: FT.emerald, size: 14)
                            Text("\(scenario.table.requirement)")
                                .font(.title3.bold()).monospacedDigit().foregroundStyle(FT.emerald)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(FT.feltGradient))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(FT.ivory.opacity(0.07), lineWidth: 1)
                .padding(5)
        )
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(FT.gold.opacity(0.3), lineWidth: 1.2))
        .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
    }

    private var timeline: some View {
        DisclosureGroup(isExpanded: $timelineOpen) {
            VStack(alignment: .leading, spacing: 4) {
                if scenario.actionHistory.isEmpty {
                    Text("You act first this round.").font(.caption).foregroundStyle(FT.ivoryDim)
                }
                ForEach(Array(scenario.actionHistory.enumerated()), id: \.offset) { _, record in
                    let seat = scenario.table.seats.first { $0.seat == record.seat }
                    Text("\(FT.profileLabel(seat?.profile)) (\(FT.positionLabel(seat?.position ?? .early))) — \(FT.actionLabel(record.action, standard: standardTerms))\(record.size.map { " \($0)" } ?? "")")
                        .font(.caption).foregroundStyle(FT.ivoryDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
        } label: {
            Text("Previous actions")
                .font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
        }
        .tint(FT.ivoryDim)
        .ftPanel()
    }

    private var playerHand: some View {
        HStack(spacing: 14) {
            HStack(spacing: 10) {
                ForEach(Array(scenario.deal.playerCards.enumerated()), id: \.element) { i, card in
                    dealIn(CardView(card: card, large: true), index: 5 + i)
                        .rotationEffect(.degrees(i == 0 ? -4 : 4))
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Your hand").font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
                if let you = scenario.table.seats.first {
                    HStack(spacing: 5) {
                        ChipIcon(size: 11)
                        Text("\(FT.positionLabel(you.position)) seat · \(you.stack) \(scenario.table.pointUnit)")
                            .font(.caption).foregroundStyle(FT.ivoryDim)
                    }
                }
            }
            Spacer()
        }
        .ftPanel()
    }

    private var inputs: some View {
        VStack(spacing: 14) {
            if probabilityActive, let key = scenario.solution.probabilityKey {
                VStack(alignment: .leading, spacing: 6) {
                    Text(key.question)
                        .font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Slider(value: $probEstimate, in: 0...100, step: 1).tint(FT.emerald)
                        Text("\(Int(probEstimate))%")
                            .font(.headline).monospacedDigit().foregroundStyle(FT.emerald)
                            .frame(width: 52)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach([GameActionType.pass, .match, .challenge, .withdraw], id: \.self) { action in
                    actionButton(action)
                }
            }

            if selectedAction == .challenge && !sizeStops.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(standardTerms ? "Raise size" : "Challenge size")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
                    HStack(spacing: 8) {
                        ForEach(sizeStops, id: \.self) { stop in
                            Button {
                                selectedSize = stop
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Text(sizeLabel(stop))
                                    .font(.subheadline.weight(.bold)).monospacedDigit()
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(RoundedRectangle(cornerRadius: 9)
                                        .fill(selectedSize == stop ? FT.emerald : FT.surfaceHi))
                                    .foregroundStyle(selectedSize == stop ? FT.navyDeep : FT.ivory)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("How confident are you?")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(FT.ivory)
                Picker("Confidence", selection: $confidence) {
                    Text("Low").tag(Confidence.low)
                    Text("Medium").tag(Confidence.medium)
                    Text("High").tag(Confidence.high)
                }
                .pickerStyle(.segmented)
            }

            Button {
                if selectedAction == .challenge && !sizeStops.isEmpty && selectedSize == nil {
                    selectedSize = sizeStops.first
                }
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if variablesStep {
                    pickingVariables = true
                } else {
                    score()
                }
            } label: {
                Text("Lock In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(selectedAction == nil ? FT.surfaceHi : FT.emerald))
                    .foregroundStyle(selectedAction == nil ? FT.ivoryDim : FT.navyDeep)
            }
            .disabled(selectedAction == nil)
            .animation(.easeInOut(duration: 0.2), value: selectedAction == nil)

            Text("Educational strategy game. No real-money gambling.")
                .font(.caption2).foregroundStyle(FT.ivoryDim.opacity(0.7))
        }
        .ftPanel()
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedAction)
    }

    private func sizeLabel(_ stop: Double) -> String {
        let points = Int((Double(scenario.table.pool) * stop).rounded())
        return "\(points)"
    }

    private func actionButton(_ action: GameActionType) -> some View {
        let reason = illegalReason(action)
        let selected = selectedAction == action
        let tint = FT.actionColor(action)
        return Button {
            selectedAction = action
            if action != .challenge { selectedSize = nil }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: FT.actionIcon(action))
                        .font(.subheadline.weight(.bold))
                    Text(FT.actionLabel(action, standard: standardTerms))
                        .font(.headline)
                }
                if let reason {
                    Text(reason)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(selected ? tint : (reason == nil ? FT.surfaceHi : FT.navyDeep)))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(reason == nil && !selected ? tint.opacity(0.4) : .clear, lineWidth: 1))
            .foregroundStyle(selected ? FT.navyDeep : (reason == nil ? FT.ivory : FT.ivoryDim.opacity(0.5)))
            .scaleEffect(selected ? 1.03 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.65), value: selected)
        }
        .disabled(reason != nil)
    }

    private var variablesSheet: some View {
        let allTags = (scenario.solution.variableKey + scenario.solution.distractorVariables).sorted()
        return VStack(spacing: 16) {
            Text("What mattered most?").ftTitle()
            Text("Pick up to three variables that drove the right decision.")
                .font(.subheadline).foregroundStyle(FT.ivoryDim)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(allTags, id: \.self) { tag in
                    let on = chosenVariables.contains(tag)
                    Button {
                        if on { chosenVariables.remove(tag) }
                        else if chosenVariables.count < 3 { chosenVariables.insert(tag) }
                    } label: {
                        Text(tag)
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10)
                                .fill(on ? FT.emerald : FT.surfaceHi))
                            .foregroundStyle(on ? FT.navyDeep : FT.ivory)
                    }
                }
            }
            Button {
                pickingVariables = false
                score()
            } label: {
                Text("Score My Decision")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(FT.emerald))
                    .foregroundStyle(FT.navyDeep)
            }
            Spacer()
        }
        .padding()
        .background(FT.navy)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func score() {
        guard let action = selectedAction else { return }
        let tier = scenario.solution.tiers[action.rawValue] ?? .majorError

        var active = Set(scenario.decisionSpec.activeComponents)
        // C1: size is N/A when the level authored no band, or when an Excellent
        // decision carries no size of its own.
        if scenario.solution.sizeBand == nil { active.remove(.size) }
        if action != .challenge && tier == .excellent { active.remove(.size) }
        // The variables step is optional (off by default). When skipped, the
        // component is inactive and its weight redistributes (C1).
        if !variablesStep { active.remove(.variables) }

        var band: ClosedRange<Double>?
        if let b = scenario.solution.sizeBand, b.count == 2 { band = b[0]...b[1] }

        let input = AttemptInput(
            chosenTier: tier,
            sizeFraction: action == .challenge ? selectedSize : nil,
            sizeBand: band,
            probabilityEstimate: probabilityActive ? probEstimate : nil,
            probabilityTruth: scenario.solution.probabilityKey?.displayPercent,
            chosenVariables: chosenVariables,
            variableKey: Set(scenario.solution.variableKey),
            confidence: confidence,
            activeComponents: active)

        let breakdown = PuzzleScorer.score(input)
        persist(breakdown)
        if breakdown.stars == 3 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        result = breakdown
    }

    private func persist(_ breakdown: ScoreBreakdown) {
        let id = scenario.id
        let descriptor = FetchDescriptor<LevelProgressRecord>(predicate: #Predicate { $0.levelID == id })
        if let existing = try? context.fetch(descriptor).first {
            existing.attempts += 1
            existing.stars = max(existing.stars, breakdown.stars)
            existing.bestScore = max(existing.bestScore, breakdown.total)
        } else {
            context.insert(LevelProgressRecord(levelID: id, stars: breakdown.stars,
                                               bestScore: breakdown.total, attempts: 1))
        }
        try? context.save()
    }
}

extension ScoreBreakdown: Identifiable {
    public var id: String { "\(total)-\(tier.rawValue)-\(stars)" }
}

/// Results: animated score count-up, stars, tier, component bars, coaching,
/// and the one-variable twist.
struct ResultsView: View {
    let scenario: Scenario
    let breakdown: ScoreBreakdown
    let chosenAction: GameActionType
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("standardTerms") private var standardTerms = true
    @State private var showCoach = false
    @State private var showTwist = false
    @State private var shownTotal = 0
    @State private var revealed = false

    private var weights: [ScoreComponent: Int] {
        ComponentWeights.redistributed(active: Set(breakdown.components.keys))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("\(shownTotal)")
                        .font(.system(size: 56, weight: .bold, design: .serif))
                        .monospacedDigit().foregroundStyle(FT.ivory)
                    Text("out of 1,000").font(.caption).foregroundStyle(FT.ivoryDim)
                    StarsView(stars: breakdown.stars, font: .title3, animated: !reduceMotion)
                    TierBadge(tier: breakdown.tier)
                        .scaleEffect(revealed ? 1 : 0.7)
                        .opacity(revealed ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.65).delay(0.55),
                                   value: revealed)
                }
                .padding(.top, 8)

                VStack(spacing: 10) {
                    componentRow(.decision, "Decision quality", delay: 0.2)
                    componentRow(.size, "Size selection", delay: 0.3)
                    componentRow(.probability, "Probability estimate", delay: 0.4)
                    componentRow(.variables, "Key variables", delay: 0.5)
                    componentRow(.confidence, "Confidence calibration", delay: 0.6)
                }
                .ftPanel()

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("You chose:").font(.subheadline).foregroundStyle(FT.ivoryDim)
                        Text(FT.actionLabel(chosenAction, standard: standardTerms))
                            .font(.subheadline.weight(.bold)).foregroundStyle(FT.ivory)
                        Spacer()
                        Text("Recommended:").font(.subheadline).foregroundStyle(FT.ivoryDim)
                        Text(FT.actionLabel(scenario.solution.recommended.action, standard: standardTerms))
                            .font(.subheadline.weight(.bold)).foregroundStyle(FT.emerald)
                    }
                    Text(scenario.explanations.quick)
                        .font(.callout).foregroundStyle(FT.ivory)
                        .fixedSize(horizontal: false, vertical: true)

                    DisclosureGroup("Coach's full explanation", isExpanded: $showCoach) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(scenario.explanations.coach)
                            Text("Common mistake: \(scenario.explanations.commonMistake)")
                                .foregroundStyle(FT.ivoryDim)
                        }
                        .font(.footnote).foregroundStyle(FT.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                    }
                    .font(.subheadline.weight(.semibold)).tint(FT.emerald)

                    if let key = scenario.solution.probabilityKey {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(key.question): \(key.displayPercent, specifier: "%.1f")% — \(key.friendly)")
                                .font(.footnote.weight(.semibold)).foregroundStyle(FT.ivory)
                            ForEach(key.assumptions, id: \.self) { note in
                                Text(note).font(.caption2).foregroundStyle(FT.ivoryDim)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ftPanel()

                if let variation = scenario.variation {
                    DisclosureGroup(variation.prompt, isExpanded: $showTwist) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(variation.explanation)
                                .font(.footnote).foregroundStyle(FT.ivory)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("New recommendation: \(FT.actionLabel(variation.newRecommended.action, standard: standardTerms))")
                                .font(.footnote.weight(.bold)).foregroundStyle(FT.emerald)
                        }
                        .padding(.top, 6)
                    }
                    .font(.subheadline.weight(.semibold)).tint(FT.gold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ftPanel()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Takeaway").font(.caption.weight(.bold)).foregroundStyle(FT.emerald)
                    Text(scenario.explanations.takeaway)
                        .font(.callout.weight(.medium)).fontDesign(.serif).foregroundStyle(FT.ivory)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ftPanel()

                Button {
                    dismiss()
                    onDone()
                } label: {
                    Text("Back to Campaign")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12).fill(FT.emerald))
                        .foregroundStyle(FT.navyDeep)
                }

                Text("Your score grades the decision, never the luck of the cards.")
                    .font(.caption2).foregroundStyle(FT.ivoryDim.opacity(0.7))
            }
            .padding()
        }
        .background(FT.navy)
        .onAppear {
            guard !revealed else { return }
            revealed = true
            if reduceMotion {
                shownTotal = breakdown.total
                return
            }
            let total = breakdown.total
            Task { @MainActor in
                let steps = 36
                for i in 1...steps {
                    let t = Double(i) / Double(steps)
                    let eased = 1 - pow(1 - t, 3)
                    shownTotal = Int(Double(total) * eased)
                    try? await Task.sleep(nanoseconds: 24_000_000)
                }
                shownTotal = total
            }
        }
    }

    @ViewBuilder
    private func componentRow(_ component: ScoreComponent, _ name: String, delay: Double) -> some View {
        if let earned = breakdown.components[component] {
            ComponentBar(name: name, earned: earned, max: weights[component] ?? component.baseWeight,
                         animated: !reduceMotion, delay: delay)
        }
    }
}
