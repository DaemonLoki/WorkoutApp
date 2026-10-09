# OnlyWorkout

The simplest possible strength-training tracker for iPhone and Apple Watch, built for one person: plan Workouts, run them set by set from the wrist, and let progressive overload happen automatically.

> **Vocabulary.** Every capitalised domain term in this document (Exercise, Workout, Planned Exercise, Session, Set, Target, Step Up, …) is defined in [CONTEXT.md](CONTEXT.md). Use those words exactly — in code, UI copy, and conversation.
>
> **Decisions.** Hard-to-reverse decisions and their reasoning live in [docs/adr/](docs/adr/). **Agent/dev setup** lives in [AGENTS.md](AGENTS.md).

---

## 1. Goals

Straight from the original brief:

1. **Track workouts in the simplest way.** Logging a Set is one tap.
2. **Configure Exercises** by type, reps and weight → a Planned Exercise with a fixed Target (Sets × reps @ weight).
3. **Different Workouts for different days** → a Rotation of Workouts, independent of weekday.
4. **Go through a Session one-by-one**, optionally alternating two Exercises → guided Session with Supersets.
5. **Apple Watch controls everything**, even without the iPhone → standalone Watch app that runs full Sessions.
6. **Progressive overload baked in** → Step Up after a Target Hit; Step Down after a Stall or Layoff.
7. **Clear statistics** per Exercise with progression over time and filtering.
8. **Integrations** → Sessions saved to Apple Health; Sessions (with every Set) uploaded to Strava, which derives the muscle groups from each Set's exercise.
9. **Technical**: native, offline-first, Watch works standalone, database reachable by other tech (future web dashboard).
10. **Design**: minimal but functional, beautiful, enjoyable, motivating — celebrate progress with animation and specific, number-backed messages.
11. **A first launch that explains the app** (M6): a short tour of what makes OnlyWorkout different, then Cloud Sync restore and the permissions it needs (§7 Onboarding).
12. **See what you train** (M7): a gender-neutral Muscle Map for every Exercise, Workout and recent stretch of Sessions, showing their Emphasis (§7, §9).
13. **Help building Workouts** (M8): Recommendations of Exercises, whole Workouts or a whole Rotation from a Focus or a Training Goal, always with a reason (§7 Recommendations, [ADR-0008](docs/adr/0008-rules-choose-recommendations-the-on-device-model-only-words-reasons.md)).

### Non-goals (deliberately out of scope)

Cardio/GPS tracking · timed Exercises (planks) · rep ranges / RPE / percentage-based programs · AI coaching or generated text (the one exception: a Recommendation's one-sentence reason may be worded on device by Apple Intelligence, ADR-0008) · schedules or weekday plans (Weekly Sessions only shapes a recommended Rotation) · social features · pounds (kg only) · iPad/Mac apps · reading workouts *from* Health · body-weight/nutrition tracking · streaks · the web dashboard itself (only the database is designed for it).

---

## 2. Platforms & stack

| | |
|---|---|
| Platforms | iOS 27, watchOS 27 (minimum = current; personal app) |
| Language | Swift 6.4, Swift 6 language mode, strict concurrency |
| UI | SwiftUI only (no UIKit), Swift Charts, WidgetKit, ActivityKit |
| Local storage | SwiftData on each device (iPhone and Watch each have their own store) |
| Health | HealthKit (`HKWorkoutSession` on Watch and iPhone, workout mirroring) |
| Phone ↔ Watch | WatchConnectivity + HealthKit mirrored workout sessions |
| Cloud | Supabase (Postgres + Auth + Edge Functions), free tier |
| Third-party deps | **Only** [`supabase-swift`](https://github.com/supabase/supabase-swift). Anything else needs explicit approval. |
| On-device AI (M8) | Apple's Foundation Models framework, iPhone only, for a Recommendation's reason text and nothing else ([ADR-0008](docs/adr/0008-rules-choose-recommendations-the-on-device-model-only-words-reasons.md), [docs/research/foundation-models.md](docs/research/foundation-models.md)) |
| Tests | Swift Testing, test-first for all logic |
| Distribution | Personal + TestFlight now; everything built to pass App Store review later (§14) |

App name **OnlyWorkout**, bundle ID prefix `com.stefanblos`.

---

## 3. Domain model

All synced records share: `id: UUID`, `createdAt`, `updatedAt` (client clock, drives conflict resolution), `deletedAt: Date?` (soft delete / tombstone). Nothing is ever hard-deleted locally before it has synced.

### Exercise
| Field | Type | Notes |
|---|---|---|
| name | String | |
| equipment | enum | `barbell, dumbbell, machine, cable, bodyweight, kettlebell` |
| muscleGroups | [MuscleGroup] | prime movers, 1–3 |
| secondaryMuscleGroups (M7) | [MuscleGroup] | Secondary Muscle Groups, 0–3, none also in `muscleGroups`; count half for Emphasis |
| eachSide (M8) | Bool | default false; reps are counted Each Side (Target text reads "3 × 10 each side") |
| catalogKey | String? | set for Exercise Catalog entries (e.g. `barbell-back-squat`); nil for Custom Exercises |
| stravaExerciseType | String? | Strava exercise type picked for a Custom Exercise; catalog Exercises fall back to their built-in one (§12) |
| archivedAt | Date? | "Deleting" an Exercise that has history archives it |

`isBodyweight` is derived: `equipment == .bodyweight`. Weight is then **Added Weight**.

**MuscleGroup** (fixed, 18 since M7): Chest, Lats, Upper Back, Lower Back, Traps, Front Delts, Side Delts, Rear Delts, Biceps, Triceps, Forearms, Abs, Obliques, Glutes, Quads, Hamstrings, Adductors, Calves. Until M7 the three Delts were one `shoulders`; decoding still maps a stray `shoulders` to Front + Side Delts ([ADR-0007](docs/adr/0007-delts-secondary-muscle-groups-and-catalog-revisions.md)). What each group covers anatomically: [docs/research/exercise-muscle-data.md](docs/research/exercise-muscle-data.md) §1.2.

Catalog Exercises can't be edited in the app; their Muscle Groups, Secondary Muscle Groups and Each Side come from `ExerciseCatalog` and are rewritten by **catalog revisions** (ADR-0007, §17).

### Workout
| Field | Type | Notes |
|---|---|---|
| name | String | e.g. "Pull Day" |
| rotationIndex | Int | position in the Rotation; the Workouts list order *is* the Rotation |
| usesRestTimer | Bool | default true; off, this Workout's Sessions time no Rest (§6) |
| focus (M8) | Focus? | `push, pull, legs, upperBody, lowerBody, fullBody, arms, core`; optional; drives Recommendations and Gaps (§7) |

### Planned Exercise
| Field | Type | Default | Notes |
|---|---|---|---|
| workoutID | UUID | | |
| exerciseID | UUID | | |
| position | Int | | order within the Workout |
| supersetID | UUID? | nil | two adjacent Planned Exercises sharing an id form a Superset (max 2) |
| linkID | UUID? | nil | Linked Planned Exercises (same Exercise, other Workouts) share an id and one Target — [ADR-0006](docs/adr/0006-linked-planned-exercises.md) |
| targetSets | Int | 3 | 1…10 |
| targetReps | Int | 10 | 1…50, **fixed number** |
| weight | Double (kg) | 0 | current Target weight; ≥ 0 |
| weightStep | Double (kg) | by equipment | barbell 2.5 · dumbbell 2 · machine 5 · cable 2.5 · bodyweight 2.5 · kettlebell 4 |
| restSeconds | Int | 90 | 30…300 in 15 s steps |

### Session
| Field | Type | Notes |
|---|---|---|
| workoutID | UUID? | nil if the Workout was deleted later |
| workoutName | String | snapshot |
| startedAt / endedAt | Date / Date? | `endedAt == nil` ⇒ in progress (resumable after crash) |
| recordedOn | enum | `watch, phone` — the device that ran it |
| healthWorkoutID | UUID? | local only, never synced (see §14) |
| stravaUploadedAt | Date? | when the Session reached Strava; synced, so it is never uploaded twice |
| stravaActivityID | Int64? | Strava's activity, for "View on Strava"; local only on the uploading iPhone, dropped after 7 days (§12) |

### Session Exercise (snapshot of a Planned Exercise inside a Session)

Sessions copy names and Targets instead of referencing the plan — see [ADR-0005](docs/adr/0005-sessions-snapshot-the-plan.md).

| Field | Type | Notes |
|---|---|---|
| sessionID, exerciseID | UUID | |
| plannedExerciseID | UUID? | |
| exerciseName | String | snapshot |
| position, supersetID | Int, UUID? | snapshot |
| targetSets, targetReps, targetWeight | Int, Int, Double | snapshot at Session start (after any accepted Layoff Step Down) |
| status | enum | `pending, done, skipped` |

### Set
| Field | Type | Notes |
|---|---|---|
| sessionExerciseID | UUID | |
| number | Int | 1-based position within the Session Exercise |
| reps | Int | |
| weight | Double (kg) | |
| isExtra | Bool | added beyond the Target's Set count |
| completedAt | Date | |

### Progression Suggestion
A pending/answered Step Up or Step Down.

| Field | Type | Notes |
|---|---|---|
| plannedExerciseID | UUID | |
| kind | enum | `stepUp, stepDown` |
| reason | enum | `targetHit, stall, layoff` |
| fromWeight, toWeight | Double | equal when the weight doesn't change |
| fromReps, toReps | Int? | reps per Set; equal when the reps don't change; nil on suggestions from before rep Step Ups |
| sourceSessionID | UUID? | nil for Layoff |
| status | enum | `pending, accepted, dismissed, superseded` |
| resolvedAt | Date? | |

At most **one pending** suggestion per Planned Exercise; creating a new one supersedes the old.

---

## 4. Progression rules

Why fixed rep Targets instead of rep ranges: [ADR-0003](docs/adr/0003-fixed-target-progression.md). All rules are pure functions in `OnlyWorkoutCore` and are written test-first. Only **planned** Sets (`isExtra == false`) count for Target Hit, Stall and total reps; extras still count for statistics.

### Target Hit
A Session Exercise is a Target Hit when **all** of:
- it has `targetSets` non-extra Sets logged (Session not ended before finishing them, not skipped);
- every one of those Sets has `reps ≥ targetReps` (extra reps count);
- every one of those Sets has `weight == targetWeight` (changing weight mid-Exercise disqualifies it).

### Step Up
- After a Target Hit, immediately after the last planned Set, a **Step Up card** appears (iPhone and Watch) offering two changes: **"Step Up to 42.5 kg"** (one Weight Step) or **"Step Up to 13 reps"** (one more rep per Set, max 50), plus **"Not yet"**. The prominent choice is one more rep for bodyweight Exercises, the Weight Step otherwise; nothing about it is stored.
- **Step Up** → Planned Exercise `weight += weightStep` *or* `targetReps += 1`, suggestion `accepted` (its record keeps only the chosen change), celebration (§9).
- **Not yet** → suggestion stays `pending` and appears in **Ready to Step Up** on the iPhone Today screen until accepted, dismissed, or superseded by the next Session of that Planned Exercise.
- Every subsequent Target Hit creates a fresh Step Up offer (still at `weight + weightStep` or `targetReps + 1`).

### Step Down — Stall
Let S1, S2, S3 be the three most recent Sessions of the Planned Exercise (oldest first). It is a **Stall** when all three were at the current Target (same weight *and* reps, so a rep Step Up starts a fresh window), none was a Target Hit, and neither S2 nor S3 set a new best total reps:
`total(S2) ≤ total(S1)` and `total(S3) ≤ max(total(S1), total(S2))`.

Examples (3×12 Target, same weight): totals `30, 28, 29` → Stall. `28, 30, 30` → no Stall (S2 improved). `30, 31, 33` → no Stall (still progressing).

Offered the same way as a Step Up (card after last Set + Ready list). If declined, it is offered again after the next Session in which the rule still holds (sliding window).

### Step Down — Layoff
When a Session reaches a Planned Exercise whose last performed Session is **more than 21 days** ago, a card appears **before its first Set**: "It's been 5 weeks — start at 57.5 kg?" Accepting lowers the Planned Exercise's weight (or reps, at 0 kg) *and* this Session's Target.

### Constraints
- Step Down never goes below 0 kg (`max(0, weight − weightStep)`). At 0 kg it lowers the reps by one instead (e.g. bodyweight Pull-ups), never below 1 rep; there is no choice for Step Downs.
- Thresholds (3 Sessions, 21 days) are constants in v1, not user settings.
- Skipped Session Exercises neither count as performed (Layoff) nor as misses (Stall).
- A Session Exercise with a skipped Set is not a Target Hit and doesn't count towards a Stall (it does count as performed for Layoff).
- Linked Planned Exercises are one progression: their Sessions form one history for Target Hit, Stall and Layoff, an accepted Step Up/Down changes all of them, and at most one suggestion is pending per link group.

---

## 5. Rotation

- Workouts are ordered by `rotationIndex` (drag to reorder in the Workouts tab).
- **Next Up** = the Workout after the Workout of the most recently *started* Session, wrapping around. With no Sessions yet, or if that Workout was deleted, Next Up is the first Workout.
- Starting any other Workout is always possible; the Rotation then continues after *that* one.
- A Session ended early still counts.

---

## 6. Session flow

A pure `SessionEngine` (in `OnlyWorkoutCore`) turns a Workout into a queue of steps and processes events. The same engine runs on iPhone and Watch.

### Queue construction
- Planned Exercises in `position` order.
- A Superset (A, B) expands to `A1 → B1 → Rest → A2 → B2 → Rest …`. If Set counts differ, the remaining Sets of the longer one continue alone with Rest after each. Superset Rest = `max(restA, restB)`.
- A normal Planned Exercise: `Set → Rest → Set → …`. No Rest after the last Set of the Session.
- **Rest Timer**: Rest is timed only when both the Workout's Rest Timer and the device-local setting (Settings → Sessions, on by default; the iPhone sends it to the Watch with the plan) are on. Otherwise no Rest follows any Set: the next Set comes right away, without Rest notification or Live Activity countdown; Step Up / Step Down cards still appear after the last planned Set. Decided at Session start and kept with the engine.

### Events
| Event | Effect |
|---|---|
| `completeSet(reps, weight)` | Logs a Set (prefilled with Target reps/weight; adjusting is optional), starts Rest (unless the Rest Timer is off) |
| `skipRest` / `extendRest(+30 s)` | |
| `skipSet(plannedExercise)` | Passes over the current Set (e.g. machine taken): not performed, not owed again, no Rest; in a Superset the partner comes next |
| `skip(plannedExercise)` | Marks Session Exercise `skipped`; a Superset partner continues alone with Rest after each Set |
| `doLater(plannedExercise)` | Moves it (or its whole Superset) to the end of the queue |
| `addExtraSet(plannedExercise)` | Appends one Set with `isExtra = true` |
| `editSet(set, reps, weight)` | Corrects a logged Set; Target Hit is re-evaluated |
| `answer(suggestion, accept)` | Step Up / Step Down decision |
| `end()` | Ends the Session (early is fine); remaining Exercises stay `pending` |

Not in v1: swapping an Exercise, adding an Exercise that isn't in the Workout.

### Primary device
The device running the Session (**Watch** when available, otherwise iPhone) owns the engine and persists the Session. The other device only *displays* live state and sends *commands* (e.g. tapping Done on the phone) through the mirrored workout session. Only the primary device writes the Session record, so there are never duplicates.

- Starting on iPhone with a reachable Watch and **Start Sessions on Apple Watch** on (Settings, device-local, on by default) → `HKHealthStore.startWatchApp(toHandle:)` launches the Session on the Watch; the Watch mirrors it back to the iPhone (`startMirroringToCompanionDevice`).
- Starting on iPhone without a reachable Watch, or with that setting off → iPhone is primary (iOS `HKWorkoutSession`, no heart rate).
- Starting on the Watch → Watch is primary; iPhone gets the mirrored session in the background.

### Persistence & recovery
The in-progress Session is saved after every event. After a crash/termination, the app resumes it (Watch: `HKHealthStore.recoverActiveWorkoutSession`). A Session left unfinished for 6 h is auto-ended at its last Set's time.

---

## 7. iPhone app

Four tabs (`Tab` API) with specific labels: **Today**, **Workouts**, **History**, **Progress**. Settings is a sheet from Today's toolbar.

### Onboarding (M6)
Shown once, on the first launch of a **fresh install**: no Workouts and no Sessions in the store when the app starts, decided before the Watch link can deliver records (catalog Exercises don't count). A device-local `hasCompletedOnboarding` is set at the end; Settings → About → **Welcome Tour** replays the tour pages (not the setup pages). `-uiTesting` skips it; Debug builds accept `-onboarding` to force it. iPhone only; the Watch keeps its empty state. Apple's rules behind every choice below: [docs/research/onboarding-and-permissions.md](docs/research/onboarding-and-permissions.md).

**Tour** (4 pages, swipeable, **Skip** in the toolbar jumps to Restore). Each page shows a real app component fed with sample values, animated once with purpose (Reduce Motion: a cross-fade):

| # | Title | Live component | Says |
|---|---|---|---|
| 1 | Get stronger, one step at a time | Next Up card of a sample "Push Day" (Targets, a Superset bracket) | Minimal and focused on progressive overload; Workouts are built from the Exercise Catalog; Supersets |
| 2 | Log a Set with one tap | Set view → Done (press feedback, values roll) → the Rest ring starts | One-tap logging; Rest Timer |
| 3 | Step Up when you're ready | `OfferCard` slides in; accepting rolls 60 → 62.5 kg with the orange glow | Hit the Target, get offered a Step Up (or a rep), automatically |
| 4 | On your iPhone or Apple Watch | The Rest ring in a simple watch-shaped frame; rows for Apple Health, Cloud Sync, Strava | Sessions run on either device; saved to Apple Health; synced; uploads to Strava (worded without promising it while the capacity gate is closed, §12) |

**Setup** (a plain sequence, no swiping, no Skip):

5. **Already use OnlyWorkout?** The system `SignInWithAppleButton` (system title, never "Restore") and **Start Fresh** with equal standing; footer: Cloud Sync is optional and can be turned on later in Settings. Signing in runs the normal Cloud Sync sign-in (push, then pull) and shows "Restoring…" while people continue. Failure keeps the page with the existing sign-in alert. The button logic is shared with Settings (one view, one nonce handling).
6. **Apple Health**: one sentence on what it adds and the official Apple Health icon (no lookalike glyph), one **Continue** that opens the system sheet. No close, back or "Not now" (HIG; App Review 5.1.1(iv)). Skipped when HealthKit reports nothing to ask (`statusForAuthorizationRequest == .unnecessary`).
7. **Rest alerts**: one sentence, one **Continue** → the notification permission alert. Skipped when already determined.

**End**: if Workouts exist by now (restored, or received from the Watch), land on Today; otherwise Today with the Workout editor pushed and its name focused ("Create your first Workout"; M8 adds **Recommend a Rotation** next to it). The in-context Health explanation before the first Session (§11) stays for anyone who quit before page 6.

### Today
1. **Ready to Step Up** (only when non-empty) — collapsed into one row with the count ("3 Exercises ready to Step Up", Step Downs counted on a second line), closed on every launch; tap to open one row per pending Progression Suggestion: *"Bench Press · Push Day — 3×10 hit at 60 kg"* with **Step Up to 62.5 kg** and **Step Up to 11 reps** buttons (prominent one first, §4) and swipe-to-dismiss. Step Downs appear here too, worded neutrally ("Squat · Leg Day — stalled at 80 kg. Step Down to 77.5 kg?").
2. **Next Up** card — Workout name, a compact Muscle Map of its Emphasis next to it (M7), its Planned Exercises with Targets (`3×12 @ 40 kg`, Supersets visually bracketed), large orange **Start** button.
3. **Other Workouts** — compact list; tap → start.
4. Empty state: `ContentUnavailableView` "No Workouts yet" + **Create Workout** (and **Recommend a Rotation**, M8).

### Workouts
- List in Rotation order; drag to reorder, swipe to delete (soft delete), `+` to create.
- **Workout editor**: name (a new Workout opens with an empty, focused name field and "New Workout" as placeholder; left empty, it's named "New Workout" once the editor closes); Planned Exercises (reorder, delete); **Add Exercise** → picker; context menu **Superset with Next** / **Break Superset**; **Rest Timer** toggle (§6). Planned Exercises with a pending suggestion show a small orange badge; linked ones a link icon. A large orange **Start** at the bottom starts a Session of this Workout the same way as Today (disabled without Planned Exercises); it doesn't change the Rotation rules.
- **Adding an Exercise that is already in another Workout** asks "Bench Press is already in another Workout — use the same settings?" with one button per existing setup ("Same as Push Day · 3 × 8 · 60 kg") and **Set Up Separately**. Choosing one links them (see §4).
- **Planned Exercise editor** of a linked one shows "Linked with Push Day" and **Unlink**; every edit is applied to all linked Planned Exercises.
- **Planned Exercise editor**: Sets (stepper), reps (stepper), weight (`TextField` bound to `Double` with `.decimalPad`, kg), Weight Step (menu: 0.5, 1, 1.25, 2, 2.5, 4, 5, 10), Rest (menu: 0:30 … 5:00).
- **Exercises** (toolbar) → Exercise Catalog + Custom Exercises; searchable (`localizedStandardContains`), filter by Muscle Group (matches `muscleGroups` only, not Secondary Muscle Groups); create/edit Custom Exercise (name, equipment, Muscle Groups; M7: Secondary Muscle Groups with a live Muscle Map; M8: Each Side).
- **Muscle Map in the Workout editor** (M7): a header with the Workout's Emphasis (front and back) and a one-line summary ("Mostly Chest, Front Delts and Triceps"); changed muscles cross-fade as Exercises are added or removed.
- **Exercise rows and detail** (M7): every Exercise row (library, picker) shows a tiny map of its own Emphasis. Tapping a catalog Exercise opens a new **Exercise detail**: large map, Muscle Groups and Secondary Muscle Groups as text, equipment, Each Side, and the Workouts it's planned in; a Custom Exercise's detail has **Edit**. In the picker, tapping still picks; the detail is one level deeper (info button).

### Recommendations (M8)
Rule-based, offline, explainable ([ADR-0008](docs/adr/0008-rules-choose-recommendations-the-on-device-model-only-words-reasons.md); evidence and tables in [docs/research/training-templates.md](docs/research/training-templates.md)). Every Recommendation shows its reason; nothing is added until the user taps **Add**.

- **Focus** row in the Workout editor (menu: None + the eight Focuses). With a Focus set:
  - **Empty Workout** → a **Recommended** section lists the Focus's Blueprint filled for the user's Equipment Access: Exercise, Target, reason ("Horizontal push — trains Chest and Front Delts"), **Add** per row and **Add All**.
  - **Workout with Exercises** → **Gaps** under the Muscle Map: each required Muscle Group no Planned Exercise trains, with the best fitting Exercise ("No Exercise trains Rear Delts yet — Face Pull?") and **Add**. Unfilled required Needs show the same way. Nothing when the Workout is complete.
- **Workouts tab `+`** becomes a menu: **New Workout** · **Recommend a Workout** · **Recommend a Rotation**.
  - **Recommend a Workout**: Focus → (Equipment Access, the first time) → preview: Muscle Map, Planned Exercises with Targets and Supersets, the reason → **review** → added at the end of the Rotation.
  - **Recommend a Rotation**: Training Goal → Weekly Sessions (2–6) → (Equipment Access) → preview: one card per Workout with its Muscle Map, the reason, and for Running/Cycling the neutral note that endurance athletes usually do 2–3 strength Sessions a week → **review** → **Add to Rotation** or **Replace My Workouts** (soft-deletes the current Workouts; Sessions keep their history, ADR-0005; Next Up becomes the first new Workout). Only asked when Workouts exist.
  - **Review**: every recommended Planned Exercise with its Target and an optional weight field (blank = 0 kg, editable any time). An Exercise already planned elsewhere offers its existing setup to link (ADR-0006) instead; the same Exercise in several recommended Workouts is linked by default.
- **Equipment Access**: Full Gym (everything) · Dumbbells & Bench (dumbbells, kettlebells, bodyweight) · Bodyweight Only (bodyweight; assumes a pull-up bar and a bench or box, which the Exercise detail mentions). Asked once, stored device-locally, changeable in every recommendation flow.
- **Rules** (pure, in `OnlyWorkoutCore`): each Focus has a **Blueprint** of Needs (role, candidate Exercises per Equipment Access, optional or required) and required/optional Muscle Groups; the Training Goal sets each role's Target and adds/removes Needs; Weekly Sessions picks the split; bodyweight Exercises at 0 kg get at least 8 or 12 reps; a Session-length estimate keeps a Workout within 45–75 min by dropping optional Needs, then pairing accessories into Supersets (antagonists only; never power or long-Rest Needs), then trimming accessory Sets. The tables are research §2–§5, encoded once.
- **Reasons**: the rules return facts and reason codes; a handwritten String Catalog sentence always exists. On iPhones with Apple Intelligence and **Settings → Recommendations → Write reasons with Apple Intelligence** on (default; hidden when not eligible), the on-device model words the same facts in one or two sentences, marked with a small "Written by Apple Intelligence" label. Any failure, timeout, refusal or failed check shows the handwritten one, silently. Reasons are never stored or synced. No health claims (e.g. never "prevents running injuries").

### Active Session (full-screen cover)
- **Set view**: Exercise name, "Set 2 of 3" (Superset: "A · Set 2 of 3"), reps and weight in huge rounded monospaced digits ("each side" under the reps for Each Side Exercises, M8; also on the Watch, in the Live Activity and in Target text everywhere), tap either to adjust (steppers); full-width **Done**; a small **Skip** menu below it with **Skip Set** and **Skip ‹Exercise›**. During the last Set of a Superset pair it also shows what follows the Rest ("After Rest: Curl · Set 2 of 3 · 10 × 14 kg"), so the next Exercise can be prepared.
- **Rest view**: countdown ring, time remaining, **+30 s** / **Skip**; below: "Next: Lat Pulldown · 3×12 @ 55 kg". Step Up / Step Down cards slide in here (or over the Set view without Rest); a Step Up card offers both changes (§4).
- Header: elapsed time, heart rate (when Watch-mirrored), per-Exercise progress dots.
- **Overview** sheet: queue with Skip / Do later / Add Set / edit logged Sets. **End** with confirmation only if Sets remain.
- When the Watch is primary, this same UI is shown mirrored; taps become commands to the Watch.

### Session Summary (end of every Session)
Celebration (§9), then: duration, Sets, volume, heart rate & calories (if recorded), a Muscle Map of what this Session trained (M7; muscles fill in on the stagger rhythm after the celebration), and a card per progress event (Step Ups accepted, new bests, Target Hits). **Done** returns to Today.

### History
- Every finished Session, newest first, in month sections (date, Workout, duration, Sets); Muscle Group filter; search by Workout or Exercise name. Swipe a Session to delete it (with confirmation; same as deleting it in the detail).
- **Session detail** shows every Set; edit Sets, upload to Strava (§12) or delete the Session (also deletes its Health workout, §11).

### Progress
- Filters: time range `4W · 3M · 6M · 1Y · All`; Muscle Group; search.
- **Muscle Coverage** (M7), above the Exercises: a Muscle Map of the Emphasis of all Sets in the last **7 days** or **4 weeks** (its own small picker, independent of the range filter), with Sets per Muscle Group listed below, largest first, and untrained groups named at the end. Descriptive only: no targets, no warnings, no guilt (§9).
- **Exercises**: every Exercise performed at least once — sparkline, current weight, change within range ("+7.5 kg").
- **Exercise detail** (Swift Charts): line of working weight per Session (max weight of its Sets), Step Up markers (annotated points), selection scrubbing (`chartXSelection`); best Set (heaviest weight, then most reps); total volume (Σ reps × weight; bodyweight Exercises with 0 kg show total reps instead); list of past Sets grouped by Session.

### Settings
Sync (Sign in with Apple / status / sign out) · Apple Health status · Sessions (**Rest Timer**, on by default; off times no Rest in any Workout, also on the Watch) · Apple Watch (**Start Sessions on Apple Watch**, on by default; off runs Sessions started on iPhone on the iPhone, without heart rate) · Strava (connect, auto-upload, disconnect) · Recommendations (**Write reasons with Apple Intelligence**, M8; hidden on ineligible devices) · Delete account & cloud data · About / privacy, **Welcome Tour** (M6).

### Live Activity & rest notifications
- A Live Activity runs for every Session: Lock Screen shows Workout name, current step ("Bench Press · Set 2 of 3 · 10 @ 60 kg" or Rest countdown via `Text(timerInterval:)`) and what's next; Dynamic Island compact shows the Rest countdown / Set indicator.
- **iPhone primary**: started with the Session; a local notification fires when Rest ends while the app is backgrounded.
- **Watch primary**: the iPhone updates the Live Activity from mirrored-session data. If iOS refuses to *start* it from the background (open question, §15), it starts the next time the iPhone app is foregrounded during the Session.

---

## 8. Apple Watch app

Standalone watchOS app with its own SwiftData store; works fully without the iPhone nearby.

- **Home**: Next Up Workout with **Start**; other Workouts below. Read-only plans — editing Workouts is iPhone-only.
- **Set screen**: Exercise name, "Set 2 of 3", reps and weight large; **Digital Crown adjusts reps**; weight via a secondary button; big **Done**. Heart rate small in the corner; a skip button in the other corner offers **Skip Set** / **Skip ‹Exercise›**. During the last Set of a Superset pair, a small line under **Done** shows what follows the Rest.
- **Rest screen**: countdown ring, haptic when Rest ends, "Next: Lat Pulldown 3×12 @ 55 kg" underneath; Step Up / Step Down cards appear here.
- **Swipe left**: Session overview — Skip, Do later, Add Set, End.
- **Summary**: celebration + key numbers.
- **Complication / Smart Stack widget**: "Next up: Pull Day"; tap starts the Session.
- Runs an `HKWorkoutSession` (`.traditionalStrengthTraining`, indoor) with `HKLiveWorkoutBuilder`: keeps the app frontmost, records heart rate & active energy, saves the workout to Health, closes Activity rings.

### Phone ↔ Watch data
- **Phone → Watch**: `updateApplicationContext` with a full plan snapshot — Exercises, Workouts, Planned Exercises, pending suggestions, and per Planned Exercise the summaries of its last 3 Sessions + last performed date (enough for the Watch to evaluate Target Hit, Stall and Layoff offline). It also carries the tombstones of Watch-recorded Sessions deleted in the last 30 days, so the Watch can delete their Health workouts (§11).
- **Watch → Phone**: the plan plus the Watch's Sessions of the last 14 days, sent as an immediate message when the iPhone is reachable *and* queued with `transferUserInfo`. Resent whenever the link activates, the iPhone becomes reachable, or a queued transfer fails (they can time out while the iPhone is off); merging makes repeats harmless.
- Both directions use the **same record-level merge** as cloud sync (§10). The Watch never talks to Supabase.

---

## 9. Design

Guided by the `apple-design` and `emil-design-eng` skills. Principles: simplicity over minimalism, the most important thing is the most obvious thing, every animation has a purpose, frequent actions stay fast.

### Visual language
- Standard iOS 27 / watchOS 27 components and Liquid Glass; follows light/dark automatically.
- **Accent: orange** (asset `AccentColor`, tuned from system orange for contrast in both appearances). Used only for primary actions (Start, Done) and progress moments (Step Up, badges, chart highlights). Everything else uses system hierarchical styles.
- Numbers: `.fontDesign(.rounded)` + `.monospacedDigit()` so values don't jitter while changing. Text: system font, Dynamic Type everywhere, `bold()` not `fontWeight(.bold)`.
- All fonts, spacing, radii and animation values live in one `DesignTokens` namespace in `OnlyWorkoutDesign`; no magic numbers in views.
- 44×44 pt minimum tap targets; `ContentUnavailableView` for every empty state.

### Motion (by frequency)
| Moment | Frequency | Treatment |
|---|---|---|
| Done (log a Set) | ~20× per Session | press feedback (scale 0.97) + light impact haptic; value changes use `.contentTransition(.numericText())`. No other animation. |
| Rest ring | every Set | linear progress (constant motion); success haptic when Rest ends |
| Step Up / Step Down card | a few per week | enters from the bottom, spring with no bounce (`.smooth`), exits the same way |
| Step Up accepted | rare | weight rolls to the new value (`numericText`), orange glow pulse, `.success` haptic on the same frame |
| Session complete | once per Session | the celebration: progress ring closes and morphs into a checkmark (spring, bounce ≈ 0.2), `.success` haptic, stats count up, progress cards stagger in (~60 ms apart) |

- All motion uses springs or `ease-out`; never `ease-in`; UI transitions < 300 ms except the celebration.
- **Reduce Motion**: celebrations become a cross-fade + checkmark without scale/morph; haptics remain.
- Haptics via `sensoryFeedback()` only.

### Muscle Map (M7)
A gender-neutral figure, front and back side by side (never a flip: hiding half the body hides half the answer), one region per Muscle Group, drawn as SwiftUI `Shape`s in `OnlyWorkoutDesign` from the chosen concept in [design/muscle-map/](design/muscle-map/) (encoding, colour steps and motion are specified there).

- **Emphasis** per Muscle Group = Σ Sets × (1 for a Muscle Group, ½ for a Secondary Muscle Group), normalised to the largest; shown in three steps (strong ≥ 0.75, medium ≥ 0.45, light > 0) of solid colours mixed from the accent over the neutral body, defined per appearance in `DesignTokens`. One hue, more is more orange. A Workout counts its planned Sets; Sessions count their logged Sets (extras included).
- This is a deliberate use of orange as a "progress picture"; no other orange element sits beside a map.
- Never colour alone: each map has a text summary ("Mostly Chest, Front Delts and Triceps"), which is also its VoiceOver label; large maps get a three-step legend; Increase Contrast outlines trained regions.
- Sizes: compact (list rows, ~44 pt tall, front and back) and full (headers, detail, Summary, Progress). Tapping a region on a full map selects it and shows its name and Sets.

### Motivational messages
Handwritten templates filled with real numbers — no generated text. The message is chosen deterministically (seeded by Session id) from 2–4 variants per trigger so it doesn't repeat every time.

| Trigger | Example |
|---|---|
| Step Up accepted | "Squat: 60 → 62.5 kg. That's +10 kg since June." |
| Target Hit | "Every set, every rep. Bench Press 3×10 @ 60 kg done." |
| New best Set | "New best: 12 pull-ups with +5 kg." |
| First Session back after a Layoff | "Welcome back. Starting a step lighter is the smart move." |
| Session complete | "Pull Day done — 18 sets, 6,420 kg moved." |

No streaks and no guilt messaging. Step Downs are worded as smart strategy, never failure.

### Localisation
English only for now. **All** user-facing strings go through `Localizable.xcstrings` using symbol keys (`Text(.startSession)`), so adding German needs no code changes. Use automatic grammar agreement (`^[\(count) set](inflect: true)`).

---

## 10. Data & sync

### Local-first
Each device's SwiftData store is the source of truth for that device. Every feature works without network or account. See [ADR-0001](docs/adr/0001-supabase-with-custom-sync.md) and [ADR-0002](docs/adr/0002-iphone-is-the-only-cloud-client.md).

### Merge rule (shared by Watch↔Phone and Phone↔Cloud)
Per record, **last write wins on `updatedAt`**; ties keep the existing record. Deletions are tombstones (`deletedAt`), so they merge like any other write. Implemented once in `OnlyWorkoutCore` (`RecordMerger`) and unit-tested.

### Cloud sync (M3)
- Opt-in: **Settings → Cloud Sync → Sign in with Apple** → `supabase.auth.signInWithIdToken(provider: .apple, …)` (with a SHA-256 nonce).
- Triggers: app launch, app foregrounded, Session finished, suggestion answered, records received from the Watch. No "sync now" button. `CloudSync` runs one sync at a time; a trigger during a sync makes it run once more afterwards.
- **Push first, then pull.** Each stored model keeps a local-only `syncedUpdatedAt`: the `updatedAt` the cloud is known to have. Every record where it differs from `updatedAt` goes in one call to the RPC `sync_push(payload jsonb)`, which upserts inside one transaction using `ON CONFLICT (user_id, id) DO UPDATE … WHERE t.updated_at < excluded.updated_at`. A per-record marker (not a `lastPushAt` cursor) is needed because Watch Sessions can reach the phone after a push with an older `updatedAt`.
- **Pull**: RPC `sync_pull(since timestamptz)` returns every row whose `server_updated_at > since`, across all tables, plus the newest `server_updated_at` as `cursor`. The client re-pulls from `cursor − 60 s`; merging is idempotent. Pulled winners are marked as synced, so they are never pushed back.
- Payloads are keyed by table name with snake_case columns (`CloudCoding`); dates go up as UTC with milliseconds. `healthWorkoutID` is stripped before a push.
- Signing out or deleting the account keeps local data and forgets the cursor and every `syncedUpdatedAt`, so the next sign-in pushes everything.
- `server_updated_at` is set by trigger (`clock_timestamp()`) and is used only as the pull cursor; `updated_at` (client) is used only for conflict resolution.
- Exercise Catalog records use **deterministic UUIDs** (UUIDv5 of `catalogKey`), so a reinstall + sign-in merges instead of duplicating. They are seeded with `updatedAt` = 1970-01-01, so an edited catalog Exercise in the cloud wins over a fresh seed.

### Supabase schema sketch (`supabase/migrations/`)
Postgres naming is `snake_case`, tables are plural, and every table has:

```sql
user_id           uuid        not null default auth.uid() references auth.users on delete cascade,
id                uuid        not null,
created_at        timestamptz not null,
updated_at        timestamptz not null,
deleted_at        timestamptz,
server_updated_at timestamptz not null default clock_timestamp(),
primary key (user_id, id)
```

| Table | Extra columns |
|---|---|
| `exercises` | `name text, equipment text, muscle_groups text[], secondary_muscle_groups text[]` (M7), `each_side bool` (M8), `catalog_key text, strava_exercise_type text, archived_at timestamptz` |
| `workouts` | `name text, rotation_index int, uses_rest_timer bool, focus text` (M8, nullable) |
| `planned_exercises` | `workout_id uuid, exercise_id uuid, position int, superset_id uuid, link_id uuid, target_sets int, target_reps int, weight numeric(6,2), weight_step numeric(5,2), rest_seconds int` |
| `sessions` | `workout_id uuid, workout_name text, started_at timestamptz, ended_at timestamptz, recorded_on text, strava_uploaded_at timestamptz` |
| `session_exercises` | `session_id uuid, exercise_id uuid, planned_exercise_id uuid, exercise_name text, position int, superset_id uuid, target_sets int, target_reps int, target_weight numeric(6,2), status text, skipped_sets int` |
| `sets` | `session_exercise_id uuid, number int, reps int, weight numeric(6,2), is_extra bool, completed_at timestamptz` |
| `progression_suggestions` | `planned_exercise_id uuid, kind text, reason text, from_weight numeric(6,2), to_weight numeric(6,2), source_session_id uuid, status text, resolved_at timestamptz` |
| `strava_connections` (M4) | `user_id uuid` (primary key), `athlete_id bigint unique, access_token text, refresh_token text, expires_at timestamptz, scope text, auto_upload bool, created_at, updated_at` — not synced and **no client access at all**; only Edge Functions (service role) touch it. The app reads `strava_connection()` (connected since, auto-upload) and calls `set_strava_auto_upload(bool)` |

- **Row Level Security** on every table: `using (user_id = auth.uid()) with check (user_id = auth.uid())`.
- Cross-table references are plain columns (no FK constraints between synced tables) so partial or out-of-order pushes can never fail; the app guarantees integrity.
- Check constraints on enums (`equipment`, `kind`, `status`, `focus`, …) and `muscle_groups <@ array[...]` (same for `secondary_muscle_groups`). Since M7 the array lists the 18 Muscle Groups **plus the legacy `shoulders`**, so records from not-yet-updated devices still push (ADR-0007). This migration must reach the hosted project **before** the app update that uses it.
- The future web dashboard reads these tables directly with the user's Supabase session — no extra API needed.

### Configuration & secrets
- Supabase URL + publishable key: `Config/Secrets.xcconfig` (gitignored; template `Config/Secrets.example.xcconfig` committed) → Info.plist → read at startup.
- Edge Function secrets (Strava client secret, Apple Sign in private key): `supabase secrets set …`. Never in the repo, never in the app. `delete-account` needs `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY` (the `.p8` contents) and `APPLE_CLIENT_ID` (`com.stefanblos.OnlyWorkouts`). The `strava-*` functions need `STRAVA_CLIENT_ID` and `STRAVA_CLIENT_SECRET`; `strava-webhook` also `STRAVA_WEBHOOK_VERIFY_TOKEN` and `STRAVA_WEBHOOK_SUBSCRIPTION_ID`.
- Strava client ID (not secret): `STRAVA_CLIENT_ID` in `Config/Secrets.xcconfig` → Info.plist `StravaClientID`, for the consent page URL.
- Supabase Auth → Apple provider: enabled, client ID `com.stefanblos.OnlyWorkouts` (native sign-in only, no secret needed). Locally the same is in `supabase/config.toml`.
- A build without `Secrets.xcconfig` runs local-only; Settings says Cloud Sync isn't set up.

---

## 11. Apple Health

- **Write only.** Each Session is saved as an `HKWorkout` (`.traditionalStrengthTraining`, indoor), including heart rate and active energy when recorded on the Watch. No workouts are read from Health.
- Permission is requested in **onboarding** (M6, §7), on its own page with one **Continue** button. HealthKit shows its sheet only once per set of types, so the explanation before the **first Session start** remains only for people who left onboarding before that page; after any answer, changes happen in Settings or the Health app.
- Deleting a Session in the app also deletes the Health workout it created — on any device, also when the deletion arrives via sync. HealthKit lets an app delete only what it saved, so each device deletes the workouts of the Sessions it recorded: the iPhone right away (or after the next pull), the Watch when the tombstone reaches it in the plan snapshot (§8). The local `healthWorkoutID` is cleared once the workout is gone; until then a failed attempt (e.g. no Health access) is retried.
- Health-derived values (heart rate, calories) are shown in the app but **never leave the device** (not synced to Supabase) — keeps App Review simple (§14).

---

## 12. Strava (M4)

Apple Health does **not** forward third-party strength workouts to Strava, so OnlyWorkout uploads directly. See [ADR-0004](docs/adr/0004-strava-direct-upload-via-edge-functions.md) and the verified API details in [docs/research/strava-api.md](docs/research/strava-api.md).

1. **Connect** (Settings → Strava, needs Cloud Sync): `ASWebAuthenticationSession` opens `https://www.strava.com/oauth/mobile/authorize` with `scope=activity:write` only and a random `state`; Strava redirects to `onlyworkouts://onlyworkout.stefanblos.com/strava` (callback domain `onlyworkout.stefanblos.com` in the Strava API app). `StravaLink` checks `state` and that `activity:write` was granted, then hands the code to Edge Function **`strava-connect`**, which swaps it for tokens with the client secret and stores them in `strava_connections`.
2. **Build the upload** in the app: `StravaUpload` (Core) turns a finished Session into Strava's "Strength Training (Limited)" JSON — `version`, `start_time`, `utc_offset`, `elapsed_time`, `creator` and one entry per Set (`exercise_type`, `repetitions`, `weight` in kg, omitted at 0). Strava lists Sets in the order sent, so each exercise's Sets go together (in performed order), exercises in the order they were started; a Superset doesn't show interleaved. Sets of Exercises without a Strava type, or with one Strava doesn't know, are left out; a Session with no Set left isn't uploaded. Heart rate, calories and other Health data are never sent.
3. **Upload**: Edge Function **`strava-upload`** refreshes the token when it expires within the hour (always storing the newest refresh token), posts the file to `POST /uploads` with `data_type=json`, `sport_type=WeightTraining`, `name` = Workout name and `external_id` = Session ID, then polls `GET /uploads/{id}` once a second for up to 10 s. A "duplicate of activity N" answer counts as uploaded.
4. **Exercise types**: every catalog Exercise has a built-in Strava type (`ExerciseCatalog+Strava.swift`); a Custom Exercise gets one picked by the user from Strava's 656 types, or none. Strava derives its muscle map from these types.
5. **When**: with auto-upload on (the default), every Session finished after connecting is uploaded after each cloud sync — after it ends, when a Watch Session arrives, on launch and foreground; failures stay queued. Earlier Sessions, or all with auto-upload off, have "Upload to Strava" on Session detail.
6. **What is kept**: Strava's activity ID is Strava Data, which may be cached for 7 days at most (Strava API Policy §6.2). It stays on the iPhone that uploaded, never in Supabase, and is dropped after 7 days, so "View on Strava" shows for a week. The cloud keeps our own `strava_uploaded_at`, so no device uploads a Session twice.
7. **Disconnect**: Edge Function **`strava-disconnect`** revokes access with `POST /oauth/revoke` and deletes the row; `delete-account` does the same first. Edge Function **`strava-webhook`** answers Strava's subscription check and deletes an athlete's row when they revoke access on Strava's side (required by Strava's API terms).
8. **Capacity gate** (M5): Strava lets an API app connect a limited number of athletes (1 for a new app, 10 after the owner's self-upgrade, more only after Strava's review) and refuses everyone else on its own consent page, which the app can't detect ([docs/research/strava-athlete-capacity.md](docs/research/strava-athlete-capacity.md)). So the one-row table `strava_settings` holds the `athlete_capacity` Strava granted, and `strava_connect_open()` tells the app whether connecting can work (the caller is connected already, or fewer athletes are connected than the capacity). When it can't, Settings shows Strava as "Full for now" instead of the button. If Strava still refuses the token exchange for its athlete limit, `strava-connect` answers `athlete_limit` and the app says so.

**Owner setup:**
1. Create the API app at <https://www.strava.com/settings/api> (needs a Strava subscription): callback domain `onlyworkout.stefanblos.com`.
2. `STRAVA_CLIENT_ID = …` in `Config/Secrets.xcconfig`.
3. `supabase secrets set STRAVA_CLIENT_ID=… STRAVA_CLIENT_SECRET=… STRAVA_WEBHOOK_VERIFY_TOKEN=<random string>`, then `supabase db push` and `supabase functions deploy`.
4. Subscribe the webhook once: `curl -X POST https://www.strava.com/api/v3/push_subscriptions -F client_id=… -F client_secret=… -F callback_url=https://<project>.supabase.co/functions/v1/strava-webhook -F verify_token=<same string>`, then `supabase secrets set STRAVA_WEBHOOK_SUBSCRIPTION_ID=<returned id>`.
5. Keep the capacity at what Strava granted, in the SQL editor: `update public.strava_settings set athlete_capacity = 10;` (the migration starts at 1).

---

## 13. Project structure

```
OnlyWorkout.xcodeproj           # Xcode project using synchronized folders
OnlyWorkout/                    # iOS app — com.stefanblos.OnlyWorkouts
  App/                          # @main, root TabView, dependency setup
  Features/
    Onboarding/ (M6)  Today/  Workouts/  Recommendations/ (M8)  Exercises/  Session/  Summary/  History/  Progress/  Settings/
  Resources/                    # Assets (AccentColor), Localizable.xcstrings, PrivacyInfo.xcprivacy
OnlyWorkoutWatch/               # watchOS app — com.stefanblos.OnlyWorkouts.watchkitapp
  App/  Features/Home/  Features/Session/  Features/Summary/  Resources/
OnlyWorkoutWidgets/             # iOS widget extension: Live Activity
OnlyWorkoutWatchWidgets/        # watchOS widget extension: complication / Smart Stack
SharedUI/                       # compiled into both apps: Localizable.xcstrings + shared wording (offers, messages, titles)
OnlyWorkoutUITests/             # one UI test: the core Session flow
Packages/OnlyWorkoutKit/        # local Swift package
  Sources/
    OnlyWorkoutCore/            # pure domain: value types, progression, rotation, SessionEngine, stats, RecordMerger, messages. No Apple frameworks beyond Foundation.
    OnlyWorkoutStore/           # SwiftData @Model types, mapping to Core, Exercise Catalog seeding
    OnlyWorkoutConnectivity/    # WorkoutRecorder (HealthKit + mirroring), PhoneWatchLink (WatchConnectivity), MirrorMessage
    OnlyWorkoutSync/            # Supabase client, auth, push/pull (iOS only — the only module importing supabase-swift)
    OnlyWorkoutDesign/          # DesignTokens, shared components (rings, number views, celebration, Muscle Map shapes — M7)
    OnlyWorkoutIntelligence/    # M8, iOS only: the sole importer of FoundationModels; words Recommendation reasons (ADR-0008)
    OnlyWorkoutLiveActivity/    # ActivityAttributes shared by the app and the widget extension (iOS only)
  Tests/
    OnlyWorkoutCoreTests/  OnlyWorkoutStoreTests/  OnlyWorkoutSyncTests/  OnlyWorkoutIntelligenceTests/ (M8)
supabase/
  config.toml
  migrations/                   # schema, RLS, sync RPCs
  tests/database/               # pgTAP tests (`supabase test db`)
  functions/                    # delete-account, strava-connect, strava-upload, strava-disconnect, strava-webhook;
                                # _shared/ (Strava rules + Deno tests: `deno test --allow-env supabase/functions`)
Config/                         # Shared.xcconfig (team, includes Secrets.xcconfig — gitignored), Info.plists, entitlements
docs/adr/  docs/research/       # decisions; researched facts with sources
docs/release/                   # App Store listing, App Privacy answers and App Review notes
site/onlyworkout/               # Privacy Policy and Support pages, copied by the owner to stefanblos.com/onlyworkout/
design/icon/                    # app icon layers (source of AppIcon.icon), concepts, Icon Composer notes
design/muscle-map/              # Muscle Map anatomy generator, concepts and encoding (M7)
.github/workflows/ci.yml
```

- Package platforms: iOS 27, watchOS 27, macOS 27 (macOS only so `swift test` runs on the host without a simulator).
- App targets: default actor isolation `MainActor`, strict concurrency complete. `OnlyWorkoutCore` types are `Sendable` value types.
- One type per file; folders by feature.
- **Capabilities**: HealthKit (iOS + watchOS), Sign in with Apple (iOS), App Groups `group.com.stefanblos.OnlyWorkouts` (app ↔ widgets), Background Modes → Workout processing (watchOS and iOS). Strava's consent page redirects to `onlyworkouts://onlyworkout.stefanblos.com/strava`, caught by `ASWebAuthenticationSession` (no URL type registration needed).

---

## 14. App Store readiness (built in from day one)

What is still missing for a release, checked against Apple's current requirements: [docs/research/app-store-readiness.md](docs/research/app-store-readiness.md).

- **Account deletion** in Settings: the user confirms with Sign in with Apple once more; Edge Function `delete-account` swaps that fresh authorization code for a token, **revokes the Sign in with Apple token** (App Review guideline 5.1.1(v)), then deletes the auth user, which deletes all rows by cascade. No Apple tokens are stored. Local data stays on the device.
- Health: purpose strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`), Health data used only for the user's own tracking, never synced to the cloud or used for ads.
- `PrivacyInfo.xcprivacy` in each target's `Resources/` (UserDefaults reasons; the iPhone app also lists the data Cloud Sync and Strava send). `ITSAppUsesNonExemptEncryption = NO`: the only cryptography is OS-provided HTTPS and CryptoKit hashing.
- Privacy Policy and Support pages (`site/onlyworkout/`, live at `https://stefanblos.com/onlyworkout/privacy/` and `/support/`), linked from Settings. Sign in with Apple asks for no email (data minimisation).
- No secrets in the binary except the Supabase publishable key (which is public by design and protected by RLS).
- Strava: a new API app connects only its owner (capacity 1); the owner can self-upgrade to 10 athletes without review. Beyond 10 needs Strava's Developer Program review, which Strava only considers once all 10 slots are used; approval, granted capacity (up to 9,999 on the Standard tier) and timing are at Strava's discretion, and the owner's Strava subscription must stay active. See [docs/research/strava-athlete-capacity.md](docs/research/strava-athlete-capacity.md). Brand guidelines: official "Connect with Strava" button, "View on Strava" links, "Compatible with Strava" attribution, no "Strava" in the app's name or icon. The privacy policy must name what goes to Strava.
- Accessibility: Dynamic Type, VoiceOver labels on every icon-only control, Reduce Motion, 44 pt targets.

---

## 15. Open questions & risks

| # | Question | Plan |
|---|---|---|
| 1 | ~~Can the iPhone *start* a Live Activity in the background when a mirrored Watch Session begins?~~ | **Resolved (M2):** no. ActivityKit starts Live Activities only in the foreground, except via a `LiveActivityIntent` or an ActivityKit push. The iPhone starts it the next time the app is active during a Watch Session. Push-to-start from a Supabase function is possible after M3. |
| 2 | ~~Exact Strava API for structured strength uploads and its exercise-type list~~ | **Resolved (M4):** `POST /uploads` with `data_type=json` (Strava's "Strength Training (Limited)" file) and 656 exercise types; see [docs/research/strava-api.md](docs/research/strava-api.md). |
| 3 | Strava muscle map reportedly inconsistent for API uploads | Accept. Strava derives muscles from each Set's exercise type (the upload has no muscle-group field); a Strava staff member acknowledged the July 2026 report without a fix. On the owner's account the map showed correctly for the first test upload (M4). Our own stats keep the Muscle Groups. |
| 4 | ~~Undocumented upload details~~ | **Resolved (M4, tried on the owner's account):** Strava shows `weight` exactly as sent and its own logging doesn't say whether dumbbell weight is per hand, so we keep sending it per dumbbell as stored. A bodyweight Set without weight shows as plain bodyweight, Added Weight as that weight. Strava lists Sets in the order sent, so we group them per exercise. Exercises without a Strava type don't appear. Muscle map, title, elapsed time, volume, Set and rep totals all came through. Watch Sessions upload too; with auto-upload off nothing is uploaded. Duplicate detection is untested (no way to re-upload from the app). |
| 5 | Apple Health permission in onboarding goes against a HIG "should" (ask when needed) | Accept (owner's call, M6): page after the tour, one neutral button, never blocks on "no"; research says no review rule forbids it. Watch App Review feedback. |
| 6 | Catalog revision vs. old app versions (M7) | Hosted migration first (legacy `shoulders` allowed), then the app; old versions skip unknown Muscle Groups without losing them (ADR-0007). |
| 7 | Foundation Models output quality changes with each OS model update; only about half of devices have Apple Intelligence | Handwritten reasons are the primary experience; model text is checked, labelled and optional; opt-in evaluation suite re-run on each iOS x.y (ADR-0008). |
| 8 | Recommendations read as health advice | Neutral wording, no claims beyond the research (training-templates.md §6); review copy before M8 ships. Age rating stays 9+ (Health or Wellness Topics). |

---

## 16. Milestones

Each milestone ships a usable app. Build test-first (`mattpocock-skills:tdd`) for everything in `OnlyWorkoutCore`.

### M1 — iPhone app, local only
**Status:** merged into `main` (DaemonLoki/WorkoutApp#1); the "Done when" flow is covered by `SessionFlowUITests`.

- Project bootstrap: Xcode project with iOS app, widget extension and UI-test targets (Watch targets can be added in M2); local package; `Localizable.xcstrings`; `AccentColor`; `Config/Secrets.example.xcconfig`; `.swift-format`; CI workflow (`swift test` on the package, build both apps, `swift-format lint`).
- Core: domain types, progression rules (§4), Rotation (§5), SessionEngine (§6), stats, messages, RecordMerger — all with tests.
- Store: SwiftData models, Exercise Catalog seed (§17) on first launch.
- UI: Today (incl. Ready to Step Up), Workouts + editors, Exercises, Active Session (iPhone primary), Summary with celebration, Progress + detail charts, Session history, Settings shell.
- Live Activity + rest-end notification for iPhone Sessions.
- **Done when**: a full Session incl. a Superset can be run on the iPhone, a Target Hit produces a Step Up card and a Ready to Step Up row, a synthetic Stall and Layoff produce Step Downs, and the Progress chart shows the history.

### M2 — Apple Watch + Health
**Status:** merged into `main` (DaemonLoki/WorkoutApp#2). Verified in paired simulators: plan reaches the Watch, a full Session incl. Step Up runs on the Watch with the iPhone off, and the result (weights, pending Step Ups) appears on the iPhone. Not verifiable in the simulator without granting Health access: saving to Health, heart rate, mirroring to the iPhone and starting on the Watch from the iPhone — try these on devices.

- Spike: open question #1.
- watchOS app + widget extension; plan snapshot sync and Session transfer via WatchConnectivity.
- HealthKit on both devices; Watch as primary with mirroring; iPhone as mirrored controller; Live Activity for Watch Sessions.
- **Done when**: with the iPhone switched off, a full Session runs on the Watch incl. Step Up prompt; it appears on the iPhone and in Health once the phone is back.

### M3 — Supabase sync
**Status:** merged into `main` (DaemonLoki/WorkoutApp#3). Tested: schema, RLS and sync RPCs (pgTAP, `supabase test db`), push/pull bookkeeping in the store, `CloudSync` against a fake backend, the cloud JSON format, and `delete-account` on the local stack. The owner tried sign-in and sync with the hosted project on a device.

- `supabase/` project, migrations (schema, RLS, `sync_push`, `sync_pull`), `delete-account` function.
- Sign in with Apple, push/pull, account deletion incl. token revocation.
- **Done when**: delete the app, reinstall, sign in → all data returns without duplicates; rows are visible in the Supabase dashboard and nobody else's are.

### M4 — Strava
**Status:** merged into `main` (DaemonLoki/WorkoutApp#8). Tested: the upload file and exercise-type list (Core), the catalog mapping, upload queue and 7-day activity-ID expiry (Store), `StravaLink` against a fake backend, the `strava_connections` table and RPCs (pgTAP), and the Strava rules in the Edge Functions (Deno tests with a stubbed fetch). On a device the owner connected Strava, uploaded test Sessions from the iPhone and the Watch, and checked that nothing is uploaded with auto-upload off (see §15 #4).

- Resolve open questions #2–3; `strava-connect`, `strava-upload`, `strava-disconnect`; Exercise → Strava type mapping; Settings UI; auto-upload.
- **Done when**: finishing a Session creates a Strava WeightTraining activity with every Set.

### After M4 — feedback rounds
The owner's feedback from using the app is tracked as GitHub issues and shipped in rounds: round 1 (DaemonLoki/WorkoutApp#13: History tab, deleting a Session also deletes its Health workout, Superset preview, start a Session from the Workout editor or on the Watch) and round 2 (DaemonLoki/WorkoutApp#16: Rest Timer that can be turned off, rep Step Ups, collapsible Ready to Step Up).

### M5 — App Store readiness
**Status:** code merged into `main` (DaemonLoki/WorkoutApp#30); the owner's tasks (#26–#29) remain, and the submission (#29) now waits for M6, which ships in 1.0. GitHub milestone "M5 — App Store readiness" (DaemonLoki/WorkoutApp#17–#29). Research: [docs/research/app-store-readiness.md](docs/research/app-store-readiness.md), [docs/research/strava-athlete-capacity.md](docs/research/strava-athlete-capacity.md).

- In code: privacy manifests for every target (#17); export compliance key, version 1.0, `-sampleData` in Debug only (#18); Privacy Policy and Support pages in `site/`, linked in Settings (#19); Health purpose strings mention calories (#20); no email scope at Sign in with Apple (#21); Strava capacity gate and athlete-limit message (#22); accessibility pass (#23); app icon `AppIcon.icon` (concept A, the Step Up plate; #24); App Store listing and review notes in `docs/release/` (#25).
- Owner: Strava capacity check, self-upgrade and Developer Program application (#26); hosted Supabase ready for review (#27); device check (#28); App Store Connect record, screenshots, TestFlight and submission (#29).
- **Done when**: a TestFlight build uploads without App Store Connect warnings, and the app passes App Review with Strava behind the capacity gate.

### M6 — Onboarding (ships in 1.0)
**Status:** planned; GitHub milestone "M6 — Onboarding" (DaemonLoki/WorkoutApp#31–#38). The 1.0 submission (DaemonLoki/WorkoutApp#29) waits for it. Research: [docs/research/onboarding-and-permissions.md](docs/research/onboarding-and-permissions.md). Spec: §7 Onboarding, §11.

- **Gate and shell**: fresh-install check at launch (before the Watch link activates), device-local `hasCompletedOnboarding`, `-uiTesting` skips it, `-onboarding` forces it in Debug, Settings → About → Welcome Tour replays the tour.
- **Tour pages 1–4** from live components with sample values. Components that today need a running Session (Set view, Rest) get a sample-value initialiser, not a fake engine. Motion per `DesignTokens`; Reduce Motion, Dynamic Type and VoiceOver on every page.
- **Restore page**: the Sign in with Apple button and nonce handling move out of `CloudSyncSection` into one shared view; Start Fresh; restoring continues in the background.
- **Apple Health and Rest-alert pages**: one Continue each, skipped when already determined; the official Apple Health icon replaces the heart glyph here and in `HealthExplanationView`.
- **Rest alerts**: add the Time Sensitive Notifications capability. `RestNotifier` already marks alerts `.timeSensitive`, but without the capability they don't break through Focus (research §3).
- **End destination** (Today vs. the Workout editor); docs: App Review notes in `docs/release/app-store-listing.md` say Apple Health is asked in onboarding.
- **Test seams**: no new domain logic, so no Core tests. Verified with a preview per page and state, a temporary UI test walking the flow on a fresh simulator (deleted afterwards), and the Session-flow UI test (onboarding skipped).
- **Owner**: download the Apple Health icon from Apple's resources and check its terms; device check of a fresh install and of a reinstall with restore, with the Watch paired.
- **Done when**: a fresh install shows the tour; Restore brings everything back without duplicates; the Apple Health and notification sheets each appear once, from their pages; a finished or skipped onboarding never comes back by itself but replays from Settings; and the 1.0 build with onboarding is submitted (#29).

### M7 — Muscle Map (1.1)
**Status:** planned; GitHub milestone "M7 — Muscle Map" (DaemonLoki/WorkoutApp#39–#48). Concepts drafted for the owner to pick: [design/muscle-map/](design/muscle-map/). Research: [docs/research/exercise-muscle-data.md](docs/research/exercise-muscle-data.md). Decision: [ADR-0007](docs/adr/0007-delts-secondary-muscle-groups-and-catalog-revisions.md). Spec: §3, §7, §9, §10, §17.

- **Artwork**: the owner picks a concept. The anatomy is refined in `design/muscle-map/generate.py`, which also emits the SwiftUI `Path` code, so drawing and app never drift. `MuscleMap` view in `OnlyWorkoutDesign` (compact/full, selection, legend, accessibility); colour steps per appearance in `DesignTokens`.
- **Core**: 18 Muscle Groups with legacy `shoulders` decoding; `Emphasis` (Sets → share per Muscle Group → step, plus the groups the text summary names).
- **Data**: `secondaryMuscleGroups` on Exercise (model, record, `CloudCoding`, migration with the 18 + legacy check, pgTAP); catalog revisions (ADR-0007) and the first revision (the 44 revised per §17); Custom Exercises' `shoulders` rewritten once.
- **UI**: Exercise rows, the new Exercise detail and the Custom Exercise editor (Secondary Muscle Groups picker with a live map); Workout editor header; Next Up card; Session Summary; Progress → Muscle Coverage; every Muscle Group filter lists the 18.
- **Release order**: the hosted migration runs **before** the app update ships (ADR-0007), the opposite of M4/M5.
- **Test seams** (to confirm at the start, `tdd`):
  - Core: `Emphasis` (half weight for Secondary, normalisation, step thresholds, empty input, extras count for Sessions); `MuscleGroup` legacy decoding.
  - Store: a catalog revision rewrites changed rows once with its date, leaves newer rows alone, is idempotent, and two stores converge after merging; the `shoulders` rewrite; record round trip.
  - Sync: `CloudCoding` of the new column.
  - pgTAP: the column and constraint (18 + legacy accepted, unknown rejected), `sync_push`/`sync_pull` carry it.
- **Owner**: pick the concept; run the hosted migration first; check maps against his own Workouts on device.
- **Done when**: every Exercise, Workout, Next Up card, Session Summary and Progress show a Muscle Map whose Emphasis matches §9; a Push and a Pull Workout are told apart at a glance; and after the update, the owner's catalog Exercises carry the revised Muscle Groups on the iPhone, the Watch and in Supabase, without duplicates or sync loops.

### M8 — Recommendations (1.2)
**Status:** planned; GitHub milestone "M8 — Recommendations" (DaemonLoki/WorkoutApp#49–#58). Research: [docs/research/training-templates.md](docs/research/training-templates.md), [docs/research/foundation-models.md](docs/research/foundation-models.md). Decision: [ADR-0008](docs/adr/0008-rules-choose-recommendations-the-on-device-model-only-words-reasons.md). Spec: §3, §7 Recommendations, §10, §17.

- **Catalog**: a second revision adds the 49 Exercises of §17 with Strava types and Each Side. `eachSide` is a synced column; Custom Exercises get a toggle. "each side" appears in Target text on iPhone, Watch and Live Activity.
- **Focus**: a synced `focus` column on Workouts; the Focus row in the Workout editor.
- **Core rules**:
  - Focus, Training Goal and Equipment Access.
  - Blueprints and Focus coverage (research §2, §5).
  - Targets per Training Goal and role (§3.6, §3.7), plus the split table (§4).
  - Bodyweight rep floors.
  - The Session-length estimate and trimming (§1.5), and Superset rules (§2.3).
  - The `Recommender` (Exercises and Gaps for a Workout, a whole Workout, a whole Rotation), with facts and reason codes for every Recommendation.
- **Store**: add recommended Exercises, Workouts or a Rotation with weights and links (ADR-0006); Replace My Workouts; Equipment Access stored on the device.
- **`OnlyWorkoutIntelligence`**: the `ReasonWriter` seam with a Foundation Models adapter and a template adapter, output checks, the Settings toggle and the label. The module also goes into AGENTS.md, CI and the swift-format paths.
- **UI**: Recommended and Gaps sections in the Workout editor; the `+` menu flows with preview and review; Recommend a Rotation on Today's empty state and at the end of onboarding.
- **Release order**: the hosted migration (`focus`, `each_side` with checks) runs before the app update ships.
- **Test seams** (to confirm at the start, `tdd`):
  - Core:
    - A Blueprint filled per Equipment Access, with Gaps instead of invented Exercises.
    - Targets per Training Goal and role; rep floors.
    - Trimming to 45–75 min; Superset pairing rules.
    - Split per Training Goal × 2–6 Weekly Sessions (Running ≤ 3, Cycling ≤ 2 Workouts).
    - Linking the same Exercise across a Rotation; reason codes.
    - Catalog consistency: every Blueprint candidate exists in the catalog with a fitting Equipment, every Strava type is one of the 656, at most 3 + 3 Muscle Groups.
  - Store: Add and Replace (soft delete, Next Up), weights, links.
  - Intelligence: `ReasonProvider` against fake writers. The model's text is used only when it passes the checks; every unavailability reason, error, timeout and failed check falls back to the template. Opt-in model tests only on an eligible Mac or device.
  - pgTAP: the new columns and checks.
- **Owner**: review the reasons and notes copy; try with Apple Intelligence on and off on an eligible iPhone.
- **Done when**:
  - Choosing a Focus on an empty Workout fills it sensibly at every Equipment Access.
  - A Workout missing a required Muscle Group shows that Gap with an Exercise to add.
  - Recommend a Rotation, for every Training Goal and 2–6 Weekly Sessions, adds or replaces Workouts that fit 45–75 min and cover their Focus, with weights and links.
  - Reasons read well with Apple Intelligence on and off.

---

## 17. Exercise Catalog (seed)

Shipped with deterministic UUIDs (UUIDv5 of the key). Muscle Groups are prime movers (1–3); Secondary Muscle Groups count half (0–3); Each Side marks one-sided Exercises. Dumbbell weights are **per dumbbell**. Strava types are exact values from Strava's 656 (§12).

The table is the **planned** catalog: 44 Exercises since M1, 34 of them revised by the M7 catalog revision (the Delt split plus evidence-based corrections, e.g. Triceps becomes secondary in Bench Press and Biceps in Pull-up and Lat Pulldown), and 49 added by the M8 revision, 93 in all. Sources and the evidence per row: [docs/research/exercise-muscle-data.md](docs/research/exercise-muscle-data.md) (Muscle Groups, Strava types) and [docs/research/training-templates.md](docs/research/training-templates.md) §5.10 (which Blueprints need them). Before M7 ships, `ExerciseCatalog.swift` still holds the M1 values.

Two deliberate holes: no rep-based Exercise trains Side Delts, Traps or Forearms as a prime mover with Bodyweight Only (they appear only as Secondary there). Left out on purpose: timed holds and carries (non-goals), Upright Row and Power Clean (unfriendly to beginners), medicine-ball throws (no such Equipment).

| Key | Name | Equipment | Muscle Groups | Secondary Muscle Groups | Each side | Strava type | Since |
|---|---|---|---|---|---|---|---|
| barbell-bench-press | Bench Press | barbell | Chest | Front Delts, Triceps |  | `BARBELL_BENCH_PRESS` | M1, revised M7 |
| incline-dumbbell-press | Incline Dumbbell Press | dumbbell | Chest, Front Delts | Triceps |  | `INCLINE_DUMBBELL_BENCH_PRESS` | M1, revised M7 |
| dumbbell-bench-press | Dumbbell Bench Press | dumbbell | Chest | Front Delts, Triceps |  | `DUMBBELL_BENCH_PRESS` | M1, revised M7 |
| machine-chest-press | Machine Chest Press | machine | Chest | Front Delts, Triceps |  | `MACHINE_CHEST_PRESS` | M1, revised M7 |
| cable-fly | Cable Fly | cable | Chest | Front Delts |  | `CABLE_CROSSOVER` | M1, revised M7 |
| push-up | Push-up | bodyweight | Chest | Front Delts, Triceps |  | `PUSH_UP_GENERIC` | M1, revised M7 |
| dip | Dip | bodyweight | Chest, Triceps | Front Delts |  | `CHEST_DIP` | M1, revised M7 |
| pull-up | Pull-up | bodyweight | Lats | Biceps, Upper Back, Forearms |  | `PULL_UP_GENERIC` | M1, revised M7 |
| chin-up | Chin-up | bodyweight | Lats, Biceps | Upper Back, Forearms |  | `CLOSE_GRIP_CHIN_UP` | M1, revised M7 |
| lat-pulldown | Lat Pulldown | cable | Lats | Biceps, Upper Back |  | `LAT_PULLDOWN` | M1, revised M7 |
| seated-cable-row | Seated Cable Row | cable | Upper Back, Lats | Biceps, Rear Delts |  | `SEATED_CABLE_ROW` | M1, revised M7 |
| barbell-row | Barbell Row | barbell | Upper Back, Lats | Rear Delts, Biceps, Lower Back |  | `BENT_OVER_BARBELL_ROW` | M1, revised M7 |
| one-arm-dumbbell-row | One-Arm Dumbbell Row | dumbbell | Lats, Upper Back | Biceps, Rear Delts | ✓ | `DUMBBELL_ROW` | M1, revised M7 |
| chest-supported-row | Chest-Supported Row | machine | Upper Back | Lats, Rear Delts, Biceps |  | `MACHINE_CHEST_SUPPORTED_ROW` | M1, revised M7 |
| face-pull | Face Pull | cable | Rear Delts, Upper Back | Side Delts |  | `FACE_PULL` | M1, revised M7 |
| deadlift | Deadlift | barbell | Glutes, Hamstrings, Lower Back | Quads, Adductors, Traps |  | `BARBELL_DEADLIFT` | M1, revised M7 |
| back-extension | Back Extension | bodyweight | Lower Back, Glutes | Hamstrings |  | `BACK_EXTENSION` | M1, revised M7 |
| overhead-press | Overhead Press | barbell | Front Delts, Side Delts | Triceps |  | `OVERHEAD_BARBELL_PRESS` | M1, revised M7 |
| seated-dumbbell-press | Seated Dumbbell Shoulder Press | dumbbell | Front Delts, Side Delts | Triceps |  | `SEATED_DUMBBELL_SHOULDER_PRESS` | M1, revised M7 |
| lateral-raise | Lateral Raise | dumbbell | Side Delts | Front Delts, Traps |  | `LATERAL_RAISE_GENERIC` | M1, revised M7 |
| rear-delt-fly | Rear Delt Fly | machine | Rear Delts | Upper Back |  | `MACHINE_REAR_DELT_REVERSE_FLY` | M1, revised M7 |
| dumbbell-shrug | Dumbbell Shrug | dumbbell | Traps | — |  | `DUMBBELL_SHRUG` | M1 |
| barbell-curl | Barbell Curl | barbell | Biceps | Forearms |  | `BARBELL_BICEPS_CURL` | M1, revised M7 |
| dumbbell-curl | Dumbbell Curl | dumbbell | Biceps | Forearms |  | `STANDING_DUMBBELL_BICEPS_CURL` | M1, revised M7 |
| hammer-curl | Hammer Curl | dumbbell | Biceps, Forearms | — |  | `DUMBBELL_HAMMER_CURL` | M1 |
| triceps-pushdown | Triceps Pushdown | cable | Triceps | — |  | `CABLE_TRICEPS_PUSHDOWN` | M1 |
| overhead-triceps-extension | Overhead Triceps Extension | cable | Triceps | — |  | `CABLE_OVERHEAD_TRICEPS_EXTENSION` | M1 |
| skull-crusher | Skull Crusher | barbell | Triceps | — |  | `SKULL_CRUSHER` | M1 |
| back-squat | Back Squat | barbell | Quads, Glutes | Adductors |  | `BARBELL_BACK_SQUAT` | M1, revised M7 |
| front-squat | Front Squat | barbell | Quads | Glutes, Adductors |  | `BARBELL_FRONT_SQUAT` | M1, revised M7 |
| goblet-squat | Goblet Squat | kettlebell | Quads, Glutes | Adductors |  | `GOBLET_SQUAT` | M1, revised M7 |
| leg-press | Leg Press | machine | Quads, Glutes | Adductors |  | `MACHINE_LEG_PRESS` | M1, revised M7 |
| romanian-deadlift | Romanian Deadlift | barbell | Hamstrings, Glutes | Lower Back, Adductors |  | `BARBELL_ROMANIAN_DEADLIFT` | M1, revised M7 |
| bulgarian-split-squat | Bulgarian Split Squat | dumbbell | Quads, Glutes | Adductors | ✓ | `DUMBBELL_BULGARIAN_SPLIT_SQUATS` | M1, revised M7 |
| walking-lunge | Walking Lunge | dumbbell | Quads, Glutes | Adductors | ✓ | `DUMBBELL_WALKING_LUNGES` | M1, revised M7 |
| leg-extension | Leg Extension | machine | Quads | — |  | `MACHINE_LEG_EXTENSION` | M1 |
| leg-curl | Leg Curl | machine | Hamstrings | — |  | `LEG_CURL_GENERIC` | M1 |
| hip-thrust | Hip Thrust | barbell | Glutes | Hamstrings, Quads |  | `BARBELL_HIP_THRUST` | M1, revised M7 |
| hip-adduction | Hip Adduction | machine | Adductors | — |  | `MACHINE_HIP_ADDUCTION` | M1 |
| standing-calf-raise | Standing Calf Raise | machine | Calves | — |  | `STANDING_CALF_RAISE` | M1 |
| seated-calf-raise | Seated Calf Raise | machine | Calves | — |  | `SEATED_CALF_RAISE` | M1 |
| hanging-leg-raise | Hanging Leg Raise | bodyweight | Abs | Obliques |  | `HANGING_LEG_RAISE` | M1, revised M7 |
| cable-crunch | Cable Crunch | cable | Abs | Obliques |  | `CABLE_CRUNCH` | M1, revised M7 |
| ab-wheel-rollout | Ab Wheel Rollout | bodyweight | Abs, Obliques | Lats |  | `AB_WHEEL_ROLLOUT` | M1, revised M7 |
| incline-bench-press | Incline Bench Press | barbell | Chest, Front Delts | Triceps |  | `INCLINE_BARBELL_BENCH_PRESS` | M8 |
| close-grip-bench-press | Close-Grip Bench Press | barbell | Triceps, Chest | Front Delts |  | `CLOSE_GRIP_BARBELL_BENCH_PRESS` | M8 |
| pike-push-up | Pike Push-up | bodyweight | Front Delts | Triceps, Side Delts |  | `PIKE_PUSH_UP` | M8 |
| cable-lateral-raise | Cable Lateral Raise | cable | Side Delts | Front Delts, Traps | ✓ | `CABLE_LATERAL_RAISE` | M8 |
| dumbbell-rear-delt-fly | Dumbbell Rear Delt Fly | dumbbell | Rear Delts | Upper Back, Side Delts |  | `DUMBBELL_REAR_DELT_FLY` | M8 |
| inverted-row | Inverted Row | bodyweight | Upper Back, Lats | Rear Delts, Biceps |  | `INVERTED_ROW` | M8 |
| dumbbell-pullover | Dumbbell Pullover | dumbbell | Chest, Lats | Triceps |  | `DUMBBELL_PULLOVER` | M8 |
| incline-dumbbell-curl | Incline Dumbbell Curl | dumbbell | Biceps | Forearms |  | `INCLINE_DUMBBELL_BICEPS_CURL` | M8 |
| cable-curl | Cable Curl | cable | Biceps | Forearms |  | `CABLE_BICEPS_CURL` | M8 |
| dumbbell-overhead-triceps-extension | Dumbbell Overhead Triceps Extension | dumbbell | Triceps | — |  | `OVERHEAD_DUMBBELL_TRICEPS_EXTENSION` | M8 |
| wrist-curl | Wrist Curl | dumbbell | Forearms | — |  | `DUMBBELL_WRIST_CURL` | M8 |
| dumbbell-romanian-deadlift | Dumbbell Romanian Deadlift | dumbbell | Hamstrings, Glutes | Lower Back, Adductors |  | `DUMBBELL_ROMANIAN_DEADLIFTS` | M8 |
| single-leg-romanian-deadlift | Single-Leg Romanian Deadlift | dumbbell | Hamstrings, Glutes | Adductors, Lower Back | ✓ | `SINGLE_LEG_DUMBBELL_ROMANIAN_DEADLIFTS` | M8 |
| nordic-hamstring-curl | Nordic Hamstring Curl | bodyweight | Hamstrings | — |  | `NORDIC_CURL` | M8 |
| step-up | Step-up | dumbbell | Quads, Glutes | Adductors, Hamstrings | ✓ | `STEP_UP` | M8 |
| copenhagen-adduction | Copenhagen Adduction | bodyweight | Adductors | Obliques | ✓ | `LL_COPENHAGEN_PLANK` | M8 |
| single-leg-calf-raise | Single-Leg Calf Raise | bodyweight | Calves | — | ✓ | `SINGLE_LEG_STANDING_CALF_RAISE` | M8 |
| box-jump | Box Jump | bodyweight | Quads, Glutes | Calves |  | `BOX_JUMP` | M8 |
| jump-squat | Jump Squat | bodyweight | Quads, Glutes | Calves |  | `BODY_WEIGHT_JUMP_SQUAT` | M8 |
| kettlebell-swing | Kettlebell Swing | kettlebell | Glutes, Hamstrings | Lower Back |  | `KETTLEBELL_SWING` | M8 |
| pallof-press | Pallof Press | cable | Obliques | Abs | ✓ | `PALLOF_PRESS` | M8 |
| dumbbell-side-bend | Dumbbell Side Bend | dumbbell | Obliques | Lower Back | ✓ | `DUMBBELL_SIDE_BEND` | M8 |
| bicycle-crunch | Bicycle Crunch | bodyweight | Abs, Obliques | — | ✓ | `BICYCLE_CRUNCH` | M8 |
| decline-push-up | Decline Push-up | bodyweight | Chest, Front Delts | Triceps |  | `DECLINE_PUSH_UP` | M8 |
| dumbbell-fly | Dumbbell Fly | dumbbell | Chest | Front Delts |  | `DUMBBELL_FLYE` | M8 |
| bench-dip | Bench Dip | bodyweight | Triceps | Chest, Front Delts |  | `BENCH_DIP` | M8 |
| chest-supported-dumbbell-row | Chest-Supported Dumbbell Row | dumbbell | Upper Back, Lats | Rear Delts, Biceps |  | `CHEST_SUPPORTED_ROW` | M8 |
| reverse-curl | Reverse Curl | barbell | Forearms, Biceps | — |  | `BARBELL_REVERSE_CURL` | M8 |
| bodyweight-squat | Bodyweight Squat | bodyweight | Quads, Glutes | Adductors |  | `AIR_SQUAT` | M8 |
| split-squat | Split Squat | bodyweight | Quads, Glutes | Adductors | ✓ | `STATIC_LUNGE` | M8 |
| single-leg-glute-bridge | Single-Leg Glute Bridge | bodyweight | Glutes | Hamstrings | ✓ | `SINGLE_LEG_GLUTE_BRIDGE` | M8 |
| lateral-bound | Lateral Bound | bodyweight | Glutes, Quads | Adductors, Calves | ✓ | `LATERAL_LEAP_AND_HOP` | M8 |
| pogo-jump | Pogo Jump | bodyweight | Calves | — |  | `POGO_JUMPS` | M8 |
| plyometric-push-up | Plyometric Push-up | bodyweight | Chest | Triceps, Front Delts |  | `CLAP_PUSH_UPS` | M8 |
| push-press | Push Press | barbell | Front Delts, Side Delts | Triceps, Quads |  | `BARBELL_PUSH_PRESS` | M8 |
| crunch | Crunch | bodyweight | Abs | — |  | `CRUNCH` | M8 |
| dead-bug | Dead Bug | bodyweight | Abs | — | ✓ | `DEADBUG` | M8 |
| bird-dog | Bird Dog | bodyweight | Lower Back, Glutes | Abs | ✓ | `BIRD_DOG` | M8 |
| cable-woodchop | Cable Woodchop | cable | Obliques | Abs | ✓ | `CABLE_WOODCHOP` | M8 |
| pec-deck | Pec Deck | machine | Chest | Front Delts |  | `PEC_DECK_BUTTERFLY` | M8 |
| diamond-push-up | Diamond Push-up | bodyweight | Triceps, Chest | Front Delts |  | `DIAMOND_PUSH_UP` | M8 |
| prone-t-raise | Prone T Raise | bodyweight | Rear Delts, Upper Back | — |  | `FLOOR_T_RAISE` | M8 |
| straight-arm-pulldown | Straight-Arm Pulldown | cable | Lats | Triceps, Rear Delts |  | `STRAIGHT_ARM_PULLDOWN` | M8 |
| preacher-curl | Preacher Curl | barbell | Biceps | Forearms |  | `EZ_BAR_PREACHER_CURL` | M8 |
| hack-squat | Hack Squat | machine | Quads, Glutes | Adductors |  | `MACHINE_HACK_SQUAT` | M8 |
| good-morning | Good Morning | barbell | Hamstrings, Glutes | Lower Back, Adductors |  | `BARBELL_GOOD_MORNING` | M8 |
| glute-bridge | Glute Bridge | bodyweight | Glutes | Hamstrings |  | `GLUTE_BRIDGE` | M8 |
| hip-abduction | Hip Abduction | machine | Glutes | — |  | `MACHINE_HIP_ABDUCTION` | M8 |
| reverse-lunge | Reverse Lunge | bodyweight | Quads, Glutes | Adductors | ✓ | `REVERSE_LUNGE` | M8 |
