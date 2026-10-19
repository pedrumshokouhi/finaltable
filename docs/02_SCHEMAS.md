# Final Table — Data Schemas, Validation Rules, and Lab/Coaching Specs

Companion to `01_SPEC.md`. Governs `FTContent` (JSON) and the explanation/lab systems.

---

## 1. Level JSON Schema (schemaVersion 1)

One file per level: `Levels/chapter_03/level_027.json`. A formal `level.schema.json` (JSON Schema draft 2020-12) ships in FTContent in Phase 2; this section is normative for its contents.

### 1.1 Annotated example (complete)

```jsonc
{
  "schemaVersion": 1,
  "id": "L027",
  "chapter": 3,
  "indexInChapter": 7,
  "title": "The Late Seat Advantage",
  "learningObjective": "Recognize how acting last increases the value of a medium-strength holding.",
  "difficulty": 4,                          // 1–10
  "skillTags": ["position", "opponentModeling"],

  "deal": {
    "playerCards": ["Kh", "Th"],            // rank: 2–9,T,J,Q,K,A; suit: c,d,h,s
    "sharedCards": ["Qs", "Jh", "4d"],      // 0, 3, 4, or 5 cards
    "street": "threeShared"                 // preShared | threeShared | fourShared | fiveShared
  },

  "table": {
    "pointUnit": "pts",
    "seats": [                              // clockwise; seat 0 = player
      { "seat": 0, "position": "final",  "stack": 4200, "profile": null,        "status": "active" },
      { "seat": 1, "position": "early",  "stack": 3100, "profile": "cautious",  "status": "withdrawn" },
      { "seat": 2, "position": "middle", "stack": 5600, "profile": "aggressive","status": "active" }
    ],
    "pool": 900,
    "requirement": 300                      // points needed to match
  },

  "actionHistory": [
    { "seat": 1, "action": "withdraw" },
    { "seat": 2, "action": "challenge", "size": 300 }
  ],

  "objective": "Decide against an aggressive challenger while holding the last-action advantage.",

  "decisionSpec": {
    "options": ["withdraw", "match", "challenge"],   // legal subset; UI renders all
                                                     // four buttons, illegal ones
                                                     // disabled with a reason (C15)
    "sizeStops": [0.5, 0.75, 1.0],                   // shown only for challenge
    "activeComponents": ["decision", "probability", "variables", "confidence"]
  },                                                 // C1: size inactive here → redistribution

  "solution": {
    "recommended": { "action": "match" },
    "tiers": {                                        // every legal option gets a tier
      "match":     "excellent",
      "withdraw":  "defensible",
      "challenge": "weak"
    },
    "sizeBand": null,                                 // [lo, hi] fraction of pool, when sizing active
    "probabilityKey": {                               // machine-verified in CI (R2)
      "question": "Chance your hand improves to a straight or better by the last card",
      "exactNumerator": 340, "exactDenominator": 1081,
      "displayPercent": 31.5,
      "friendly": "about 1 in 3",
      "basis": "exactEnumeration",
      "assumptions": ["Only your improvement is counted; opponents' cards are unknown."]
    },
    "variableKey": ["position", "opponentProfile", "poolOdds"],   // 2–3 of the 6 tags
    "distractorVariables": ["stackDepth", "standingValue", "cardRemoval"]
  },

  "explanations": {
    "quick": "Acting last with a strong draw and good pool odds, matching keeps every option open. Withdrawing surrenders a profitable spot.",
    "coach": "…one paragraph…",
    "deepDive": { "sections": ["handCategory", "improvement", "position", "resourceDepth", "opponent", "pressure", "whyOthersScoredLower", "lesson"] },
    "commonMistake": "Re-challenging a draw out of position habit — here the last-action seat makes patience free.",
    "takeaway": "Position converts uncertain hands into playable ones."
  },

  "variation": {
    "prompt": "What changes the answer?",
    "change": { "path": "table.seats[0].position", "to": "early" },
    "newRecommended": { "action": "withdraw" },
    "explanation": "Acting first, you face two unknowns behind you and the same requirement buys far less information."
  }
}
```

### 1.2 Field constraints (validator-enforced)

| Field | Constraint |
|---|---|
| All cards | Unique across player + shared + any revealed opponent cards (52-bit mask check) |
| `seats` | 2–8 entries; seat indices consecutive from 0; exactly one seat per position claim consistent with count; player is seat 0 |
| `stack` | Integer > 0; withdrawn seats keep their stack; stack ≥ prior contributions implied by history |
| `actionHistory` | Legal sequence: no action after withdraw; challenge sizes ≤ actor's stack; requirement equals last unmatched challenge; a pass is illegal facing a positive requirement |
| `tiers` | Every option in `options` has a tier; ≥ 1 option is `excellent`; not all options share one tier ("meaningful decision" rule) |
| `probabilityKey` | `exactNumerator/exactDenominator` recomputed by FTEngine in CI; mismatch fails the build |
| `difficulty` | 1–10 and within the chapter's declared band |
| `variation.change` | Must alter exactly one field and produce a still-valid scenario |

## 2. Generated-Scenario Schema (`ScenarioSeed`)

```jsonc
{ "templateID": "T217", "seed": 8114213377, "generatorVersion": 3 }
// Scenario code: FT1-T217-3QZ0P1-3   (C6: version-pinned reproducibility)
```

Templates are combinations over the axes in the brief (169 starting classes × seats 2–9 × 4 positions × 3 stack depths × textures × sequences × 5 profiles × pressure settings × 4 tiers × size menus × objectives × pre/post street). The generator emits the **same level JSON structure** as §1 with explanations assembled from parameterized fragments, then runs the same validator. Bounded rejection sampling: up to 64 deterministic redraws inside the seed; template+seed pairs that exhaust redraws are excluded from the shipped 500-template matrix by CI.

**Validation matrix in CI:** all 500 templates × 20 smoke seeds → 10,000 scenarios; every one must pass §1.2 rules plus: no duplicate cards, possible action sequences, valid stacks, consistent seat order, valid player counts, non-contradictory profile actions (a `cautious` profile never open-challenges > pool without a premium-class holding — profile behavior tables ship in FTEngine), probabilities in [0,1] recomputed exactly, meaningful-decision rule.

## 3. Coaching System (explanation contract)

Every result generates the 12-part structure (brief §Coaching) from authored + engine data:
selected vs. recommended, why, current hand category, improvements, probability (with Basis label), position effect, resource-depth effect, opponent effect, pressure effect, why other options scored lower (from tier gaps), transferable lesson.

Modes: **Quick** = authored 2 sentences · **Coach** = authored paragraph · **Deep Dive** = 12 sections, mixing authored text with live engine numbers so they can never drift apart. Nothing renders pre-lock-in (C4).

## 4. Hand-Strength Lab (content contract)

- Category chart + visual examples: static content in FTContent (`Lab/categories.json`).
- Starting-card matrix: 13×13 grid (13 pairs, 78 suited, 78 offsuit = 169). **No universal ranking shown.** The matrix requires a context selection first (players remaining, position, stack depth); tints re-compute from engine equity vs. sampled fields, with the banner: "Strength is contextual — change the context and watch the map change."
- Interactive comparison: two hands + board → winner/tie with full tiebreak narration.
- Remaining-card counter + improvement probability: live enumeration with the four-part display (exact %, friendly form, method, assumptions, misleading-variables note — brief requirement).
- Card-removal explainer ("blockers" as card removal), commonly-misread-hands gallery (three-pair illusion, ignored board pairs, counterfeit two pair), searchable glossary (educational + toggle terms).

## 5. Testing Requirements Map (traceability)

| Brief requirement | Test home |
|---|---|
| Every hand category, tiebreaks, best-five | FTEngine `EvaluatorTests` (golden vectors incl. wheel straight, steel wheel, board-plays ties) |
| Duplicate prevention, malformed data | FTContent `ValidatorTests` (fuzzed + curated bad files) |
| Probability calcs | `EnumerationTests` vs. hand-counted combinatorics (e.g., 378/1081 flush draw) |
| Seed reproducibility | `GeneratorDeterminismTests` (cross-run + golden files) |
| Scoring, redistribution, stars | `ScoringTests` (C1/C3 edge cases) |
| Campaign unlock, saved progress | App `ProgressTests` (in-memory SwiftData container) |
| 100 levels + 500 templates | CI content-validation job (§2) |
| Accessibility labels | `AccessibilityAuditTests` + manual VoiceOver pass (Phase 10) |
