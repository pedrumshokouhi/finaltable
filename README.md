# Final Table: Strategy Puzzles

An offline iOS puzzle game that teaches probability, position, resource management and decision quality through 100 handcrafted card scenarios. You are scored on how well you decided, never on how the cards fell.

No real money, no gambling, no account, no network. Educational vocabulary by default.

## How a puzzle works

1. Read the table: your cards, the shared cards, the stacks, the position, the pressure.
2. Choose one of four actions. Illegal ones are disabled with a plain-language reason, which is itself the lesson.
3. From Chapter 2, estimate the probability you are ahead. Pick the variables that mattered. Say how confident you are.
4. Get a score out of 1,000 across decision quality, probability accuracy, variable identification and calibration. Stars key on decision quality first, so a lucky outcome never earns a star and a good decision with a rough estimate still earns two.

Ten chapters of ten levels each, from reading your hand to a final-table "standing value" model, plus a daily puzzle that every player in the world gets on the same date with no server involved.

## The engine

`Packages/FTEngine` is a dependency-free Swift package that the app imports.

| Piece | What it does |
|---|---|
| `Cards`, `HandEvaluation` | Card model and a best-five evaluator with full tie-break rules |
| `Equity` | Exact enumeration for heads-up spots, which is the default. Monte Carlo only for three or more unknown hands against weighted ranges, with a fixed SplitMix64 generator, fixed iteration order and integer counters, so results are bit-identical on every device |
| `Probability` | Exact figures and the "friendly" estimates (the times-four and times-two rules) the game teaches |
| `Scoring` | The 1,000-point model, star tiers, confidence calibration, and the rule that redistributes points when a component does not apply to a puzzle |
| `ScenarioModels`, `ScenarioValidator` | Authored and generated scenarios, with a validator that rejects any level without at least two legal, meaningfully different options |

Tests live in `Packages/FTEngine/Tests` and cover cards, evaluation, enumeration, equity, scoring, standing value, tie-breaks and the validator.

```bash
cd Packages/FTEngine && swift test
```

## Spec first

The product was specified before any code. [docs/01_SPEC.md](docs/01_SPEC.md) opens with a consistency review that found 15 contradictions in the original brief and records the decision taken on each one, so the spec that follows is internally consistent. The data schemas, the 100-level campaign and ten fully worked sample scenarios are in the same folder.

## Build it

Requires Xcode 26 or later. Open `App/FinalTable.xcodeproj` and run on an iOS 17 or later simulator or device. SwiftData handles persistence; Game Center is optional and never prompted for.

App Store copy, rating answers and screenshots are in [AppStore/RELEASE_PACKAGE.md](AppStore/RELEASE_PACKAGE.md).

## License

MIT. See [LICENSE](LICENSE).
