# OnlyWorkout — agent guide

Native iOS 27 + watchOS 27 strength-training tracker (SwiftUI, SwiftData, HealthKit, Supabase). One user, the owner; built to App Store standards.

## Read first

- **`CONTEXT.md`** — the glossary. Before naming any type, property, UI string or test, use its terms exactly (Session, never "workout" for a gym visit). When a new domain concept appears, add it there using the `domain-modeling` skill.
- **`README.md`** — the spec: domain model (§3), progression rules (§4), Session flow (§6), screens (§7–8), design (§9), sync (§10), structure (§13), milestones (§16). Work milestone by milestone; a milestone's "Done when" is its completion criterion.
- **`docs/adr/`** — before changing sync, progression, Watch↔phone data flow, Strava or Session history shape, read the matching ADR. Record a new ADR only for hard-to-reverse, surprising trade-offs.

## Commands

```bash
# Logic tests (fast, no simulator) — run after every change to Packages/
swift test --package-path Packages/OnlyWorkoutKit

# Build the iOS app (also builds and embeds the Watch app), and run the Session-flow UI test
# (it saves screenshots into the .xcresult)
xcodebuild -project OnlyWorkout.xcodeproj -scheme OnlyWorkout -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' build
xcodebuild -project OnlyWorkout.xcodeproj -scheme OnlyWorkout -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' test

# Watch app alone
xcodebuild -project OnlyWorkout.xcodeproj -scheme OnlyWorkoutWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm),OS=27.0' build

# Formatting (bundled with the toolchain; config in .swift-format) — add new target folders here and in CI
xcrun swift-format lint --strict --recursive Packages/OnlyWorkoutKit/Sources Packages/OnlyWorkoutKit/Tests OnlyWorkout OnlyWorkoutWidgets OnlyWorkoutWatch OnlyWorkoutWatchWidgets SharedUI OnlyWorkoutUITests
xcrun swift-format format --in-place --recursive <paths>

# Supabase (M3+; `brew install supabase/tap/supabase`, needs Docker)
supabase start && supabase db reset   # local stack + migrations
supabase test db                      # pgTAP tests in supabase/tests/database (RLS, sync_push, sync_pull)
supabase functions serve              # serves delete-account and the strava-* functions locally
deno test --allow-env supabase/functions   # Strava rules of the Edge Functions, against a stubbed fetch (`brew install deno`)
```

The Xcode project uses **synchronized folders**: create files on disk inside a target folder and they join the target — only edit `project.pbxproj` for targets, capabilities and build settings. `SharedUI/` is compiled into both the iPhone and the Watch app. `Config/` holds `Shared.xcconfig` (team, secrets include), the Info.plists and entitlements (HealthKit; App Group `group.com.stefanblos.OnlyWorkouts` for the Watch complication).

Launch arguments: `-uiTesting` starts the iPhone app with an in-memory store, a sample "Push Day" Workout and no Apple Health; `-sampleData` adds that Workout to the real store (handy for trying the Watch); `-onboarding` shows onboarding even when it's done (Debug only; a fresh install shows it by itself). Previews use `SampleData.previewContainer()`.

**Watch in the simulator:** use a *paired* pair (`xcrun simctl list pairs`, e.g. iPhone 18 Pro Max + Apple Watch Series 12 (46mm)), install `OnlyWorkout.app` on the iPhone and `OnlyWorkout.app/Watch/OnlyWorkoutWatch.app` on the Watch. Queued `transferUserInfo` deliveries often never arrive in the simulator (they work on devices), and rebooting only the iPhone simulator can break the pair's messaging until both are restarted.

## Architecture in one breath

- `Packages/OnlyWorkoutKit/OnlyWorkoutCore` holds **all** domain logic as pure, `Sendable` value types (progression, Rotation, `SessionEngine`, stats, `RecordMerger`, messages). Views and SwiftData models stay thin and call into it.
- `OnlyWorkoutStore` = SwiftData models + `TrainingLog` (all reads/writes views need; feeds Core with plain values) + Exercise Catalog seed + `SessionRunner` (runs a Session on whichever device is primary) + `RecordBatch` (Codable records moved between devices; `exportPlan`/`watchSnapshot`/`apply`). `OnlyWorkoutDesign` = `DesignTokens` + shared components. `OnlyWorkoutLiveActivity` = the `ActivityAttributes` shared by app and widget extension. `OnlyWorkoutConnectivity` = `WorkoutRecorder` (HealthKit workout + mirroring channel), `PhoneWatchLink` (WatchConnectivity), `MirrorMessage` (state/commands during a mirrored Session). `OnlyWorkoutSync` = `CloudSync` (push then pull, account lifecycle) behind the `CloudBackend` protocol, `StravaLink` (connect, upload, disconnect) behind `StravaBackend`, `SupabaseBackend` (both), `CloudCoding` (the RPC JSON); iOS only, the sole importer of `supabase-swift`.
- The stored Set type is `SetEntry` because `Set` is Swift's collection; in Core the value type is `LoggedSet`.
- `SessionRunner` wraps `SessionEngine` for a live Session: every event is saved via `TrainingLog.save` (which also stores the encoded engine so a Session resumes after termination). On iPhone the Session screen talks to a `SessionDriver`: `LocalSession` (runner + Live Activity + notification + Health) or `MirroredSession` (draws the Watch's `MirrorState`, sends `MirrorCommand`s back).
- Every synced record carries `id`, `createdAt`, `updatedAt`, `deletedAt`; delete by setting `deletedAt`. Stored models also keep a local-only `syncedUpdatedAt`; bumping `updatedAt` is all it takes to get a change pushed. A new column goes into the migration, the `*Record` type and its `write(to:)`; the RPCs read the columns from the table.
- Linked Planned Exercises (ADR-0006) must stay identical: after changing a Planned Exercise's Target, Weight Step or Rest, call `TrainingLog.propagateSettings(from:)`; progression history, suggestions and `accept` already work per link group.
- The Watch syncs only with the iPhone; only the iPhone talks to Supabase.

## Working rules

- **Test-first** for everything in `OnlyWorkoutCore`, via the `tdd` skill: Swift Testing (`@Test`, `#expect`), one behaviour per test, named in glossary terms (`stallAfterThreeMissesWithoutNewBest`). UI is verified with SwiftUI previews fed by sample data; the single UI test covers the core Session flow.
- **SwiftUI/Swift**: follow the `swiftui-pro` skill when writing or reviewing Swift. App and widget targets use `MainActor` default isolation (the UI-test target is `nonisolated`, with `@MainActor` test classes); `@Observable` for shared state; `NavigationStack` + `navigationDestination(for:)`; one type per file; folders by feature.
- **Design & motion**: consult `apple-design` and `emil-design-eng` for any animation, gesture, haptic or visual decision; README §9 holds the chosen values. Pull fonts, spacing, radii and animations from `DesignTokens`; orange accent only for primary actions and progress moments.
- **Strings**: every user-facing string goes into `SharedUI/Localizable.xcstrings` (shared by iPhone and Watch; the Watch widget extension has its own small catalog) with a symbol key and `extractionState: manual`, used as `Text(.keyName)` or `String(localized: .keyName)`. `%lld` becomes an `Int` argument, `%@` a `String`; counts use plural variations (`.setCount(n)`). Package modules take text as parameters instead of owning strings.
- **Dependencies**: `supabase-swift` is the only third-party package; ask the owner before adding another.
- **Secrets** live in `Config/Secrets.xcconfig` (gitignored; copy `Config/Secrets.example.xcconfig`) and in `supabase secrets`. The repo and binary carry only the Supabase publishable key.
- **Health data** (heart rate, energy) stays on device — keep it out of synced models, the Supabase schema and Strava uploads.
- **Strava Data** (anything read from Strava's API, e.g. activity IDs) is kept 7 days at most and never in Supabase, except the tokens the Edge Functions need (README §12, ADR-0004).
- **Git**: work on a feature branch; the owner reviews every change before it lands on `main`.

## Skills

Project skills live in `.agents/skills/` (symlinked into `.claude/skills/`, pinned in `skills-lock.json`): `swiftui-pro`, `apple-design`, `emil-design-eng`. Plugin skills used here: `tdd`, `domain-modeling`, `code-review`.
