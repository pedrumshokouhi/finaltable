# Final Table: Strategy Puzzles — App Store Release Package

Prepared 2026-08-05. Everything below is copy-paste-ready for App Store Connect.
**Blocker to submission:** builds must come from a release (non-beta) Xcode. This Mac runs
macOS beta and can only run Xcode 27 beta → submit when Xcode 27 goes final (typically
September), or build once on any Mac with release Xcode. Everything else is ready.

---

## App record (App Store Connect → My Apps → "+")

| Field | Value |
|---|---|
| Platform | iOS |
| Name | **Final Table: Strategy Puzzles** |
| Primary language | English (U.S.) |
| Bundle ID | `com.pedrumshokouhi.finaltable` (auto-registered to team RMZ2B524CF) |
| SKU | `finaltable-001` |
| Access | Full Access |

## Version information

**Subtitle** (30 chars max):
`Decision-quality training`

**Promotional text** (170 chars):
`100 handcrafted card-strategy puzzles. Weigh probability, position, and pressure — then get graded on your reasoning, never your luck. Fully offline.`

**Description:**
```
Final Table is an educational strategy game about making great decisions under uncertainty.

Study the cards, the seats, and the stakes. Estimate your chances. Choose your action and
commit fictional points. Then get scored on the one thing that matters: the quality of your
reasoning — never the luck of the draw.

EDUCATIONAL STRATEGY GAME. NO REAL-MONEY GAMBLING.
All chips are fictional puzzle points. Nothing to buy, deposit, win, or cash out.

• 100 HANDCRAFTED PUZZLES across 10 chapters: hand reading, probability, position,
  resource depth, action sizing, opponent profiles, multi-player decisions, tournament
  pressure, advanced reasoning, and final-table mastery.
• SCORED OUT OF 1,000 on five dimensions: decision quality, sizing, probability
  estimation, key-variable identification, and confidence calibration.
• A COACH ON EVERY PUZZLE: quick takeaways, full explanations, the common mistake,
  and a "what changes the answer?" twist that flips one variable.
• EXACT MATH, HONESTLY LABELED: every probability shows its exact value, a friendly
  approximation, the calculation method, and its assumptions.
• DECISIONS ≠ OUTCOMES: a mathematically sound decision never loses points to an
  unlucky card. Stars measure judgment, not variance.
• FULLY OFFLINE: no account, no ads, no tracking, no data collection. Your progress
  stays on your device.

From your first pair to reward-jump mathematics, Final Table teaches the transferable
skill underneath every card game — and every real decision: how to think clearly when
you can't be certain.
```

**Keywords** (100 chars):
`strategy,puzzle,probability,logic,decision,card game,brain training,odds,critical thinking`

**Support URL:** `https://pedrumshokouhi.com`
**Marketing URL:** (optional — leave blank or use same)
**Copyright:** `© 2026 Pedrum Shokouhi`

## Screenshots (captured, in ./screenshots/)

- `iphone-6.9/` — 5 shots at 1320×2868 (required 6.9" set): onboarding, home, campaign, puzzle, results
- `ipad-13/` — 4 shots at 2064×2752 (required 13" set)
- Suggested order: puzzle first (hero), then results, campaign, home, onboarding.

## App icon
1024×1024 in the project asset catalog (`Assets.xcassets/AppIcon.appiconset`). No alpha issues (opaque background).

## Age rating questionnaire (answer honestly)

- All categories: **None** (no violence, no profanity, etc.)
- **Simulated Gambling: Infrequent/Mild** — the game uses card-game mechanics with
  fictional points and no wagering. (Answering "None" risks a metadata rejection;
  Infrequent/Mild typically yields a 12+ rating.)
- Unrestricted web access: No · Contests: No

## Privacy (App Privacy section)

- **Data collection: "Data Not Collected"** — the app has no network features, no
  analytics, no accounts, no third-party SDKs. The privacy label is the simplest possible.

## Pricing & availability

- Price: **Free** (no IAP in v1)
- Availability: all territories

## App Review notes (paste into "Notes" box)

```
Final Table is an educational strategy-puzzle game. It contains:
- NO wagering and no real or purchasable currency of any kind
- NO in-app purchases, no prizes, no cash-out, and no links to gambling services
- All "points" are fictional puzzle scores used to grade decision quality

The game teaches probability and decision-making using card-game scenarios in the same
way chess apps teach tactics. Scoring rewards correct reasoning and explicitly never
rewards lucky outcomes. The app is fully offline, collects no data, and requires no account.

The disclaimer "Educational strategy game. No real-money gambling." appears in onboarding,
on the home screen, in Settings, and on every puzzle screen.
```

## Build & upload procedure (when a release Xcode is available)

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer   # release Xcode, license accepted
cd ~/Desktop/ClauWork/FinalTable/App
xcodebuild -project FinalTable.xcodeproj -scheme FinalTable \
  -destination 'generic/platform=iOS' -archivePath ./build/FinalTable.xcarchive \
  -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath ./build/FinalTable.xcarchive \
  -exportOptionsPlist AppStore/ExportOptions.plist -exportPath ./build/export \
  -allowProvisioningUpdates
# Upload with an App Store Connect API key (Users and Access → Integrations → "+"):
xcrun altool --upload-app -f ./build/export/FinalTable.ipa -t ios \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

Then in App Store Connect: attach the build to version 1.0, complete the sections above,
**Submit for Review** (Pedrum confirms this final step).

## Pre-submission checklist

- [ ] Release (non-beta) Xcode available (Xcode 27 final, ~September)
- [ ] Version/build numbers: 1.0 (1) — already set
- [ ] Run the 181-engine-test suite one final time
- [ ] Test on real iPad (pending Developer Mode enable)
- [ ] Accessibility pass (VoiceOver on puzzle + results screens)
- [ ] App Store Connect app record created
- [ ] API key created for upload
- [ ] Final play-through of Chapters 1–2 on device
