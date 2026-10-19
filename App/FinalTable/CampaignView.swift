import SwiftUI
import SwiftData
import FTEngine

/// Campaign map: 10 chapters × 10 levels, star-gated (15★ unlocks the next chapter).
struct CampaignView: View {
    @Query private var progress: [LevelProgressRecord]

    private func stars(chapter: Int) -> Int {
        let ids = Set(ContentLibrary.levels(chapter: chapter).map(\.id))
        return progress.filter { ids.contains($0.levelID) }.reduce(0) { $0 + $1.stars }
    }

    private func isUnlocked(_ chapter: Int) -> Bool {
        chapter == 1 || stars(chapter: chapter - 1) >= 15
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(ContentLibrary.chapters) { chapter in
                        ChapterCard(chapter: chapter,
                                    stars: stars(chapter: chapter.num),
                                    unlocked: isUnlocked(chapter.num),
                                    progress: progress)
                    }
                }
                .padding()
            }
            .background(FT.navy)
            .navigationTitle("Campaign")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct ChapterCard: View {
    let chapter: ChapterInfo
    let stars: Int
    let unlocked: Bool
    let progress: [LevelProgressRecord]

    @State private var expanded = ScreenshotMode.screen == "campaign"

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                if unlocked { withAnimation(.snappy) { expanded.toggle() } }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Chapter \(chapter.num)")
                            .font(.caption.weight(.semibold)).foregroundStyle(FT.emerald)
                        Text(chapter.title).ftTitle()
                        Text(chapter.skill).font(.caption).foregroundStyle(FT.ivoryDim)
                    }
                    Spacer()
                    if unlocked {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(stars)/30 ★").font(.subheadline.weight(.bold)).foregroundStyle(FT.gold)
                            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                                .font(.caption).foregroundStyle(FT.ivoryDim)
                        }
                    } else {
                        VStack(alignment: .trailing, spacing: 4) {
                            Image(systemName: "lock.fill").foregroundStyle(FT.ivoryDim)
                            Text("15★ in Ch. \(chapter.num - 1)")
                                .font(.caption2).foregroundStyle(FT.ivoryDim)
                        }
                    }
                }
            }
            .buttonStyle(.plain)

            if unlocked {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(FT.navyDeep)
                        Capsule()
                            .fill(LinearGradient(colors: [FT.gold.opacity(0.85), FT.gold],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(min(stars, 30)) / 30)
                    }
                }
                .frame(height: 4)
                .accessibilityHidden(true)
            }

            if expanded && unlocked {
                Text(chapter.primer)
                    .font(.footnote).foregroundStyle(FT.ivoryDim)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                    ForEach(ContentLibrary.levels(chapter: chapter.num), id: \.id) { level in
                        NavigationLink {
                            PuzzleView(scenario: level)
                        } label: {
                            LevelTile(level: level,
                                      record: progress.first { $0.levelID == level.id })
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .ftPanel()
        .opacity(unlocked ? 1 : 0.6)
    }
}

private struct LevelTile: View {
    let level: Scenario
    let record: LevelProgressRecord?

    var body: some View {
        VStack(spacing: 5) {
            Text(level.id.replacingOccurrences(of: "L0", with: "").replacingOccurrences(of: "L", with: ""))
                .font(.headline.weight(.bold)).monospacedDigit()
                .foregroundStyle(record != nil ? FT.emerald : FT.ivory)
            StarsView(stars: record?.stars ?? 0)
            DifficultyDots(level: level.difficulty)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(FT.surfaceHi))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke((record?.stars ?? 0) == 3 ? FT.gold.opacity(0.45)
                    : (record != nil ? FT.emerald.opacity(0.35) : .clear), lineWidth: 1))
        .accessibilityLabel("Level \(level.id), \(level.title), \(record?.stars ?? 0) stars")
    }
}
