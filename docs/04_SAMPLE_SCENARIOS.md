# Final Table — Ten Fully Written Sample Scenarios

One per chapter, in the level-JSON structure of `02_SCHEMAS.md`, rendered here as readable specs. Point unit is always **pts**. All four action buttons always render; illegal ones are disabled with a reason (C15). Every probability below states its exact method and assumptions; all values are hand-computed and will be **machine-verified by FTEngine in CI** (risk R2) — the engine is the source of truth if any drift is found. No real tournament brands appear anywhere (risk R8).

---

## S1 · L005 "Two Pair, Not Three" — Chapter 1 · Difficulty 2

- **Learning objective:** Only five cards count — name your true category before you act.
- **Skill tags:** hand recognition. **Active components (C1):** decision 615 · variables 231 · confidence 154.
- **Deal:** You hold **A♥ 9♥**. Shared (all five): **A♦ 9♣ K♠ K♥ 2♦**.
- **Table (2 active of 2):** Seat 0 = you, final position, 4,300 pts. Seat 1 = opponent, early position, 3,900 pts, profile **cautious**.
- **Pool:** 500 pts · **Requirement:** 100 pts.
- **Previous actions:** Opponent challenged 100 after the last shared card.
- **Objective:** Name your real hand, then answer a small challenge from a careful opponent.
- **Decisions:** Pass *(disabled — you face a requirement)* · **Match 100** · Challenge · Withdraw.
- **Recommended:** **Match.** · **Acceptable alternative:** Withdraw (Defensible).
- **Tiers:** Match **Excellent** · Withdraw **Defensible** · Challenge **Weak**.
- **Hand-strength explanation:** You have pairs of aces, nines, and (on the board) kings — but only five cards play. Best five: **A A K K 9 — two pair, aces and kings, nine kicker.** The nines are an illusion; they never appear in your final hand.
- **Key variables (author key):** Hand category · Opponent profile. Distractors: Position, Pool odds, Stack depth, Card removal.
- **Why:** Aces-and-kings is strong here, and the price is tiny (100 to win 600). But a cautious profile challenging into a paired board can hold a king (three kings beats you), so raising the stakes yourself buys nothing — only better hands continue. Match, don't escalate.
- **Common mistake:** Announcing "three pair" and re-challenging as if the nines added strength.
- **What changes the answer?** Replace the shared 2♦ with **9♦**: now your best five is **9 9 9 A A** — a full house, nines full of aces — and a value **challenge** becomes recommended.
- **Takeaway:** Count to five before you count your points.
- **Replay:** loads the variation immediately, tagged `studied` (C4).

---

## S2 · L013 "The Rule of Four" — Chapter 2 · Difficulty 3

- **Learning objective:** Estimate improvement probability with the ×4 shortcut, then compare it to the price.
- **Skill tags:** probability. **Active components:** decision 400 · probability 267 · variables 200 · confidence 133 (size inactive, C1).
- **Deal:** You hold **Q♥ J♥**. Shared (three): **9♥ 4♥ 2♠**.
- **Table (2 of 2):** Seat 0 = you, final, 5,100 pts. Seat 1 = opponent, early, 4,700 pts, profile **balanced**.
- **Pool:** 600 → opponent challenged 200 → **800**. **Requirement:** 200.
- **Objective:** Put a number on your flush chance before you touch a button.
- **Decisions:** Pass *(disabled)* · **Match 200** · Challenge · Withdraw.
- **Recommended:** **Match.** · **Acceptable alternative:** Challenge (Strong — pressure plus a real draw).
- **Tiers:** Match **Excellent** · Challenge **Strong** · Withdraw **Weak**.
- **Probability (the scored estimate):** 9 helpful hearts remain among 47 unseen cards, two cards to come.
  - **Exact:** 1 − C(38,2)/C(47,2) = 378/1081 = **34.97%** → shown as **35.0%**.
  - **Friendly:** "about 1 in 3." **Method:** exact enumeration. 
  - **Shortcut taught:** 9 outs × 4 ≈ 36% — close enough for the table.
  - **Assumptions:** counts only your flush; ignores Q/J pairing improvements (a bonus, not counted) and the small chance a flush loses anyway.
- **Price comparison:** 200 to win 1,000 → you need **20%**. You have 35%. Clear match.
- **Key variables:** Pool odds · Hand category. Distractors: Position, Stack depth, Opponent profile, Standing value.
- **Common mistake:** Multiplying 9 × 4 *per street twice* and claiming ~70% — the shortcut already covers both cards.
- **What changes the answer?** Make the challenge 700 instead of 200: now you need 33% *and* face reverse pressure later; withdraw becomes recommended.
- **Takeaway:** A draw is neither good nor bad until you compare its chance to its price.

---

## S3 · L025 "Late Steal Logic" — Chapter 3 · Difficulty 4

- **Learning objective:** Acting last with only commitment seats behind, initiative plus position beats card strength.
- **Skill tags:** position, opponent modeling. **Active components:** decision 400 · probability 150 · variables 150 · confidence 100 · size 200 — *size active with fixed stops.*
- **Deal:** You hold **K♣ 9♦**. Shared: none (pre-shared decision).
- **Table (3 active of 5):** Seat 0 = you, **final position (marker)**, 5,000. Seat 1 early (4,200, balanced) — withdrawn. Seat 2 middle (3,800, cautious) — withdrawn. Seat 3 small commitment 50 (4,600, balanced). Seat 4 large commitment 100 (5,400, **cautious**).
- **Pool:** 150 · **Requirement:** 100.
- **Previous actions:** Seat 1 withdrew · Seat 2 withdrew.
- **Objective:** Everyone folded to you. Turn the best seat at the table into points.
- **Decisions:** Pass *(disabled)* · Match 100 · **Challenge (stops: 2×=200 · 2.5×=250 · 3×=300)** · Withdraw.
- **Recommended:** **Challenge 250** (band 2×–3×; slider scored per §8.3).
- **Tiers:** Challenge **Excellent** · Withdraw **Defensible** · Match **Weak**.
- **Probability (scored estimate):** "Chance at least one of the two seats behind you was dealt a pair of tens or better."
  - Premium pairs available given your K♣ 9♦: TT(6) JJ(6) QQ(6) KK(3) AA(6) = 27 of C(50,2) = 1,225 → **2.20%** per seat; across two seats ≈ 1 − (1 − 0.022)² = **4.4%**.
  - **Friendly:** "about 1 in 23." **Method:** exact per hand; independence approximation across seats (labeled). **Assumptions:** random deals; says nothing about weaker hands that still match you.
- **Key variables:** Position · Opponent profile. Distractors: Hand category, Pool odds, Stack depth, Card removal.
- **Why:** ~96% of the time nobody behind holds a premium; a cautious large-commitment seat withdraws often. K9 is unremarkable — the *seat* is the asset. Matching (just paying 100) invites a free contest with no initiative: the worst of both.
- **Common mistake:** "My cards are mediocre, so I withdraw" — evaluating cards while ignoring that only two, mostly-folding opponents remain.
- **What changes the answer?** Move you to **early** position with five players behind: withdraw becomes recommended — same cards, opposite answer.
- **Takeaway:** The later you act, the less your cards have to say.

---

## S4 · L033 "Short Means Simple" — Chapter 4 · Difficulty 5

- **Learning objective:** At 7× the requirement, commitment beats cleverness: pick all-or-nothing, never dribble.
- **Skill tags:** resource management. **Active components:** all five at base weights (sizes are discrete options).
- **Deal:** You hold **A♠ J♠**. Shared: none.
- **Table (4 active of 6):** Seat 0 = you, late, **1,400** (7× the large commitment). Behind you: final seat (6,000, balanced), small commitment 100 (3,500, **aggressive**), large commitment 200 (2,800, cautious). Two early/middle seats withdrew.
- **Pool:** 300 · **Requirement:** 200.
- **Objective:** Your stack is short. Choose the line that uses all of its remaining power.
- **Decisions (four sized options, C15):** Withdraw · Match 200 · Challenge to 500 · **Challenge all 1,400**.
- **Recommended:** **Challenge all 1,400.**
- **Tiers:** All-in **Excellent** · Challenge 500 **Weak** · Withdraw **Weak** · Match **Major error**.
- **Probability (scored estimate):** "If one opponent matches with a random hand, chance your A♠ J♠ wins after five shared cards": **≈ 63.5%**, friendly "just under 2 in 3." **Method:** exact enumeration (engine). **Assumptions:** a *random* matching hand — real matching ranges are stronger, so treat 63.5% as an upper bound (labeled).
- **Key variables:** Stack depth · Hand category. Distractors: Position, Opponent profile, Pool odds, Standing value.
- **Why:** All-in risks 1,400 to win 300 immediately, and folds out the frequent mediocre hands behind (fold power). A 500 challenge leaves 900 behind — already committed, but having paid for none of the pressure. Matching 200 is worst: it invites the aggressive seat to attack a stack too short to answer. Withdrawing surrenders a premium-class hand as the clock runs down.
- **Common mistake:** "Saving" points with the small challenge — the 900 behind is an illusion of optionality you can no longer use.
- **What changes the answer?** Same hand at **8,000** (40×): the small challenge to 500 becomes recommended and all-in becomes Weak — depth restores optionality's value.
- **Takeaway:** Below ~10× the requirement, your only honest sizes are everything or nothing.

---

## S5 · L043 "Big Sizes, Wet Boards" — Chapter 5 · Difficulty 5

- **Learning objective:** Size is a price you set — on draw-heavy boards, charge for the chance you're giving away.
- **Skill tags:** action sizing. **Active components:** all five (slider live).
- **Deal:** You hold **A♦ A♣**. Shared (three): **K♠ Q♠ 7♦**.
- **Table (2 of 2):** Seat 0 = you, final, 5,200. Seat 1, early, 4,800, **balanced** — just **passed**.
- **Pool:** 800 · **Requirement:** 0.
- **Decisions:** **Pass** · Match *(disabled — nothing to match)* · **Challenge (slider ⅓ · ½ · ⅔ · ¾ · 1×)** · Withdraw *(disabled-equivalent: legal but scored)*.
- **Recommended:** **Challenge, band 0.65–1.0 of pool** (520–800). ⅔, ¾, or full pool scores the size band fully.
- **Tiers:** Challenge **Excellent** (size scored §8.3) · Pass **Weak** · Withdraw **Major error**.
- **Probability (scored estimate):** "If your opponent holds two spades, chance they complete a flush by the last card": 9 spades among 45 unseen → 1 − C(36,2)/C(45,2) = 360/990 = **36.4%**, friendly "a bit over 1 in 3." **Method:** exact enumeration *conditioned on an assumed holding* — labeled as an assumption, not knowledge.
- **Key variables:** Pool odds (the price you set) · Hand category. Distractors: Position, Opponent profile, Stack depth, Standing value.
- **Why:** Your pair of aces is almost certainly best *right now*; the board offers flush and straight draws that beat you by the end. A big challenge makes every draw's price wrong (¾ pool forces them to pay 600 to win 1,400 → they need 30% but must pay repeatedly). Passing hands a ~36% freeroll to exactly the hands that want one.
- **Common mistake:** Challenging tiny "to keep them in" — you keep them in *cheaply*, which is the one thing this board forbids.
- **What changes the answer?** Change the board to **K♠ 7♦ 2♥** (dry): the 0.25–0.4 band becomes recommended; big sizes now only fold out hands you beat.
- **Takeaway:** Bet the board's danger, not your hand's beauty.

---

## S6 · L054 "Calling the Bluffer" — Chapter 6 · Difficulty 6

- **Learning objective:** An aggressive profile's pressure changes the math of medium strength: become the bluff-catcher.
- **Skill tags:** opponent modeling. **Active components:** decision 400 · probability 150 · variables 150 · confidence 100 · size 200 → size inactive → decision 500, probability 187, variables 187, confidence 126.
- **Deal:** You hold **K♦ Q♦**. Shared (all five): **K♠ 8♣ 3♥ 2♦ 6♣**.
- **Table (2 of 2):** Seat 0 = you, final, 3,800. Seat 1, early, 4,100, **aggressive**.
- **Pool:** 900 → opponent challenged 600 → **1,500**. **Requirement:** 600.
- **Previous actions (timeline):** Opponent has challenged **every** street: 200, then 350, now 600.
- **Objective:** Top pair, good kicker, three barrels of pressure. Decide what the profile — not the cards — is telling you.
- **Decisions:** Pass *(disabled)* · **Match 600** · Challenge · Withdraw.
- **Recommended:** **Match.** · **Acceptable alternative:** Withdraw (Defensible — never Major error against relentless pressure).
- **Tiers:** Match **Excellent** · Withdraw **Defensible** · Challenge **Weak** (a raise folds out every bluff and is matched only by better).
- **Probability (scored estimate):** "Chance your hand is best against this profile's challenging range": **≈ 55%**, friendly "slightly better than a coin flip." **Method:** seeded simulation vs. the aggressive profile's authored range table. **Basis: behavioral assumption — clearly labeled;** against a *cautious* profile the same math returns ~30%.
- **Price:** 600 to win 2,100 → you need **28.6%**. Even generous error bars on 55% clear it.
- **Key variables:** Opponent profile · Pool odds. Distractors: Position, Hand category, Stack depth, Card removal.
- **Common mistake:** Treating the third challenge as automatic proof of strength regardless of who makes it — profile is the whole lesson.
- **What changes the answer?** Swap the opponent to **cautious** with the identical timeline: withdraw becomes recommended, match becomes Weak.
- **Takeaway:** The same action means different things from different hands — er, people.

---

## S7 · L064 "Top Pair, Traffic Ahead" — Chapter 7 · Difficulty 7

- **Learning objective:** Multiway, against a challenge *and* a match, top pair shrinks from asset to liability.
- **Skill tags:** multi-player reasoning. **Active components:** decision, probability, variables, confidence (redistributed per C1).
- **Deal:** You hold **K♥ T♥**. Shared (three): **T♦ 8♣ 6♣**.
- **Table (4 of 4):** Seat 0 = you, final, 4,400. Seat 1 early (5,000, unpredictable) — passed, still active. Seat 2 middle (4,700, balanced) — **challenged 500**. Seat 3 late (3,900, **cautious**) — **matched 500**.
- **Pool:** 600 + 500 + 500 = **1,600**. **Requirement:** 500.
- **Objective:** Best pair, best kicker — and three opponents. Count who you actually beat.
- **Decisions:** Pass *(disabled)* · Match 500 · Challenge · **Withdraw**.
- **Recommended:** **Withdraw.**
- **Tiers:** Withdraw **Excellent** · Match **Weak** · Challenge **Major error**.
- **Probability (scored estimate):** "Chance you improve to two pair or three of a kind by the last card": 5 outs (three kings, two tens) among 47 unseen → 1 − C(42,2)/C(47,2) = 220/1081 = **20.4%**, friendly "about 1 in 5." **Method:** exact enumeration. **Assumptions:** improvement ≠ winning — K♣ also arms club draws (a tainted out, flagged).
- **Why:** Heads-up, top pair here is a clear match. But a challenge into three people plus a **cautious profile's match** compresses the field's range: two pair, sets, and big draws are heavily represented. You beat almost nothing that continues and improve only 1 in 5. Price (500/2,100 = 23.8%) exceeds your clean-improvement chance before even counting the times improvement isn't enough.
- **Key variables:** Multi-player field · Opponent profile · Pool odds. Distractors: Position, Stack depth, Card removal.
- **Common mistake:** Reading your hand in a mirror ("top pair, good kicker!") instead of against the number of people telling you they like theirs.
- **What changes the answer?** Remove seats 1 and 3 — heads-up against the same challenge, match becomes recommended.
- **Takeaway:** Every extra opponent raises the bar your hand must clear.

---

## S8 · L073 "Big Stack Bullying (You)" — Chapter 8 · Difficulty 8

- **Learning objective:** Standing value: a profitable point gamble can still be a losing ranking decision.
- **Skill tags:** tournament pressure. **Active components:** decision, probability, variables, confidence (C1 redistribution).
- **Standing context (all fictional):** 5 players remain. Ranking points by finish: **100 · 60 · 40 · 25 · 10**, with a **badge tier at 4th** (the "reward jump").
- **Deal:** You hold **9♠ 9♥**. Shared: none.
- **Table (5 of 5, commitments 100/200):** Seat 1 early = **leader, 5,800, aggressive — challenged to 3,400** (covers you). Seats 2–3 withdrew. Seat 4 small commitment (**900**, cautious). Seat 5 large commitment (**1,100**, balanced). Seat 0 = you, final, **3,200**.
- **Pool:** 300 + 3,400 = **3,700**. **Requirement:** 3,200 (your whole stack).
- **Decisions:** Pass *(disabled)* · **Match 3,200 (all)** · Challenge *(disabled — matching already commits everything)* · **Withdraw**.
- **Recommended:** **Withdraw.**
- **Tiers:** Withdraw **Excellent** · Match **Weak** (not Major error — it is close in raw points, which is exactly the lesson).
- **Probability (scored estimate):** "Chance 9♠ 9♥ wins if you match": **≈ 52%** vs. the aggressive leader's pressure range. **Basis: behavioral assumption, labeled.** Raw-point price: risk 3,200 to win ~3,500 → need ~47.8% → *slightly profitable in points.*
- **Standing value analysis (the point of the level):** Two players sit on 900 and 1,100 stacks paying 300 per round. By surviving, you climb toward the 4th-place badge at almost no cost; matching converts a near-lock 25–40 ranking points into a coin flip between ~10 and a shot at more. The Standing Value Model prices the match at **−6 ranking points** despite +150 game points. (Model label: "assumes equal skill — a simplification.")
- **Key variables:** Standing value · Stack depth · Opponent profile. Distractors: Position, Pool odds, Hand category.
- **Common mistake:** "I'm 52% and priced in" — true, and irrelevant, because game points and ranking points are different currencies here.
- **What changes the answer?** Remove the two short stacks (3 players remain, no jump pending): matching becomes recommended — the same 52% is now simply a good price.
- **Takeaway:** Near a reward jump, survival is a hand you're always holding.

---

## S9 · L084 "Removal as a Weapon" — Chapter 9 · Difficulty 9

- **Learning objective:** Card removal ("blockers"): what you hold reshapes what they can hold — and arms a polarized challenge.
- **Skill tags:** probability, opponent modeling. **Active components:** all five (sizing active).
- **Deal:** You hold **A♠ 5♦**. Shared (four): **K♠ 9♠ 4♠ 2♥**.
- **Table (2 of 2):** Seat 0 = you, final, 6,800. Seat 1, early, 5,900, **balanced** — **challenged 700**.
- **Pool:** 1,000 + 700 = **1,700**. **Requirement:** 700.
- **Objective:** You hold no flush and (almost) no hand. You also hold the most important card in the deck. Use it.
- **Decisions:** Pass *(disabled)* · Match 700 · **Challenge (slider: 1.0× · 1.2× · 1.35× · 1.5× of pool)** · Withdraw.
- **Recommended:** **Challenge, band 1.2–1.5× pool (2,040–2,550).** A polarized size: it claims the flush you make impossible for them to hold in its strongest form.
- **Tiers:** Challenge **Excellent** · Withdraw **Strong** (folding no-pair is never a disaster) · Match **Weak** (ace-high can't win a showdown it calls).
- **Probability (scored estimate):** "Chance the opponent holds two spades (a made flush)": spades left = 13 − 3 board − **your A♠** = 9 → C(9,2)/C(46,2) = 36/1,035 = **3.5%**, friendly "about 1 in 29."
  - **The removal lesson, quantified:** without your A♠ it would be C(10,2)/C(46,2) = 45/1,035 = **4.3%** — and the flushes that remain can never be the *nut* flush, so their strongest matching hands simply don't exist.
  - **Method:** exact enumeration over uniform random hands. **Assumptions (labeled):** real challenging ranges aren't uniform — this is a floor for the reasoning, not a range analysis.
- **Key variables:** Card removal · Opponent profile (a balanced profile can withdraw) · Pool odds. Distractors: Position, Stack depth, Standing value.
- **Common mistake:** Seeing A-high, thinking "I have nothing," and withdrawing — evaluating your *showdown* hand when the decision is about your *challenge* hand.
- **What changes the answer?** Swap your A♠ for the **A♦**: now they *can* hold the nut flush; withdraw becomes recommended and the bluff drops to Weak.
- **Takeaway:** Sometimes the card that matters is the one nobody else can have.

---

## S10 · L099 "One Decision for Everything" — Chapter 10 · Difficulty 10

- **Learning objective:** Position, depth, profile, probability, sizing, and standing pressure — resolved in a single lock-in.
- **Skill tags:** all nine feed the dashboard. **Active components:** all five (sized discrete options).
- **Standing context:** 3 players remain. Ranking points: **100 · 60 · 40**. The 3rd→2nd gap is the last big jump.
- **Deal:** You hold **A♥ Q♥**. Shared: none.
- **Table (3 of 3, commitments 100/200):** Seat 1 = **leader**, final position (marker), 6,100, **aggressive** — **challenged to 600**. Seat 2 = small commitment, 1,300, **cautious** — withdrew. Seat 0 = you, large commitment, **2,600**.
- **Pool:** 100 + 200 + 600 = **900**. **Requirement:** 400 more.
- **Decisions (four sized options, C15):** Withdraw · Match 400 · Challenge to 1,200 · **Challenge all 2,600**.
- **Recommended:** **Challenge all 2,600.**
- **Tiers:** All-in **Excellent** · Withdraw **Defensible** (survival logic is real with a 1,300 stack at the table) · Match **Weak** (out-of-initiative, awkward stack afterward) · Challenge 1,200 **Major error** (commits half your stack while leaving the decision unfinished — the L033 lesson under maximum pressure).
- **Probability (scored estimate):** "Chance A♥ Q♥ wins all-in against this profile's challenging range": **≈ 57%**, friendly "a bit better than 5 in 9." **Basis: behavioral assumption, labeled** — an aggressive leader in the last seat challenges very widely.
- **Standing value analysis:** Withdrawing keeps you ~2,400 vs. a 1,300 short stack — decent 2nd-place odds by patience alone, which is why withdraw stays Defensible. But the Standing Value Model prices the all-in at **+4 ranking points**: 57% equity, plus the ~40% of the time the leader simply withdraws and you collect 900 uncontested (fold power ≈ the whole margin). Against a *cautious* leader, that fold-power term shrinks and withdraw takes over — profile is doing real work in the math, and the model says so on screen.
- **Key variables:** Opponent profile · Standing value · Stack depth. Distractors: Position, Pool odds, Card removal.
- **Common mistake:** Splitting the difference with the 1,200 challenge — the "compromise" that takes all of the risk with none of the leverage.
- **What changes the answer?** Make the leader **cautious**: their challenge now means strength, fold power evaporates, and **withdraw** becomes recommended.
- **Takeaway:** Mastery isn't a new rule — it's every old rule, weighed at once.
