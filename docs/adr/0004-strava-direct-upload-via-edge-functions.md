# Strava via direct upload from Supabase Edge Functions, not via Apple Health

Strava's Apple Health integration only imports workouts recorded by Apple's own Workout app, so Sessions saved to Health never reach Strava. We therefore upload to Strava's API directly, as a `WeightTraining` activity with structured Sets so Strava can build its muscle map. The OAuth token exchange needs Strava's client secret, which can't ship in the app, so connect/upload/disconnect run as Supabase Edge Functions that read the Session from Postgres; tokens live in a table clients cannot read.

## Consequences

Strava upload requires cloud sync to be enabled (the function reads the synced Session). Exact endpoint and payload must be verified against official docs at the start of M4.
