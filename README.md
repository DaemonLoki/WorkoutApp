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
8. **Integrations** → Sessions saved to Apple Health; Sessions (with every Set and muscle groups) uploaded to Strava.
9. **Technical**: native, offline-first, Watch works standalone, database reachable by other tech (future web dashboard).
10. **Design**: minimal but functional, beautiful, enjoyable, motivating — celebrate progress with animation and specific, number-backed messages.

### Non-goals (deliberately out of scope)

Cardio/GPS tracking · timed Exercises (planks) · rep ranges / RPE / percentage-based programs · AI coaching or generated text · social features · pounds (kg only) · iPad/Mac apps · reading workouts *from* Health · body-weight/nutrition tracking · streaks · the web dashboard itself (only the database is designed for it).

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
| muscleGroups | [MuscleGroup] | primary muscle groups, 1–3 |
| catalogKey | String? | set for Exercise Catalog entries (e.g. `barbell-back-squat`); nil for Custom Exercises |
| stravaExerciseType | String? | mapping to Strava's exercise type (filled in M4) |
| archivedAt | Date? | "Deleting" an Exercise that has history archives it |

`isBodyweight` is derived: `equipment == .bodyweight`. Weight is then **Added Weight**.

**MuscleGroup** (fixed): Chest, Lats, Upper Back, Lower Back, Traps, Shoulders, Biceps, Triceps, Forearms, Abs, Obliques, Glutes, Quads, Hamstrings, Adductors, Calves.

### Workout
| Field | Type | Notes |
|---|---|---|
| name | String | e.g. "Pull Day" |
| rotationIndex | Int | position in the Rotation; the Workouts list order *is* the Rotation |

### Planned Exercise
| Field | Type | Default | Notes |
|---|---|---|---|
| workoutID | UUID | | |
| exerciseID | UUID | | |
| position | Int | | order within the Workout |
| supersetID | UUID? | nil | two adjacent Planned Exercises sharing an id form a Superset (max 2) |
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
| stravaActivityID | Int64? | M4 |

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
| fromWeight, toWeight | Double | |
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
- After a Target Hit, immediately after the last planned Set, a **Step Up card** appears during Rest (iPhone and Watch): **"Step Up to 42.5 kg"** / **"Not yet"**.
- **Step Up** → Planned Exercise `weight += weightStep`, suggestion `accepted`, celebration (§9).
- **Not yet** → suggestion stays `pending` and appears in **Ready to Step Up** on the iPhone Today screen until accepted, dismissed, or superseded by the next Session of that Planned Exercise.
- Every subsequent Target Hit creates a fresh Step Up offer (still at `weight + weightStep`).

### Step Down — Stall
Let S1, S2, S3 be the three most recent Sessions of the Planned Exercise (oldest first). It is a **Stall** when all three were at the current weight, none was a Target Hit, and neither S2 nor S3 set a new best total reps:
`total(S2) ≤ total(S1)` and `total(S3) ≤ max(total(S1), total(S2))`.

Examples (3×12 Target, same weight): totals `30, 28, 29` → Stall. `28, 30, 30` → no Stall (S2 improved). `30, 31, 33` → no Stall (still progressing).

Offered the same way as a Step Up (card after last Set + Ready list). If declined, it is offered again after the next Session in which the rule still holds (sliding window).

### Step Down — Layoff
When a Session reaches a Planned Exercise whose last performed Session is **more than 21 days** ago, a card appears **before its first Set**: "It's been 5 weeks — start at 57.5 kg?" Accepting lowers the Planned Exercise's weight *and* this Session's Target weight.

### Constraints
- Step Down never goes below 0 kg (`max(0, weight − weightStep)`).
- Thresholds (3 Sessions, 21 days) are constants in v1, not user settings.
- Skipped Session Exercises neither count as performed (Layoff) nor as misses (Stall).

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

### Events
| Event | Effect |
|---|---|
| `completeSet(reps, weight)` | Logs a Set (prefilled with Target reps/weight; adjusting is optional), starts Rest |
| `skipRest` / `extendRest(+30 s)` | |
| `skip(plannedExercise)` | Marks Session Exercise `skipped` |
| `doLater(plannedExercise)` | Moves it (or its whole Superset) to the end of the queue |
| `addExtraSet(plannedExercise)` | Appends one Set with `isExtra = true` |
| `editSet(set, reps, weight)` | Corrects a logged Set; Target Hit is re-evaluated |
| `answer(suggestion, accept)` | Step Up / Step Down decision |
| `end()` | Ends the Session (early is fine); remaining Exercises stay `pending` |

Not in v1: swapping an Exercise, adding an Exercise that isn't in the Workout.

### Primary device
The device running the Session (**Watch** when available, otherwise iPhone) owns the engine and persists the Session. The other device only *displays* live state and sends *commands* (e.g. tapping Done on the phone) through the mirrored workout session. Only the primary device writes the Session record, so there are never duplicates.

- Starting on iPhone with a reachable Watch → `HKHealthStore.startWatchApp(toHandle:)` launches the Session on the Watch; the Watch mirrors it back to the iPhone (`startMirroringToCompanionDevice`).
- Starting on iPhone without a reachable Watch → iPhone is primary (iOS `HKWorkoutSession`, no heart rate).
- Starting on the Watch → Watch is primary; iPhone gets the mirrored session in the background.

### Persistence & recovery
The in-progress Session is saved after every event. After a crash/termination, the app resumes it (Watch: `HKHealthStore.recoverActiveWorkoutSession`). A Session left unfinished for 6 h is auto-ended at its last Set's time.

---

## 7. iPhone app

Three tabs (`Tab` API) with specific labels: **Today**, **Workouts**, **Progress**. Settings is a sheet from Today's toolbar.

### Today
1. **Ready to Step Up** (only when non-empty) — one row per pending Progression Suggestion: *"Bench Press · Push Day — 3×10 hit at 60 kg"* with **Step Up to 62.5 kg** button and swipe-to-dismiss. Step Downs appear here too, worded neutrally ("Squat · Leg Day — stalled at 80 kg. Step Down to 77.5 kg?").
2. **Next Up** card — Workout name, its Planned Exercises with Targets (`3×12 @ 40 kg`, Supersets visually bracketed), large orange **Start** button.
3. **Other Workouts** — compact list; tap → start.
4. Empty state: `ContentUnavailableView` "No Workouts yet" + **Create Workout**.

### Workouts
- List in Rotation order; drag to reorder, swipe to delete (soft delete), `+` to create.
- **Workout editor**: name; Planned Exercises (reorder, delete); **Add Exercise** → picker; context menu **Superset with Next** / **Break Superset**. Planned Exercises with a pending suggestion show a small orange badge.
- **Planned Exercise editor**: Sets (stepper), reps (stepper), weight (`TextField` bound to `Double` with `.decimalPad`, kg), Weight Step (menu: 0.5, 1, 1.25, 2, 2.5, 4, 5, 10), Rest (menu: 0:30 … 5:00).
- **Exercises** (toolbar) → Exercise Catalog + Custom Exercises; searchable (`localizedStandardContains`), filter by Muscle Group; create/edit Custom Exercise (name, equipment, Muscle Groups).

### Active Session (full-screen cover)
- **Set view**: Exercise name, "Set 2 of 3" (Superset: "A · Set 2 of 3"), reps and weight in huge rounded monospaced digits, tap either to adjust (steppers); full-width **Done**.
- **Rest view**: countdown ring, time remaining, **+30 s** / **Skip**; below: "Next: Lat Pulldown · 3×12 @ 55 kg". Step Up / Step Down cards slide in here.
- Header: elapsed time, heart rate (when Watch-mirrored), per-Exercise progress dots.
- **Overview** sheet: queue with Skip / Do later / Add Set / edit logged Sets. **End** with confirmation only if Sets remain.
- When the Watch is primary, this same UI is shown mirrored; taps become commands to the Watch.

### Session Summary (end of every Session)
Celebration (§9), then: duration, Sets, volume, heart rate & calories (if recorded), and a card per progress event (Step Ups accepted, new bests, Target Hits). **Done** returns to Today.

### Progress
- Segmented: **Exercises** | **Sessions**.
- Filters (shared): time range `4W · 3M · 6M · 1Y · All`; Muscle Group chips; search.
- **Exercises**: every Exercise performed at least once — sparkline, current weight, change within range ("+7.5 kg").
- **Exercise detail** (Swift Charts): line of working weight per Session (max weight of its Sets), Step Up markers (annotated points), selection scrubbing (`chartXSelection`); best Set (heaviest weight, then most reps); total volume (Σ reps × weight; bodyweight Exercises with 0 kg show total reps instead); list of past Sets grouped by Session.
- **Sessions**: history list (date, Workout, duration, Sets); detail shows every Set; edit Sets or delete the Session (also deletes its Health workout).

### Settings
Sync (Sign in with Apple / status / sign out) · Apple Health status · Strava connect (M4) · Delete account & cloud data · About / privacy.

### Live Activity & rest notifications
- A Live Activity runs for every Session: Lock Screen shows Workout name, current step ("Bench Press · Set 2 of 3 · 10 @ 60 kg" or Rest countdown via `Text(timerInterval:)`) and what's next; Dynamic Island compact shows the Rest countdown / Set indicator.
- **iPhone primary**: started with the Session; a local notification fires when Rest ends while the app is backgrounded.
- **Watch primary**: the iPhone updates the Live Activity from mirrored-session data. If iOS refuses to *start* it from the background (open question, §15), it starts the next time the iPhone app is foregrounded during the Session.

---

## 8. Apple Watch app

Standalone watchOS app with its own SwiftData store; works fully without the iPhone nearby.

- **Home**: Next Up Workout with **Start**; other Workouts below. Read-only plans — editing Workouts is iPhone-only.
- **Set screen**: Exercise name, "Set 2 of 3", reps and weight large; **Digital Crown adjusts reps**; weight via a secondary button; big **Done**. Heart rate small in the corner.
- **Rest screen**: countdown ring, haptic when Rest ends, "Next: Lat Pulldown 3×12 @ 55 kg" underneath; Step Up / Step Down cards appear here.
- **Swipe left**: Session overview — Skip, Do later, Add Set, End.
- **Summary**: celebration + key numbers.
- **Complication / Smart Stack widget**: "Next up: Pull Day"; tap starts the Session.
- Runs an `HKWorkoutSession` (`.traditionalStrengthTraining`, indoor) with `HKLiveWorkoutBuilder`: keeps the app frontmost, records heart rate & active energy, saves the workout to Health, closes Activity rings.

### Phone ↔ Watch data
- **Phone → Watch**: `updateApplicationContext` with a full plan snapshot — Exercises, Workouts, Planned Exercises, pending suggestions, and per Planned Exercise the summaries of its last 3 Sessions + last performed date (enough for the Watch to evaluate Target Hit, Stall and Layoff offline).
- **Watch → Phone**: `transferUserInfo` (queued, guaranteed delivery) with each finished Session and any changed Planned Exercise / Progression Suggestion records.
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
- Opt-in: **Settings → Sync → Sign in with Apple** → `supabase.auth.signInWithIdToken(provider: .apple, …)`.
- Triggers: app launch, app foregrounded, Session finished, suggestion answered. No "sync now" button.
- **Push**: all records with `updatedAt > lastPushAt` go in one call to the RPC `sync_push(payload jsonb)`, which upserts in dependency order inside one transaction using `ON CONFLICT (user_id, id) DO UPDATE … WHERE table.updated_at < excluded.updated_at`.
- **Pull**: RPC `sync_pull(since timestamptz)` returns every row whose `server_updated_at > since`, across all tables. The client re-pulls with a 60 s overlap; merging is idempotent.
- `server_updated_at` is set by trigger (`clock_timestamp()`) and is used only as the pull cursor; `updated_at` (client) is used only for conflict resolution.
- Exercise Catalog records use **deterministic UUIDs** (UUIDv5 of `catalogKey`), so a reinstall + sign-in merges instead of duplicating.

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
| `exercises` | `name text, equipment text, muscle_groups text[], catalog_key text, strava_exercise_type text, archived_at timestamptz` |
| `workouts` | `name text, rotation_index int` |
| `planned_exercises` | `workout_id uuid, exercise_id uuid, position int, superset_id uuid, target_sets int, target_reps int, weight numeric(6,2), weight_step numeric(5,2), rest_seconds int` |
| `sessions` | `workout_id uuid, workout_name text, started_at timestamptz, ended_at timestamptz, recorded_on text, strava_activity_id bigint` |
| `session_exercises` | `session_id uuid, exercise_id uuid, planned_exercise_id uuid, exercise_name text, position int, superset_id uuid, target_sets int, target_reps int, target_weight numeric(6,2), status text` |
| `sets` | `session_exercise_id uuid, number int, reps int, weight numeric(6,2), is_extra bool, completed_at timestamptz` |
| `progression_suggestions` | `planned_exercise_id uuid, kind text, reason text, from_weight numeric(6,2), to_weight numeric(6,2), source_session_id uuid, status text, resolved_at timestamptz` |
| `strava_connections` (M4) | `athlete_id bigint, access_token text, refresh_token text, expires_at timestamptz, auto_upload bool` — **no client read policy**; only Edge Functions (service role) touch tokens |

- **Row Level Security** on every table: `using (user_id = auth.uid()) with check (user_id = auth.uid())`.
- Cross-table references are plain columns (no FK constraints between synced tables) so partial or out-of-order pushes can never fail; the app guarantees integrity.
- Check constraints on enums (`equipment`, `kind`, `status`, …) and `muscle_groups <@ array[...]`.
- The future web dashboard reads these tables directly with the user's Supabase session — no extra API needed.

### Configuration & secrets
- Supabase URL + publishable key: `Config/Secrets.xcconfig` (gitignored; template `Config/Secrets.example.xcconfig` committed) → Info.plist → read at startup.
- Edge Function secrets (Strava client secret, Apple Sign in private key): `supabase secrets set …`. Never in the repo, never in the app.

---

## 11. Apple Health

- **Write only.** Each Session is saved as an `HKWorkout` (`.traditionalStrengthTraining`, indoor), including heart rate and active energy when recorded on the Watch. No workouts are read from Health.
- Permission is requested at the **first Session start**, with a one-line explanation screen before the system sheet.
- Deleting a Session in the app also deletes the Health workout it created.
- Health-derived values (heart rate, calories) are shown in the app but **never leave the device** (not synced to Supabase) — keeps App Review simple (§14).

---

## 12. Strava (M4 — sketch)

Apple Health does **not** forward third-party strength workouts to Strava, so OnlyWorkout uploads directly. See [ADR-0004](docs/adr/0004-strava-direct-upload-via-edge-functions.md).

1. **Connect** (Settings → Strava): `ASWebAuthenticationSession` to Strava's OAuth (`scope=activity:write`), redirect back to the app with `code`.
2. App calls Edge Function **`strava-connect`** with the code (authenticated with the user's Supabase session). The function exchanges it for tokens with the Strava client secret and stores them in `strava_connections`.
3. After a finished Session has synced, the app calls **`strava-upload`** with `session_id`. The function loads the Session and its Sets from Postgres, refreshes the token if needed, and creates a `WeightTraining` activity with structured Sets (exercise type, reps, weight) via Strava's upload API. It polls upload status and writes `strava_activity_id` back to `sessions`.
4. Strava builds its muscle map from the exercise types → every catalog Exercise gets a `strava_exercise_type` mapping; Custom Exercises get one picked by the user (or none).
5. Settings toggle: auto-upload every Session, or manual "Upload to Strava" on Session detail. Sessions finished while unsynced are queued.
6. Disconnect: Edge Function **`strava-disconnect`** deauthorises at Strava and deletes the row.

**To verify at M4 start** (from a July 2026 developer-forum report, not official docs): exact endpoint and payload for structured strength uploads; Strava's list of exercise types; muscle maps reportedly appear inconsistently for API uploads. Release needs Strava's app review (new API apps are limited to a single athlete) and adherence to Strava brand guidelines ("Connect with Strava" button, "Compatible with Strava" attribution).

---

## 13. Project structure

```
OnlyWorkout.xcodeproj           # Xcode project using synchronized folders
OnlyWorkout/                    # iOS app — com.stefanblos.OnlyWorkout
  App/                          # @main, root TabView, dependency setup
  Features/
    Today/  Workouts/  Exercises/  Session/  Summary/  Progress/  Settings/
  Resources/                    # Assets (AccentColor), Localizable.xcstrings, PrivacyInfo.xcprivacy
OnlyWorkoutWatch/               # watchOS app — com.stefanblos.OnlyWorkout.watchkitapp
  App/  Features/Home/  Features/Session/  Features/Summary/  Resources/
OnlyWorkoutWidgets/             # iOS widget extension: Live Activity
OnlyWorkoutWatchWidgets/        # watchOS widget extension: complication / Smart Stack
OnlyWorkoutUITests/             # one UI test: the core Session flow
Packages/OnlyWorkoutKit/        # local Swift package
  Sources/
    OnlyWorkoutCore/            # pure domain: value types, progression, rotation, SessionEngine, stats, RecordMerger, messages. No Apple frameworks beyond Foundation.
    OnlyWorkoutStore/           # SwiftData @Model types, mapping to Core, Exercise Catalog seeding
    OnlyWorkoutConnectivity/    # WatchConnectivity + HealthKit workout/mirroring wrappers
    OnlyWorkoutSync/            # Supabase client, auth, push/pull (iOS only — the only module importing supabase-swift)
    OnlyWorkoutDesign/          # DesignTokens, shared components (rings, number views, celebration)
    OnlyWorkoutLiveActivity/    # ActivityAttributes shared by the app and the widget extension (iOS only)
  Tests/
    OnlyWorkoutCoreTests/  OnlyWorkoutStoreTests/
supabase/
  config.toml
  migrations/                   # schema, RLS, sync RPCs
  functions/                    # strava-connect, strava-upload, strava-disconnect, delete-account
Config/                         # Shared.xcconfig (team, includes Secrets.xcconfig — gitignored)
docs/adr/
.github/workflows/ci.yml
```

- Package platforms: iOS 27, watchOS 27, macOS 27 (macOS only so `swift test` runs on the host without a simulator).
- App targets: default actor isolation `MainActor`, strict concurrency complete. `OnlyWorkoutCore` types are `Sendable` value types.
- One type per file; folders by feature.
- **Capabilities**: HealthKit (iOS + watchOS), Sign in with Apple (iOS), App Groups `group.com.stefanblos.OnlyWorkout` (app ↔ widgets), Background Modes → Workout processing (watchOS and iOS). Associated URL scheme `onlyworkout://` for Strava OAuth return and widget deep links.

---

## 14. App Store readiness (built in from day one)

- **Account deletion** in Settings: Edge Function `delete-account` deletes all rows (cascade from `auth.users`) and **revokes the Sign in with Apple token** (App Review guideline 5.1.1(v)).
- Health: purpose strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`), Health data used only for the user's own tracking, never synced to the cloud or used for ads.
- `PrivacyInfo.xcprivacy` for each target; privacy policy page (needed for HealthKit + accounts) before public release.
- No secrets in the binary except the Supabase publishable key (which is public by design and protected by RLS).
- Strava: app review for athlete capacity + brand guidelines before release.
- Accessibility: Dynamic Type, VoiceOver labels on every icon-only control, Reduce Motion, 44 pt targets.

---

## 15. Open questions & risks

| # | Question | Plan |
|---|---|---|
| 1 | Can the iPhone *start* a Live Activity in the background when a mirrored Watch Session begins? | Spike at the very start of M2. Fallback: start it on next foreground. |
| 2 | Exact Strava API for structured strength uploads and its exercise-type list | Verify against official docs at M4 start before writing mappings. |
| 3 | Strava muscle map reportedly inconsistent for API uploads | Accept; muscle groups are still in the Strava payload and in our own stats. |

---

## 16. Milestones

Each milestone ships a usable app. Build test-first (`mattpocock-skills:tdd`) for everything in `OnlyWorkoutCore`.

### M1 — iPhone app, local only
**Status:** implemented on branch `m1-iphone-app`; the "Done when" flow is covered by `SessionFlowUITests`. CI is written but not yet run on GitHub.

- Project bootstrap: Xcode project with iOS app, widget extension and UI-test targets (Watch targets can be added in M2); local package; `Localizable.xcstrings`; `AccentColor`; `Config/Secrets.example.xcconfig`; `.swift-format`; CI workflow (`swift test` on the package, build both apps, `swift-format lint`).
- Core: domain types, progression rules (§4), Rotation (§5), SessionEngine (§6), stats, messages, RecordMerger — all with tests.
- Store: SwiftData models, Exercise Catalog seed (§17) on first launch.
- UI: Today (incl. Ready to Step Up), Workouts + editors, Exercises, Active Session (iPhone primary), Summary with celebration, Progress + detail charts, Session history, Settings shell.
- Live Activity + rest-end notification for iPhone Sessions.
- **Done when**: a full Session incl. a Superset can be run on the iPhone, a Target Hit produces a Step Up card and a Ready to Step Up row, a synthetic Stall and Layoff produce Step Downs, and the Progress chart shows the history.

### M2 — Apple Watch + Health
- Spike: open question #1.
- watchOS app + widget extension; plan snapshot sync and Session transfer via WatchConnectivity.
- HealthKit on both devices; Watch as primary with mirroring; iPhone as mirrored controller; Live Activity for Watch Sessions.
- **Done when**: with the iPhone switched off, a full Session runs on the Watch incl. Step Up prompt; it appears on the iPhone and in Health once the phone is back.

### M3 — Supabase sync
- `supabase/` project, migrations (schema, RLS, `sync_push`, `sync_pull`), `delete-account` function.
- Sign in with Apple, push/pull, account deletion incl. token revocation.
- **Done when**: delete the app, reinstall, sign in → all data returns without duplicates; rows are visible in the Supabase dashboard and nobody else's are.

### M4 — Strava
- Resolve open questions #2–3; `strava-connect`, `strava-upload`, `strava-disconnect`; Exercise → Strava type mapping; Settings UI; auto-upload.
- **Done when**: finishing a Session creates a Strava WeightTraining activity with every Set.

---

## 17. Exercise Catalog (seed)

Shipped with deterministic UUIDs (UUIDv5 of the key). Muscle Groups are primary movers. Dumbbell weights are **per dumbbell**.

| Key | Name | Equipment | Muscle Groups |
|---|---|---|---|
| barbell-bench-press | Bench Press | barbell | Chest, Triceps, Shoulders |
| incline-dumbbell-press | Incline Dumbbell Press | dumbbell | Chest, Shoulders |
| dumbbell-bench-press | Dumbbell Bench Press | dumbbell | Chest, Triceps |
| machine-chest-press | Machine Chest Press | machine | Chest, Triceps |
| cable-fly | Cable Fly | cable | Chest |
| push-up | Push-up | bodyweight | Chest, Triceps |
| dip | Dip | bodyweight | Chest, Triceps |
| pull-up | Pull-up | bodyweight | Lats, Biceps |
| chin-up | Chin-up | bodyweight | Lats, Biceps |
| lat-pulldown | Lat Pulldown | cable | Lats, Biceps |
| seated-cable-row | Seated Cable Row | cable | Upper Back, Lats |
| barbell-row | Barbell Row | barbell | Upper Back, Lats |
| one-arm-dumbbell-row | One-Arm Dumbbell Row | dumbbell | Lats, Upper Back |
| chest-supported-row | Chest-Supported Row | machine | Upper Back |
| face-pull | Face Pull | cable | Shoulders, Upper Back |
| deadlift | Deadlift | barbell | Hamstrings, Glutes, Lower Back |
| back-extension | Back Extension | bodyweight | Lower Back, Glutes |
| overhead-press | Overhead Press | barbell | Shoulders, Triceps |
| seated-dumbbell-press | Seated Dumbbell Shoulder Press | dumbbell | Shoulders, Triceps |
| lateral-raise | Lateral Raise | dumbbell | Shoulders |
| rear-delt-fly | Rear Delt Fly | machine | Shoulders, Upper Back |
| dumbbell-shrug | Dumbbell Shrug | dumbbell | Traps |
| barbell-curl | Barbell Curl | barbell | Biceps |
| dumbbell-curl | Dumbbell Curl | dumbbell | Biceps |
| hammer-curl | Hammer Curl | dumbbell | Biceps, Forearms |
| triceps-pushdown | Triceps Pushdown | cable | Triceps |
| overhead-triceps-extension | Overhead Triceps Extension | cable | Triceps |
| skull-crusher | Skull Crusher | barbell | Triceps |
| back-squat | Back Squat | barbell | Quads, Glutes |
| front-squat | Front Squat | barbell | Quads |
| goblet-squat | Goblet Squat | kettlebell | Quads, Glutes |
| leg-press | Leg Press | machine | Quads, Glutes |
| romanian-deadlift | Romanian Deadlift | barbell | Hamstrings, Glutes |
| bulgarian-split-squat | Bulgarian Split Squat | dumbbell | Quads, Glutes |
| walking-lunge | Walking Lunge | dumbbell | Quads, Glutes |
| leg-extension | Leg Extension | machine | Quads |
| leg-curl | Leg Curl | machine | Hamstrings |
| hip-thrust | Hip Thrust | barbell | Glutes |
| hip-adduction | Hip Adduction | machine | Adductors |
| standing-calf-raise | Standing Calf Raise | machine | Calves |
| seated-calf-raise | Seated Calf Raise | machine | Calves |
| hanging-leg-raise | Hanging Leg Raise | bodyweight | Abs |
| cable-crunch | Cable Crunch | cable | Abs |
| ab-wheel-rollout | Ab Wheel Rollout | bodyweight | Abs, Obliques |
