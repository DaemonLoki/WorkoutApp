# Exercise muscle data and catalog expansion

Researched 2026-10-09. This covers the split of Shoulders into three delt heads, the new Secondary Muscle Groups, and the Exercise Catalog's growth from 44 to 80 Exercises. Sources are listed at the end, and each `[S…]`/`[P…]` label links to its URL. Each claim carries one of three labels:

- **confirmed**: a peer-reviewed EMG, muscle-force or hypertrophy study (PubMed abstract read), ExRx.net (a well-known reference; labelled as such), ACE or NSCA material.
- **unverified**: no primary source found; the mapping comes from mechanics or from a closely related exercise.
- **not documented**: the question isn't answered anywhere I could find.

ExRx.net refuses automated requests (HTTP 403), so every ExRx page was read from its Internet Archive copy (2023–2025 snapshots). The URLs at the end point to the live pages.

## Summary

1. **Re-mapping rule.** Every `.shoulders` maps to delt heads by the movement: presses → **Front Delts** (overhead presses also get **Side Delts**), lateral raises → **Side Delts**, reverse flies and Face Pull → **Rear Delts**. Seven catalog Exercises carry `shoulders` today. Each one's mapping is in §2.1.
2. **Corrections to today's primaries.** I propose 9 changes, all moving a synergist from primary to secondary, plus one reorder (§2.2):
   - Bench Press, Dumbbell Bench Press, Machine Chest Press, Push-up: Triceps → secondary. Bench pressing alone did not grow the triceps significantly [P4], and ExRx lists the triceps as a synergist [S1].
   - Overhead Press, Seated Dumbbell Shoulder Press: Triceps → secondary, and Side Delts become primary. Medial-delt EMG in the shoulder press (27.9% MVIC) is close to the lateral raise's (30.3%) [P1].
   - Pull-up, Lat Pulldown: Biceps → secondary. ExRx: Target lats, biceps a synergist [S8, S10]. Chin-up keeps Biceps primary: its biceps EMG is significantly higher [P6].
   - Rear Delt Fly: Upper Back → secondary [S21].
   - Deadlift: same three primaries, reordered to put Glutes first (ExRx Target) [S16].
3. **36 new Exercises** (§4), for 80 in total. All are rep-based, with no holds, carries or cardio. **Every one has an exact Strava type, so none needs `null`.** One type is a compromise: Copenhagen Adduction → `LL_COPENHAGEN_PLANK`, which Strava files under "Plank" (§4.2).
4. **Uncovered cells in the catalog** (§5; not the glossary's *Gap*, which is per Workout):
   - Bodyweight-only has no primary option for **Side Delts, Traps or Forearms**. No credible rep-based bodyweight exercise exists for any of them. Pike Push-up gives Side Delts secondary only, and Pull-up and Chin-up do the same for Forearms.
   - Thin spots: **Lower Back** (1 option at each lighter tier, Back Extension, which needs a bench), **Calves** and **Adductors** at the Dumbbells & bench tier.
   - "Bodyweight" Exercises often need a fixture: a bar, dip station, bench, box or foot anchor. §5 lists them.
5. **Custom Exercise migration** (§6): map `shoulders` → **Front Delts + Side Delts**, and Front Delts alone where that would exceed 3 primaries. Keep `shoulders` legal in the Supabase check constraint during the transition. Do the rewrite on the iPhone, bumping `updatedAt`, so it syncs like any edit.

---

## 1. Conventions used in this document

### 1.1 Primary vs secondary

The README calls primary Muscle Groups "prime movers, 1–3". I made that operational with ExRx's classification, plus studies where they exist:

- **Primary** = ExRx's **Target**, plus any muscle with direct evidence of comparable activation or growth. Example: Side Delts in the overhead press [P1].
- **Secondary** (0–3) = ExRx **Synergists** that get a meaningful share of the work. ExRx **Stabilizers** and **Dynamic Stabilizers** are left out (e.g. erector spinae in a squat, hamstrings in a squat), unless a study shows a training effect. Example: Adductors in squats, which grew with squat training [P13] and carry high adductor-magnus forces [P11].
- **One judgement call against ExRx:** Deadlift keeps **Lower Back** as a primary. ExRx lists the erector spinae only as a stabilizer for the conventional deadlift [S16], but as a synergist for the straight-leg deadlift [S32]. Escamilla measured substantial L3/T12 paraspinal activity [P10]. A lifter who filters "Lower Back" expects the Deadlift.

### 1.2 Which anatomical muscles each Muscle Group means

This is a **proposed convention**. **Not documented** in README or CONTEXT; record it with the `domain-modeling` skill if accepted.

| Muscle Group | Anatomical muscles |
|---|---|
| Traps | upper trapezius (shrug, upright row) |
| Upper Back | rhomboids, middle/lower trapezius, teres major/minor, infraspinatus |
| Lats | latissimus dorsi |
| Lower Back | erector spinae, quadratus lumborum |
| Front / Side / Rear Delts | anterior / lateral (medial) / posterior deltoid |
| Biceps | biceps brachii and brachialis |
| Forearms | brachioradialis, wrist flexors and extensors |
| Glutes | gluteus maximus, medius, minimus |
| Adductors | adductor magnus/longus/brevis, gracilis, pectineus |
| Calves | gastrocnemius, soleus |

- Hip flexors and the rotator cuff have no Muscle Group. Hanging Leg Raise therefore stays on **Abs**, although ExRx's Target is the iliopsoas [S41].
- The upright row's ExRx list has middle trapezius as a synergist and upper trapezius as a stabilizer [S48]. I still give it **Traps** primary, because McAllister found grip width strongly changes upper-trapezius activity [P20]. That is the muscle a lifter feels.

### 1.3 Equipment tiers

- **Full gym** = every equipment value.
- **Dumbbells & bench** = `dumbbell`, `kettlebell` and `bodyweight`. Kettlebell entries are counted here because each catalog kettlebell movement (Goblet Squat, Kettlebell Swing) is commonly done with one dumbbell. This is a proposal for the owner.
- **Bodyweight only** = `bodyweight`.

Today's tier filter can only key off `equipment`. Many `bodyweight` Exercises need a fixture: a bar, dip station, bench, box or anchor. See §5.2.

---

## 2. Shoulders → delt heads, and corrections

### 2.1 Re-mapping rule for `.shoulders`

| Movement pattern | `.shoulders` becomes | Evidence |
|---|---|---|
| Horizontal or incline press (bench, incline, push-up, dip) | Front Delts | **confirmed**: ExRx lists the anterior deltoid, not lateral/posterior, as the synergist [S1, S2]. In the bench press, medial delt is 5% and posterior delt 3.5% MVIC vs 21.4% anterior [P1]. Incline raises anterior-delt activity over flat [P2, P3]. |
| Overhead press (barbell, dumbbell, pike) | Front Delts **+ Side Delts** | **confirmed**: ExRx Target anterior deltoid, synergist lateral deltoid [S18, S19]. Shoulder press: anterior 33.3%, medial 27.9% MVIC; lateral raise medial 30.3% [P1]. |
| Lateral raise (dumbbell, cable), upright row | Side Delts | **confirmed**: ExRx Target lateral deltoid [S20, S47, S48]. Highest medial-delt EMG in neutral-rotation lateral raises [P12]. |
| Reverse fly, face pull, rear-delt row | Rear Delts | **confirmed**: ExRx Target posterior deltoid [S15, S21, S49]. |

Applied to the seven catalog Exercises tagged `shoulders` today:

| Exercise | Today | Proposed |
|---|---|---|
| Bench Press | Chest, Triceps, Shoulders | primary Chest; secondary Front Delts, Triceps |
| Incline Dumbbell Press | Chest, Shoulders | primary Chest, Front Delts; secondary Triceps |
| Face Pull | Shoulders, Upper Back | primary Rear Delts, Upper Back; secondary Side Delts |
| Overhead Press | Shoulders, Triceps | primary Front Delts, Side Delts; secondary Triceps |
| Seated Dumbbell Shoulder Press | Shoulders, Triceps | primary Front Delts, Side Delts; secondary Triceps |
| Lateral Raise | Shoulders | primary Side Delts; secondary Front Delts, Traps |
| Rear Delt Fly | Shoulders, Upper Back | primary Rear Delts; secondary Upper Back |

Front Delts stay **primary on the incline press**, but **secondary on the flat bench**. Anterior-delt EMG rises significantly from 0° to 28–56° of incline [P2]. ExRx's incline Target is the clavicular pectoralis, with the anterior deltoid a synergist [S43, S2]. The flat bench's anterior delt is only ~21% MVIC [P1]. Making Front Delts primary on the incline is a judgement; secondary would also be defensible.

### 2.2 Corrections to today's primaries (flagged)

**1. Bench Press, Dumbbell Bench Press, Machine Chest Press, Push-up: Triceps → secondary.**
- ExRx: Target pectoralis major (sternal); synergists anterior deltoid and triceps [S1, S3, S4, S6]. **confirmed** (well-known reference).
- Brandão et al. 2020: 43 men trained 8 weeks. The bench-press-only group's total triceps CSA did **not** increase significantly; only the lateral head grew. The group doing a triceps isolation exercise did increase it [P4]. **confirmed**.
- Narrow-grip and narrow-hand variants shift work to the triceps [P5, P19]. Close-Grip Bench Press and Diamond Push-up therefore carry **Triceps primary** (§4).

**2. Dip: no change** (Chest, Triceps). The catalog's Dip is uploaded to Strava as `CHEST_DIP`, and ExRx's chest dip lists Target pec, synergist triceps [S7]. Keeping Triceps primary is a usability choice: the dip is the main bodyweight triceps builder. **unverified** as a prime-mover claim.

**3. Overhead Press, Seated Dumbbell Shoulder Press: Triceps → secondary; Side Delts → primary.**
- ExRx Target anterior deltoid. Synergists include the lateral deltoid and triceps [S18, S19]. **confirmed** (well-known reference).
- Campos et al. 2020: medial-delt activity in the shoulder press (27.9% MVIC) is statistically similar to the lateral raise (30.3%) [P1]. **confirmed**.

**4. Pull-up, Lat Pulldown: Biceps → secondary.**
- ExRx: Target latissimus dorsi. Synergists are brachialis, brachioradialis, biceps, teres major, posterior delt, rhomboids, middle/lower trapezius [S8, S10]. **confirmed** (well-known reference).
- Youdas et al. 2010: lats 117–130% MVIC vs biceps 78–96%. Biceps were significantly more active in the chin-up than the pull-up [P6]. **confirmed**.
- Lat-pulldown grip changes did not significantly alter lat or biceps activation [P7].
- **Chin-up keeps Biceps primary** on the supinated-grip evidence [P6]. That gives the Bodyweight-only tier a primary Biceps option.

**5. Rear Delt Fly: Upper Back → secondary.** ExRx's seated rear-delt fly: Target posterior deltoid; synergists infraspinatus, teres minor, middle/lower trapezius, rhomboids [S21]. **confirmed** (well-known reference).

**6. Deadlift: reorder only** (Glutes, Hamstrings, Lower Back).
- ExRx: Target gluteus maximus; synergists quadriceps, adductor magnus, hamstrings (top half) [S16]. **confirmed**.
- Escamilla et al. 2002 measured high quadriceps, hamstring, hip adductor, gluteus maximus, paraspinal and trapezius activity [P10].
- Deadlift and sumo deadlift reach tier 1 adductor-magnus forces [P11].
- Lower Back stays primary (see §1.1). Quads, Adductors and Traps are secondary.

**7. Considered, no change.**
- **Face Pull**: owner's guess is confirmed. Rear Delts + Upper Back [S15, P9].
- **Front Squat**: stays Quads only. ExRx files the barbell front squat under gluteus maximus [S30], but its dumbbell front squat page targets the quadriceps [S65]. The upright torso is the usual reason for quad emphasis; **unverified**.
- **Hammer Curl**: ExRx's Target is the brachioradialis, so Forearms is legitimately primary [S25].
- **Ab Wheel Rollout**: keeps Abs + Obliques. External-oblique activity was among the highest of all exercises tested [P18].

---

## 3. The 44 existing Exercises

"Today" is `ExerciseCatalog.swift` as of commit `7779879`. Strava types are unchanged from `ExerciseCatalog+Strava.swift`. A row is **confirmed** when its Sources cell names an ExRx page (well-known reference) or a study. The secondary picks are judgements within ExRx's synergist list; §1.1 gives the rule.

| Key | Name | Equipment | Today | Proposed primary | Proposed secondary | Strava type | Change | Sources |
|---|---|---|---|---|---|---|---|---|
| `barbell-bench-press` | Bench Press | barbell | Chest, Triceps, **Shoulders** | Chest | Front Delts, Triceps | `BARBELL_BENCH_PRESS` | Triceps, Shoulders → secondary | S1, P1, P3, P4 |
| `incline-dumbbell-press` | Incline Dumbbell Press | dumbbell | Chest, **Shoulders** | Chest, Front Delts | Triceps | `INCLINE_DUMBBELL_BENCH_PRESS` | Shoulders → Front Delts | S2, P2, P3 |
| `dumbbell-bench-press` | Dumbbell Bench Press | dumbbell | Chest, Triceps | Chest | Front Delts, Triceps | `DUMBBELL_BENCH_PRESS` | Triceps → secondary | S3, P1, P4 |
| `machine-chest-press` | Machine Chest Press | machine | Chest, Triceps | Chest | Front Delts, Triceps | `MACHINE_CHEST_PRESS` | Triceps → secondary | S4, P3 |
| `cable-fly` | Cable Fly | cable | Chest | Chest | Front Delts | `CABLE_CROSSOVER` | — | S5, P1 |
| `push-up` | Push-up | bodyweight | Chest, Triceps | Chest | Front Delts, Triceps | `PUSH_UP_GENERIC` | Triceps → secondary | S6, P5 |
| `dip` | Dip | bodyweight | Chest, Triceps | Chest, Triceps | Front Delts | `CHEST_DIP` | — | S7 |
| `pull-up` | Pull-up | bodyweight | Lats, Biceps | Lats | Biceps, Upper Back, Forearms | `PULL_UP_GENERIC` | Biceps → secondary | S8, P6 |
| `chin-up` | Chin-up | bodyweight | Lats, Biceps | Lats, Biceps | Upper Back, Forearms | `CLOSE_GRIP_CHIN_UP` | — | S9, P6 |
| `lat-pulldown` | Lat Pulldown | cable | Lats, Biceps | Lats | Biceps, Upper Back | `LAT_PULLDOWN` | Biceps → secondary | S10, P7 |
| `seated-cable-row` | Seated Cable Row | cable | Upper Back, Lats | Upper Back, Lats | Biceps, Rear Delts | `SEATED_CABLE_ROW` | — | S11 |
| `barbell-row` | Barbell Row | barbell | Upper Back, Lats | Upper Back, Lats | Rear Delts, Biceps, Lower Back | `BENT_OVER_BARBELL_ROW` | — | S12, P8 |
| `one-arm-dumbbell-row` | One-Arm Dumbbell Row | dumbbell | Lats, Upper Back | Lats, Upper Back | Biceps, Rear Delts | `DUMBBELL_ROW` | — | S13 |
| `chest-supported-row` | Chest-Supported Row | machine | Upper Back | Upper Back | Lats, Rear Delts, Biceps | `MACHINE_CHEST_SUPPORTED_ROW` | — | S14 |
| `face-pull` | Face Pull | cable | **Shoulders**, Upper Back | Rear Delts, Upper Back | Side Delts | `FACE_PULL` | Shoulders → Rear Delts | S15, P9 |
| `deadlift` | Deadlift | barbell | Hamstrings, Glutes, Lower Back | Glutes, Hamstrings, Lower Back | Quads, Adductors, Traps | `BARBELL_DEADLIFT` | order only (Glutes first, per ExRx Target) | S16, P10, P11 |
| `back-extension` | Back Extension | bodyweight | Lower Back, Glutes | Lower Back, Glutes | Hamstrings | `BACK_EXTENSION` | — | S17 |
| `overhead-press` | Overhead Press | barbell | **Shoulders**, Triceps | Front Delts, Side Delts | Triceps | `OVERHEAD_BARBELL_PRESS` | Shoulders → Front + Side Delts; Triceps → secondary | S18, P1 |
| `seated-dumbbell-press` | Seated Dumbbell Shoulder Press | dumbbell | **Shoulders**, Triceps | Front Delts, Side Delts | Triceps | `SEATED_DUMBBELL_SHOULDER_PRESS` | Shoulders → Front + Side Delts; Triceps → secondary | S19, P1 |
| `lateral-raise` | Lateral Raise | dumbbell | **Shoulders** | Side Delts | Front Delts, Traps | `LATERAL_RAISE_GENERIC` | Shoulders → Side Delts | S20, P1, P12 |
| `rear-delt-fly` | Rear Delt Fly | machine | **Shoulders**, Upper Back | Rear Delts | Upper Back | `MACHINE_REAR_DELT_REVERSE_FLY` | Shoulders → Rear Delts; Upper Back → secondary | S21 |
| `dumbbell-shrug` | Dumbbell Shrug | dumbbell | Traps | Traps | — | `DUMBBELL_SHRUG` | — | S22, P9 |
| `barbell-curl` | Barbell Curl | barbell | Biceps | Biceps | Forearms | `BARBELL_BICEPS_CURL` | — | S23 |
| `dumbbell-curl` | Dumbbell Curl | dumbbell | Biceps | Biceps | Forearms | `STANDING_DUMBBELL_BICEPS_CURL` | — | S24 |
| `hammer-curl` | Hammer Curl | dumbbell | Biceps, Forearms | Biceps, Forearms | — | `DUMBBELL_HAMMER_CURL` | — | S25 |
| `triceps-pushdown` | Triceps Pushdown | cable | Triceps | Triceps | — | `CABLE_TRICEPS_PUSHDOWN` | — | S26 |
| `overhead-triceps-extension` | Overhead Triceps Extension | cable | Triceps | Triceps | — | `CABLE_OVERHEAD_TRICEPS_EXTENSION` | — | S55, P4 |
| `skull-crusher` | Skull Crusher | barbell | Triceps | Triceps | — | `SKULL_CRUSHER` | — | S28 |
| `back-squat` | Back Squat | barbell | Quads, Glutes | Quads, Glutes | Adductors | `BARBELL_BACK_SQUAT` | — | S29, P13, P11 |
| `front-squat` | Front Squat | barbell | Quads | Quads | Glutes, Adductors | `BARBELL_FRONT_SQUAT` | — | S30, P11 |
| `goblet-squat` | Goblet Squat | kettlebell | Quads, Glutes | Quads, Glutes | Adductors | `GOBLET_SQUAT` | — | S65, P13 |
| `leg-press` | Leg Press | machine | Quads, Glutes | Quads, Glutes | Adductors | `MACHINE_LEG_PRESS` | — | S31 |
| `romanian-deadlift` | Romanian Deadlift | barbell | Hamstrings, Glutes | Hamstrings, Glutes | Lower Back, Adductors | `BARBELL_ROMANIAN_DEADLIFT` | — | S32, P14, P15 |
| `bulgarian-split-squat` | Bulgarian Split Squat | dumbbell | Quads, Glutes | Quads, Glutes | Adductors | `DUMBBELL_BULGARIAN_SPLIT_SQUATS` | — | S33, P16 |
| `walking-lunge` | Walking Lunge | dumbbell | Quads, Glutes | Quads, Glutes | Adductors | `DUMBBELL_WALKING_LUNGES` | — | S34 |
| `leg-extension` | Leg Extension | machine | Quads | Quads | — | `MACHINE_LEG_EXTENSION` | — | S35 |
| `leg-curl` | Leg Curl | machine | Hamstrings | Hamstrings | — | `LEG_CURL_GENERIC` | — | S36, P14 |
| `hip-thrust` | Hip Thrust | barbell | Glutes | Glutes | Hamstrings, Quads | `BARBELL_HIP_THRUST` | — | S37, P17 |
| `hip-adduction` | Hip Adduction | machine | Adductors | Adductors | — | `MACHINE_HIP_ADDUCTION` | — | S38 |
| `standing-calf-raise` | Standing Calf Raise | machine | Calves | Calves | — | `STANDING_CALF_RAISE` | — | S39 |
| `seated-calf-raise` | Seated Calf Raise | machine | Calves | Calves | — | `SEATED_CALF_RAISE` | — | S40 |
| `hanging-leg-raise` | Hanging Leg Raise | bodyweight | Abs | Abs | Obliques | `HANGING_LEG_RAISE` | — | S41, P18 |
| `cable-crunch` | Cable Crunch | cable | Abs | Abs | Obliques | `CABLE_CRUNCH` | — | S42 |
| `ab-wheel-rollout` | Ab Wheel Rollout | bodyweight | Abs, Obliques | Abs, Obliques | Lats | `AB_WHEEL_ROLLOUT` | — | P18 |

Notes on secondaries:

- **Squats, leg press, lunges → Adductors.** Ten weeks of full squats grew the adductors (+6.2%) and gluteus maximus (+6.7%), but not the hamstrings or rectus femoris [P13]. Squat and step-up are tier 1 for adductor-magnus force [P11]. **confirmed**. Hamstrings are therefore *not* a secondary for squats, although ExRx lists them as dynamic stabilizers [S29].
- **Hip Thrust → Hamstrings, Quads.** Mean vastus-lateralis EMG was ~100% MVIC in both hip thrust and back squat, and biceps femoris was 40.8% vs 14.9% [P17]. **confirmed**.
- **Pull-up / Chin-up → Forearms.** The brachioradialis is an ExRx synergist [S8, S9]. **confirmed** (well-known reference).
- **Lateral Raise → Front Delts, Traps.**
  - Anterior delt is a synergist and upper trapezius a stabilizer in ExRx [S20].
  - Upper-trap EMG rises with internal rotation [P12].
  - Posterior-delt EMG (24% MVIC) was actually higher than anterior (21.2%) in Campos's lateral raise [P1]. Adding **Rear Delts** as a third secondary would be equally defensible.
- **Leg Curl:** no secondary. ExRx lists gastrocnemius as a synergist [S36]. Calves could be added; I left them out as not a "felt" muscle.
- **Dumbbell Shrug:** no secondary. ExRx synergists are middle trapezius and levator scapulae [S22], which are already Traps / Upper Back.

---

## 4. 36 new Exercises

Keys follow the existing style: kebab-case, equipment prefix only where another variant exists. Names use US gym naming. Every Strava type below was checked by script against the 656 values in `StravaExerciseGroup+All.swift`.

**Goals / Focus** abbreviations: Push, Pull, Legs, Upper Body, Lower Body, Full Body, Arms, Core are Focus types. Overall Health, Bigger Arms, Athleticism, Running, Cycling are Training Goals. The tier named is the lightest one the Exercise works at.

| # | Key | Name | Equipment | Primary | Secondary | Strava type | Serves (Training Goal, Focus, lightest tier) | Sources |
|---|---|---|---|---|---|---|---|---|
| 1 | `incline-bench-press` | Incline Bench Press | barbell | Chest, Front Delts | Triceps | `INCLINE_BARBELL_BENCH_PRESS` | Push, Upper Body; Overall Health; Full gym | S43, P2, P3 |
| 2 | `pec-deck` | Pec Deck | machine | Chest | Front Delts | `PEC_DECK_BUTTERFLY` | Push, Upper Body; Full gym | S44, P1 |
| 3 | `close-grip-bench-press` | Close-Grip Bench Press | barbell | Triceps, Chest | Front Delts | `CLOSE_GRIP_BARBELL_BENCH_PRESS` | Bigger Arms; Push, Arms; Full gym | S45, P4, P19 |
| 4 | `diamond-push-up` | Diamond Push-up | bodyweight | Triceps, Chest | Front Delts | `DIAMOND_PUSH_UP` | Bigger Arms; Push, Arms; all tiers | S46, P5 |
| 5 | `pike-push-up` | Pike Push-up | bodyweight | Front Delts | Triceps, Side Delts | `PIKE_PUSH_UP` | Push, Upper Body; all tiers | U1 |
| 6 | `cable-lateral-raise` | Cable Lateral Raise | cable | Side Delts | Front Delts, Traps | `CABLE_LATERAL_RAISE` | Push, Upper Body; Full gym | S47, P12 |
| 7 | `upright-row` | Upright Row | barbell | Side Delts, Traps | Front Delts, Biceps | `BARBELL_UPRIGHT_ROW` | Push/Pull, Upper Body; Full gym | S48, P20 |
| 8 | `dumbbell-rear-delt-fly` | Dumbbell Rear Delt Fly | dumbbell | Rear Delts | Upper Back, Side Delts | `DUMBBELL_REAR_DELT_FLY` | Pull, Upper Body; Dumbbells & bench | S49 |
| 9 | `prone-t-raise` | Prone T Raise | bodyweight | Rear Delts, Upper Back | — | `FLOOR_T_RAISE` | Pull, Upper Body; all tiers | P9 |
| 10 | `inverted-row` | Inverted Row | bodyweight | Upper Back, Lats | Rear Delts, Biceps | `INVERTED_ROW` | Pull, Upper Body, Full Body; Overall Health; all tiers | S50, P8 |
| 11 | `straight-arm-pulldown` | Straight-Arm Pulldown | cable | Lats | Triceps, Rear Delts | `STRAIGHT_ARM_PULLDOWN` | Pull; Full gym | S51 |
| 12 | `dumbbell-pullover` | Dumbbell Pullover | dumbbell | Chest, Lats | Triceps | `DUMBBELL_PULLOVER` | Push/Pull, Upper Body; Dumbbells & bench | S52, P21 |
| 13 | `preacher-curl` | Preacher Curl | barbell | Biceps | Forearms | `EZ_BAR_PREACHER_CURL` | Bigger Arms; Arms, Pull; Full gym | U2 |
| 14 | `incline-dumbbell-curl` | Incline Dumbbell Curl | dumbbell | Biceps | Forearms | `INCLINE_DUMBBELL_BICEPS_CURL` | Bigger Arms; Arms, Pull; Dumbbells & bench | S53 |
| 15 | `cable-curl` | Cable Curl | cable | Biceps | Forearms | `CABLE_BICEPS_CURL` | Bigger Arms; Arms, Pull; Full gym | S54 |
| 16 | `dumbbell-overhead-triceps-extension` | Dumbbell Overhead Triceps Extension | dumbbell | Triceps | — | `OVERHEAD_DUMBBELL_TRICEPS_EXTENSION` | Bigger Arms; Arms, Push; Dumbbells & bench | S55, P4 |
| 17 | `wrist-curl` | Wrist Curl | dumbbell | Forearms | — | `DUMBBELL_WRIST_CURL` | Bigger Arms; Arms; Dumbbells & bench | S56 |
| 18 | `hack-squat` | Hack Squat | machine | Quads, Glutes | Adductors | `MACHINE_HACK_SQUAT` | Legs, Lower Body; Cycling; Full gym | S57, P13 |
| 19 | `good-morning` | Good Morning | barbell | Hamstrings, Glutes | Lower Back, Adductors | `BARBELL_GOOD_MORNING` | Legs, Lower Body; Athleticism; Full gym | S58, P14 |
| 20 | `dumbbell-romanian-deadlift` | Dumbbell Romanian Deadlift | dumbbell | Hamstrings, Glutes | Lower Back, Adductors | `DUMBBELL_ROMANIAN_DEADLIFTS` | Legs, Lower Body, Full Body; Overall Health, Running; Dumbbells & bench | S32, P14 |
| 21 | `single-leg-romanian-deadlift` | Single-Leg Romanian Deadlift | dumbbell | Hamstrings, Glutes | Adductors, Lower Back | `SINGLE_LEG_DUMBBELL_ROMANIAN_DEADLIFTS` | Legs, Lower Body; Running, Athleticism; Dumbbells & bench | S59 |
| 22 | `nordic-curl` | Nordic Curl | bodyweight | Hamstrings | — | `NORDIC_CURL` | Legs, Lower Body; Running, Athleticism; all tiers | P15, P22 |
| 23 | `glute-bridge` | Glute Bridge | bodyweight | Glutes | Hamstrings | `GLUTE_BRIDGE` | Legs, Lower Body; Overall Health, Running, Cycling; all tiers | S37, P17 |
| 24 | `hip-abduction` | Hip Abduction | machine | Glutes | — | `MACHINE_HIP_ABDUCTION` | Legs, Lower Body; Running; Full gym | S60 |
| 25 | `step-up` | Step-up | dumbbell | Quads, Glutes | Adductors, Hamstrings | `STEP_UP` | Legs, Lower Body, Full Body; Running, Cycling, Athleticism, Overall Health; Dumbbells & bench | S61, P11, P16 |
| 26 | `lateral-lunge` | Lateral Lunge | dumbbell | Quads, Glutes, Adductors | — | `LATERAL_LUNGE` | Legs, Lower Body; Athleticism, Running; Dumbbells & bench | U3 |
| 27 | `reverse-lunge` | Reverse Lunge | bodyweight | Quads, Glutes | Adductors | `REVERSE_LUNGE` | Legs, Lower Body, Full Body; Overall Health, Running, Cycling; all tiers | S62 |
| 28 | `copenhagen-adduction` | Copenhagen Adduction | bodyweight | Adductors | Obliques | `LL_COPENHAGEN_PLANK` | Legs, Lower Body, Core; Running, Athleticism; all tiers | P11, P23 |
| 29 | `single-leg-calf-raise` | Single-Leg Calf Raise | bodyweight | Calves | — | `SINGLE_LEG_STANDING_CALF_RAISE` | Legs, Lower Body; Running, Cycling; all tiers | S63 |
| 30 | `box-jump` | Box Jump | bodyweight | Quads, Glutes | Calves | `BOX_JUMP` | Legs, Full Body; Athleticism; all tiers (needs a box) | P24, U4 |
| 31 | `jump-squat` | Jump Squat | bodyweight | Quads, Glutes | Calves | `BODY_WEIGHT_JUMP_SQUAT` | Legs, Full Body; Athleticism, Running; all tiers | P24 |
| 32 | `kettlebell-swing` | Kettlebell Swing | kettlebell | Glutes, Hamstrings | Lower Back | `KETTLEBELL_SWING` | Full Body, Lower Body; Athleticism, Overall Health; Dumbbells & bench (with a kettlebell) | P25 |
| 33 | `power-clean` | Power Clean | barbell | Glutes, Quads, Hamstrings | Traps, Calves | `BARBELL_POWER_CLEAN` | Full Body; Athleticism; Full gym | N1, N2 |
| 34 | `pallof-press` | Pallof Press | cable | Obliques | Abs | `PALLOF_PRESS` | Core; Overall Health, Running, Athleticism; Full gym | U5 |
| 35 | `dumbbell-side-bend` | Dumbbell Side Bend | dumbbell | Obliques | Lower Back | `DUMBBELL_SIDE_BEND` | Core; Dumbbells & bench | S64 |
| 36 | `bicycle-crunch` | Bicycle Crunch | bodyweight | Abs, Obliques | — | `BICYCLE_CRUNCH` | Core; Overall Health; all tiers | A1 |

### 4.1 Evidence notes for the new Exercises

- **Incline Bench Press**: clavicular-pec and anterior-delt EMG rise with incline [P2]. The clavicular head is most active at 45° [P3]. **confirmed**.
- **Pec Deck**: ExRx Target pec (sternal); no anterior-deltoid synergist [S44]. Front Delts secondary rests on dumbbell-fly anterior-delt activity of 18.8% MVIC, similar to the bench press's 21.4% [P1]. **confirmed** for the fly; the pec deck was not tested.
- **Close-Grip Bench Press / Diamond Push-up**:
  - ExRx Target triceps for both [S45, S46].
  - Narrower grip → more triceps [P19].
  - Narrow-base push-ups raised triceps *and* pec EMG over wide-base [P5].
  - **confirmed**.
- **Pike Push-up**: **unverified**. No EMG study of the pike push-up was found [U1]. Front Delts primary with Triceps and Side Delts secondary is by analogy with the overhead press [S18, P1]. Strava has `PIKE_PUSH_UP`.
- **Cable Lateral Raise / Upright Row**:
  - ExRx Target lateral deltoid for both [S47, S48].
  - Upright row: wider grip → more deltoid and trapezius, less biceps [P20]. US gyms commonly use a wide-ish grip, so Biceps stays secondary only.
  - **confirmed**.
- **Dumbbell Rear Delt Fly**: ExRx bent-over rear lateral raise. Target posterior deltoid; synergists include the lateral deltoid and middle/lower trapezius [S49]. **confirmed**.
- **Prone T Raise** (lying face down, arms out to the sides, thumbs up, lift and lower):
  - Shoulder horizontal extension with external rotation, done prone, produced the greatest middle-trapezius EMG of 10 exercises [P9]. **confirmed** for the middle trapezius (Upper Back).
  - Rear-delt involvement follows from the movement (horizontal abduction is the posterior delt's main action [S49]).
  - It is the only rep-based bodyweight Rear Delt option. It is low-load: progress is by reps or a light plate, as Added Weight.
- **Inverted Row**: highest lat, upper-back and hip-extensor activation of three rows, with the lowest spine load [P8]. ExRx (supine row) lists the same synergists as rows [S50]. **confirmed**.
- **Straight-Arm Pulldown**: **confirmed by proxy**. The ExRx straight-arm pulldown page is missing from the archive. The ExRx cable bent-over pullover (same shoulder-extension movement) has Target lats; synergists pec (sternal), triceps long head, teres major, posterior deltoid [S51].
- **Dumbbell Pullover**: primary **Chest + Lats**, deliberately both.
  - ExRx Target pectoralis major (sternal), lats a synergist [S52].
  - A 2026 narrative review of lat EMG concludes the pullover "appeared to preferentially activate the pectoralis major rather than selectively target the LD" [P21].
  - Owner's call whether Lats should be secondary only.
- **Preacher Curl**: **unverified** [U2]. The ExRx preacher-curl page wasn't retrievable. Mapping copied from ExRx barbell/cable curl (Target biceps; synergists brachialis, brachioradialis) [S23, S54]. Strava `EZ_BAR_PREACHER_CURL` assumes the common EZ-bar version under equipment `barbell`. If the owner prefers the machine version, use `PREACHER_CURL_MACHINE` with equipment `machine`.
- **Incline Dumbbell Curl / Cable Curl / Wrist Curl / Dumbbell Overhead Triceps Extension**: ExRx [S53, S54, S56, S55]. Overhead (single-joint) triceps work grew the long head more than bench pressing [P4]. **confirmed**.
- **Hack Squat**: ExRx sled hack squat. Target gluteus maximus; synergists quadriceps, adductor magnus [S57].
  - I list **Quads first**. The hack squat is commonly treated as quad-dominant, but that is **unverified**: ExRx files it under both the quadriceps and gluteus maximus lists.
- **Good Morning**: ExRx Target hamstrings; synergists gluteus maximus, adductor magnus; erector spinae a stabilizer [S58]. Hamstring EMG during the good morning was below the RDL and glute-ham raise [P14]. **confirmed**.
- **Dumbbell RDL / Single-Leg RDL**:
  - ExRx straight-back straight-leg deadlift: Target hamstrings [S32].
  - Single-leg stiff-leg deadlift: Target gluteus maximus (supporting leg); synergists hamstrings, adductor magnus [S59].
  - The RDL maximised hamstring activity among four exercises [P14]. Stiff-leg deadlift training selectively grew the semimembranosus [P15].
  - **confirmed**.
  - Single-Leg RDL is `dumbbell` but works without load. It could also be filed `bodyweight` for the Bodyweight tier (§5.2).
- **Nordic Curl**: 9 weeks grew the semitendinosus by 24% [P15, P22]. **confirmed**. Rep-based. Progression is mostly by reps and range of motion, not weight, which fits fixed-Target Step Ups by reps.
- **Glute Bridge / Hip Abduction**:
  - Glute Bridge: ExRx's hip thrust profile [S37] and the hip-thrust EMG [P17] are the closest evidence. **unverified** for the floor bridge specifically.
  - Hip Abduction: ExRx Target hip abductors = gluteus medius, minimus, maximus [S60]. **confirmed**. It maps to Glutes as the owner decided.
- **Step-up / Reverse Lunge / Lateral Lunge**:
  - Step-up and reverse lunge: ExRx Target gluteus maximus; synergists quadriceps, adductor magnus [S61, S62]. **confirmed**.
  - Step-up gluteus-max, vasti and biceps-femoris forces scale with load more than in the squat [P16], so step-up gets Hamstrings secondary.
  - Lateral Lunge: **unverified** [U3]. No ExRx page or study was retrieved. Quads, Glutes and Adductors are all primary because the frontal-plane lunge loads the adductors eccentrically.
- **Copenhagen Adduction**:
  - Tier 1 (highest) force for every adductor muscle among 8 exercises (long-lever version) [P11]. **confirmed**.
  - A single-exercise Copenhagen programme cut groin-problem risk by 41% [P23]. **confirmed**.
  - It is performed as raise-and-lower reps of the top leg in the side-plank position, not as a hold. That is the sense used in [P23], but the abstract doesn't state reps, so **unverified** from what I read.
  - See §4.2 for its Strava type.
- **Single-Leg Calf Raise**: ExRx Target gastrocnemius; synergist soleus [S63]. Added Weight = a dumbbell in the free hand. **confirmed**.
- **Box Jump / Jump Squat**:
  - In ballistic squat jumps, the gluteus maximus, vastus lateralis, soleus, rectus femoris, gastrocnemius and semitendinosus all fire in sequence, and the pattern is unaffected by load [P24]. **confirmed** for the jump squat.
  - Box jump: by analogy; **unverified** [U4].
  - Caveat: a box jump's progression is box height, which the app doesn't record. With a fixed Target its Step Ups can only add reps.
- **Kettlebell Swing**: ~80% MVC for the gluteals and ~50% for the low-back extensors with a 16 kg bell [P25]. **confirmed**. Hamstrings primary is **unverified**: they were not reported in that abstract, though they are the other hip extensor.
- **Power Clean**: the NSCA describes triple extension of hip, knee and ankle [N1]. The NSCA textbook excerpt lists the gluteus maximus, hamstrings, quadriceps, soleus, gastrocnemius, deltoids and trapezius [N2]. **confirmed**. It is technique-heavy, so it may suit the Athleticism goal only.
- **Pallof Press**: **unverified** [U5]. One methodology study recorded oblique and erector activity during anti-rotation and rotation Pallof variants; I read only its listing. The press-out is done for reps, so it qualifies as rep-based.
- **Dumbbell Side Bend**: ExRx Target obliques; synergists quadratus lumborum, iliocostalis [S64]. **confirmed**.
- **Bicycle Crunch**: ACE/San Diego State study (2001, ACE-sponsored, n=30, normalised to a crunch). The bicycle maneuver was #1 for rectus abdominis and #2 for obliques [A1]. **confirmed**, sponsor caveat noted.

### 4.2 Strava types: decisions and caveats

- **All 36 have a type**; none needs `null`.
- **Copenhagen Adduction → `LL_COPENHAGEN_PLANK`**. Strava has no dynamic Copenhagen type, only `SL_COPENHAGEN_PLANK` / `LL_COPENHAGEN_PLANK` in its "Plank" group. Strava's semantics for the `SL`/`LL` prefixes are **not documented**. I read LL as long-lever (knee straight, top foot on the bench), the version that ranked tier 1 [P11].
  - Upload consequence: Strava will show the exercise as a plank variant with repetitions. This is acceptable because the upload carries reps per Set either way.
  - Alternative: `null`, which drops these Sets from the upload.
- **Prone T Raise → `FLOOR_T_RAISE`** ("Shoulder Stability" group).
- **Jump Squat → `BODY_WEIGHT_JUMP_SQUAT`** (Plyo group). Added weight is still sent in kg if non-zero.
- **Step-up → `STEP_UP`** (Squat group). Strava also has `STEP_UPS` in its Leg Raise group; `STEP_UP` matches the movement.
- **Reverse Lunge → `REVERSE_LUNGE`**. `DUMBBELL_REVERSE_LUNGE` also exists, but the catalog Exercise is bodyweight with Added Weight.
- **Cable Curl → `CABLE_BICEPS_CURL`**. Strava also lists `CABLE_CURL`; either is valid.

### 4.3 Considered and left out (to land at 80)

| Candidate | Why not |
|---|---|
| Sumo Deadlift (`SUMO_DEADLIFT`) | Overlaps Deadlift; Escamilla found mostly quad/tibialis differences [P10]. Good 81st Exercise if wanted. |
| Arnold Press (`ARNOLD_PRESS`) | Duplicates Seated Dumbbell Shoulder Press for the map; no distinct evidence found. |
| Machine Shoulder Press, T-Bar Row, Barbell Shrug | Staples, but they duplicate existing maps at the Full gym tier. |
| Dumbbell Fly | Pec Deck and Cable Fly cover isolation; the dumbbell tier has 3 chest presses. |
| Reverse Curl, Sliding Leg Curl, Cable Woodchop, Russian Twist, Cossack Squat | Lower priority or weaker evidence; Woodchop (`CABLE_WOODCHOP`) and Sliding Leg Curl (`SLIDING_LEG_CURL`) are valid Strava types if wanted. |
| Bench Dip | Diamond Push-up covers bodyweight triceps with better evidence [P5]. |
| Superman (`SUPERMAN_FROM_FLOOR`) | Would add a no-fixture Lower Back option (ExRx Target erector spinae [S66]) but is very low load. Candidate if the owner wants a true no-equipment Lower Back entry. |
| Plank, Side Plank, Copenhagen plank hold, Dead Hang, Farmer's Carry, Wall Sit | Holds/carries: not rep-based (owner rule). |
| Assisted Pull-up machine | Its "weight" is assistance (higher = easier), which inverts Step Up/Down logic. |

---

## 5. Coverage matrix (primary Muscle Groups only)

Counts per tier:
- **Full gym** = all columns.
- **DB & bench** = dumbbell/kettlebell + bodyweight.
- **BW only** = bodyweight.

"(KB)" marks the two kettlebell Exercises.

| Muscle Group | Gym-only (barbell, machine, cable) | Dumbbell / kettlebell | Bodyweight | Full gym | DB & bench | BW only |
|---|---|---|---|---|---|---|
| Chest | Bench Press, Machine Chest Press, Cable Fly, Incline Bench Press, Pec Deck, Close-Grip Bench Press | Incline Dumbbell Press, Dumbbell Bench Press, Dumbbell Pullover | Push-up, Dip, Diamond Push-up | 12 | 6 | 3 |
| Lats | Lat Pulldown, Seated Cable Row, Barbell Row, Straight-Arm Pulldown | One-Arm Dumbbell Row, Dumbbell Pullover | Pull-up, Chin-up, Inverted Row | 9 | 5 | 3 |
| Upper Back | Seated Cable Row, Barbell Row, Chest-Supported Row, Face Pull | One-Arm Dumbbell Row | Prone T Raise, Inverted Row | 7 | 3 | 2 |
| Lower Back | Deadlift | — | Back Extension | 2 | 1 | 1 |
| Traps | Upright Row | Dumbbell Shrug | — | 2 | 1 | **0 — none** |
| Front Delts | Overhead Press, Incline Bench Press | Incline Dumbbell Press, Seated Dumbbell Shoulder Press | Pike Push-up | 5 | 3 | 1 |
| Side Delts | Overhead Press, Cable Lateral Raise, Upright Row | Seated Dumbbell Shoulder Press, Lateral Raise | — (secondary only: Pike Push-up) | 5 | 2 | **0 — none** |
| Rear Delts | Face Pull, Rear Delt Fly | Dumbbell Rear Delt Fly | Prone T Raise | 4 | 2 | 1 |
| Biceps | Barbell Curl, Preacher Curl, Cable Curl | Dumbbell Curl, Hammer Curl, Incline Dumbbell Curl | Chin-up | 7 | 4 | 1 |
| Triceps | Triceps Pushdown, Overhead Triceps Extension, Skull Crusher, Close-Grip Bench Press | Dumbbell Overhead Triceps Extension | Dip, Diamond Push-up | 7 | 3 | 2 |
| Forearms | — | Hammer Curl, Wrist Curl | — (secondary only: Pull-up, Chin-up) | 2 | 2 | **0 — none** |
| Abs | Cable Crunch | — | Hanging Leg Raise, Ab Wheel Rollout, Bicycle Crunch | 4 | 3 | 3 |
| Obliques | Pallof Press | Dumbbell Side Bend | Ab Wheel Rollout, Bicycle Crunch | 4 | 3 | 2 |
| Glutes | Deadlift, Back Squat, Leg Press, Romanian Deadlift, Hip Thrust, Hack Squat, Good Morning, Hip Abduction, Power Clean | Goblet Squat (KB), Bulgarian Split Squat, Walking Lunge, Dumbbell Romanian Deadlift, Single-Leg Romanian Deadlift, Step-up, Lateral Lunge, Kettlebell Swing (KB) | Back Extension, Glute Bridge, Reverse Lunge, Box Jump, Jump Squat | 22 | 13 | 5 |
| Quads | Back Squat, Front Squat, Leg Press, Leg Extension, Hack Squat, Power Clean | Goblet Squat (KB), Bulgarian Split Squat, Walking Lunge, Step-up, Lateral Lunge | Reverse Lunge, Box Jump, Jump Squat | 14 | 8 | 3 |
| Hamstrings | Deadlift, Romanian Deadlift, Leg Curl, Good Morning, Power Clean | Dumbbell Romanian Deadlift, Single-Leg Romanian Deadlift, Kettlebell Swing (KB) | Nordic Curl | 9 | 4 | 1 |
| Adductors | Hip Adduction | Lateral Lunge | Copenhagen Adduction | 3 | 2 | 1 |
| Calves | Standing Calf Raise, Seated Calf Raise | — | Single-Leg Calf Raise | 3 | 1 | 1 |

### 5.1 Uncovered cells and thin spots

**Uncovered cells (no primary option at a tier):**

| Muscle Group × tier | Status | Options |
|---|---|---|
| Side Delts × Bodyweight only | **none** | Pike Push-up has it as secondary only. No credible rep-based bodyweight lateral-delt exercise was found (**not documented**). A light-load Prone Y/T or side-lying raise with a water bottle is really a dumbbell exercise. Accept the gap. |
| Traps × Bodyweight only | **none** | ExRx lists an "inverted shrug" on parallel bars or rings [S67 list], but it needs a fixture and its Target is not confirmed here. Accept the gap. Upright Row, Dumbbell Shrug and Power Clean (secondary) cover heavier tiers. |
| Forearms × Bodyweight only | **none** | Pull-up and Chin-up give Forearms as secondary. The only bodyweight forearm drill is the dead hang, a hold, which is excluded. Accept the gap. |

**Thin spots (exactly 1 option):**

- **Lower Back** at the DB & bench and BW tiers: only Back Extension, which needs a hyperextension bench. Dumbbell RDL, Single-Leg RDL and Good Morning carry it as secondary. Superman (§4.3) would add a true no-equipment option.
- **Calves** at the DB & bench tier: only Single-Leg Calf Raise. That is the right exercise, with a dumbbell as Added Weight.
- **Adductors**: Lateral Lunge (DB tier) and Copenhagen Adduction (BW tier). Squats and lunges add Adductors as secondary at every tier.
- **Hamstrings** at the BW tier: only Nordic Curl, which needs a foot anchor. Single-Leg RDL can be done unloaded; Sliding Leg Curl (§4.3) is the fallback.
- **Front Delts, Rear Delts, Biceps** at the BW tier: 1 each (Pike Push-up, Prone T Raise, Chin-up).

### 5.2 "Bodyweight" Exercises that need a fixture

If "Bodyweight only" means *no equipment at all*, these drop out:

| Fixture | Exercises |
|---|---|
| Pull-up bar | Pull-up, Chin-up, Hanging Leg Raise |
| Dip bars | Dip |
| Low bar or rings | Inverted Row |
| Bench or box | Back Extension (hyperextension bench), Copenhagen Adduction (bench), Box Jump (box) |
| Foot anchor | Nordic Curl |
| Ab wheel | Ab Wheel Rollout |

Two options:
1. Define the tier as "bodyweight plus a bar and a bench".
2. Add a separate `requiresFixture` flag.

Not deciding here.

### 5.3 Training Goal / Focus coverage (quick check)

| Training Goal or Focus | What covers it (new Exercises in bold) |
|---|---|
| Bigger Arms | 7 biceps-primary options (incl. **Preacher, Incline DB, Cable Curl**) and 7 triceps-primary options (incl. **Close-Grip Bench, Diamond Push-up, DB Overhead Extension**), plus forearms (**Wrist Curl**) |
| Athleticism | **Power Clean, Box Jump, Jump Squat, Kettlebell Swing, Step-up, Lateral Lunge, Single-Leg RDL, Copenhagen Adduction, Nordic Curl** |
| Running | Single-leg strength and tissue-capacity work: **Step-up, Reverse Lunge, Single-Leg RDL, Single-Leg Calf Raise, Nordic Curl, Copenhagen Adduction, Hip Abduction, Glute Bridge** |
| Cycling | Knee- and hip-extension strength: Back Squat, Leg Press, **Hack Squat**, Bulgarian Split Squat, **Step-up**, Hip Thrust, **Glute Bridge**, **Single-Leg Calf Raise** |
| Core | Crunch/flexion (Cable Crunch, **Bicycle Crunch**), hip flexion (Hanging Leg Raise), anti-extension (Ab Wheel), anti-rotation (**Pallof Press**), lateral flexion (**Dumbbell Side Bend**) |

Which Exercises a goal *should* prescribe is a programming question, out of scope here. This table only shows the catalog has material for each goal.

---

## 6. Custom Exercise data migration (`shoulders` → delt heads)

**Recommended mapping:** `shoulders` → `frontDelts` + `sideDelts`.

- Most user-created "shoulder" Exercises are presses or raises, and presses train both heads [P1]. Rear Delts is the least likely intent.
- If the result would exceed 3 primaries (e.g. `[chest, triceps, shoulders]`), use `frontDelts` alone. That pattern is almost always a press.
- A name heuristic ("rear", "reverse", "face pull" → `rearDelts`; "lateral", "side", "upright" → `sideDelts`) is possible. It is fragile with free-text names in any language, so if used, apply it only on top of the default.

**Caveats found in the code:**

1. **Supabase check constraint.** `supabase/migrations/20260930120000_schema.sql` restricts `exercises.muscle_groups` to the 16 current values, `'shoulders'` included.
   - The new migration must add `'frontDelts', 'sideDelts', 'rearDelts'`, and should **keep `'shoulders'` legal** for a while. Otherwise a not-yet-updated install or Watch-relayed record that still pushes `shoulders` makes the whole `sync_push` fail.
   - `secondaryMuscleGroups` needs its own `text[]` column with the same check. Per AGENTS.md, it also goes into the migration, the `ExerciseRecord`, and its `write(to:)`.
2. **Old clients drop unknown values silently.**
   - `Exercise.muscleGroups` decodes with `compactMap(MuscleGroup.init(rawValue:))` (`Exercise.swift:44`). An older build seeing `frontDelts` won't crash; it just shows the Exercise without its delt groups.
   - The new build seeing a lingering `shoulders` would also drop it. So the decode path (or the migration) must map `shoulders` → `[frontDelts, sideDelts]` rather than discard it.
3. **Do the rewrite on the iPhone, as a normal edit.**
   - The migration sets the new groups and bumps `updatedAt`, so the existing push carries it to Supabase and other devices (AGENTS.md: "bumping `updatedAt` is all it takes").
   - A server-side SQL rewrite would change rows without a client-clock `updatedAt` the other devices trust.
   - The Watch receives the change from the iPhone, like any edit.
4. **Catalog Exercises already in users' stores.** `ExerciseCatalog.seed` (as of `7779879`) only *inserts* missing keys and never updates existing ones.
   - The draft [ADR-0007](../adr/0007-delts-secondary-muscle-groups-and-catalog-revisions.md), written alongside this research, already covers this with dated **catalog revisions**. The seed rewrites any catalog Exercise that differs from its entry and is older than the revision date, stamping it with that date.
   - The tables in §3–§4 are the data for that revision. Nothing here conflicts with the ADR.
5. **Do it in one release for iPhone and Watch.** Both apps share `MuscleGroup` (Core), and the Watch app is embedded in the iPhone app (AGENTS.md), so they ship together. The only window is a user whose Watch hasn't updated yet.
6. **Archived Exercises.** Migrate them too. Session history snapshots names, not Muscle Groups (ADR-0005), so a Muscle Map over past Sessions will read the Exercise's current groups.

---

## 7. Open questions for the owner

1. Accept the anatomical convention in §1.2 (Traps = upper trapezius; Upper Back = rhomboids + middle/lower traps)? If yes, add it to CONTEXT.md.
2. Bench-family Triceps → secondary, and Pull-up/Lat Pulldown Biceps → secondary? These change today's filters. Bigger Arms filters keep Dip, Chin-up, Close-Grip Bench and Diamond Push-up as primary arm options.
3. Dumbbell Pullover: Chest + Lats primary, or Chest primary with Lats secondary?
4. Copenhagen Adduction: upload as `LL_COPENHAGEN_PLANK`, or `null`?
5. Does the "Bodyweight only" tier assume a bar and a bench (§5.2)? Should kettlebell Exercises count in "Dumbbells & bench" (§1.3)?
6. Accept the three uncovered bodyweight cells (Side Delts, Traps, Forearms), or add Superman for Lower Back as an 81st Exercise?

---

## Sources

### ExRx.net (well-known reference; read from Internet Archive snapshots 2023–2025 because exrx.net returns HTTP 403 to automated clients)

- **S1** ExRx BBBenchPress: <https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress>
- **S2** ExRx DBInclineBenchPress: <https://exrx.net/WeightExercises/PectoralClavicular/DBInclineBenchPress>
- **S3** ExRx DBBenchPress: <https://exrx.net/WeightExercises/PectoralSternal/DBBenchPress>
- **S4** ExRx LVChestPress: <https://exrx.net/WeightExercises/PectoralSternal/LVChestPress>
- **S5** ExRx CBStandingFly: <https://exrx.net/WeightExercises/PectoralSternal/CBStandingFly>
- **S6** ExRx BWPushup: <https://exrx.net/WeightExercises/PectoralSternal/BWPushup>
- **S7** ExRx BWChestDip: <https://exrx.net/WeightExercises/PectoralSternal/BWChestDip>
- **S8** ExRx BWPullup: <https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup>
- **S9** ExRx BWUnderhandChinup: <https://exrx.net/WeightExercises/LatissimusDorsi/BWUnderhandChinup>
- **S10** ExRx CBFrontPulldown: <https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown>
- **S11** ExRx CBSeatedRow: <https://exrx.net/WeightExercises/BackGeneral/CBSeatedRow>
- **S12** ExRx BBBentOverRow: <https://exrx.net/WeightExercises/BackGeneral/BBBentOverRow>
- **S13** ExRx DBBentOverRow: <https://exrx.net/WeightExercises/BackGeneral/DBBentOverRow>
- **S14** ExRx LVSeatedRow: <https://exrx.net/WeightExercises/BackGeneral/LVSeatedRow>
- **S15** ExRx CBRearDeltRow: <https://exrx.net/WeightExercises/DeltoidPosterior/CBRearDeltRow>
- **S16** ExRx BBDeadlift: <https://exrx.net/WeightExercises/GluteusMaximus/BBDeadlift>
- **S17** ExRx BW45HyperextensionArmsCrossed: <https://exrx.net/WeightExercises/ErectorSpinae/BW45HyperextensionArmsCrossed>
- **S18** ExRx BBMilitaryPress: <https://exrx.net/WeightExercises/DeltoidAnterior/BBMilitaryPress>
- **S19** ExRx DBShoulderPress: <https://exrx.net/WeightExercises/DeltoidAnterior/DBShoulderPress>
- **S20** ExRx DBLateralRaise: <https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise>
- **S21** ExRx LVSeatedRearDeltFly: <https://exrx.net/WeightExercises/DeltoidPosterior/LVSeatedRearDeltFly>
- **S22** ExRx DBShrug: <https://exrx.net/WeightExercises/TrapeziusUpper/DBShrug>
- **S23** ExRx BBCurl: <https://exrx.net/WeightExercises/Biceps/BBCurl>
- **S24** ExRx DBCurl: <https://exrx.net/WeightExercises/Biceps/DBCurl>
- **S25** ExRx DBHammerCurl: <https://exrx.net/WeightExercises/Brachioradialis/DBHammerCurl>
- **S26** ExRx CBPushdown: <https://exrx.net/WeightExercises/Triceps/CBPushdown>
- **S28** ExRx BBLyingTriExt: <https://exrx.net/WeightExercises/Triceps/BBLyingTriExt>
- **S29** ExRx BBSquat: <https://exrx.net/WeightExercises/GluteusMaximus/BBSquat>
- **S30** ExRx BBFrontSquat: <https://exrx.net/WeightExercises/GluteusMaximus/BBFrontSquat>
- **S31** ExRx LV45LegPress: <https://exrx.net/WeightExercises/GluteusMaximus/LV45LegPress>
- **S32** ExRx DBStrBackStrLegDeadlift: <https://exrx.net/WeightExercises/Hamstrings/DBStrBackStrLegDeadlift>
- **S33** ExRx BWSingleLegSplitSquat: <https://exrx.net/WeightExercises/GluteusMaximus/BWSingleLegSplitSquat>
- **S34** ExRx DBLunge: <https://exrx.net/WeightExercises/GluteusMaximus/DBLunge>
- **S35** ExRx LVLegExtension: <https://exrx.net/WeightExercises/Quadriceps/LVLegExtension>
- **S36** ExRx LVLyingLegCurl: <https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl>
- **S37** ExRx BBHipThrust: <https://exrx.net/WeightExercises/GluteusMaximus/BBHipThrust>
- **S38** ExRx LVSeatedHipAdduction: <https://exrx.net/WeightExercises/HipAdductors/LVSeatedHipAdduction>
- **S39** ExRx LVStandingCalfRaise: <https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaise>
- **S40** ExRx LVSeatedCalfRaise: <https://exrx.net/WeightExercises/Soleus/LVSeatedCalfRaise>
- **S41** ExRx BWHangingLegRaise: <https://exrx.net/WeightExercises/HipFlexors/BWHangingLegRaise>
- **S42** ExRx CBKneelingCrunch: <https://exrx.net/WeightExercises/RectusAbdominis/CBKneelingCrunch>
- **S43** ExRx BBInclineBenchPress: <https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress>
- **S44** ExRx LVPecDeckFly: <https://exrx.net/WeightExercises/PectoralSternal/LVPecDeckFly>
- **S45** ExRx BBCloseGripBenchPress: <https://exrx.net/WeightExercises/Triceps/BBCloseGripBenchPress>
- **S46** ExRx BWCloseGripPushup: <https://exrx.net/WeightExercises/Triceps/BWCloseGripPushup>
- **S47** ExRx CBOneArmLateralRaise: <https://exrx.net/WeightExercises/DeltoidLateral/CBOneArmLateralRaise>
- **S48** ExRx BBUprightRow: <https://exrx.net/WeightExercises/DeltoidLateral/BBUprightRow>
- **S49** ExRx DBRearLateralRaise: <https://exrx.net/WeightExercises/DeltoidPosterior/DBRearLateralRaise>
- **S50** ExRx BWSupineRow: <https://exrx.net/WeightExercises/BackGeneral/BWSupineRow>
- **S51** ExRx CBBentoverPullover: <https://exrx.net/WeightExercises/LatissimusDorsi/CBBentoverPullover>
- **S52** ExRx DBPullover: <https://exrx.net/WeightExercises/PectoralSternal/DBPullover>
- **S53** ExRx DBInclineCurl: <https://exrx.net/WeightExercises/Biceps/DBInclineCurl>
- **S54** ExRx CBCurl: <https://exrx.net/WeightExercises/Biceps/CBCurl>
- **S55** ExRx DBTriExt: <https://exrx.net/WeightExercises/Triceps/DBTriExt>
- **S56** ExRx DBWristCurl: <https://exrx.net/WeightExercises/WristFlexors/DBWristCurl>
- **S57** ExRx SLHackSquat: <https://exrx.net/WeightExercises/GluteusMaximus/SLHackSquat>
- **S58** ExRx BBGoodMorning: <https://exrx.net/WeightExercises/Hamstrings/BBGoodMorning>
- **S59** ExRx BWSingleLegStiffLegDeadlift: <https://exrx.net/WeightExercises/GluteusMaximus/BWSingleLegStiffLegDeadlift>
- **S60** ExRx LVSeatedHipAbduction: <https://exrx.net/WeightExercises/HipAbductor/LVSeatedHipAbduction>
- **S61** ExRx DBStepUp: <https://exrx.net/WeightExercises/GluteusMaximus/DBStepUp>
- **S62** ExRx BWRearLunge: <https://exrx.net/WeightExercises/GluteusMaximus/BWRearLunge>
- **S63** ExRx BWSingleLegCalfRaise: <https://exrx.net/WeightExercises/Gastrocnemius/BWSingleLegCalfRaise>
- **S64** ExRx DBSideBend: <https://exrx.net/WeightExercises/Obliques/DBSideBend>
- **S65** ExRx DBFrontSquat: <https://exrx.net/WeightExercises/Quadriceps/DBFrontSquat>
- **S66** ExRx Superman: <https://exrx.net/WeightExercises/ErectorSpinae/Superman>
- **S67** ExRx Trapezius exercise list (BW inverted shrug entries): <https://exrx.net/Lists/ExList/BackWt>
- (S27 unused: the ExRx cable overhead triceps extension page is not archived; Overhead Triceps Extension cites S55.)

### Peer-reviewed studies (PubMed abstracts read via NCBI E-utilities)

- **P1** Campos YAC et al. Different shoulder exercises affect the activation of deltoid portions in resistance-trained individuals. *J Hum Kinet* 2020;75:5–14. PMID 33312291: <https://pubmed.ncbi.nlm.nih.gov/33312291/>
- **P2** Trebs AA et al. An electromyography analysis of 3 muscles surrounding the shoulder joint during the performance of a chest press exercise at several angles. *J Strength Cond Res* 2010;24(7):1925–30. PMID 20512064: <https://pubmed.ncbi.nlm.nih.gov/20512064/>
- **P3** Coratella G et al. Specific prime movers' excitation during free-weight bench press variations and chest press machine in competitive bodybuilders. *Eur J Sport Sci* 2020;20(5):571–9. PMID 31397215: <https://pubmed.ncbi.nlm.nih.gov/31397215/>
- **P4** Brandão L et al. Varying the order of combinations of single- and multi-joint exercises differentially affects resistance training adaptations. *J Strength Cond Res* 2020;34(5):1254–63. PMID 32149887: <https://pubmed.ncbi.nlm.nih.gov/32149887/>
- **P5** Cogley RM et al. Comparison of muscle activation using various hand positions during the push-up exercise. *J Strength Cond Res* 2005;19(3):628–33. PMID 16095413: <https://pubmed.ncbi.nlm.nih.gov/16095413/>
- **P6** Youdas JW et al. Surface electromyographic activation patterns and elbow joint motion during a pull-up, chin-up, or Perfect-Pullup rotational exercise. *J Strength Cond Res* 2010;24(12):3404–14. PMID 21068680: <https://pubmed.ncbi.nlm.nih.gov/21068680/>
- **P7** Buonsenso A et al. Electromyographic analysis of back muscle activation during lat pulldown exercise: effects of grip variations and forearm orientation. *J Funct Morphol Kinesiol* 2025. PMID 40981044: <https://pubmed.ncbi.nlm.nih.gov/40981044/>
- **P8** Fenwick CM, Brown SH, McGill SM. Comparison of different rowing exercises: trunk muscle activation and lumbar spine motion, load, and stiffness. *J Strength Cond Res* 2009;23(5):1408–17. PMID 19620925: <https://pubmed.ncbi.nlm.nih.gov/19620925/>
- **P9** Ekstrom RA et al. Surface electromyographic analysis of exercises for the trapezius and serratus anterior muscles. *J Orthop Sports Phys Ther* 2003;33(5):247–58. PMID 12774999: <https://pubmed.ncbi.nlm.nih.gov/12774999/>
- **P10** Escamilla RF et al. An electromyographic analysis of sumo and conventional style deadlifts. *Med Sci Sports Exerc* 2002;34(4):682–8. PMID 11932579: <https://pubmed.ncbi.nlm.nih.gov/11932579/>
- **P11** Collings TJ et al. Hip adductor muscle forces during strength training and rehabilitation exercises. *Med Sci Sports Exerc* 2026;58(8):1751–63. PMID 41931009: <https://pubmed.ncbi.nlm.nih.gov/41931009/>
- **P12** Coratella G et al. An electromyographic analysis of lateral raise variations and frontal raise in competitive bodybuilders. *Int J Environ Res Public Health* 2020;17(17):6015. PMID 32824894: <https://pubmed.ncbi.nlm.nih.gov/32824894/>
- **P13** Kubo K, Ikebukuro T, Yata H. Effects of squat training with different depths on lower limb muscle volumes. *Eur J Appl Physiol* 2019;119(9):1933–42. PMID 31230110: <https://pubmed.ncbi.nlm.nih.gov/31230110/>
- **P14** McAllister MJ et al. Muscle activation during various hamstring exercises. *J Strength Cond Res* 2014;28(6):1573–80. PMID 24149748: <https://pubmed.ncbi.nlm.nih.gov/24149748/>
- **P15** Morin T et al. Robustness of hamstring muscle activation strategies following selective hypertrophy induced by Nordic hamstring curl and stiff-leg deadlift exercises. *J Appl Physiol* 2025;139(1):296–307. PMID 40586278: <https://pubmed.ncbi.nlm.nih.gov/40586278/>
- **P16** Kipp K, Kim H, Wolf WI. Muscle forces during the squat, split squat, and step-up across a range of external loads in college-aged men. *J Strength Cond Res* 2022;36(2):314–23. PMID 32569122: <https://pubmed.ncbi.nlm.nih.gov/32569122/>
- **P17** Contreras B et al. A comparison of gluteus maximus, biceps femoris, and vastus lateralis electromyographic activity in the back squat and barbell hip thrust exercises. *J Appl Biomech* 2015;31(6):452–8. PMID 26214739: <https://pubmed.ncbi.nlm.nih.gov/26214739/>
- **P18** Escamilla RF et al. Electromyographic analysis of traditional and nontraditional abdominal exercises: implications for rehabilitation and training. *Phys Ther* 2006;86(5):656–71. PMID 16649890: <https://pubmed.ncbi.nlm.nih.gov/16649890/>
- **P19** Lehman GJ. The influence of grip width and forearm pronation/supination on upper-body myoelectric activity during the flat bench press. *J Strength Cond Res* 2005;19(3):587–91. PMID 16095407: <https://pubmed.ncbi.nlm.nih.gov/16095407/>
- **P20** McAllister MJ et al. Effect of grip width on electromyographic activity during the upright row. *J Strength Cond Res* 2013;27(1):181–7. PMID 22362088: <https://pubmed.ncbi.nlm.nih.gov/22362088/>
- **P21** Di Fonza D et al. Electromyographic analysis of latissimus dorsi activation during common resistance training exercises: a narrative review. *J Funct Morphol Kinesiol* 2026;11(3):315. PMID 42647355: <https://pubmed.ncbi.nlm.nih.gov/42647355/>
- **P22** Morin T et al. Neuromechanical determinants of muscle-specific hamstring damage and hypertrophy across exercises. *Med Sci Sports Exerc* 2026 (online ahead of print). PMID 42735209: <https://pubmed.ncbi.nlm.nih.gov/42735209/>
- **P23** Harøy J et al. The Adductor Strengthening Programme prevents groin problems among male football players: a cluster-randomised controlled trial. *Br J Sports Med* 2019;53(3):150–7. PMID 29891614: <https://pubmed.ncbi.nlm.nih.gov/29891614/>
- **P24** Giroux C et al. Is muscle coordination affected by loading condition in ballistic movements? *J Electromyogr Kinesiol* 2015;25(1):69–76. PMID 25467546: <https://pubmed.ncbi.nlm.nih.gov/25467546/>
- **P25** McGill SM, Marshall LW. Kettlebell swing, snatch, and bottoms-up carry: back and hip muscle activation, motion, and low back loads. *J Strength Cond Res* 2012;26(1):16–27. PMID 21997449: <https://pubmed.ncbi.nlm.nih.gov/21997449/>

### Professional bodies

- **A1** American Council on Exercise, "ACE-sponsored study reveals best and worst abdominal exercises" (San Diego State University, 2001; ACE-sponsored): <https://www.acefitness.org/about-ace/press-room/press-releases/246/american-council-on-exercise-ace-sponsored-study-reveals-best-and-worst-abdominal-exercises/>
- **N1** NSCA, Kinetic Select: Power Clean: <https://www.nsca.com/education/articles/kinetic-select/power-clean/>
- **N2** Human Kinetics excerpt, "Power Exercises: Power Clean" (from NSCA's *Essentials of Strength Training and Conditioning*), "Major muscles involved": <https://us.humankinetics.com/blogs/excerpt/power-exercises-power-clean-and-hang-power-clean-variation>

### Unverified (no primary source found or read)

- **U1** Pike push-up: no EMG study found (PubMed and web search, 2026-10-09). Nearest: push-up variant studies, e.g. <https://pubmed.ncbi.nlm.nih.gov/26488636/>.
- **U2** Preacher curl: the ExRx page could not be retrieved; mapping copied from S23/S54.
- **U3** Lateral lunge: no ExRx page or study retrieved; mapping from movement mechanics.
- **U4** Box jump: no study read; mapping by analogy with P24.
- **U5** Pallof press: "Anti-rotational and rotational abdominal exercises and the concurrent muscle activation: a methodology study", *Int J Exerc Sci: Conf Proc* (WKU), listing only: <https://digitalcommons.wku.edu/ijesab/vol8/iss9/12>

### Repository files read

- `CONTEXT.md`; `README.md` §3, §12, §17
- `Packages/OnlyWorkoutKit/Sources/OnlyWorkoutStore/ExerciseCatalog.swift`, `ExerciseCatalog+Strava.swift`, `Exercise.swift`, `Records/ExerciseRecord.swift`
- `Packages/OnlyWorkoutKit/Sources/OnlyWorkoutCore/StravaExerciseGroup+All.swift` (all 36 new Strava types validated against it by script), `MuscleGroup.swift`, `Equipment.swift`
- `supabase/migrations/20260930120000_schema.sql` (the `muscle_groups` check constraint)

[S1]: https://exrx.net/WeightExercises/PectoralSternal/BBBenchPress
[S2]: https://exrx.net/WeightExercises/PectoralClavicular/DBInclineBenchPress
[S3]: https://exrx.net/WeightExercises/PectoralSternal/DBBenchPress
[S4]: https://exrx.net/WeightExercises/PectoralSternal/LVChestPress
[S5]: https://exrx.net/WeightExercises/PectoralSternal/CBStandingFly
[S6]: https://exrx.net/WeightExercises/PectoralSternal/BWPushup
[S7]: https://exrx.net/WeightExercises/PectoralSternal/BWChestDip
[S8]: https://exrx.net/WeightExercises/LatissimusDorsi/BWPullup
[S9]: https://exrx.net/WeightExercises/LatissimusDorsi/BWUnderhandChinup
[S10]: https://exrx.net/WeightExercises/LatissimusDorsi/CBFrontPulldown
[S11]: https://exrx.net/WeightExercises/BackGeneral/CBSeatedRow
[S12]: https://exrx.net/WeightExercises/BackGeneral/BBBentOverRow
[S13]: https://exrx.net/WeightExercises/BackGeneral/DBBentOverRow
[S14]: https://exrx.net/WeightExercises/BackGeneral/LVSeatedRow
[S15]: https://exrx.net/WeightExercises/DeltoidPosterior/CBRearDeltRow
[S16]: https://exrx.net/WeightExercises/GluteusMaximus/BBDeadlift
[S17]: https://exrx.net/WeightExercises/ErectorSpinae/BW45HyperextensionArmsCrossed
[S18]: https://exrx.net/WeightExercises/DeltoidAnterior/BBMilitaryPress
[S19]: https://exrx.net/WeightExercises/DeltoidAnterior/DBShoulderPress
[S20]: https://exrx.net/WeightExercises/DeltoidLateral/DBLateralRaise
[S21]: https://exrx.net/WeightExercises/DeltoidPosterior/LVSeatedRearDeltFly
[S22]: https://exrx.net/WeightExercises/TrapeziusUpper/DBShrug
[S23]: https://exrx.net/WeightExercises/Biceps/BBCurl
[S24]: https://exrx.net/WeightExercises/Biceps/DBCurl
[S25]: https://exrx.net/WeightExercises/Brachioradialis/DBHammerCurl
[S26]: https://exrx.net/WeightExercises/Triceps/CBPushdown
[S28]: https://exrx.net/WeightExercises/Triceps/BBLyingTriExt
[S29]: https://exrx.net/WeightExercises/GluteusMaximus/BBSquat
[S30]: https://exrx.net/WeightExercises/GluteusMaximus/BBFrontSquat
[S31]: https://exrx.net/WeightExercises/GluteusMaximus/LV45LegPress
[S32]: https://exrx.net/WeightExercises/Hamstrings/DBStrBackStrLegDeadlift
[S33]: https://exrx.net/WeightExercises/GluteusMaximus/BWSingleLegSplitSquat
[S34]: https://exrx.net/WeightExercises/GluteusMaximus/DBLunge
[S35]: https://exrx.net/WeightExercises/Quadriceps/LVLegExtension
[S36]: https://exrx.net/WeightExercises/Hamstrings/LVLyingLegCurl
[S37]: https://exrx.net/WeightExercises/GluteusMaximus/BBHipThrust
[S38]: https://exrx.net/WeightExercises/HipAdductors/LVSeatedHipAdduction
[S39]: https://exrx.net/WeightExercises/Gastrocnemius/LVStandingCalfRaise
[S40]: https://exrx.net/WeightExercises/Soleus/LVSeatedCalfRaise
[S41]: https://exrx.net/WeightExercises/HipFlexors/BWHangingLegRaise
[S42]: https://exrx.net/WeightExercises/RectusAbdominis/CBKneelingCrunch
[S43]: https://exrx.net/WeightExercises/PectoralClavicular/BBInclineBenchPress
[S44]: https://exrx.net/WeightExercises/PectoralSternal/LVPecDeckFly
[S45]: https://exrx.net/WeightExercises/Triceps/BBCloseGripBenchPress
[S46]: https://exrx.net/WeightExercises/Triceps/BWCloseGripPushup
[S47]: https://exrx.net/WeightExercises/DeltoidLateral/CBOneArmLateralRaise
[S48]: https://exrx.net/WeightExercises/DeltoidLateral/BBUprightRow
[S49]: https://exrx.net/WeightExercises/DeltoidPosterior/DBRearLateralRaise
[S50]: https://exrx.net/WeightExercises/BackGeneral/BWSupineRow
[S51]: https://exrx.net/WeightExercises/LatissimusDorsi/CBBentoverPullover
[S52]: https://exrx.net/WeightExercises/PectoralSternal/DBPullover
[S53]: https://exrx.net/WeightExercises/Biceps/DBInclineCurl
[S54]: https://exrx.net/WeightExercises/Biceps/CBCurl
[S55]: https://exrx.net/WeightExercises/Triceps/DBTriExt
[S56]: https://exrx.net/WeightExercises/WristFlexors/DBWristCurl
[S57]: https://exrx.net/WeightExercises/GluteusMaximus/SLHackSquat
[S58]: https://exrx.net/WeightExercises/Hamstrings/BBGoodMorning
[S59]: https://exrx.net/WeightExercises/GluteusMaximus/BWSingleLegStiffLegDeadlift
[S60]: https://exrx.net/WeightExercises/HipAbductor/LVSeatedHipAbduction
[S61]: https://exrx.net/WeightExercises/GluteusMaximus/DBStepUp
[S62]: https://exrx.net/WeightExercises/GluteusMaximus/BWRearLunge
[S63]: https://exrx.net/WeightExercises/Gastrocnemius/BWSingleLegCalfRaise
[S64]: https://exrx.net/WeightExercises/Obliques/DBSideBend
[S65]: https://exrx.net/WeightExercises/Quadriceps/DBFrontSquat
[S66]: https://exrx.net/WeightExercises/ErectorSpinae/Superman
[S67]: https://exrx.net/Lists/ExList/BackWt
[P1]: https://pubmed.ncbi.nlm.nih.gov/33312291/
[P2]: https://pubmed.ncbi.nlm.nih.gov/20512064/
[P3]: https://pubmed.ncbi.nlm.nih.gov/31397215/
[P4]: https://pubmed.ncbi.nlm.nih.gov/32149887/
[P5]: https://pubmed.ncbi.nlm.nih.gov/16095413/
[P6]: https://pubmed.ncbi.nlm.nih.gov/21068680/
[P7]: https://pubmed.ncbi.nlm.nih.gov/40981044/
[P8]: https://pubmed.ncbi.nlm.nih.gov/19620925/
[P9]: https://pubmed.ncbi.nlm.nih.gov/12774999/
[P10]: https://pubmed.ncbi.nlm.nih.gov/11932579/
[P11]: https://pubmed.ncbi.nlm.nih.gov/41931009/
[P12]: https://pubmed.ncbi.nlm.nih.gov/32824894/
[P13]: https://pubmed.ncbi.nlm.nih.gov/31230110/
[P14]: https://pubmed.ncbi.nlm.nih.gov/24149748/
[P15]: https://pubmed.ncbi.nlm.nih.gov/40586278/
[P16]: https://pubmed.ncbi.nlm.nih.gov/32569122/
[P17]: https://pubmed.ncbi.nlm.nih.gov/26214739/
[P18]: https://pubmed.ncbi.nlm.nih.gov/16649890/
[P19]: https://pubmed.ncbi.nlm.nih.gov/16095407/
[P20]: https://pubmed.ncbi.nlm.nih.gov/22362088/
[P21]: https://pubmed.ncbi.nlm.nih.gov/42647355/
[P22]: https://pubmed.ncbi.nlm.nih.gov/42735209/
[P23]: https://pubmed.ncbi.nlm.nih.gov/29891614/
[P24]: https://pubmed.ncbi.nlm.nih.gov/25467546/
[P25]: https://pubmed.ncbi.nlm.nih.gov/21997449/
[A1]: https://www.acefitness.org/about-ace/press-room/press-releases/246/american-council-on-exercise-ace-sponsored-study-reveals-best-and-worst-abdominal-exercises/
[N1]: https://www.nsca.com/education/articles/kinetic-select/power-clean/
[N2]: https://us.humankinetics.com/blogs/excerpt/power-exercises-power-clean-and-hang-power-clean-variation
[U1]: https://pubmed.ncbi.nlm.nih.gov/26488636/
[U5]: https://digitalcommons.wku.edu/ijesab/vol8/iss9/12
