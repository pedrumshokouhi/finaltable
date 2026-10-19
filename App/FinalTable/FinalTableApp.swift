import SwiftUI
import SwiftData
import FTEngine

@Model
final class LevelProgressRecord {
    @Attribute(.unique) var levelID: String
    var stars: Int
    var bestScore: Int
    var attempts: Int

    init(levelID: String, stars: Int, bestScore: Int, attempts: Int) {
        self.levelID = levelID
        self.stars = stars
        self.bestScore = bestScore
        self.attempts = attempts
    }
}

@main
struct FinalTableApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(FT.emerald)
        }
        .modelContainer(for: LevelProgressRecord.self)
    }
}

/// Marketing/screenshot automation: launch with e.g.
///   -ftScreen home | campaign | puzzle | results
/// to land directly on a screen with demo state. No effect in normal launches.
enum ScreenshotMode {
    static var screen: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-ftScreen"), index + 1 < args.count else { return nil }
        return args[index + 1]
    }
}

struct RootView: View {
    @AppStorage("onboarded") private var onboarded = false
    @Environment(\.modelContext) private var context
    @State private var tab = 0

    var body: some View {
        if let screen = ScreenshotMode.screen {
            screenshotContent(screen)
        } else {
            normalContent
        }
    }

    @ViewBuilder
    private func screenshotContent(_ screen: String) -> some View {
        switch screen {
        case "puzzle":
            NavigationStack { PuzzleView(scenario: ContentLibrary.levels(chapter: 2)[2]) }
                .preferredColorScheme(.dark).tint(FT.emerald)
        case "results":
            ResultsView(
                scenario: ContentLibrary.levels(chapter: 1)[4],
                breakdown: ScoreBreakdown(
                    components: [.decision: 615, .variables: 154, .confidence: 154],
                    total: 923, tier: .excellent, stars: 3),
                chosenAction: .match, onDone: {})
                .preferredColorScheme(.dark).tint(FT.emerald)
        case "campaign":
            CampaignView()
                .preferredColorScheme(.dark).tint(FT.emerald)
                .onAppear { seedDemoProgress() }
        default:
            HomeView(goPlay: {})
                .preferredColorScheme(.dark).tint(FT.emerald)
                .onAppear { seedDemoProgress() }
        }
    }

    private func seedDemoProgress() {
        let demo: [(String, Int, Int)] = [
            ("L001", 3, 923), ("L002", 3, 951), ("L003", 2, 780),
            ("L004", 3, 905), ("L005", 2, 812), ("L006", 3, 890)
        ]
        for (id, stars, score) in demo {
            let descriptor = FetchDescriptor<LevelProgressRecord>(predicate: #Predicate { $0.levelID == id })
            if (try? context.fetch(descriptor).first) == nil {
                context.insert(LevelProgressRecord(levelID: id, stars: stars, bestScore: score, attempts: 1))
            }
        }
        try? context.save()
    }

    private var normalContent: some View {
        TabView(selection: $tab) {
            HomeView(goPlay: { tab = 1 })
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            CampaignView()
                .tabItem { Label("Campaign", systemImage: "map.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .fullScreenCover(isPresented: .constant(!onboarded)) {
            OnboardingView { onboarded = true }
        }
    }
}

struct HomeView: View {
    @Query private var progress: [LevelProgressRecord]
    let goPlay: () -> Void

    private var totalStars: Int { progress.reduce(0) { $0 + $1.stars } }
    private var levelsPlayed: Int { progress.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Final Table")
                                .font(.system(size: 34, weight: .bold, design: .serif))
                                .foregroundStyle(FT.ivory)
                            Text("Strategy Puzzles")
                                .font(.headline).foregroundStyle(FT.emerald)
                            Text("Train the quality of your decisions — never your luck.")
                                .font(.subheadline).foregroundStyle(FT.ivoryDim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let a = Card("As"), let k = Card("Kh") {
                            ZStack {
                                CardView(card: k)
                                    .rotationEffect(.degrees(10))
                                    .offset(x: 10, y: 2)
                                CardView(card: a)
                                    .rotationEffect(.degrees(-6))
                                    .offset(x: -16, y: -2)
                            }
                            .scaleEffect(0.85)
                            .opacity(0.95)
                            .accessibilityHidden(true)
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 16).fill(FT.feltGradient))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(FT.gold.opacity(0.25), lineWidth: 1))

                    HStack(spacing: 14) {
                        statTile("\(levelsPlayed)/100", "Levels played")
                        statTile("\(totalStars)", "Stars earned")
                        statTile("\(progress.map(\.bestScore).max() ?? 0)", "Best score")
                    }

                    Button(action: goPlay) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(levelsPlayed == 0 ? "Start Chapter 1" : "Continue the Campaign")
                                    .font(.headline).foregroundStyle(FT.navyDeep)
                                Text("100 handcrafted decision puzzles")
                                    .font(.caption).foregroundStyle(FT.navyDeep.opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2).foregroundStyle(FT.navyDeep)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(FT.emerald))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How scoring works")
                            .font(.subheadline.weight(.bold)).foregroundStyle(FT.ivory)
                        Text("Every puzzle is scored out of 1,000 for decision quality, sizing, probability estimation, variable identification, and confidence calibration. A mathematically sound decision never loses points to an unlucky card.")
                            .font(.footnote).foregroundStyle(FT.ivoryDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .ftPanel()

                    Text("Educational strategy game. No real-money gambling.\nAll points are fictional puzzle scores.")
                        .font(.caption2).foregroundStyle(FT.ivoryDim.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(FT.navy)
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func statTile(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold()).monospacedDigit().foregroundStyle(FT.emerald)
            Text(label).font(.caption2).foregroundStyle(FT.ivoryDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 12).fill(FT.surface))
    }
}

struct SettingsView: View {
    @AppStorage("standardTerms") private var standardTerms = true
    @AppStorage("variablesStep") private var variablesStep = false
    @Environment(\.modelContext) private var context
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Standard card-game terminology", isOn: $standardTerms)
                    Text(standardTerms
                         ? "Actions show as Check, Call, Raise, and Fold."
                         : "Actions show as Pass, Match, Challenge, and Withdraw.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: {
                    Text("Vocabulary")
                } footer: {
                    Text("A vocabulary preference only — the game is identical either way.")
                }

                Section {
                    Toggle("\u{201C}What mattered most?\u{201D} step", isOn: $variablesStep)
                    Text(variablesStep
                         ? "After locking in, you'll pick the key variables before seeing your score."
                         : "Your score appears the moment you lock in.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: {
                    Text("Gameplay")
                } footer: {
                    Text("An optional deeper-analysis step. When it's off, that component is excluded and its points redistribute across the rest of your score.")
                }

                Section("Progress") {
                    Button("Delete all progress", role: .destructive) { confirmDelete = true }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.1")
                    Text("Educational strategy game. No real-money gambling. All chips are fictional puzzle points. This game does not involve wagering, prizes, or cash, and no skill practiced here is a promise of real-world results.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FT.navy)
            .navigationTitle("Settings")
            .confirmationDialog("Delete all progress? This cannot be undone.",
                                isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    try? context.delete(model: LevelProgressRecord.self)
                    try? context.save()
                }
            }
        }
    }
}

struct OnboardingView: View {
    let done: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 20) {
            TabView(selection: $page) {
                onboardPage(icon: "suit.spade.fill",
                            title: "Welcome to Final Table",
                            text: "One hundred handcrafted card-strategy puzzles about probability, position, resources, and reading people. Study the table, weigh the odds, and lock in your decision.")
                    .tag(0)
                onboardPage(icon: "checkmark.seal.fill",
                            title: "Graded on reasoning, not luck",
                            text: "Every decision scores out of 1,000: the quality of your choice, your sizing, your probability estimate, the variables you spot, and your confidence calibration. A great decision that gets unlucky is still a great decision.")
                    .tag(1)
                onboardPage(icon: "shield.lefthalf.filled",
                            title: "Educational strategy game",
                            text: "No real-money gambling. All chips are fictional puzzle points — there is nothing to buy, deposit, win, or cash out, and nothing here promises real-world results. Just decisions, and how to make them better.")
                    .tag(2)
            }
            .tabViewStyle(.page)

            Button {
                if page < 2 { withAnimation { page += 1 } } else { done() }
            } label: {
                Text(page < 2 ? "Next" : "Start Playing")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(FT.emerald))
                    .foregroundStyle(FT.navyDeep)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(FT.navy)
    }

    private func onboardPage(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: icon)
                .font(.system(size: 52)).foregroundStyle(FT.emerald)
            Text(title)
                .font(.title.weight(.bold)).fontDesign(.serif)
                .foregroundStyle(FT.ivory)
                .multilineTextAlignment(.center)
            Text(text)
                .font(.callout).foregroundStyle(FT.ivoryDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
    }
}

#Preview("Home") {
    RootView()
        .modelContainer(for: LevelProgressRecord.self, inMemory: true)
}
