# Supabase with a small custom sync instead of CloudKit

The data must be reachable from other tech (a future web dashboard) and a server is needed anyway for Strava's OAuth client secret, so we sync to Supabase (Postgres) rather than CloudKit, whose web access is awkward and whose SwiftData record layout is not meant to be queried by other clients. Each device keeps a local SwiftData store as its source of truth; sync is opt-in and uses per-record last-write-wins on a client `updated_at`, tombstones via `deleted_at`, and two RPCs (`sync_push`, `sync_pull`). This is safe because there is exactly one user, so real conflicts are rare.

## Considered Options

- **SwiftData + CloudKit**: free phone↔watch sync, no server — rejected because of web access and because Strava still needs a server.
- **Local only**: rejected; the brief asks for an externally accessible database.
