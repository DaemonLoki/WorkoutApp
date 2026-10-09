# Split Shoulders into three Delts, add Secondary Muscle Groups, and let code revise the Exercise Catalog

The Muscle Map (M7) and Gaps (M8) have to show where a Workout's Emphasis lies, but with one Shoulders group Push and Pull lit up the same region, and an Exercise's 1–3 Muscle Groups counted equally (Bench Press lit Triceps as strongly as Chest). So the fixed list grows from 16 to 18: Shoulders becomes Front, Side and Rear Delts. Exercises also get synced **Secondary Muscle Groups** (0–3), which count half.

Both changes rewrite data that already exists, on devices and in the cloud. So the Exercise Catalog becomes code-owned and revisable:

- Catalog Exercises can't be edited in the app, so `ExerciseCatalog` is their source of truth.
- Each **catalog revision** has a fixed date. The seed rewrites any catalog Exercise that differs from its entry and whose `updatedAt` is older than that date, stamping it with that date.
- Every device writes the same values with the same `updatedAt`. Ties keep the existing record (README §10), so devices converge without ping-pong, and the cloud accepts the rewrite exactly once.

Custom Exercises tagged with the old `shoulders` are rewritten locally once, to Front + Side Delts (they then sync like any edit). Decoding still maps a stray `shoulders` the same way, for records from devices that haven't updated yet.

## Considered options

- **Keep 16 groups, treat the first Muscle Group as primary**: no migration, but implicit. The Map still couldn't tell Push from Pull.
- **Secondary Muscle Groups only in code, not synced**: no column, but Custom Exercises couldn't have them and the web dashboard couldn't read them.
- **Re-seed with `updatedAt = now`**: every device would write a different time, and they would overwrite each other once per device.

## Consequences

- **Deployment order is reversed** compared to M4/M5. The hosted migration (new column, `muscle_groups` check accepting the new values *and* the legacy `shoulders`) must run **before** the app update ships. Otherwise the first push of a revised catalog Exercise fails the check.
- Older app versions (e.g. a Watch not yet updated) skip Muscle Groups they don't know when displaying them. The raw strings stay in `muscleGroupsRaw`, so nothing is lost by syncing through them. Only editing a Custom Exercise on an old iPhone version would drop the new groups. That's acceptable for a one-user app that updates both devices together.
- Any later catalog change (the M8 additions, corrected Muscle Groups, Strava types) is a new revision date, not a migration.
