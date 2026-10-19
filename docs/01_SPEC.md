# Final Table: Strategy Puzzles — Product Specification (Phase 1)

**Version:** 1.0 · **Date:** 2026-08-04 · **Status:** Awaiting approval before Phase 2 (code)

> Educational strategy game. No real-money gambling.

---

## 0. Consistency Review — Contradictions Found and Decisions Made

The brief was audited before drafting this spec. These are the internal contradictions, missing decisions, and resolutions. **Every resolution below is binding on the rest of this document.**

| # | Conflict / gap | Decision |
|---|---|---|
| C1 | Scoring allocates 200 pts to "size selection," but many puzzles (all of Chapter 1, most pre-shared-card passes) have no size decision. | **Component redistribution rule.** When a component is not applicable to a puzzle, its points redistribute pro-rata across the applicable components so every puzzle is still scored out of 1,000. Authored levels declare which components are active. |
| C2 | A probability-estimate input on every puzzle contradicts "beginners should not be overwhelmed." | Probability input is **optional in Chapter 1** (points redistribute per C1), **required from Chapter 2 onward**, where it is itself the learning objective. |
| C3 | "Award stars based on decision quality" vs. a 1,000-point score that includes probability and calibration components. | Stars key on the **decision-quality tier first**, total score second: 3★ = Excellent decision AND total ≥ 850; 2★ = Strong-or-better AND ≥ 650; 1★ = Defensible-or-better AND ≥ 400. A lucky outcome never changes stars; a perfect decision with a rough probability estimate still earns 2★. |
| C4 | "Never reveal the answer before submit" vs. "replay with one variable changed" (the player now knows the answer). | Replays and Mistake Review attempts are tagged `studied`. They can raise stars (mastery is the goal, not punishment) but are **excluded from calibration metrics and skill-dashboard trend lines**, which use first attempts only. |
| C5 | GameKit leaderboards vs. "work without creating an account." | Game Center is **strictly optional**. The app never prompts for it; leaderboards/achievements sync only if the user enables them in Settings. Everything else is local via SwiftData. |
| C6 | "Procedural simulator" + "validated" + "deterministic seeds": a generator can emit invalid scenarios, but rejection sampling breaks seed reproducibility if the validator changes. | Generator uses **bounded rejection sampling inside the seed**: a scenario code encodes `(templateID, seed, generatorVersion)`. The generator version is part of the code, so old codes always reproduce the exact scenario they produced. CI validates the full 500-template × smoke-seed matrix on every content change. |
| C7 | "Optional terminology setting for adult educational contexts" — but the app has no accounts and cannot verify age. | The toggle is labeled **"Standard card-game terminology"** (check/bet/call/raise/fold, pot, blinds). It is presented as a vocabulary preference, not an age gate — the app makes no age claims it cannot verify. Default is OFF (educational vocabulary). Content is identical either way; no gambling framing is ever added. |
| C8 | Daily Puzzle must be identical for all players but the app is offline-first (no server). | Daily seed = SHA-256 of the **local-date string** `"FT-daily-YYYY-MM-DD"`. No network needed; players in different time zones may differ by a few hours at day boundaries — accepted. |
| C9 | Monte Carlo results must be reproducible across devices, but floating-point reduction order can differ. | Exact **enumeration is the default** (heads-up post-flop is fully enumerable). Monte Carlo is used only for 3+ unknown hands vs. weighted ranges, with a fixed SplitMix64 RNG, fixed iteration order, integer win/tie counters, and division performed once at the end. Bit-identical across devices. |
| C10 | Chapter 8 needs "uneven rewards / survival value" (an ICM analog) without money language. | Named the **Standing Value Model**: finishing positions award fictional *ranking points*; the engine converts point-stacks to expected ranking points. All UI copy says "standing value," never "$EV" or "payouts." |
| C11 | Minimum iOS version unstated; SwiftData requires iOS 17. | **Minimum iOS 17.0**, built with the latest stable SDK (iOS 26). SwiftData schema uses `VersionedSchema` + `SchemaMigrationPlan` from day one. |
| C12 | App Store rating risk: a poker-mechanics game may draw a "Simulated Gambling" content descriptor even with zero money. | Positioning treats this as a launch risk, not a surprise (see §12 and Risks R1). We answer the rating questionnaire honestly ("Infrequent/Mild Simulated Gambling" at most, arguing the puzzle/education framing) and accept a possible 12+/17+ rating. No design change can fully remove this risk. |
| C13 | "Confidence calibration: 100 pts" — no formula given. | Defined in §8.5: per-puzzle score from a confidence×quality mapping table, plus a longitudinal Brier-style calibration curve on the skill dashboard (first attempts only, per C4). |
| C14 | "Identification of relevant variables: 150 pts" — interaction undefined. | Defined in §8.4: after locking a decision, the player picks up to 3 variable tags from 6 shown; scored against the level's authored key. |
| C15 | "Four possible decisions" per level vs. game legality — you cannot pass while facing a requirement, and a short stack may have no distinct challenge size. | The UI **always renders all four action buttons**; illegal ones are disabled with a plain-language reason ("You can't pass while facing a requirement") — which is itself teaching material. The validator requires ≥ 2 *legal* options per level, and the meaningful-decision rule applies to the legal set. |

No remaining contradictions are known. The spec below is internally consistent under these decisions.

---

## 1. Product Requirements Document

### 1.1 One-line pitch
A premium, offline-first iOS puzzle game that teaches probability, position, resource management, and decision quality through fictional final-table card scenarios — scored on *how well you decided*, never on how the cards happened to fall.

### 1.2 Audience
- Primary: adults and teens who enjoy logic/strategy puzzles (chess-puzzle, Wordle-streak, brain-training audiences).
- Secondary: card-game hobbyists who want structured decision training; educators teaching applied probability.

### 1.3 Non-negotiable constraints (compliance spine)
1. All chips are fictional **points**. No purchase, deposit, withdrawal, prize, or cash-equivalent exists anywhere.
2. No IAP that sells points, randomized rewards, or gameplay advantage. (v1 ships with **no IAP at all**; a future cosmetic-only, non-random IAP is permitted but out of scope.)
3. No links to, ads for, or integrations with gambling services.
4. The notice **"Educational strategy game. No real-money gambling."** appears on: onboarding screen 2, the App Store description, Settings > About, and the results screen footer.
5. Default vocabulary is educational (pass / match / challenge / withdraw, point stacks, commitments). See C7 for the terminology toggle.
6. No claims, implied or explicit, that skills transfer to winning money.
7. No dark patterns: no loss-aversion timers, no decaying streaks (streaks pause, never reset punitively), no "come back or lose X" notifications, adaptive difficulty never inflates session length (C-level requirement, revisited in §10).

### 1.4 Vocabulary (canonical, used across all code, content, and UI)
| Educational term (default) | Toggle term | Meaning |
|---|---|---|
| Pass | Check | Decline to add points; stay in |
| Match | Call | Add exactly the required points |
| Challenge | Bet / Raise | Add more than required |
| Withdraw | Fold | Exit the round, keeping remaining stack |
| Point stack | Chip stack | A player's fictional points |
| Commitment | Blind/Ante | Forced opening contribution |
| Requirement | Amount to call | Points needed to stay in |
| Pool | Pot | Points at stake in the center |
| Standing value | ICM equity | Expected ranking points (C10) |

### 1.5 Success metrics (non-manipulative)
- D7 retention via genuine progress (levels completed), not streak fear.
- Median "explanation read time" > 8s on Coach mode (are people actually learning?).
- Calibration curve slope improving across a player's first 50 first-attempts.
- Zero App Review rejections for gambling policy (4.7 / 5.3 guidelines).

---

## 2. Game Architecture

### 2.1 Module layout (SPM workspace)

```
FinalTable.xcworkspace
├── FinalTableApp/            # iOS app target (SwiftUI, MVVM view models)
├── Packages/
│   ├── FTEngine/             # Pure Swift, zero UI deps: cards, evaluator,
│   │                         #   probability, scoring, Standing Value Model,
│   │                         #   scenario generator + validator. 100% testable.
│   ├── FTContent/            # Versioned JSON levels + Codable loaders +
│   │                         #   content validation CLI (swift run ftlint)
│   └── FTDesignSystem/       # Colors, typography, card views, table view,
│   │                         #   haptics, reusable components, previews
```

**Dependency rule:** `FTEngine` imports only Foundation. `FTContent` imports FTEngine. `FTDesignSystem` imports SwiftUI only. The app imports all three. Nothing imports the app.

### 2.2 MVVM shape
- **Models:** FTEngine value types (structs/enums, `Sendable`, `Codable`).
- **Stores (SwiftData):** progress-only `@Model` classes (§5). Content is *never* stored in SwiftData — levels load from bundled JSON (C-of-truth split: JSON = content, SwiftData = player state).
- **ViewModels:** `@Observable` classes per screen, engine calls dispatched to a `CalculationActor` (global actor) so evaluation/Monte Carlo never touches the main thread.
- **Views:** SwiftUI, previews required for every major view (Phase 3+ requirement).

### 2.3 Concurrency
- `@globalActor CalculationActor` owns the evaluator, enumerator, and MC runner.
- Results cached in an LRU (`ScenarioID → EvaluationBundle`, cap 128 entries).
- All engine APIs are `async`; UI shows a lightweight progress shimmer for anything > 100 ms (rare — heads-up enumeration is ~1–5 ms).

### 2.4 Offline-first
Everything works with airplane mode on: campaign, simulator, daily puzzle (C8), labs, progress. Game Center sync (C5) and nothing else touches the network.

---

## 3. Complete Screen Map

Navigation is a `TabView` (Home · Campaign · Practice · Labs · Profile) plus pushed/sheet flows.

| # | Screen | Route | Notes |
|---|--------|-------|-------|
| 1 | Onboarding (3 pages) | first-launch flow | What the game is, how scoring works, vocabulary |
| 2 | Safety & purpose notice | onboarding p.2 + Settings | The §1.3.4 notice; must be scrolled past once |
| 3 | Home dashboard | Tab: Home | Daily puzzle card, continue-campaign card, weakest-skill card |
| 4 | Campaign map | Tab: Campaign | 100 nodes, 10 chapter bands, stars |
| 5 | Chapter overview | push from 4 | Objective, concept primer, 10 level cards |
| 6 | Puzzle table | push from 5/15/17/18 | The core screen (§7 layout) |
| 7 | Decision panel | region of 6 | Pass / Match / Challenge / Withdraw |
| 8 | Action-size selector | expands from 7 | Percent-of-pool slider with named stops |
| 9 | Probability estimate input | region of 6 | Slider 0–100%, hidden when N/A (C2) |
| 10 | Confidence selector | region of 6 | Low / Medium / High segmented control |
| 11 | Results screen | sheet over 6 | Score wheel, tier, star delta, Quick explanation |
| 12 | Deep-dive analysis | push from 11 | Coach + Deep Dive modes, variable bars, "what changes the answer" |
| 13 | Hand-strength lab | Tab: Labs | Reference centre home |
| 14 | Starting-card matrix | push from 13 | 13×13 grid, context selectors |
| 15 | Scenario simulator | Tab: Practice | Daily / Quick Practice / Custom Lab entries |
| 16 | Custom Lab | push from 15 | Full scenario configurator + Randomize |
| 17 | Daily Puzzle | push from 3/15 | One seeded puzzle/day, calendar history |
| 18 | Mistake Review | push from 3/19 | Queue of Weak/Major-error first attempts |
| 19 | Skill dashboard | Tab: Profile | 9 skill meters, calibration curve, trends |
| 20 | Achievements | push from 19 | Badges + chapter certificates |
| 21 | Settings | gear from 3/19 | Terminology toggle, adaptive toggle, Game Center, data deletion |
| 22 | Accessibility controls | push from 21 | Motion, haptics, sound, dyslexia font, left-hand layout, contrast |

---

## 4. Core Gameplay Loop (canonical sequence)

1. **Present** — table renders: shared cards center, player cards bottom, opponents around a simplified oval, position badge, stacks, requirement, collapsible action timeline, scenario objective banner.
2. **Study** — player may expand the info panel (progressive disclosure: beginner default shows cards/stacks/objective only; "Full detail" reveals profiles, timeline, standing context).
3. **Estimate** — player sets improvement-probability slider (when active per C2).
4. **Decide** — choose pass / match / challenge / withdraw; if challenge (or a sized match variant), the size slider appears with stops at ¼, ½, ⅔, 1×, 1½×, All (levels may restrict stops).
5. **Calibrate** — pick confidence: Low / Medium / High.
6. **Lock in** — single confirm button (44-pt min target). No answer info leaks before this (C4).
7. **Variables** — post-lock, pick up to 3 of 6 variable tags: "What mattered most?" (§8.4).
8. **Score** — results sheet: total /1,000, component bars, tier (Excellent → Major error), stars.
9. **Learn** — Quick explanation inline; Coach and Deep Dive one tap away (§9).
10. **Replay** — "Replay with a twist": the level's authored variation (one variable changed) loads immediately, tagged `studied` (C4).

An optional **outcome reveal** button ("See how the cards fell") deals the remaining cards *after* scoring, with the permanent caption: "Outcomes don't grade decisions. Your score is already final."

---

## 5. SwiftData Schema (progress only — content lives in JSON)

All models in `FinalTableApp/Persistence/`, `SchemaV1` under a `VersionedSchema`.

```swift
@Model PlayerProfile        // singleton
  id, createdAt, terminologyStandard: Bool, adaptiveEnabled: Bool,
  gameCenterEnabled: Bool, explanationMode: enum, accessibilityPrefs: Codable blob

@Model LevelProgress        // one per campaign level touched
  levelID: String (unique), bestScore: Int, stars: Int(0–3),
  bestDecisionTier: String, firstAttemptAt: Date?, attemptCount: Int

@Model AttemptRecord        // every lock-in, campaign or generated
  id: UUID, scenarioCode: String, levelID: String?, date: Date,
  isFirstAttempt: Bool, isStudied: Bool,                    // C4
  decision: String, sizeFraction: Double?, probabilityEstimate: Double?,
  confidence: String, variableTags: [String],
  totalScore: Int, componentScores: Codable blob, decisionTier: String

@Model SkillMetricRecord    // 9 rows, one per skill (§10 list)
  skill: String (unique), attempts: Int, weightedScore: Double,
  trend: Codable blob (last 20 first-attempt scores)

@Model AchievementRecord    // earned only
  achievementID: String (unique), earnedAt: Date, gameKitReported: Bool

@Model MistakeQueueItem
  attemptID: UUID (unique), scenarioCode: String, addedAt: Date,
  resolvedAt: Date?     // resolved when replayed at Defensible+

@Model BookmarkRecord       // scenarioCode, note, createdAt
@Model DailyPuzzleRecord    // dateKey "YYYY-MM-DD" (unique), completed, score
@Model StreakRecord         // practice days; missing a day pauses, never punishes
```

**Deletion:** Settings > "Delete all progress" wipes the store and Game Center-local caches after a typed confirmation. No export needed for v1 (no accounts, nothing leaves the device).

---

## 6. JSON Scenario Schema (summary — full field tables in 02_SCHEMAS.md)

Handcrafted levels ship as `Levels/chapter_NN/level_NNN.json`, one file per level, with a bundle-level `content_manifest.json` (`contentVersion`, checksums). Schema is versioned via a top-level `"schemaVersion": 1`.

A level contains: identity + learning objective + difficulty; the deal (`playerCards`, `sharedCards` with street marker); the table (`seats[]` with position, stack, profile, status); `actionHistory[]`; the decision spec (`options[]`, `sizeStops`, `activeComponents` per C1); the solution (`recommended`, `alternatives[]` with tiers, `variableKey[]`, `probabilityKey`); explanations (quick/coach/deepDive, `commonMistake`, `takeaway`); and `variation` (the one-variable replay). Generated scenarios use the same schema, produced in memory from a `ScenarioSeed`.

**Scenario codes** (share/reproduce): `FT1-<templateID>-<seed base36>-<genVersion>` per C6.

---

## 7. Puzzle Interface Specification

Layout (portrait iPhone; iPad uses a wider table with side panel):

- **Top band:** objective banner + position badge + standing context chip (Chapter 8+).
- **Table oval:** 2–8 seats; each seat = avatar glyph (profile-coded shape, color-blind safe), stack in large numerals with point-unit indicator "pts", status (active/withdrawn), last action chip. Dealer marker for position reference.
- **Center:** shared cards (up to 5, face-down slots for future streets), pool total, current requirement in emphasized type.
- **Timeline:** collapsible previous-actions strip ("Seat 3 challenged 300 · Seat 5 matched…").
- **Bottom sheet:** player cards (large), then the decision stack — probability slider (when active) → four decision buttons → size slider (contextual) → confidence → Lock In.
- **Progressive disclosure:** "Detail" toggle reveals opponent profiles, exact stack ratios, and standing value; default off through Chapter 2, default on from Chapter 7.
- Left-handed mode mirrors the bottom sheet controls. All targets ≥ 44 pt. Haptic tick on selection, success pattern on 3★ (respecting system settings).

---

## 8. Scoring Formula (out of 1,000)

### 8.1 Components and redistribution (C1)
Base weights: Decision 400 · Size 200 · Probability 150 · Variables 150 · Confidence 100.
If a component is inactive for a level, its weight redistributes pro-rata over active components; the total is always 1,000. Example (no size, no probability — a Chapter 1 level): Decision 615, Variables 231, Confidence 154.

### 8.2 Decision quality (400)
Each option is authored with a tier: **Excellent 400 · Strong 320 · Defensible 240 · Weak 120 · Major error 0.** Multiple options can share a tier (mixed-decision levels in Chapter 9 author two Excellent options).

### 8.3 Size selection (200)
Authored as a recommended band `[lo, hi]` (fraction of pool) per option that has sizing. Inside band = 200; outside decays linearly to 0 at 2× band-width distance. Choosing a decision with no sizing (e.g., withdraw) when the recommended decision had sizing: size component scores 0 unless the chosen option is Excellent-tier (then N/A per C1).

### 8.4 Variable identification (150)
Six tags shown (e.g., Position · Pool odds · Stack depth · Opponent profile · Standing value · Card removal); the authored key marks 2–3 as correct. +50 per correct pick, −25 per incorrect pick, floor 0, cap 150.

### 8.5 Probability estimate (150) and confidence calibration (100)
- Probability: full 150 within ±3 percentage points of the engine's exact value; linear decay to 0 at ±20 pp.
- Confidence (C13): mapping table —

| | Decision Excellent/Strong | Defensible | Weak/Major error |
|---|---|---|---|
| **High** | 100 | 40 | 0 |
| **Medium** | 70 | 100 | 40 |
| **Low** | 40 | 70 | 100 |

Honest uncertainty is rewarded; overconfidence in bad decisions is the heavily penalized cell. Longitudinal calibration (dashboard) uses first attempts only (C4).

### 8.6 Stars (C3)
3★ = Excellent AND ≥ 850 · 2★ = Strong+ AND ≥ 650 · 1★ = Defensible+ AND ≥ 400. Stars never depend on revealed outcomes.

---

## 9. Calculation Engine Design (FTEngine)

- **Card model:** `Card` = 6-bit int (rank 2–14, suit 0–3); deck ops on a 52-bit mask for O(1) duplicate detection.
- **Evaluator:** best-5-of-5/6/7 via category detection on rank/suit histograms + straight bitmask; returns a totally ordered 32-bit `HandRank` (category ≪ 20 | tiebreak kickers). Ties detected by equal `HandRank`.
- **Enumerator:** exact outcomes over unseen cards — one street = ≤ 47 deals, two streets = C(47,2) = 1,081 deals, heads-up vs. a known hand fully exact. Improvement probability = exact rational (e.g., 378/1081), displayed with exact %, friendly approximation ("about 1 in 3"), method, and assumptions (§ Hand-Strength Lab spec, 02_SCHEMAS.md).
- **Range equity:** vs. weighted 169-class ranges — exact when ≤ 2 unknown hands post-flop; Monte Carlo (seeded SplitMix64, integer tallies, fixed order — C9) for 3+ opponents pre-flop, default 200k trials off-main-thread with cached results.
- **Standing Value Model (C10):** Malmuth-Harville-style conversion of stacks → finish-probability → ranking points; exposed as "standing value" with an explicit assumptions label ("assumes equal skill; a simplification").
- **Honesty rule:** every displayed number carries a `Basis` enum: `.exactEnumeration`, `.seededSimulation(trials:)`, `.behavioralAssumption` — rendered as a small label. The engine never presents assumption-based numbers as exact (brief requirement: no fabricated math).
- **Generator + validator:** `ScenarioSeed → Scenario` with the C6 versioning contract; validator enforces the brief's 8 invalidity rules plus "meaningful decision" (no two options may differ by < 30 authored points of expected score — degenerate puzzles rejected).

Target: ≥ 100 engine unit tests (evaluator categories, tiebreaks, enumeration counts vs. known combinatorics, seed reproducibility, validator rules) — Phase 2 exit criterion.

---

## 10. Adaptive Difficulty, Progression, Accessibility, Privacy

- **9 tracked skills:** hand recognition, probability, position, resource management, action sizing, opponent modeling, multi-player reasoning, tournament pressure, confidence calibration. Each attempt maps its level's authored skill tags → updates `SkillMetricRecord` (first attempts drive trends, C4).
- **Adaptive rule:** if a skill's rolling mean < 550/1000 over ≥ 5 attempts, Home surfaces a "Targeted practice" card generating simulator puzzles tagged for that skill. Never changes campaign difficulty; never extends sessions; fully disableable (Settings).
- **Progression:** chapter N+1 unlocks at ≥ 15★ in chapter N (of 30 possible) — mastery-gated but forgiving. Cosmetic table themes unlock at skill milestones only. Certificates on chapter completion. Streaks pause on missed days (§1.3.7).
- **Accessibility (Phase 10 audit, built-in from Phase 3):** VoiceOver labels for every card ("Queen of hearts"), full Dynamic Type, suit symbols use shape + 4-color palette (color-blind safe), reduced motion swaps all animations for crossfades, optional dyslexia-friendly font, left-hand mirror, ≥ 44-pt targets, plain-language default copy.
- **Privacy:** no account, no analytics SDK in v1, no ads, no tracking; leaderboards opt-in (C5); social features are v1-absent so parental controls reduce to the Game Center system-level controls; full local data deletion (§5).

---

## 11. Development Roadmap (phases, each gated on approval)

| Phase | Deliverable | Exit criteria |
|---|---|---|
| 1 | This spec | Approved, contradictions resolved |
| 2 | FTEngine + models + tests | ≥ 100 passing engine tests; seed reproducibility proven |
| 3 | FTDesignSystem | Component gallery with previews; both themes; accessibility pass |
| 4 | Core puzzle gameplay | One hardcoded level playable end-to-end with scoring |
| 5 | Levels 1–20 + campaign shell | Chapters 1–2 playable; content validator in CI |
| 6 | Levels 21–100 | All 100 levels pass automated validation |
| 7 | 500-template generator | Full matrix validated; scenario codes shareable |
| 8 | Labs | Matrix, comparisons, probability displays with Basis labels |
| 9 | Coaching + adaptive + progression | Skill dashboard live; mistake queue live |
| 10 | Hardening | Accessibility audit, performance, App Store package |

## 12. Key Technical & Product Risks

- **R1 (highest): App Store "Simulated Gambling" descriptor** despite zero money (C12). Mitigation: honest questionnaire, education-forward metadata, no casino trade dress, review notes citing guideline 5.3 non-applicability (no wagering). Accept possible 12+/17+.
- **R2: Poker-math correctness at authoring scale** — 100 levels × authored keys. Mitigation: every authored probability/tier is machine-checked by FTEngine in CI (no hand-authored number ships unverified).
- **R3: Determinism across devices/OS versions** (C9). Mitigation: integer-domain enumeration, seeded MC, golden-file tests on CI for both simulator architectures.
- **R4: Content-authoring volume** (explanations ×3 modes ×100 levels). Mitigation: shared explanation fragments + per-level overrides; Phase 5 validates the authoring pipeline on 20 levels before committing to 80.
- **R5: SwiftData migration fragility.** Mitigation: VersionedSchema from v1; AttemptRecord blobs are Codable JSON, tolerant of additive change.
- **R6: Standing Value Model misread as financial advice.** Mitigation: fictional ranking points only, assumptions label, no currency formatting anywhere in the codebase (lint rule).
- **R7: Scope** — 22 screens, 3 labs, generator. Mitigation: phase gates; Custom Lab and matrix are Phase 7–8, not MVP-blocking.
- **R8: IP / trademark clearance.** Binding constraint: **no references to real tournament brands or organizations anywhere** — no WSOP, WPT, EPT, or any real event/venue names, logos, bracelet imagery, or recognizable trade dress, in app, metadata, or marketing. "Final table" is used strictly as the generic tournament concept. Card designs, tables, and badges are original artwork. Action: run an App Store + trademark search on the name "Final Table: Strategy Puzzles" before Phase 10; keep "Strategy Puzzles" as the distinctive element and have a fallback name ready if clearance fails.

## 13. App Store Safety & Positioning Language

- **Name:** Final Table: Strategy Puzzles · **Subtitle:** "Decision-quality training, one puzzle at a time."
- **Description (opening):** "Final Table is an educational strategy game about making great decisions under uncertainty. Study the cards, weigh position and probability, commit fictional points, and get graded on your reasoning — never on luck. Educational strategy game. No real-money gambling."
- **Keywords:** strategy puzzle, probability, logic, decision, brain training, card puzzle.
- **Review notes (draft):** "Contains no wagering, no real or purchasable currency, no prizes, and no gambling-service links. All points are fictional puzzle scores. The app works fully offline with no account."
- **Never in metadata:** win, cash, casino, jackpot, betting odds (as gambling framing), or any transfer-to-real-play claim.
