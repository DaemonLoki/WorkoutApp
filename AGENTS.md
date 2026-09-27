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

# Build the apps
xcodebuild -project OnlyWorkout.xcodeproj -scheme OnlyWorkout -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' build
xcodebuild -project OnlyWorkout.xcodeproj -scheme OnlyWorkoutWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 12 (46mm),OS=27.0' build

# Formatting (bundled with the toolchain; config in .swift-format)
xcrun swift-format lint --strict --recursive Packages OnlyWorkout OnlyWorkoutWatch OnlyWorkoutWidgets OnlyWorkoutWatchWidgets
xcrun swift-format format --in-place --recursive <paths>

# Supabase (M3+; `brew install supabase/tap/supabase`)
supabase start && supabase db reset   # local stack + migrations
```

Until M1's bootstrap lands, these paths don't exist yet. The Xcode project uses **synchronized folders**: create files on disk inside a target folder and they join the target — only edit `project.pbxproj` for targets, capabilities and build settings.

## Architecture in one breath

- `Packages/OnlyWorkoutKit/OnlyWorkoutCore` holds **all** domain logic as pure, `Sendable` value types (progression, Rotation, `SessionEngine`, stats, `RecordMerger`, messages). Views and SwiftData models stay thin and call into it.
- `OnlyWorkoutStore` = SwiftData models + mapping to Core. `OnlyWorkoutConnectivity` = WatchConnectivity/HealthKit. `OnlyWorkoutDesign` = `DesignTokens` + shared components. `OnlyWorkoutSync` = Supabase, iOS only, the sole importer of `supabase-swift`.
- Every synced record carries `id`, `createdAt`, `updatedAt`, `deletedAt`; delete by setting `deletedAt`.
- The Watch syncs only with the iPhone; only the iPhone talks to Supabase.

## Working rules

- **Test-first** for everything in `OnlyWorkoutCore`, via the `tdd` skill: Swift Testing (`@Test`, `#expect`), one behaviour per test, named in glossary terms (`stallAfterThreeMissesWithoutNewBest`). UI is verified with SwiftUI previews fed by sample data; the single UI test covers the core Session flow.
- **SwiftUI/Swift**: follow the `swiftui-pro` skill when writing or reviewing Swift. App targets use `MainActor` default isolation; `@Observable` for shared state; `NavigationStack` + `navigationDestination(for:)`; one type per file; folders by feature.
- **Design & motion**: consult `apple-design` and `emil-design-eng` for any animation, gesture, haptic or visual decision; README §9 holds the chosen values. Pull fonts, spacing, radii and animations from `DesignTokens`; orange accent only for primary actions and progress moments.
- **Strings**: every user-facing string goes into `Localizable.xcstrings` with a symbol key and `extractionState: manual`, used as `Text(.keyName)`.
- **Dependencies**: `supabase-swift` is the only third-party package; ask the owner before adding another.
- **Secrets** live in `Config/Secrets.xcconfig` (gitignored; copy `Config/Secrets.example.xcconfig`) and in `supabase secrets`. The repo and binary carry only the Supabase publishable key.
- **Health data** (heart rate, energy) stays on device — keep it out of synced models and the Supabase schema.
- **Git**: work on a feature branch; the owner reviews every change before it lands on `main`.

## Skills

Project skills live in `.agents/skills/` (symlinked into `.claude/skills/`, pinned in `skills-lock.json`): `swiftui-pro`, `apple-design`, `emil-design-eng`. Plugin skills used here: `tdd`, `domain-modeling`, `code-review`.
