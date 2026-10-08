# Strava via direct upload from Supabase Edge Functions, not via Apple Health

Strava's Apple Health integration only imports workouts recorded by Apple's own Workout app, so Sessions saved to Health never reach Strava. We therefore upload to Strava's API directly, as a `WeightTraining` activity with structured Sets so Strava can build its muscle map. The OAuth token exchange needs Strava's client secret, which can't ship in the app, so connect/upload/disconnect run as Supabase Edge Functions; tokens live in a table clients cannot read.

## Amendment (M4, 2026-10-06)

- The upload is Strava's "Strength Training (Limited)" JSON file posted to `POST /uploads` with `data_type=json`; there is no dedicated strength endpoint (docs/research/strava-api.md).
- **The app builds that file** (`StravaUpload` in OnlyWorkoutCore) and `strava-upload` only adds the token and posts it, instead of reading the Session from Postgres. One exercise mapping (in Swift, tested), and an upload doesn't wait for the Session to sync. Strava upload still needs a cloud account, because the tokens live there.
- **Strava's activity ID never reaches Supabase.** Under Strava's API Agreement it is Strava Data ("all data you access or collect from the Strava API"), which may be cached for 7 days at most; the uploading iPhone keeps it for 7 days. The cloud keeps our own `strava_uploaded_at` so a Session is uploaded once.
- Strava's terms require webhooks to learn about deauthorization, so a fourth, public function `strava-webhook` deletes the tokens of an athlete who revokes access.

## Consequences

Strava upload requires cloud sync to be enabled. "View on Strava" disappears 7 days after an upload; asking Strava whether IDs may be kept longer would be the way to change that.
