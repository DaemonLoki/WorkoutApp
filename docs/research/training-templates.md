# Training templates for the Smart Workout Builder

Researched 2026-10-09. This note feeds the rule-based Smart Workout Builder. A Workout gets an optional **Focus** (Push, Pull, Legs, Upper Body, Lower Body, Full Body, Arms, Core). A recommended Rotation is shaped by a **Training Goal** (Overall Health, Bigger Arms, Athleticism, Running, Cycling), by **Weekly Sessions** (2–6) and by **Equipment Access** (Full Gym, Dumbbells & Bench, Bodyweight Only). Sources are listed at the end, and each `[S…]` / `[U…]` label links to its URL. Each claim carries one of three labels:

- **confirmed**: from a primary or authoritative source. These are position stands and guidelines (ACSM, NSCA, WHO, UK CMO, US HHS) and peer-reviewed systematic reviews, meta-analyses or trials, read on PubMed Central or Europe PMC. Where only the abstract was available, the claim rests on the abstract.
- **unverified**: from secondary sources only (coaching sites, blogs).
- **not documented**: no source found. The value is a derivation or design choice made in this note, and the note says so.

Terms follow [CONTEXT.md](../../CONTEXT.md) as edited in the working tree on 2026-10-09: Focus, Training Goal, Weekly Sessions, Equipment Access, Recommendation, Gap, Secondary Muscle Group ([ADR-0007](../adr/0007-delts-secondary-muscle-groups-and-catalog-revisions.md)). Two words from the brief clash with it. "Template" is listed under *Avoid* for Recommendation, and "slot" under *Avoid* for Planned Exercise. This note still uses "template" (for the data the builder encodes) and "slot" (a placeholder in a template that becomes a Planned Exercise), because the brief does. The implementation needs its own glossary term for the slot, for example **Movement Slot**.

> **Glossary note (added when planning M8):** this research says "slot" and "template"; the app's terms are **Need** and **Blueprint** (CONTEXT.md). Where it and [exercise-muscle-data.md](exercise-muscle-data.md) disagree on an Exercise's Muscle Groups, the latter wins; the merged catalog is README §17.

## Summary

1. **The evidence fits a simple, fixed-Target app.** ACSM's 2026 position stand is an overview of 137 systematic reviews [S1]. It says the biggest gain comes from doing any resistance training at all. Every major muscle group should be trained on at least 2 days a week, with at least 2 Sets per Exercise. Failure training, machines versus free weights and periodization "did not consistently change results" [S1, S2]. WHO, US HHS and the UK CMOs all set the same minimum of 2 days a week [S4, S5, S7].
2. **Volume.** Hypertrophy improves with weekly Sets per Muscle Group: ≥10 Sets a week helps, with diminishing returns around 18–20 [S1, S8, S11]. Strength levels off after about 2–3 Sets per Exercise [S1]. **Frequency:** training a muscle twice a week beats once a week [S9]. Beyond that, frequency hardly matters for hypertrophy once volume is equal [S10, S11].
3. **One fixed rep number works.** Hypertrophy is similar across loads from 30% to 100% of 1RM [S1, S13, S14]. Strength favours heavy loads, ≥80% 1RM, roughly ≤6–8 reps [S1, S13]. Power favours moderate loads lifted fast, with ≤24 reps × Sets per Exercise [S1]. The defaults are **3×10** for Overall Health compounds (in the 8–12 band of [S3, S5]), **3×12** for arm isolation, and **3×6** for heavy athletic/endurance-support compounds. Power Exercises get **3×5** or **3×8 jumps**. The owner's example "4×6" is trimmed to 3×6, because [S1] finds that strength levels off after 2–3 Sets.
4. **Rest:** use ≥90 s for hypertrophy [S15] and 2–3 min for heavy compounds [S3, S16, S17]. Shorter Rest is fine for small muscles and core. **Order:** power first, then compounds, then isolation [S3, S18]. **Supersets** of antagonists save time without losing volume [S19, S20].
5. **Running / Cycling.** Use 2 strength Sessions a week, never more than 3 [S23, S29]. Heavy compound lifting and plyometrics improve running economy [S23, S24, S28]. Heavy lower-body compounds help cycling [S28, S29, S30]. Concurrent training does not blunt strength or hypertrophy, but it does reduce explosive strength, especially when both are done in the same session [S31]. **The app must not claim strength training prevents running injuries.** The runner-specific meta-analysis found no significant effect [S25], even though strength training reduces sports injuries in general [S26, S27].
6. **Templates (§5)** are ordered slot lists per Focus, each slot having a role (power / primary / secondary / upper / accessory / calves / core). The Training Goal chooses Sets × reps @ Rest per role (§3.6) and adds or removes slots (§3.7). Equipment Access picks the first candidate Exercise that fits (§5.0).
7. **The catalog grows from 44 to 83 Exercises**, with 39 new rep-based Exercises (§5.10); 85 if a medicine-ball Equipment case is added. The Muscle Group remap for the existing "Shoulders" tags is in §5.11.
8. **Open decisions for the owner** are in §7. They include: does Bodyweight Only assume a pull-up bar? Should Dumbbells & Bench include kettlebell Exercises? How are reps counted for unilateral Exercises? Should power Exercises get rep Step Ups?

---

## 1. Dosing evidence

### 1.1 Weekly Sets per Muscle Group

| Aim | Weekly Sets per Muscle Group | Label | Source |
|---|---|---|---|
| General health | No set count given. Train "all major muscle groups" on ≥2 days a week. "At least two sets per exercise." | **confirmed** | [S1, S4, S5, S7] |
| General health (US) | One Set of 8–12 reps per Exercise works, and 2–3 Sets may work better | **unverified** (quoted by secondary sites from the HHS guidelines; the primary PDF could not be loaded) | [U3] |
| Hypertrophy | ≥10 Sets a week, with a dose–response; diminishing returns beyond ~18–20 weekly Sets | **confirmed** | [S1] (Table 6 and Discussion) |
| Hypertrophy | Each extra weekly Set adds ~0.37% gain; higher volume beats lower (ES diff 0.24); data only reached ~10+ Sets | **confirmed** | [S8] |
| Hypertrophy and strength | Both rise with volume with diminishing returns, more pronounced for strength. Best predictor: "fractional" counting (a Set counts 1 for directly trained muscles, 0.5 for indirectly trained ones) | **confirmed** | [S11] (abstract and preprint; plateau figures only in the preprint, so not used) |
| Strength | 2–3 Sets per Exercise per Session; diminishing returns beyond that | **confirmed** | [S1] |

**Builder rule (derived from [S1, S11]):** count weekly Sets per Muscle Group fractionally: a Muscle Group counts 1, a Secondary Muscle Group 0.5. This is exactly ADR-0007's "Secondary Muscle Groups … count half", and it matches the counting method that best predicted outcomes in [S11]. Targets per Training Goal are in §3.6.

### 1.2 Frequency per muscle

- Training a muscle **2×/week beats 1×/week** for hypertrophy when volume is equal: **confirmed** [S9].
- Above that, frequency has no meaningful effect on hypertrophy once volume is equal: **confirmed** [S10, S11]. For strength, frequency has a consistent effect with diminishing returns: **confirmed** [S11]. ACSM favours ≥2 Sessions a week for strength: **confirmed** [S1].
- The highest-ranked prescriptions in a network meta-analysis were higher load, multiple Sets, and 2× a week for hypertrophy or 3× a week for strength. All prescriptions beat no training: **confirmed** [S12].
- **Builder rule:** every Rotation the builder recommends should hit each major Muscle Group at least twice per pass through the Rotation, wherever the Session count allows (§4). This applies the ≥2 days a week minimum from [S1, S4, S5, S7].

### 1.3 Reps per aim, and why one fixed number is fine

- **Strength:** loads ≥80% 1RM with 2–3 Sets: **confirmed** [S1, S2]. High loads (>60% 1RM) give more 1RM strength than low loads: **confirmed** [S13]. ACSM 2009 recommended 1–6 RM for advanced strength: **confirmed** [S3]. The idea that ~80% 1RM is "about 6–8 reps" comes from the usual %1RM–reps tables: **unverified** (no primary source read).
- **Hypertrophy:** similar gains from 30% to 100% 1RM, provided effort is high: **confirmed** [S1, S13]. The "repetition continuum" (heavy for strength, moderate for size, light for endurance) holds only partly; adaptations happen across a wide range of loads: **confirmed** [S14]. ACSM 2009 put the emphasis on 6–12 RM: **confirmed** [S3]. Several summaries say the 2026 stand dropped the 6–12 RM prescription as too specific: **unverified**, but consistent with [S1].
- **Muscular endurance:** 40–60% 1RM for >15 reps with <90 s Rest: **confirmed** [S3], from the 2009 stand. The 2026 stand found too little data to recommend a load: **confirmed** [S1].
- **Power:** 30–70% 1RM, concentric phase as fast as possible, low-to-moderate volume (reps × Sets < 24): **confirmed** [S1]. Olympic-style lifting also improves power [S1].
- **Novices:** 8–12 RM loads, 2–3 days a week: **confirmed** [S3]. US guidance: 8–12 reps per Set [U3].
- **Effort:** training to failure "does not enhance gains"; aim for about 2–3 reps in reserve: **confirmed** [S1]. Hypertrophy (but not strength) may improve slightly as Sets get closer to failure: **confirmed** but exploratory [S37].

**Implications for a fixed Target (not documented, derived):**

- The app has no %1RM. Any rep number within ~6–15 works for hypertrophy and health, provided the weight makes the last reps hard. The first-Session copy should say so (§6).
- Weight Step granularity matters. ACSM 2009 advises raising the load by 2–10% once the Target is beaten by 1–2 reps [S3]. A 2 kg dumbbell Weight Step on a 10 kg curl is +20%, so isolation Exercises will mostly progress by +1 rep. That argues for **12 rather than 8 reps on isolation**: there is room to add reps before a weight Step Up. Rep Step Ups are capped at 50 (README §4).
- Bodyweight Exercises at 0 kg Added Weight progress only by reps, so they need a starting rep number the user can actually reach (§3.6, last rule).

### 1.4 Rest

| Finding | Label | Source |
|---|---|---|
| Small hypertrophy benefit from Rest >60 s; no detectable difference beyond 90 s | **confirmed** | [S15] |
| Strength: untrained lifters do fine with 60–120 s, trained lifters need >2 min to maximise strength; short Rest (<60 s) still gives solid strength gains | **confirmed** | [S16] |
| Trained men, 8 weeks: 3 min Rest beat 1 min for 1RM and thigh thickness | **confirmed** | [S17] |
| ACSM 2009: 3–5 min for strength/power core lifts, 1–2 min for hypertrophy, <90 s for endurance | **confirmed** | [S3] |
| ACSM 2026: no strength difference between <1 min and >1 min Rest; hypertrophy evidence insufficient | **confirmed** | [S1] |
| Cyclists: 2–4 min between Sets of heavy lower-body work | **confirmed** | [S29] |
| NSCA tables (2–5 min strength, 30–90 s hypertrophy, ≤30 s endurance) | **unverified** (quoted secondhand, NSCA primary not read) | — |

**Defaults (not documented, derived from the table above):** heavy compounds 150–180 s, hypertrophy compounds 120 s, isolation 75–90 s (≥60 s per [S15]), core and calves 60 s, power 150 s. All values fit the app's 30–300 s range in 15 s steps.

### 1.5 Sets per Session and Session length

**not documented:** no guideline sets a per-Session Set cap. The estimate below is derived and is meant to be encoded:

```
minutes ≈ warmUp (8)
        + Σ Exercises × 1 (walk/setup)
        + Σ Sets × (10 s + 3 s × reps [× 2 if unilateral]) / 60
        + Σ Rests / 60          // Rest after every Set; in a Superset only after each pair
```

| Example | Sets | ≈ minutes |
|---|---|---|
| Overall Health Full Body: 4 compounds 3×10 @ 90 s + 3 accessories 2×12 @ 60 s | 18 | ~52 |
| Same, with the push/pull and arm pairs as Supersets | 18 | ~45 |
| Athleticism Lower Body: 3×5 power @ 150 s, 3×6 @ 180 s, 2 × 3×8 @ 120 s, 2×12 @ 60 s, 3×10 core @ 60 s | 17 | ~59 |
| Bigger Arms Upper Body: 4 compounds (3×8 @ 150 s, 3×10 @ 120 s) + 4 arm accessories 3×12 @ 90 s, with slots 3+4 and both arm pairs as Supersets | 24 | ~63 |

**Builder limits (not documented, derived):** for a 45–75 min Session, aim for 15–22 Sets (up to 24 when at least two Supersets are used). Stay at ≤16 when most Rests are ≥150 s. Use 4–7 Exercises (8 only with Supersets). If the estimate passes 75 min, drop optional slots first, then turn accessory pairs into Supersets, then reduce accessory Sets from 3 to 2. Supersets save time without losing volume: **confirmed** [S19].

---

## 2. Focus → Muscle Groups, Exercise count, order, Supersets

### 2.1 Coverage per Focus

The required/optional split is a design choice (**not documented**). It follows the usual splits: push = chest/shoulders/triceps, pull = back/biceps, and so on. Typical Exercise counts follow from §1.5.

| Focus | Required Muscle Groups | Optional Muscle Groups | Exercises |
|---|---|---|---|
| Push | Chest, Front Delts, Triceps | Side Delts | 5–6 |
| Pull | Lats, Upper Back, Biceps | Rear Delts, Traps, Forearms | 5–6 |
| Legs | Quads, Glutes, Hamstrings | Calves, Adductors, Lower Back | 5–6 |
| Upper Body | Chest, Lats, Upper Back, Front Delts | Side Delts, Rear Delts, Biceps, Triceps, Traps | 6–7 |
| Lower Body | Quads, Glutes, Hamstrings, Abs | Calves, Adductors, Lower Back, Obliques | 5–6 |
| Full Body | Quads, Glutes, Hamstrings, Chest, Lats or Upper Back | Front Delts, Side/Rear Delts, Biceps, Triceps, Abs, Obliques, Calves | 5–7 |
| Arms | Biceps, Triceps | Forearms, Side Delts | 4–6 |
| Core | Abs, Obliques | Lower Back | 4–5 (a short Workout, ~20–25 min) |

Legs and Lower Body overlap almost entirely. In this note, **Lower Body = Legs + a core slot**: it pairs with Upper Body, while Legs pairs with Push/Pull, where core can live on any day.

### 2.2 Ordering rules

1. **Power/plyometric Exercises first**, while fresh. ACSM 2009 orders higher-intensity before lower-intensity Exercises: **confirmed** [S3]. "Power first" as a specific rule is common coaching practice: **unverified**.
2. **Multi-joint before single-joint, large before small Muscle Groups:** **confirmed** [S3].
3. **The priority lift first.** Strength gains are largest for the Exercises done at the start of a Session; hypertrophy does not depend on order: **confirmed** [S1, S18]. So the order matters for strength goals and is free to vary for Bigger Arms.
4. **Core and calves last.** Not tiring the trunk before heavy squats and hinges is coaching convention: **unverified**. It does not conflict with rule 2.

### 2.3 Superset pairings

The evidence: agonist–antagonist Supersets keep total reps and volume load, cut Session time, and match traditional Sets for strength and hypertrophy over time. Supersets of the same movement pattern reduce volume load. Supersets raise lactate, perceived exertion and muscle damage: **confirmed** [S19]. Paired antagonist Sets are an efficient way to build strength: **confirmed** [S20].

**Builder rules (not documented, derived from [S19]):**

- Pair only adjacent slots, at most 2 per Superset (README §3).
- Never put power slots or primary slots with Rest ≥150 s in a Superset; they need full recovery.
- Rest after the pair = the longer of the two Rests.

Recommended pairs:

| Pair | Where |
|---|---|
| Horizontal push + horizontal pull (e.g. Dumbbell Bench Press + One-Arm Dumbbell Row) | Full Body, Upper Body (secondary compounds only) |
| Vertical push + vertical pull (Seated Dumbbell Shoulder Press + Lat Pulldown) | Upper Body |
| Biceps + Triceps (Dumbbell Curl + Triceps Pushdown) | Arms, Upper Body, Full Body, Push/Pull add-ons |
| Leg Extension + Leg Curl | Legs, Lower Body |
| Chest isolation + rear delts (Cable Fly + Face Pull) | Upper Body |
| Calves + core (Standing Calf Raise + Cable Crunch) | Legs, Lower Body |
| Side Delts + Triceps (non-competing, not antagonists) | Push. **unverified** that unrelated pairs keep volume as well as antagonists do; [S19] only separates antagonist from same-pattern pairs |

---

## 3. Training Goals

### 3.1 Overall Health

- **Evidence: confirmed.**
  - WHO: muscle-strengthening at moderate or greater intensity, involving all major muscle groups, on ≥2 days a week. For older adults, multicomponent balance and strength training on ≥3 days a week [S4].
  - US HHS: muscle-strengthening on ≥2 days a week [S5, S6].
  - UK CMOs: strength-based exercise on ≥2 days a week. It "can help delay the natural decline in muscle mass and bone density" [S7].
  - ACSM 2026: the biggest gain is going from none to any. Adherence and enjoyment drive results. Resistance training improves gait speed, balance and chair-stand performance [S1, S2].
- **Muscle Groups to prioritise:** all of them, evenly. Focus on legs/hips, back, chest, shoulders, arms and abs, the groups HHS lists [U3].
- **Patterns:** squat, hinge, single-leg, horizontal push, horizontal pull, vertical push, vertical pull, anti-extension/anti-rotation core, calves. Carries are excluded because they are measured in distance or time.
- **Defaults:** compounds 3×10 @ 90 s, accessories and core 2×12 @ 60 s.
  - 10 is in the middle of the 8–12 novice band [S3, U3].
  - 3 Sets meets ACSM's "at least two sets per exercise" [S1] and leaves one Set of margin for Sets the user skips.

### 3.2 Bigger Arms

The owner's brief called this "blown-up arms".

- **Evidence: confirmed.**
  - Hypertrophy needs ≥10 weekly Sets per Muscle Group, with diminishing returns around 18–20 [S1, S8].
  - In untrained men, curls grew the elbow flexors more than rows did (11.1% vs 5.2%): direct arm work adds to compound pulling [S21].
  - An earlier trial in untrained men found no extra benefit from adding single-joint arm work to compounds [S22]. The evidence is mixed, so the templates keep both compounds and direct arm work.
  - Rest >60 s helps arm hypertrophy a little [S15].
- **Muscle Groups to prioritise:** Biceps, Triceps, then Forearms. Keep Chest, Lats, Upper Back and Front/Side Delts at health level or above (the pressing and pulling compounds also train the arms). Keep legs at the ≥2 days a week minimum.
- **Weekly target (derived):** Biceps and Triceps each 12–20 fractional Sets. Example: 2 direct arm Exercises × 3 Sets × 2 Sessions = 12, plus indirect work from rows and presses.
  - Coaching sources give 6 Sets a week as a minimum effective dose and 10–16 as a typical working range for biceps: **unverified** [U1].
- **Defaults:** primary compounds 3×8 @ 150 s, secondary 3×10 @ 120 s, arm isolation 3×12 @ 90 s, other accessories 3×12 @ 90 s, core 2×12 @ 60 s.

### 3.3 Athleticism

- **Evidence: confirmed.**
  - Gains in lower-body strength carry over to sprint speed (mean +3.1%; squat-strength effect size correlates with sprint effect size, r = −0.77) [S32].
  - Greater strength goes with better jumping, sprinting and change of direction [S33].
  - Plyometrics improve jump height. Training of >10 weeks and >20 sessions works best, and combining jump types beats a single type. Added weight on jumps gave no extra benefit [S34].
  - Power: 30–70% 1RM moved fast, reps × Sets < 24. Olympic-style lifts help [S1].
- **Muscle Groups to prioritise:** Glutes, Quads, Hamstrings, Calves, Adductors, Obliques (anti-rotation and lateral work), then balanced upper body.
- **Patterns:**
  - Jump/bound: vertical, horizontal and lateral. All are rep-based.
  - Squat, hinge, single-leg, horizontal/vertical push and pull, anti-rotation core, calf/ankle.
  - Medicine-ball throws do not fit the `Equipment` enum (§7).
- **Defaults:**
  - Power 3×5 @ 150 s (15 reps × Sets, under 24 [S1]).
  - Primary compounds 3×6 @ 180 s.
  - Secondary 3×8 @ 120 s.
  - Accessories 2×12 @ 60 s, core 3×10 @ 60 s.
  - Power Exercises stay at 0 kg Added Weight [S34]. Kettlebell Swing and Push Press are loaded.

### 3.4 Running

- **Evidence: confirmed.**
  - Adding 2–3 strength Sessions a week improves running economy by 2–8%, along with time-trial performance and sprint speed. Body composition is not harmed. Multi-joint free-weight Exercises likely give the better stimulus. Heavy, explosive and plyometric training all help [S23].
  - High-load training and plyometrics improve running economy; submaximal-load and isometric training do not [S24]. Plyometrics help most at slower speeds (≤12 km/h), heavy loads most in runners with high VO₂max [S24].
  - Running economy improves with both heavy and explosive strength training [S28].
- **Injury: confirmed, and it limits what the app may say.**
  - A 2024 meta-analysis of endurance runners (9 studies, 1,904 runners) found **no significant reduction** in running-related injury risk or rate from exercise-based programmes. Supervised programmes only did show a reduction [S25].
  - Strength training does reduce sports injuries in general. RR 0.315 across 25 trials [S26]. Risk falls further with more volume and intensity [S27]. These trials were mostly not runners.
  - Wording rule in §6.
- **Muscle Groups to prioritise:** Glutes, Quads, Hamstrings, Calves, Adductors, Abs and Obliques. Upper body at maintenance level.
- **Patterns:** heavy squat or leg press, hinge, single-leg (Bulgarian Split Squat, Step-up, Single-Leg Romanian Deadlift), calf/ankle (Single-Leg Calf Raise, Pogo Jump), low-volume plyometrics, anti-rotation core, 1 push + 1 pull.
- **Defaults:**
  - Plyometrics 3×8 @ 90 s, within [S23]'s range of 1–6 Sets × 4–10 reps.
  - Primary 3×6 @ 180 s, within [S23]'s 2–6 Sets × 3–10 reps at >70% 1RM.
  - Single-leg 3×8 @ 120 s.
  - Calves 3×15 @ 60 s. The endurance-style dose [S3] is a design choice (**not documented** for runners specifically).
  - Core 3×10 @ 60 s, upper body 2×10 @ 90 s.

### 3.5 Cycling

- **Evidence: confirmed.**
  - Heavy strength training is recommended for cycling economy and has "the most compelling evidence" of an added effect on cycling performance [S28].
  - A 2026 review recommends 1–2 Sessions a week at 60–85% 1RM, 2–4 Sets of 3–5 compound lower-body Exercises, with little fatigue within each Set and 2–4 min Rest [S29]. Complementary Exercises: hip thrust, deadlift, calf raise, lunge/split squat [S29].
  - Use 2 Sessions a week while building, 1 in the competition phase. Same-day sessions should be ≥3 h apart [S29].
  - Core work is commonly prescribed, but it has not been shown to improve cycling performance [S29].
  - In highly trained cyclists, strength training helped when it *replaced* part of the endurance training, not when it was added on top. Two of the three positive trials included explosive Exercises [S30].
  - Strength training does not appear to harm cycling through unwanted hypertrophy when dosed this way [S29].
- **Muscle Groups to prioritise:** Quads, Glutes, Hamstrings, Calves, then Lower Back, Abs and Obliques. Upper body at maintenance level.
- **Patterns:** squat or leg press, hinge, single-leg (Step-up, Bulgarian Split Squat), hip thrust, calves, anti-extension/anti-rotation core, 1 push + 1 pull.
  - Single-leg work appears in trials (unilateral leg press, step-ups) but is not separately recommended [S29]. Its emphasis here is a design choice: pedalling is unilateral (**not documented**).
- **Defaults:** primary 3×6 @ 180 s (≈80% 1RM, leave 2–3 reps in reserve [S1, S29]), secondary 3×8 @ 120 s, accessories 2×12 @ 60 s, core 3×10 @ 60 s, upper body 2×10 @ 90 s. Power slot optional: Jump Squat 3×5 @ 150 s [S30].

### 3.6 Default Target per Training Goal and slot role

The single table the builder encodes. Sets × reps @ Rest. All values are derived from §1 and §3.1–3.5 (**not documented** as a set).

| Role | Overall Health | Bigger Arms | Athleticism | Running | Cycling |
|---|---|---|---|---|---|
| power | — | — | 3×5 @ 150 s | 3×8 @ 90 s | 3×5 @ 150 s (optional) |
| primary (main compound) | 3×10 @ 90 s | 3×8 @ 150 s | 3×6 @ 180 s | 3×6 @ 180 s | 3×6 @ 180 s |
| secondary (other compound) | 3×10 @ 90 s | 3×10 @ 120 s | 3×8 @ 120 s | 3×8 @ 120 s | 3×8 @ 120 s |
| upper (upper-body compound for Running/Cycling) | — | — | — | 2×10 @ 90 s | 2×10 @ 90 s |
| accessory (isolation) | 2×12 @ 60 s | 3×12 @ 90 s | 2×12 @ 60 s | 2×12 @ 60 s | 2×12 @ 60 s |
| calves | 2×12 @ 60 s | 2×12 @ 60 s | 3×12 @ 60 s | 3×15 @ 60 s | 2×12 @ 60 s |
| core | 2×12 @ 60 s | 2×12 @ 60 s | 3×10 @ 60 s | 3×10 @ 60 s | 3×10 @ 60 s |

**Bodyweight Exercises at 0 kg (not documented, derived from §1.3):** reps are their only lever. Use the role's reps, raised to at least:

- **8** for hard bodyweight Exercises: Pull-up, Chin-up, Dip, Pike Push-up, Nordic Hamstring Curl, Inverted Row, Plyometric Push-up, Hanging Leg Raise, Ab Wheel Rollout.
- **12** for the rest, e.g. Push-up, Bodyweight Squat, Split Squat, Single-Leg Glute Bridge, Single-Leg Calf Raise, Crunch.

If the user cannot reach the Target, the existing Step Down rule takes reps down at 0 kg (README §4).

### 3.7 How a Training Goal changes the base templates of §5

| Goal | Changes |
|---|---|
| Overall Health | Base templates. No power slot. Prefer Full Body Workouts. Include the core slot in every Rotation pass. |
| Bigger Arms | Push: add a 2nd triceps slot. Pull: add a 2nd biceps slot. Upper Body: arm slots become 2 Supersets (4 arm slots). Full Body: arm Superset required. Use the Arms Focus where the split table says so. |
| Athleticism | Lower Body / Legs / Full Body: insert a lower-body power slot first. Upper Body / Push: insert an upper-body power slot first. Keep single-leg and anti-rotation core required. |
| Running | Full Body only. Order: power (Pogo Jump or Jump Squat), primary lower, single-leg, hinge, 1 push + 1 pull (role "upper"), calves (required), core (anti-rotation preferred). Drop arm and chest/delt isolation. |
| Cycling | Full Body or Lower Body. Order: primary lower (squat/leg press), hinge, single-leg (Step-up first), Hip Thrust, calves, core, 1 push + 1 pull (role "upper"). Power slot optional. Drop arm isolation. |

---

## 4. Split table: Sessions per week → Rotation

**Base Rotations (frequency logic confirmed [S1, S9]; the specific splits are common coaching practice, unverified [U2]).**

The Rotation is independent of weekdays (README §5). Sessions per week sets the **number of Workouts** and how much volume each one carries. "A/B" Workouts share slots but pick the second- or third-ranked candidate in some slots, for variety. When the same Exercise lands in several generated Workouts, link those Planned Exercises by default (ADR-0006), so that they progress as one.

| Sessions/week | Overall Health | Bigger Arms | Athleticism | Running | Cycling |
|---|---|---|---|---|---|
| 2 | Full Body A, Full Body B | Full Body A, Full Body B (arm Superset in both) | Full Body A, Full Body B (power slot in both) | Full Body A, Full Body B | Full Body A, Full Body B |
| 3 | Full Body A, B, C | Full Body A, Full Body B, Arms | Full Body A, B, C | Full Body A, B, C | Full Body A, Full Body B (+ note) |
| 4 | Upper A, Lower A, Upper B, Lower B | Upper A, Lower A, Upper B, Lower B (4 arm slots per Upper) | Upper A, Lower A, Upper B, Lower B | Full Body A, B, C (+ note) | Full Body A, Full Body B (+ note) |
| 5 | Upper, Lower, Push, Pull, Legs | Upper, Lower, Push, Pull, Legs (2nd arm slot in Push and Pull) | Upper A, Lower A, Upper B, Lower B, Full Body | as 4 | as 4 |
| 6 | Push A, Pull A, Legs A, Push B, Pull B, Legs B | Push, Pull, Legs, Upper, Lower, Arms | Upper A, Lower A, Upper B, Lower B, Upper C, Lower C | as 4 | as 4 |

Rows 5 and 6 satisfy "each major Muscle Group ≥2× per pass": Upper+Push / Lower+Legs, and so on. Push/Pull/Legs with only 3 Sessions trains each muscle 1× a week, which falls below [S1, S9]. So 3 Sessions defaults to Full Body, and PPL is offered only as an alternative the user can pick.

**Running and Cycling modifier: confirmed basis, app wording derived.**

- Runners benefit from 2–3 strength Sessions a week [S23]. Cyclists: 1–2 Sessions a week (2 while building, 1 to maintain) [S29].
- Concurrent training keeps strength and hypertrophy but reduces explosive strength, more so when both are done in the same session [S31]. Adding strength training on top of full endurance training did not improve cycling performance [S30].
- So the builder recommends at most 3 strength Workouts for Running and 2 for Cycling, whatever the input. Because the Rotation ignores weekdays, Workout count cannot cap how often the user trains; it only shapes volume per Session. The note does the rest.
- It shows a neutral note: "Endurance athletes usually do 2–3 strength Sessions a week alongside their running/riding." Plan same-day sessions ≥3 h apart where possible [S29].
- The user can override this.

---

## 5. Template drafts per Focus

### 5.0 Conventions

- **Equipment Access tiers** (proposed; see §7). Column headers below say "Full gym", "Dumbbells & bench", "Bodyweight only" for short:
  - Full Gym = all six `Equipment` values.
  - Dumbbells & Bench = `dumbbell`, `kettlebell`, `bodyweight`. A kettlebell Exercise is done with one dumbbell; the Weight Step stays by equipment.
  - Bodyweight Only = `bodyweight`.
- **Selection rule:** walk the tier's column top to bottom and take the first Exercise not already used in this Workout. If the column is empty ("—"), drop the slot. If dropping leaves a required Muscle Group uncovered (§2.1), show it as a Gap rather than inventing an Exercise.
- **Needs** marks gear a bodyweight Exercise assumes: bar = pull-up bar, box, bench, bars = parallel bars, anchor = something to hook the feet under.
- **Role** maps to the Target via §3.6. "opt" marks a slot the builder may drop for time (§1.5). New Exercises are marked with **\***.
- Variants: **A** picks the first candidate, **B** the second (if any), **C** the third.

### 5.1 Push (5–6 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Horizontal push | primary | Bench Press, Dumbbell Bench Press, Machine Chest Press | Dumbbell Bench Press | Push-up, Decline Push-up\* |
| 2 | Vertical push | secondary | Overhead Press, Seated Dumbbell Shoulder Press | Seated Dumbbell Shoulder Press | Pike Push-up\* |
| 3 | Incline push | secondary | Incline Dumbbell Press, Incline Bench Press\* | Incline Dumbbell Press | Decline Push-up\* |
| 4 | Chest isolation (opt) | accessory | Cable Fly, Dumbbell Fly\* | Dumbbell Fly\* | — |
| 5 | Side Delts | accessory | Lateral Raise, Cable Lateral Raise\* | Lateral Raise | — |
| 6 | Triceps | accessory | Triceps Pushdown, Overhead Triceps Extension, Skull Crusher | Dumbbell Overhead Triceps Extension\*, Bench Dip\* | Dip (bars), Bench Dip\* (bench) |

Superset: 5 + 6 (non-competing). Bigger Arms adds a second triceps slot (6b): the next candidate in the same list.

### 5.2 Pull (5–6 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Vertical pull | primary | Lat Pulldown, Pull-up, Chin-up | Pull-up (bar), Dumbbell Pullover\* | Pull-up (bar), Chin-up (bar) |
| 2 | Horizontal pull | secondary | Seated Cable Row, Barbell Row, Chest-Supported Row | One-Arm Dumbbell Row, Chest-Supported Dumbbell Row\* | Inverted Row\* (bar or sturdy table) |
| 3 | Second row | secondary | Chest-Supported Row, One-Arm Dumbbell Row | Chest-Supported Dumbbell Row\* | Chin-up (bar) |
| 4 | Rear Delts | accessory | Face Pull, Rear Delt Fly | Dumbbell Rear Delt Fly\* | — |
| 5 | Biceps | accessory | Barbell Curl, Dumbbell Curl, Cable Curl\* | Dumbbell Curl, Incline Dumbbell Curl\* | — (Chin-up in 3 covers it) |
| 6 | Traps / Forearms (opt) | accessory | Dumbbell Shrug, Hammer Curl | Dumbbell Shrug, Hammer Curl | — |

Superset: 4 + 5. Lat Pulldown is ranked above Pull-up in Full gym because its load can be set to any level, while a 0 kg Pull-up may be out of reach for a beginner (**not documented**). Bigger Arms adds a second biceps slot (5b): Incline Dumbbell Curl or Hammer Curl.

### 5.3 Legs (5–6 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Squat | primary | Back Squat, Leg Press, Front Squat | Goblet Squat | Bodyweight Squat\* |
| 2 | Hinge | secondary | Romanian Deadlift, Deadlift | Dumbbell Romanian Deadlift\* | Single-Leg Glute Bridge\* |
| 3 | Single-leg | secondary | Bulgarian Split Squat, Walking Lunge, Step-up\* | Bulgarian Split Squat, Step-up\*, Walking Lunge | Split Squat\* |
| 4 | Quads isolation (opt) | accessory | Leg Extension | — | — |
| 5 | Hamstrings isolation | accessory | Leg Curl, Nordic Hamstring Curl\* | Single-Leg Romanian Deadlift\*, Nordic Hamstring Curl\* (anchor) | Nordic Hamstring Curl\* (anchor) |
| 6 | Calves | calves | Standing Calf Raise, Seated Calf Raise | Single-Leg Calf Raise\* | Single-Leg Calf Raise\* |
| 6b | Glutes / Adductors (opt) | accessory | Hip Thrust, Hip Adduction | Single-Leg Glute Bridge\*, Copenhagen Adduction\* (bench) | Copenhagen Adduction\* |

Supersets: 4 + 5, 6 + core (if present). Deadlift is placed here, not in Pull. Putting the hinge on Pull day is also common (**unverified**), but keeping it here gives the Legs Workout its posterior-chain work.

### 5.4 Upper Body (6–7 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Horizontal push | primary | Bench Press, Dumbbell Bench Press, Machine Chest Press | Dumbbell Bench Press | Push-up, Decline Push-up\* |
| 2 | Horizontal pull | primary | Barbell Row, Seated Cable Row, Chest-Supported Row | One-Arm Dumbbell Row, Chest-Supported Dumbbell Row\* | Inverted Row\* |
| 3 | Vertical push | secondary | Seated Dumbbell Shoulder Press, Overhead Press | Seated Dumbbell Shoulder Press | Pike Push-up\* |
| 4 | Vertical pull | secondary | Lat Pulldown, Pull-up, Chin-up | Pull-up (bar), Dumbbell Pullover\* | Pull-up (bar), Chin-up (bar) |
| 5 | Delts: A = Side Delts, B = Rear Delts | accessory | A: Lateral Raise, Cable Lateral Raise\*; B: Face Pull, Rear Delt Fly | A: Lateral Raise; B: Dumbbell Rear Delt Fly\* | — |
| 6 | Biceps | accessory | Dumbbell Curl, Cable Curl\*, Barbell Curl | Dumbbell Curl, Incline Dumbbell Curl\* | — |
| 7 | Triceps | accessory | Triceps Pushdown, Overhead Triceps Extension | Dumbbell Overhead Triceps Extension\* | Bench Dip\* (bench), Dip (bars) |

Supersets: 3 + 4 (antagonists; allowed because their Rest is <150 s, except under Athleticism) and 6 + 7. Bigger Arms: drop slot 5, add 6b/7b as a second arm Superset (Incline Dumbbell Curl + Skull Crusher or Dumbbell Overhead Triceps Extension\*), and run 3 + 4 as a Superset: 8 Exercises, 24 Sets, ~63 min (§1.5). Athleticism: slot 0 = upper-body power (Push Press\*, then Plyometric Push-up\*).

### 5.5 Lower Body (5–6 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 0 | Power (Athleticism, Running, Cycling opt) | power | Box Jump\* (box), Jump Squat\*, Kettlebell Swing; Running: Pogo Jump\*, Lateral Bound\* | Jump Squat\*, Kettlebell Swing, Lateral Bound\* | Jump Squat\*, Lateral Bound\*, Pogo Jump\* |
| 1 | Squat (A) / Hinge (B) | primary | A: Back Squat, Leg Press, Front Squat; B: Deadlift, Romanian Deadlift | A: Goblet Squat; B: Dumbbell Romanian Deadlift\* | A: Bodyweight Squat\*; B: Single-Leg Glute Bridge\* |
| 2 | Hinge (A) / Squat (B) | secondary | A: Romanian Deadlift; B: Leg Press, Front Squat | A: Dumbbell Romanian Deadlift\*; B: Goblet Squat | A: Nordic Hamstring Curl\* (anchor); B: Bodyweight Squat\* |
| 3 | Single-leg | secondary | Bulgarian Split Squat, Step-up\*, Walking Lunge | Bulgarian Split Squat, Step-up\*, Single-Leg Romanian Deadlift\* | Split Squat\* |
| 4 | Hamstrings / Glutes | accessory | Leg Curl, Hip Thrust | Single-Leg Romanian Deadlift\*, Single-Leg Glute Bridge\* | Single-Leg Glute Bridge\* |
| 5 | Calves | calves | Standing Calf Raise, Seated Calf Raise | Single-Leg Calf Raise\* | Single-Leg Calf Raise\* |
| 6 | Core: anti-extension (A) / anti-rotation (B) | core | A: Ab Wheel Rollout, Hanging Leg Raise; B: Pallof Press\*, Cable Woodchop\* | A: Ab Wheel Rollout, Dead Bug\*; B: Bird Dog\*, Dumbbell Side Bend\* | A: Dead Bug\*; B: Bird Dog\* |

Superset: 5 + 6.

### 5.6 Full Body (5–7 Exercises; variants A/B/C rotate the emphasis)

| # | Slot | Role | A | B | C |
|---|---|---|---|---|---|
| 0 | Power (Athleticism, Running; Cycling opt) | power | Box Jump\* / Jump Squat\* | Kettlebell Swing / Lateral Bound\* | Jump Squat\*; Running: Pogo Jump\* |
| 1 | Lower primary | primary | **Squat** (Legs #1 list) | **Hinge**: Deadlift, Romanian Deadlift / Dumbbell Romanian Deadlift\* / Single-Leg Glute Bridge\* | **Single-leg**: Bulgarian Split Squat / Step-up\* / Split Squat\* |
| 2 | Upper push | secondary | Horizontal (Push #1 list) | Vertical (Push #2 list) | Incline (Push #3 list) |
| 3 | Upper pull | secondary | Horizontal (Pull #2 list) | Vertical (Pull #1 list) | Horizontal, 2nd candidate (Pull #3 list) |
| 4 | Lower secondary | secondary | Hinge: Romanian Deadlift / Dumbbell Romanian Deadlift\* / Nordic Hamstring Curl\* | Single-leg (Legs #3 list) | Squat: Leg Press / Goblet Squat / Bodyweight Squat\* |
| 5 | Arms / delts (opt; required for Bigger Arms) | accessory | Biceps + Triceps Superset (Upper #6 + #7) | Side Delts (Upper #5A) | Rear Delts (Upper #5B) |
| 6 | Calves (opt; required for Running) | calves | Legs #6 list | Legs #6 list | Legs #6 list |
| 7 | Core | core | Anti-extension (Lower #6A) | Anti-rotation (Lower #6B) | Flexion: Cable Crunch / Crunch\* / Hanging Leg Raise |

Supersets: 2 + 3 (antagonists) and 6 + 7. Running/Cycling: slots 2 and 3 use role "upper" (2×10 @ 90 s). Slot 5 is dropped, except under Bigger Arms.

### 5.7 Arms (4–6 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Triceps compound | secondary | Close-Grip Bench Press\*, Dip | Bench Dip\* | Dip (bars), Bench Dip\* |
| 2 | Biceps compound | secondary | Chin-up, Barbell Curl | Chin-up (bar), Dumbbell Curl | Chin-up (bar) |
| 3 | Biceps, lengthened | accessory | Incline Dumbbell Curl\*, Cable Curl\* | Incline Dumbbell Curl\* | — |
| 4 | Triceps, overhead | accessory | Overhead Triceps Extension, Skull Crusher | Dumbbell Overhead Triceps Extension\* | — |
| 5 | Forearms / brachialis | accessory | Hammer Curl, Reverse Curl\*, Wrist Curl\* | Hammer Curl, Wrist Curl\* | — |
| 6 | Side Delts (opt) | accessory | Lateral Raise, Cable Lateral Raise\* | Lateral Raise | — |

Supersets: 3 + 4, then 5 + 6. Slots 1 and 2 stay as straight Sets.

The bodyweight-only Arms Workout has just 2 Exercises, so the builder should **not offer the Arms Focus for Bodyweight Only**. It falls back to Upper Body (**not documented**).

"Lengthened" and "overhead" are chosen for variety. Some trials suggest larger gains when muscles are trained at long lengths, but no source was read for that here: **unverified**.

### 5.8 Core (4–5 Exercises)

| # | Slot | Role | Full gym | Dumbbells & bench | Bodyweight only |
|---|---|---|---|---|---|
| 1 | Flexion | core | Hanging Leg Raise, Cable Crunch | Crunch\*, Hanging Leg Raise (bar) | Hanging Leg Raise (bar), Crunch\* |
| 2 | Anti-extension | core | Ab Wheel Rollout, Dead Bug\* | Ab Wheel Rollout, Dead Bug\* | Dead Bug\* |
| 3 | Anti-rotation | core | Pallof Press\*, Bird Dog\* | Bird Dog\* | Bird Dog\* |
| 4 | Obliques | core | Cable Woodchop\*, Dumbbell Side Bend\* | Dumbbell Side Bend\*, Bicycle Crunch\* | Bicycle Crunch\* |
| 5 | Lower Back (opt) | core | Back Extension | Back Extension (bench) | Bird Dog\* (if not in 3) |

Core Focus Targets: 3×12 @ 45 s, except the hard ones (Ab Wheel Rollout, Hanging Leg Raise) at 3×8 (§3.6 floor rule). The Workout is short (~20–25 min); recommend it as an add-on Workout or let the user put it in the Rotation. The builder never recommends a Core Workout by itself: every template above already includes a core slot.

Timed holds (plank, side plank, hollow hold) are excluded per README §1. Anti-extension and anti-rotation are covered by rep-based Exercises (Dead Bug, Bird Dog, Pallof Press).

### 5.9 Bigger Arms weekly check (derived example)

The 4-Session Upper A / Lower A / Upper B / Lower B Rotation, Full gym, counted fractionally:

- Direct work per Upper: 2 biceps slots × 3 Sets = 6 Biceps Sets; 2 triceps slots × 3 = 6 Triceps Sets.
- Indirect work per Upper, assuming Biceps is a Secondary Muscle Group of Lat Pulldown and Triceps of the presses (§5.11): Lat Pulldown 3 × 0.5 = 1.5 for Biceps (Seated Cable Row and Barbell Row carry no Biceps tag today); Bench Press and Seated Dumbbell Shoulder Press 6 × 0.5 = 3 for Triceps.
- Per Rotation pass (2 Uppers): **Biceps ≈ 15, Triceps ≈ 18.** That is inside the ≥10 range and near the ~18–20 diminishing-returns point [S1]. With only 1 arm Superset per Upper it drops to ≈ 9 / 12, so Bigger Arms keeps 2.

### 5.10 New Exercises (39). The catalog grows from 44 to 83.

All are rep-based. Tags use the 18-value list, split into Muscle Groups (prime movers) and Secondary Muscle Groups (count half, ADR-0007). The Weight Step follows equipment per README §3. Each new catalog Exercise also needs a built-in Strava exercise type (README §12); that mapping is out of scope here.

| # | Key | Name | Equipment | Muscle Groups | Secondary | Used in | Notes |
|---|---|---|---|---|---|---|---|
| 1 | incline-bench-press | Incline Bench Press | barbell | Chest, Front Delts | Triceps | Push | |
| 2 | decline-push-up | Decline Push-up | bodyweight | Chest, Front Delts | Triceps | Push, Upper | feet elevated |
| 3 | pike-push-up | Pike Push-up | bodyweight | Front Delts | Triceps | Push, Upper | |
| 4 | dumbbell-fly | Dumbbell Fly | dumbbell | Chest | Front Delts | Push | bench |
| 5 | cable-lateral-raise | Cable Lateral Raise | cable | Side Delts | — | Push, Upper, Arms | unilateral |
| 6 | dumbbell-overhead-triceps-extension | Dumbbell Overhead Triceps Extension | dumbbell | Triceps | — | Push, Upper, Arms | |
| 7 | close-grip-bench-press | Close-Grip Bench Press | barbell | Triceps, Chest | Front Delts | Arms | |
| 8 | bench-dip | Bench Dip | bodyweight | Triceps | Chest, Front Delts | Push, Upper, Arms | bench or chair |
| 9 | dumbbell-pullover | Dumbbell Pullover | dumbbell | Lats, Chest | Triceps | Pull, Upper | vertical-pull stand-in without a bar |
| 10 | chest-supported-dumbbell-row | Chest-Supported Dumbbell Row | dumbbell | Upper Back, Lats | Rear Delts, Biceps | Pull, Upper | incline bench |
| 11 | inverted-row | Inverted Row | bodyweight | Upper Back, Lats | Biceps, Rear Delts | Pull, Upper | bar or sturdy table |
| 12 | dumbbell-rear-delt-fly | Dumbbell Rear Delt Fly | dumbbell | Rear Delts | Upper Back | Pull, Upper | |
| 13 | incline-dumbbell-curl | Incline Dumbbell Curl | dumbbell | Biceps | — | Pull, Upper, Arms | |
| 14 | cable-curl | Cable Curl | cable | Biceps | Forearms | Pull, Upper, Arms | |
| 15 | reverse-curl | Reverse Curl | barbell | Forearms, Biceps | — | Arms | |
| 16 | wrist-curl | Wrist Curl | dumbbell | Forearms | — | Arms | |
| 17 | bodyweight-squat | Bodyweight Squat | bodyweight | Quads, Glutes | Adductors | Legs, Lower, Full | |
| 18 | dumbbell-romanian-deadlift | Dumbbell Romanian Deadlift | dumbbell | Hamstrings, Glutes | Lower Back | Legs, Lower, Full | |
| 19 | single-leg-romanian-deadlift | Single-Leg Romanian Deadlift | dumbbell | Hamstrings, Glutes | Lower Back | Legs, Lower, Running | unilateral |
| 20 | step-up | Step-up | dumbbell | Quads, Glutes | Hamstrings | Legs, Lower, Running, Cycling | unilateral; box/bench |
| 21 | split-squat | Split Squat | bodyweight | Quads, Glutes | Adductors | Legs, Lower, Full | unilateral |
| 22 | single-leg-glute-bridge | Single-Leg Glute Bridge | bodyweight | Glutes | Hamstrings | Legs, Lower, Full | unilateral; floor |
| 23 | nordic-hamstring-curl | Nordic Hamstring Curl | bodyweight | Hamstrings | — | Legs, Lower | anchor; hard (8-rep floor) |
| 24 | copenhagen-adduction | Copenhagen Adduction | bodyweight | Adductors | Obliques | Legs (opt), Athleticism, Running | unilateral; bench; the *dynamic* rep version, not the hold |
| 25 | single-leg-calf-raise | Single-Leg Calf Raise | bodyweight | Calves | — | Legs, Lower, Full, Running | unilateral; dumbbell in hand = Added Weight |
| 26 | kettlebell-swing | Kettlebell Swing | kettlebell | Glutes, Hamstrings | Lower Back | power slot | ballistic hinge |
| 27 | box-jump | Box Jump | bodyweight | Quads, Glutes | Calves | power slot | box; step down |
| 28 | jump-squat | Jump Squat | bodyweight | Quads, Glutes | Calves | power slot | 0 kg [S34] |
| 29 | lateral-bound | Lateral Bound | bodyweight | Glutes, Quads | Adductors, Calves | power slot | reps per side |
| 30 | pogo-jump | Pogo Jump | bodyweight | Calves | — | Running power | stiff-ankle hops |
| 31 | plyometric-push-up | Plyometric Push-up | bodyweight | Chest | Triceps, Front Delts | Athleticism upper power | |
| 32 | push-press | Push Press | barbell | Front Delts | Triceps, Quads | Athleticism upper power | leg-drive press |
| 33 | crunch | Crunch | bodyweight | Abs | — | Core, Full | |
| 34 | bicycle-crunch | Bicycle Crunch | bodyweight | Abs, Obliques | — | Core | reps per side |
| 35 | dead-bug | Dead Bug | bodyweight | Abs | — | Core, Lower, Full | reps per side |
| 36 | bird-dog | Bird Dog | bodyweight | Lower Back, Glutes | Abs | Core, Lower, Full | reps per side |
| 37 | pallof-press | Pallof Press | cable | Obliques, Abs | — | Core, Lower, Full | reps per side |
| 38 | cable-woodchop | Cable Woodchop | cable | Obliques | Abs | Core | reps per side |
| 39 | dumbbell-side-bend | Dumbbell Side Bend | dumbbell | Obliques | — | Core, Lower | reps per side |

Medicine-ball throws (chest pass, rotational throw, slam) are the textbook rep-based power drills for Athleticism, but `Equipment` has no medicine-ball case. If the owner adds `medicineBall`, add **Medicine Ball Chest Pass** (Chest, Triceps) and **Rotational Medicine Ball Throw** (Obliques, Abs); the catalog then reaches 85. Without that change the catalog is **44 + 39 = 83**.

Considered and left out to stay near 80: Machine Fly, Machine Shoulder Press, Barbell Shrug, Diamond Push-up, Reverse Crunch, Broad Jump, Glute Bridge, Preacher Curl. Each duplicates a listed Exercise's slot. Power Clean was left out because the technique is too demanding for a builder that also serves beginners (**not documented**; ACSM lists Olympic-style lifting as effective for power [S1]).

### 5.11 Muscle Group remap of existing catalog Exercises (Shoulders → Front/Side/Rear Delts, plus Secondary)

A proposal for the rows that carry Shoulders today. ADR-0007's catalog revision decides the final tags; this table only shows what the templates assume.

| Key | Muscle Groups | Secondary Muscle Groups |
|---|---|---|
| barbell-bench-press | Chest | Triceps, Front Delts |
| incline-dumbbell-press | Chest, Front Delts | Triceps |
| overhead-press | Front Delts | Triceps, Side Delts |
| seated-dumbbell-press | Front Delts | Side Delts, Triceps |
| lateral-raise | Side Delts | — |
| rear-delt-fly | Rear Delts | Upper Back |
| face-pull | Rear Delts, Upper Back | — |
| dip | Chest, Triceps | Front Delts |
| lat-pulldown (no Shoulders tag; for §5.9) | Lats | Biceps |

---

## 6. Safety and wording

- **Not medical advice.** A Recommendation is a starting point. It does not diagnose, treat, or claim injury prevention.
  - Copy should use words like "recommended", "a common starting point", "you can change anything" (not "suggested": Suggestion is reserved for Step Up and Step Down). It should avoid "prescribed", "optimal", "guaranteed", "prevents", "clinically proven".
  - README §1 excludes AI coaching and generated text. Rule-based, fixed copy fits that. Apple's review rules for health and medical claims were not re-checked for this note (**not documented** here).
- **Claims the app must not make:**
  - **"Prevents running injuries."** Not supported for runners [S25]. Acceptable: "Strength training is commonly recommended for runners and can improve running economy" [S23, S24].
  - **"Burns fat" / body-composition promises.** Not researched here.
  - **Any statement about health conditions.**
- **Screening line, shown once in the builder.** ACSM's screening rests on current activity, known cardiovascular, metabolic or renal disease or symptoms, and the intended intensity [S36]. Suggested copy: "If you have a health condition or symptoms, are pregnant, or haven't been active for a long time, check with a healthcare professional before starting." The exact screening algorithm is in the full paper, which was not read; the wording is a conservative paraphrase (**unverified** in its details).
- **Safety in general:** "Resistance training is safe for healthy adults of all ages" [S1]. Most of the evidence comes from inexperienced trainees, so the defaults suit beginners [S1].
- **Effort cue for the first Session:** "Pick a weight you could lift for about 2–3 more reps than the Target." This follows the 2–3 reps-in-reserve advice; failure is not needed [S1]. It also lets the first Step Up arrive quickly, which is motivating.
- **Beginners:**
  - Start with Full Body at 2–3 Sessions a week [S3].
  - Equipment type (machines vs free weights) made no consistent difference to outcomes [S1, S2]. Candidate order in §5 is therefore a design choice about ease of learning and loading (**not documented**); for example, Lat Pulldown ranks above Pull-up.
  - Plyometrics: start with low volume, step down from the box rather than jumping down (**unverified**, coaching convention). Athleticism and Running templates keep jumps at ≤24 contacts per Exercise [S1].
- **Older adults:** WHO adds balance-focused multicomponent activity on ≥3 days a week for those 65+ [S4]. NSCA has a dedicated position statement [S35]; its prescription details were not read. The builder can point to this with a neutral line; it should not adapt Targets by age without that research.
- **Power Exercises and Step Ups:** a rep Step Up on Jump Squat (3×8 → 3×9 …) pushes reps × Sets past the ≤24 power range [S1]. See §7.

---

## 7. Open decisions for the owner

1. **Pull-up bar in Bodyweight Only.** Without one, Pull, Upper Body and Full Body lose all vertical pulling and Inverted Row, so Lats/Biceps coverage collapses. Options: (a) assume a doorway bar, (b) ask "Do you have a pull-up bar?" as a fourth equipment answer, (c) accept it and show it as a Gap.
2. **Kettlebell Exercises in Dumbbells & Bench.** Goblet Squat and Kettlebell Swing are kettlebell in the catalog, and both work with one dumbbell. If they are excluded, the D&B squat slot has no candidate except Bulgarian Split Squat.
3. **Unilateral reps.** The catalog already has One-Arm Dumbbell Row, Bulgarian Split Squat and Walking Lunge, and 14 new Exercises are unilateral or counted per side. The app needs a rule ("reps are per side") and probably an `isUnilateral` flag. The flag would also feed the Session-length estimate (§1.5).
4. **Step Up for power Exercises.** Power has a volume ceiling [S1]. Options: offer only weight Step Ups for Kettlebell Swing and Push Press, and no rep Step Ups above 8 for jumps. The alternative is to treat jumps as "maintenance" Planned Exercises with Step Ups off.
5. **Medicine ball.** Add `medicineBall` to `Equipment` (2 extra Exercises), or keep Athleticism to jumps, swings and Push Press.
6. **Glossary.** Add a term for the template slot to CONTEXT.md. Do not use "slot", which is listed as an avoided synonym for Planned Exercise.
7. **Muscle Group tags for the remap and new Exercises.** §5.10–§5.11 propose Muscle Groups and Secondary Muscle Groups. ADR-0007's catalog revision is the source of truth; where it already decides a tag, it wins.

---

## Sources

Primary (guidelines and position stands):

- **S1** Currier BS, D'Souza AC, Fiatarone Singh MA, … Phillips SM. ACSM Position Stand: Resistance Training Prescription for Muscle Function, Hypertrophy, and Physical Performance in Healthy Adults: An Overview of Reviews. *Med Sci Sports Exerc* 2026;58(4):851–872. doi:10.1249/MSS.0000000000003897, PMID 41843416: <https://pmc.ncbi.nlm.nih.gov/articles/PMC12965823/>
- **S2** ACSM, "5 Things to Know About Creating an Effective Resistance Training Plan" (infographic for S1), 2026: <https://acsm.org/wp-content/uploads/2026/03/Resistance-Training-Position-Stand-infographic.pdf>, and the summary page <https://acsm.org/resistance-training-guidelines-update-2026/>
- **S3** ACSM Position Stand: Progression Models in Resistance Training for Healthy Adults. *Med Sci Sports Exerc* 2009;41(3):687–708. PMID 19204579 (abstract via Europe PMC): <https://europepmc.org/article/MED/19204579>
- **S4** Bull FC et al. World Health Organization 2020 guidelines on physical activity and sedentary behaviour. *Br J Sports Med* 2020;54(24):1451–1462. PMID 33239350: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7719906/>
- **S5** US HHS / ODPHP, Physical Activity Guidelines for Americans (2nd ed.), "Top 10 Things to Know": <https://odphp.health.gov/our-work/nutrition-physical-activity/physical-activity-guidelines/current-guidelines/top-10-things-know>
- **S6** Piercy KL et al. The Physical Activity Guidelines for Americans. *JAMA* 2018;320(19):2020–2028. PMID 30418471: <https://europepmc.org/article/MED/30418471>
- **S7** UK Department of Health and Social Care, "New physical activity guidelines issued by UK Chief Medical Officers", 2019-09-07: <https://www.gov.uk/government/news/new-physical-activity-guidelines-issued-by-uk-chief-medical-officers>
- **S35** Fragala MS et al. Resistance Training for Older Adults: Position Statement From the NSCA. *J Strength Cond Res* 2019;33(8):2019–2052. PMID 31343601: <https://europepmc.org/article/MED/31343601>
- **S36** Riebe D et al. Updating ACSM's Recommendations for Exercise Preparticipation Health Screening. *Med Sci Sports Exerc* 2015;47(11):2473–2479. PMID 26473759: <https://europepmc.org/article/MED/26473759>

Primary (systematic reviews, meta-analyses, trials):

- **S8** Schoenfeld BJ, Ogborn D, Krieger JW. Dose-response relationship between weekly resistance training volume and increases in muscle mass. *J Sports Sci* 2017;35(11):1073–1082. PMID 27433992: <https://europepmc.org/article/MED/27433992>
- **S9** Schoenfeld BJ, Ogborn D, Krieger JW. Effects of Resistance Training Frequency on Measures of Muscle Hypertrophy. *Sports Med* 2016;46(11):1689–1697. PMID 27102172: <https://europepmc.org/article/MED/27102172>
- **S10** Schoenfeld BJ, Grgic J, Krieger J. How many times per week should a muscle be trained to maximize muscle hypertrophy? *J Sports Sci* 2019;37(11):1286–1295. PMID 30558493: <https://europepmc.org/article/MED/30558493>
- **S11** Pelland JC, Remmert JF, Robinson ZP, et al. The Resistance Training Dose Response: Meta-Regressions Exploring the Effects of Weekly Volume and Frequency on Muscle Hypertrophy and Strength Gains. *Sports Med* 2026;56(2):481–505. PMID 41343037: <https://europepmc.org/article/MED/41343037>. Preprint: <https://sportrxiv.org/index.php/server/preprint/view/460>
- **S12** Currier BS, Mcleod JC, Banfield L, et al. Resistance training prescription for muscle strength and hypertrophy in healthy adults: a systematic review and Bayesian network meta-analysis. *Br J Sports Med* 2023;57(18):1211–1220. PMID 37414459: <https://europepmc.org/article/MED/37414459>
- **S13** Schoenfeld BJ, Grgic J, Ogborn D, et al. Strength and Hypertrophy Adaptations Between Low- vs. High-Load Resistance Training. *J Strength Cond Res* 2017;31(12):3508–3523. PMID 28834797: <https://europepmc.org/article/MED/28834797>
- **S14** Schoenfeld BJ, Grgic J, Van Every DW, Plotkin DL. Loading Recommendations for Muscle Strength, Hypertrophy, and Local Endurance: A Re-Examination of the Repetition Continuum. *Sports* 2021;9(2):32: <https://pmc.ncbi.nlm.nih.gov/articles/PMC7927075/>
- **S15** Singer A, …, Schoenfeld BJ. Give it a rest: a systematic review with Bayesian meta-analysis on the effect of inter-set rest interval duration on muscle hypertrophy. *Front Sports Act Living* 2024;6:1429789. PMID 39205815: <https://www.frontiersin.org/articles/10.3389/fspor.2024.1429789/full>
- **S16** Grgic J, et al. Effects of Rest Interval Duration in Resistance Training on Measures of Muscular Strength: A Systematic Review. *Sports Med* 2018;48(1):137–151. PMID 28933024: <https://europepmc.org/article/MED/28933024>
- **S17** Schoenfeld BJ, Pope ZK, Benik FM, et al. Longer Interset Rest Periods Enhance Muscle Strength and Hypertrophy in Resistance-Trained Men. *J Strength Cond Res* 2016;30(7):1805–1812. PMID 26605807: <https://europepmc.org/article/MED/26605807>
- **S18** Nunes JP, Grgic J, Cunha PM, et al. What influence does resistance exercise order have on muscular strength gains and muscle hypertrophy? *Eur J Sport Sci* 2021;21(2):149–157. PMID 32077380: <https://europepmc.org/article/MED/32077380>
- **S19** Zhang X, Weakley J, Li H, et al. Superset Versus Traditional Resistance Training Prescriptions: A Systematic Review and Meta-analysis. *Sports Med* 2025;55(4):953–975. PMID 39903375: <https://europepmc.org/article/MED/39903375>
- **S20** Robbins DW, Young WB, Behm DG. Agonist-antagonist paired set resistance training: a brief review. *J Strength Cond Res* 2010;24(10):2873–2882. PMID 20733520: <https://europepmc.org/article/MED/20733520>
- **S21** Mannarino P, et al. Single-Joint Exercise Results in Higher Hypertrophy of Elbow Flexors Than Multijoint Exercise. *J Strength Cond Res* 2021;35(10):2677–2681. PMID 31268995: <https://europepmc.org/article/MED/31268995>
- **S22** Gentil P, Soares SR, Pereira MC, et al. Effect of adding single-joint exercises to a multi-joint exercise resistance-training program on strength and hypertrophy in untrained subjects. *Appl Physiol Nutr Metab* 2013;38(3):341–344. PMID 23537028: <https://europepmc.org/article/MED/23537028>
- **S23** Blagrove RC, Howatson G, Hayes PR. Effects of Strength Training on the Physiological Determinants of Middle- and Long-Distance Running Performance: A Systematic Review. *Sports Med* 2018;48(5):1117–1149: <https://pmc.ncbi.nlm.nih.gov/articles/PMC5889786/>
- **S24** Llanos-Lagos C, Ramirez-Campillo R, Moran J, Sáez de Villarreal E. Effect of Strength Training Programs in Middle- and Long-Distance Runners' Economy at Different Running Speeds. *Sports Med* 2024;54(4):895–932. PMID 38165636: <https://europepmc.org/article/MED/38165636>
- **S25** Wu H, Brooke-Wavell K, Fong DTP, et al. Do Exercise-Based Prevention Programs Reduce Injury in Endurance Runners? A Systematic Review and Meta-Analysis. *Sports Med* 2024;54(5):1249–1267. PMID 38261240: <https://europepmc.org/article/MED/38261240>
- **S26** Lauersen JB, Bertelsen DM, Andersen LB. The effectiveness of exercise interventions to prevent sports injuries: a systematic review and meta-analysis of randomised controlled trials. *Br J Sports Med* 2014;48(11):871–877. PMID 24100287: <https://europepmc.org/article/MED/24100287>
- **S27** Lauersen JB, et al. Strength training as superior, dose-dependent and safe prevention of acute and overuse sports injuries. *Br J Sports Med* 2018;52(24):1557–1563. PMID 30131332: <https://europepmc.org/article/MED/30131332>
- **S28** Rønnestad BR, Mujika I. Optimizing strength training for running and cycling endurance performance: A review. *Scand J Med Sci Sports* 2014;24(4):603–612. PMID 23914932: <https://europepmc.org/article/MED/23914932>
- **S29** de Pablos R, Sánchez-Redondo IR, Alejo LB, et al. Resistance Training for Cyclists: Scientific Evidence and Practical Recommendations. *Scand J Med Sci Sports* 2026;36(10):e70377. PMID 42828469: <https://pmc.ncbi.nlm.nih.gov/articles/PMC13633594/>
- **S30** Yamamoto LM, Klau JF, Casa DJ, et al. The effects of resistance training on road cycling performance among highly trained cyclists: a systematic review. *J Strength Cond Res* 2010;24(2):560–566. PMID 20072042: <https://europepmc.org/article/MED/20072042>
- **S31** Schumann M, Feuerbacher JF, Sünkeler M, et al. Compatibility of Concurrent Aerobic and Strength Training for Skeletal Muscle Size and Function: An Updated Systematic Review and Meta-Analysis. *Sports Med* 2022;52(3):601–612. PMID 34757594: <https://europepmc.org/article/MED/34757594>
- **S32** Seitz LB, et al. Increases in lower-body strength transfer positively to sprint performance: a systematic review with meta-analysis. *Sports Med* 2014;44(12):1693–1702. PMID 25059334: <https://europepmc.org/article/MED/25059334>
- **S33** Suchomel TJ, et al. The Importance of Muscular Strength in Athletic Performance. *Sports Med* 2016;46(10):1419–1449. PMID 26838985: <https://europepmc.org/article/MED/26838985>
- **S34** de Villarreal ES, et al. Determining variables of plyometric training for improving vertical jump height performance: a meta-analysis. *J Strength Cond Res* 2009;23(2):495–506. PMID 19197203: <https://europepmc.org/article/MED/19197203>
- **S37** Robinson ZP, Pelland JC, Remmert JF, et al. Exploring the Dose–Response Relationship Between Estimated Resistance Training Proximity to Failure, Strength Gain, and Muscle Hypertrophy. *Sports Med* 2024;54(9):2209–2231. PMID 38970765: <https://europepmc.org/article/MED/38970765>

Secondary (unverified):

- **U1** RP-style volume landmarks (biceps MEV ≈ 6, MAV ≈ 10–16 Sets a week), arvo.guru summary of Renaissance Periodization: <https://arvo.guru/resources/methods/rp-training>
- **U2** Split conventions (full body for 2–3 days, upper/lower for 4, PPL for 5–6), Built With Science: <https://builtwithscience.com/workouts/best-workout-split/>
- **U3** US guidance "1 Set of 8–12 reps; 2–3 Sets may be more effective; legs, hips, back, abdomen, chest, shoulders, arms", as quoted from the HHS guidelines by Lumen Learning (the primary 2018 PDF exceeded the fetch limit): <https://med.libretexts.org/Courses/Lumen_Learning/Book%3A_Disease_Prevention_and_Healthy_Lifestyles_(Lumen)/04%3A_2-_Physical_Activity/4.01%3A_Physical_Activity_Guidelines_for_Adults>

[S1]: https://pmc.ncbi.nlm.nih.gov/articles/PMC12965823/
[S2]: https://acsm.org/resistance-training-guidelines-update-2026/
[S3]: https://europepmc.org/article/MED/19204579
[S4]: https://pmc.ncbi.nlm.nih.gov/articles/PMC7719906/
[S5]: https://odphp.health.gov/our-work/nutrition-physical-activity/physical-activity-guidelines/current-guidelines/top-10-things-know
[S6]: https://europepmc.org/article/MED/30418471
[S7]: https://www.gov.uk/government/news/new-physical-activity-guidelines-issued-by-uk-chief-medical-officers
[S8]: https://europepmc.org/article/MED/27433992
[S9]: https://europepmc.org/article/MED/27102172
[S10]: https://europepmc.org/article/MED/30558493
[S11]: https://europepmc.org/article/MED/41343037
[S12]: https://europepmc.org/article/MED/37414459
[S13]: https://europepmc.org/article/MED/28834797
[S14]: https://pmc.ncbi.nlm.nih.gov/articles/PMC7927075/
[S15]: https://www.frontiersin.org/articles/10.3389/fspor.2024.1429789/full
[S16]: https://europepmc.org/article/MED/28933024
[S17]: https://europepmc.org/article/MED/26605807
[S18]: https://europepmc.org/article/MED/32077380
[S19]: https://europepmc.org/article/MED/39903375
[S20]: https://europepmc.org/article/MED/20733520
[S21]: https://europepmc.org/article/MED/31268995
[S22]: https://europepmc.org/article/MED/23537028
[S23]: https://pmc.ncbi.nlm.nih.gov/articles/PMC5889786/
[S24]: https://europepmc.org/article/MED/38165636
[S25]: https://europepmc.org/article/MED/38261240
[S26]: https://europepmc.org/article/MED/24100287
[S27]: https://europepmc.org/article/MED/30131332
[S28]: https://europepmc.org/article/MED/23914932
[S29]: https://pmc.ncbi.nlm.nih.gov/articles/PMC13633594/
[S30]: https://europepmc.org/article/MED/20072042
[S31]: https://europepmc.org/article/MED/34757594
[S32]: https://europepmc.org/article/MED/25059334
[S33]: https://europepmc.org/article/MED/26838985
[S34]: https://europepmc.org/article/MED/19197203
[S35]: https://europepmc.org/article/MED/31343601
[S36]: https://europepmc.org/article/MED/26473759
[S37]: https://europepmc.org/article/MED/38970765
[U1]: https://arvo.guru/resources/methods/rp-training
[U2]: https://builtwithscience.com/workouts/best-workout-split/
[U3]: https://med.libretexts.org/Courses/Lumen_Learning/Book%3A_Disease_Prevention_and_Healthy_Lifestyles_(Lumen)/04%3A_2-_Physical_Activity/4.01%3A_Physical_Activity_Guidelines_for_Adults
