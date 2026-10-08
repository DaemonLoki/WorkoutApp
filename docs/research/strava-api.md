# Strava API for M4: verified against primary sources

Researched 2026-10-03. Sources are listed at the end. Each claim carries one of three labels: **confirmed** (official Strava or Garmin docs, or a Strava staff post), **unverified** (no primary source found), or **not supported**.

## Summary and verdict

**The README §12 / ADR-0004 plan holds.** The July 2026 forum report was correct in substance. Strava's public API has supported structured strength uploads since **2026-05-21**, but not through a new REST endpoint. They go through the existing **file upload endpoint `POST /uploads`** with a new **`data_type=json`** file format (or FIT `set` messages) [S2, S3]. The upload is asynchronous and is polled with `GET /uploads/{id}` [S3].

Changes to make:

1. **Name the mechanism exactly.** `strava-upload` builds a small JSON document (`version`, `start_time`, `utc_offset`, `elapsed_time`, `sets[]`) and posts it as a multipart file with `data_type=json` and `sport_type=WeightTraining`. It does **not** use `POST /activities`, which is manual activities only and has no set fields [S1].
2. **Exercise types are Strava's own `UPPER_SNAKE_CASE` identifiers**, 656 of them in 34 groups, published on the uploads page. They are **not** the FIT `exercise_name` enum (only 243 of the 656 coincide with FIT names) [S3, S16]. `strava_exercise_type` stores such a string. A mapping for the whole seed catalog is in [Implications for M4](#implications-for-m4).
3. **Muscle maps**: Strava says the map is generated from uploaded files for WeightTraining/HIIT/Workout/Crossfit [S9]. Staff have **not** resolved a July 2026 report that it shows up inconsistently for JSON uploads [S9]. README open question #3 ("accept") still stands.
4. **New since the README was written (all confirmed):**
   - Creating an API app now **requires a Strava subscription** [S5, S10].
   - New apps start at an athlete capacity of **1**, and a self-service upgrade raises that to **10** with no review. Review is only needed above 10 [S6].
   - **Deauthorize is moving** from `POST /oauth/deauthorize` to **`POST /oauth/revoke`** (HTTP Basic client auth). The old endpoint goes away on **2027-06-01** [S4].
   - The **API base URL changes** to `https://api-v3.strava.com`, available from **2027-01-04** [S2].
   - Per the Getting Started guide, apps **must implement webhooks** to learn about deauthorizations [S5], and the API Policy requires deleting the athlete's Strava Data within 30 days of revocation [S8].
5. **Health data stays out.** The JSON format accepts optional `heartrate` / `active` streams and `total_calories` [S3]. AGENTS.md keeps Health data on device and out of Supabase, so the Edge Function sends sets only.

---

## 1. Structured strength upload

**Endpoint: confirmed** [S3]

- `POST https://www.strava.com/api/v3/uploads`, sent as `multipart/form-data`. Requires the `activity:write` scope.
- Form fields:

  | Field | Status | Meaning |
  |---|---|---|
  | `file` | required | The file. For gzipped data, `data_type` must end in `.gz`. |
  | `data_type` | required, case-insensitive | One of `fit`, `fit.gz`, `tcx`, `tcx.gz`, `gpx`, `gpx.gz`, `json` |
  | `sport_type` | optional, case-sensitive | Overrides the sport type detected from the file |
  | `name` | optional | Activity name |
  | `description` | optional | Activity description |
  | `trainer` | optional | Stationary flag. Activities without lat/lng are marked stationary automatically. |
  | `commute` | optional | Commute flag |
  | `external_id` | optional | Defaults to the filename; "should be a unique identifier" |
  | `activity_type` | optional, deprecated | Ignored when `sport_type` is present |

- **The swagger file is stale.** `swagger.json` still lists `data_type` without `json` and has no `sport_type` on uploads [S1]. The uploads guide [S3] and changelog [S2] are the authority. Official generated SDKs built from the swagger will not know about JSON uploads.
- The response is an `Upload` object: `id` (int64), `id_str`, `external_id`, `error` (nullable, English, may contain escaped HTML), `status`, `activity_id` (nullable int64).
  - Success returns `201` with status "Your activity is still being processed."
  - Errors return `400` with a status string [S3].

**JSON file format "Strength Training (Limited)": confirmed** [S3]

It is accepted only for **WeightTraining, HighIntensityIntervalTraining, Workout, Crossfit**.

| Field | Type | Notes |
|---|---|---|
| `version` | string, required | must be `"1.0"` |
| `start_time` | string, required | ISO 8601 **with** `Z` or offset |
| `utc_offset` | integer, required | athlete's local offset in seconds; display only |
| `elapsed_time` | integer, required | seconds |
| `active_time` | integer, optional | seconds |
| `total_calories` | integer, optional | |
| `creator` | object, optional | `{ "name": "…" }` |
| `streams` | object, optional | `time` (int[], required if streams present), `active` (bool[]), `heartrate` (int[]); all arrays the same length |
| `sets` | array, required, ≥1 | see below |

Each element of `sets[]`:

| Field | Type | Notes |
|---|---|---|
| `exercise_type` | string, required | identifier from the Supported Exercises list (appendix) |
| `repetitions` | integer, optional | |
| `weight` | number, optional | **kilograms** |
| `duration` | integer, optional | seconds (timed exercises, e.g. planks) |
| `start_time` | string, optional | ISO 8601 with designator |

Example from the docs [S3]:

```json
{ "version": "1.0", "start_time": "2025-01-15T08:30:00Z", "utc_offset": -28800,
  "elapsed_time": 3600, "active_time": 2400, "creator": { "name": "My App" },
  "sets": [ { "exercise_type": "BARBELL_BENCH_PRESS", "repetitions": 10, "weight": 60.0 },
            { "exercise_type": "PLANK_GENERIC", "duration": 60 } ] }
```

FIT and JSON files that contain sets do **not** need per-record timestamps, unlike every other upload [S3].

**FIT alternative: confirmed** [S3, S2, S16]

- Strava reads FIT `set` messages for the same four sport types. It reads these fields: `set_type`, `start_time`, `duration`, `repetitions`, `weight`, `category`, `category_subtype` [S3].
- In the FIT profile [S16], the `set` message is global message 225:
  - `duration`: uint32, scale 1000, seconds
  - `repetitions`: uint16
  - `weight`: uint16, **scale 16, kg**
  - `set_type`: `rest`=0 / `active`=1
  - `category`: array of `exercise_category`, e.g. 0 `bench_press`, 28 `squat`
  - `category_subtype`: array of uint16 indexing `<category>_exercise_name`
- Activity type comes from `session.sport` / `session.sub_sport`, for example `training`(10) / `strength_training`(20) [S3, S16].
- The file must contain `activity.timestamp` and `session.total_elapsed_time` [S3].
- Strava: "We support all FIT exercises as defined by the FIT SDK. Some exercise mappings may map to a more general type in Strava" [S3].
- For OnlyWorkout, FIT means writing a binary encoder in Deno. JSON is simpler and has a richer vocabulary, for example `MACHINE_CHEST_PRESS` and `CABLE_TRICEPS_PUSHDOWN`. **Use JSON.**

**Status polling: confirmed** [S3]

- Poll `GET /uploads/{id}` no more than once per second. Mean processing time is under 2 s.
- Status strings:
  - "Your activity is still being processed."
  - "Your activity is ready." (`activity_id` set)
  - "There was an error processing your activity." (`error` set, e.g. "… duplicate of activity 21234316")
  - "The created activity has been deleted."
- Treat `id` and `activity_id` as 64-bit. In Deno, parse with care or use `id_str`.

**Unverified (not documented anywhere official):**

- Whether `weight` is per dumbbell or the total load.
- How Strava treats bodyweight exercises that carry `weight` (Added Weight).
- Whether the order of `sets[]` defines exercise order and grouping.
- Whether duplicate detection applies to JSON uploads by `external_id` or by content.

Test these on the owner's account first.

## 2. Exercise-type list

- **Confirmed** [S3]: the list lives under "Supported Exercises" on <https://developers.strava.com/docs/uploads/>. It has **656 unique identifiers** in 34 groups, for example Bench Press 28, Squat 40, Core 64 and Warm Up 63. Every identifier is unique across groups.
- Format: `UPPER_SNAKE_CASE`. Each FIT-derived group has a `<GROUP>_GENERIC` fallback, e.g. `CURL_GENERIC`, `ROW_GENERIC`, `PLANK_GENERIC`. Three late groups have no `_GENERIC`: Hip Thrust, Lower Leg, Quad Extension.
- The vocabulary is **Strava's own**. It overlaps with the FIT SDK `*_exercise_name` enums, converted to upper snake case, for only 243 of 656 values; it adds machine and cable variants FIT lacks, such as `MACHINE_CHEST_PRESS` and `BAYESIAN_CURL` [S3, S16].
- Some groupings are odd, so map on the exact ID and not on the group name:
  - `MACHINE_LEG_EXTENSION` is under *Squat*.
  - `LEG_EXTENSIONS` is under *Core*.
  - `FACE_PULL` is under *Row*.
  - `CHEST_DIP` is under *Triceps Extension*.
- Some common movements have no plain ID. Push-up only has `PUSH_UP_GENERIC`. Pull-up has `PULL_UP_GENERIC` / `WIDE_PULL_UP` / `NEUTRAL_GRIP_PULL_UP`. Chin-up has `CLOSE_GRIP_CHIN_UP` / `WEIGHTED_CHIN_UP` / `ASSISTED_CHIN_UP`.
- **Unverified:** the support article says Strava "maps exercise names from partner apps to its own exercise library" [S12]. Whether every API identifier resolves to a library exercise with muscle data is not documented. The muscle-map article says unmatched exercises "are left off the map" [S11].
- The full list is in the appendix.

## 3. Muscle maps

- **Confirmed** [S11]: Strava generates the muscle map automatically from workout data for Weight Training, CrossFit, Workout and HIIT. For Physical Therapy the user picks the muscles manually.
  - Shading counts **working sets per muscle group**, not weight or reps.
  - The primary muscle gets full credit; secondary muscles get half.
  - Exercises that can't be matched are left off. With no exercise data, no map is shown.
  - Muscle groups: Biceps, Triceps, Forearms, Shoulders, Chest, Upper Back, Lats, Lower Back, Abs, Quads, Hamstrings, Glutes, Calves, Abductors, Adductors.
- **The upload format has no muscle-group field** [S3]. Strava derives muscles from `exercise_type`, so the README §12 wording "muscle groups are still in the Strava payload" is wrong: our Muscle Groups never reach Strava.
- **Third-party uploads**: Strava's press release and support pages describe partner apps (Hevy, Fitbod, Garmin, …) syncing sets, and say every logged workout gets a map [S12, S13].
  - In a dev-forum thread from 2026-07-03, a developer using `POST /uploads` with `data_type=json` and `sport_type=WeightTraining` reported the map on some accounts but not others with identical JSON.
  - Strava Community Manager Emily_A said muscle maps "are generated through uploaded activity files for WeightTraining, HighIntensityIntervalTraining, Workout, and Crossfit activities", then referred the developer to developers@strava.com. **No resolution was posted** [S9].
  - Status: **supported in principle, reliability unverified.**

## 4. Sport type

- **Confirmed** [S1, S3]: `sport_type=WeightTraining`. It is case-sensitive and appears in the `SportType` enum. The deprecated `type` / `activity_type` value is `WeightTraining` too.
- Structured sets are accepted only for `WeightTraining`, `HighIntensityIntervalTraining`, `Workout`, `Crossfit` [S3].
- **Unverified:** what sport type Strava infers from a JSON file with no `sport_type` field. Always send `sport_type=WeightTraining`, which is also what the forum reporter did [S9].

## 5. OAuth

All of the following is **confirmed** [S4] unless noted.

- **Authorize URLs**
  - Web: `GET https://www.strava.com/oauth/authorize`.
  - Mobile: `GET https://www.strava.com/oauth/mobile/authorize`.
  - On iOS, if the Strava app is installed (`canOpenURL` with `strava` in `LSApplicationQueriesSchemes`), open `strava://oauth/mobile/authorize?...` and the Strava app handles consent. Otherwise use `ASWebAuthenticationSession` with the web mobile URL. Mobile OAuth needs Strava app version 75.0 or later.
- **Authorize parameters**
  - `client_id`, `redirect_uri`, `response_type=code`, `scope` (comma- or space-separated), and optional `approval_prompt=auto|force` (default `auto`) and `state`.
  - `redirect_uri` "must be within the callback domain specified by the application"; `localhost` and `127.0.0.1` are allow-listed.
  - The iOS sample uses a custom scheme whose host is the callback domain: `YourApp://www.yourapp.com/en-US`.
  - **Unverified:** how strictly a custom scheme's host is matched.
- **Scope**
  - `activity:write` grants "create manual activities and uploads".
  - The user can untick scopes, so check the `scope` returned on the redirect and in the token response. The token response has included `scope` since 2026-04-23 [S2].
- **Token exchange**
  - `POST https://www.strava.com/oauth/token` (the docs also use `/api/v3/oauth/token`) with `client_id`, `client_secret`, `code`, `grant_type=authorization_code`.
  - The response contains `token_type`, `access_token`, `expires_at`, `expires_in`, `refresh_token`, `athlete` (summary) and `scope`.
  - The `code` is short-lived and can be used once.
- **Lifetime and refresh**
  - Access tokens last **6 hours**.
  - Refresh with `grant_type=refresh_token`. If the current token expires in more than 1 h, the same one is returned.
  - Refresh tokens **may rotate**: always store the latest one, because "once a new refresh token is returned, the older refresh token is invalidated immediately".
- **Revocation**
  - Legacy: `POST https://www.strava.com/oauth/deauthorize?access_token=…`.
  - New since 2026-06-01: **`POST https://www.strava.com/oauth/revoke`** with `Authorization: Basic base64(client_id:client_secret)` and form field `token` (access or refresh token), plus optional `token_type_hint`.
    - Returns `200` with an empty body even if the token is unknown.
    - `503` is safe to retry.
    - `/oauth/revoke` becomes the only deauthorization endpoint from **2027-06-01**.
- **PKCE**: not documented. The secret-holding server exchange in ADR-0004 is the documented model.
- **Upcoming** [S2, S10]
  - Base URL `https://api-v3.strava.com`, available 2027-01-04. The community post spells it `www.api-v3.strava.com`; the changelog is authoritative.
  - Tokens must go in headers, not form parameters, from 2027-06-01.

## 6. Rate limits, athlete capacity, review

**Default limits: confirmed** [S6]

| Limit | 15 minutes | Day |
|---|---|---|
| Overall | 200 | 2,000 |
| "Non-upload" (every endpoint except `POST /activities`, `POST /uploads`, media upload) | 100 | 1,000 |

- `GET /uploads/{id}` polling counts against non-upload.
- The 15-minute windows reset at :00, :15, :30 and :45; the daily limit resets at midnight UTC.
- Over the limit you get `429`.
- The headers `X-RateLimit-Limit/Usage` and `X-ReadRateLimit-Limit/Usage` report the limits.

**Athlete capacity: confirmed** [S5, S6, S8, S10]

- New apps have **capacity 1 ("Single Player Mode")**: only the developer's own account can connect.
- After configuring the app, the owner can **self-upgrade** in the API Settings dashboard to capacity 10 with 400/15 min and 4,000/day overall and 200/2,000 read. No review.
- Above 10 athletes requires submitting the Developer Program form, with screenshots of every place Strava data appears and of the "Connect with Strava" button. Approval is not guaranteed and has no SLA [S6, S8 §3.6].
- The API Policy defines a Standard Tier with two levels (≤10 and ≤9,999 users) and an Extended Access Tier (10,000+, by approval) [S8 §3.3].
- **A Strava subscription is required to create and keep an API app** on the Standard Tier [S5, S10].
- For OnlyWorkout (one user, the owner), capacity 1 is enough. App Store distribution to others needs the self-upgrade, and review beyond 10 users.

## 7. Brand guidelines and API terms

**Brand guidelines: confirmed** [S7], last revised 2025-09-29

- **"Connect with Strava" button**
  - If used, it must link to `https://www.strava.com/oauth/authorize` or `/oauth/mobile/authorize`.
  - Comes in orange or white; height 48 px @1x / 96 px @2x.
  - Assets: `https://developers.strava.com/downloads/1.1-Connect-with-Strava-Buttons.zip`.
- **"Powered by Strava" / "Compatible with Strava" logos**: orange, white or black, horizontal and stacked (`/downloads/1.2-Strava-API-Logos.zip`).
  - Never imply Strava developed or sponsors the app.
  - Keep the logos separate from, and no more prominent than, the app's name or logo.
  - Never use any part of them as the app icon; never modify or animate them.
- **Links to Strava data** must use the text **"View on Strava"**, legible and marked as a link by bold, underline, or orange `#FC5200`.
- **Naming**
  - "Strava" must not appear in the app name, and the word must not be set larger than the surrounding text.
  - References to interoperability must say "Powered by Strava" or "Compatible with Strava".
  - Truthful plain-text references are fine.

**API Agreement and API Policy: confirmed** [S14, S8], both effective 2026-06-01. The points relevant here:

- **Consent before accessing data** (§2.1): disclose what data is collected, how, how to withdraw consent, how to request deletion, and confirm deletion [S8].
- **Support and links**: provide support contact information and links to the user's Strava account [S8 §2.4].
- **Deletion** on user request, on revocation, or on Strava account deletion, within 30 days, with written confirmation to the user [S8 §2.5, §7.4].
- **Caching**: no Strava Data in a cache for longer than **7 days**. Strava Data the user deleted must disappear within 48 h [S8 §6.2–6.3].
  - **Open interpretation:** whether storing `strava_activity_id` long-term (for "View on Strava" and dedupe) counts as retained Strava Data. It is a returned identifier needed for the app's function (§6.4 "only so long as necessary"). Confirm with developers@strava.com if in doubt.
- **No AI/ML use** of Strava Data or anything derived from it (§5.3). This covers training, RAG, embeddings and "ingestion into a context window". It doesn't affect upload-only use, but **never feed data read back from Strava into an LLM feature**.
- **No analytics or aggregation** of Strava Data (§5.4).
- **No charging users** for Strava functionality (§5.8).
- **No intermediary or proxy platforms** that re-expose the API (§5.16). OnlyWorkout's own Supabase functions are a direct integration, not a third-party intermediary [S10].
- **No implied endorsement**, and no press release mentioning Strava without consent (§4.3, §4.6).
- **Privacy policy**: the app's privacy policy must meet GDPR and include a statement that Strava collects Usage Data (§6.5, §7.3).
- **Security breaches** must be reported to legal@strava.com within 24 h (§8.3).

## 8. Webhooks

**Mechanism: confirmed** [S15]

- One push subscription per app, managed at `https://www.strava.com/api/v3/push_subscriptions`. Create it with `client_id`, `client_secret`, `callback_url` (≤255 chars) and `verify_token`.
- Strava validates the callback with a GET carrying `hub.mode=subscribe`, `hub.challenge` and `hub.verify_token`. The callback must reply within **2 s** with a 200 JSON body `{"hub.challenge": "…"}`.
- Events arrive as a POST that must be acknowledged with a 200 within 2 s. Strava makes up to 3 attempts.
- Event fields: `object_type` (`activity`|`athlete`), `object_id`, `aspect_type` (`create`|`update`|`delete`), `updates`, `owner_id`, `subscription_id`, `event_time`.
- **Deauthorization** arrives as an `athlete` event with `updates: {"authorized": "false"}`.

**Do we need them?** Yes.

- The Getting Started guide states: "Per our API terms, you need to implement webhooks to know when an athlete has deauthorized your API application" [S5].
- The Policy requires deleting data after revocation [S8 §7.4].
- Activity events (create/delete/update) require `activity:read`; the authorize docs say "The scope activity:read is required for activity webhooks" [S4]. With only `activity:write`, we won't hear when the user deletes the uploaded activity on Strava.
- **Unverified:** whether athlete deauthorization events are delivered to apps holding only `activity:write`. The docs don't tie them to a scope.

---

## Implications for M4

**Endpoint and payload**

- `strava-upload` sends `POST {base}/uploads` as multipart: `file` (Blob of JSON, filename `<session_id>.json`), `data_type=json`, `sport_type=WeightTraining`, `name` (e.g. the Workout name), `external_id=<session uuid>`, and optionally `description`.
- Keep the base URL a single constant so that the switch to `https://api-v3.strava.com` (2027) is one line.
- Send the token as an `Authorization: Bearer` header; form-param tokens are being retired [S10].

**Building the JSON**

| JSON field | Value |
|---|---|
| `version` | `"1.0"` |
| `start_time` | `sessions.started_at` in UTC with `Z` |
| `elapsed_time` | `ended_at - started_at` |
| `utc_offset` | **Not in the schema today.** Either the app sends it with the `strava-upload` call (`TimeZone.current.secondsFromGMT(for: startedAt)`), or `sessions` gains a synced `utc_offset` column (migration + record + `write(to:)`). The column survives re-uploads from another device, so prefer it. |
| `creator` | `{ "name": "OnlyWorkout" }` |
| `sets[]` | one entry per stored Set of every `done` Session Exercise, in performed order: `exercise_type`, `repetitions`, `weight` (kg) |

- Omit `weight` when it is 0, for example a bodyweight Set with no Added Weight.
- Skip Session Exercises with no `strava_exercise_type`.
- If no Set is left, don't upload: `sets` needs at least one entry.
- `start_time` per Set is optional, and we only store `completed_at`. Omit it, or don't put completion times in a "start" field.
- Do **not** send `streams.heartrate`, `active_time` from Health, or `total_calories` (Health data stays on device).
- **Test first on the owner's account**: dumbbell weight per hand vs total, bodyweight Added Weight, set ordering and grouping, and whether the muscle map appears. Record the results in README §12.

**Polling**

- After `201`, poll `GET /uploads/{id}` about once per second for up to ~10–15 s. Mean processing time is under 2 s.
- On "ready", write `activity_id` to `sessions.strava_activity_id`.
- On `error`, surface the message. A "duplicate of activity N" error can store N.
- If processing runs past the window, store `upload_id` and let a later call resume polling instead of uploading again.

**Exercise mapping**

- `exercises.strava_exercise_type` (already in the schema) holds one identifier from the appendix.
- Ship it for every seed Exercise with the values in the table below.
- For Custom Exercises, let the user pick from a searchable list grouped by Strava group, or none. Ship the list as a static resource or in an Edge Function.
- Validate server-side against the list so a typo can't fail an upload.

**Seed catalog → `exercise_type`** (every ID checked against the list)

| Key | `exercise_type` |
|---|---|
| barbell-bench-press | BARBELL_BENCH_PRESS |
| incline-dumbbell-press | INCLINE_DUMBBELL_BENCH_PRESS |
| dumbbell-bench-press | DUMBBELL_BENCH_PRESS |
| machine-chest-press | MACHINE_CHEST_PRESS |
| cable-fly | CABLE_CROSSOVER |
| push-up | PUSH_UP_GENERIC |
| dip | CHEST_DIP (or BODY_WEIGHT_DIP) |
| pull-up | PULL_UP_GENERIC |
| chin-up | CLOSE_GRIP_CHIN_UP |
| lat-pulldown | LAT_PULLDOWN |
| seated-cable-row | SEATED_CABLE_ROW |
| barbell-row | BENT_OVER_BARBELL_ROW |
| one-arm-dumbbell-row | DUMBBELL_ROW |
| chest-supported-row | MACHINE_CHEST_SUPPORTED_ROW |
| face-pull | FACE_PULL |
| deadlift | BARBELL_DEADLIFT |
| back-extension | BACK_EXTENSION |
| overhead-press | OVERHEAD_BARBELL_PRESS |
| seated-dumbbell-press | SEATED_DUMBBELL_SHOULDER_PRESS |
| lateral-raise | LATERAL_RAISE_GENERIC (no standing dumbbell ID; SEATED_DUMBBELL_LATERAL_RAISE exists) |
| rear-delt-fly | MACHINE_REAR_DELT_REVERSE_FLY |
| dumbbell-shrug | DUMBBELL_SHRUG |
| barbell-curl | BARBELL_BICEPS_CURL |
| dumbbell-curl | STANDING_DUMBBELL_BICEPS_CURL |
| hammer-curl | DUMBBELL_HAMMER_CURL |
| triceps-pushdown | CABLE_TRICEPS_PUSHDOWN |
| overhead-triceps-extension | CABLE_OVERHEAD_TRICEPS_EXTENSION |
| skull-crusher | SKULL_CRUSHER |
| back-squat | BARBELL_BACK_SQUAT |
| front-squat | BARBELL_FRONT_SQUAT |
| goblet-squat | GOBLET_SQUAT |
| leg-press | MACHINE_LEG_PRESS |
| romanian-deadlift | BARBELL_ROMANIAN_DEADLIFT |
| bulgarian-split-squat | DUMBBELL_BULGARIAN_SPLIT_SQUATS |
| walking-lunge | DUMBBELL_WALKING_LUNGES |
| leg-extension | MACHINE_LEG_EXTENSION |
| leg-curl | LEG_CURL_GENERIC (seated machine: MACHINE_LEG_CURL_SEATED; no lying-machine ID) |
| hip-thrust | BARBELL_HIP_THRUST |
| hip-adduction | MACHINE_HIP_ADDUCTION |
| standing-calf-raise | STANDING_CALF_RAISE |
| seated-calf-raise | SEATED_CALF_RAISE |
| hanging-leg-raise | HANGING_LEG_RAISE |
| cable-crunch | CABLE_CRUNCH |
| ab-wheel-rollout | AB_WHEEL_ROLLOUT |

Other Exercises you asked about: plank → `PLANK_GENERIC` (send `duration`), crunch → `CRUNCH`, barbell shrug → `BARBELL_SHRUG`, pec deck → `PEC_DECK_BUTTERFLY`.

**OAuth redirect**

- Register a callback domain in Strava's API settings, e.g. `onlyworkout.app` or a domain the owner controls.
- Use a custom-scheme redirect whose host is that domain, e.g. `onlyworkout://onlyworkout.app/strava`, as in Strava's iOS sample.
- `ASWebAuthenticationSession(url: https://www.strava.com/oauth/mobile/authorize?..., callback: .customScheme("onlyworkout"))` with `scope=activity:write`, `approval_prompt=auto` and a random `state` verified on return.
- **Optional improvement:** when `canOpenURL(strava://)` is true, open `strava://oauth/mobile/authorize` so the installed app handles consent. The redirect then comes back through `onOpenURL` rather than the auth session. This needs `strava` in `LSApplicationQueriesSchemes`.
- After the redirect, check that `scope` contains `activity:write`. If it doesn't, show "Allow uploads" guidance and don't call `strava-connect`.

**Token storage** (`strava_connections`, not readable by clients)

- Columns: `user_id`, `athlete_id` (needed to match webhook `owner_id`), `access_token`, `expires_at`, `refresh_token`, `scope`, `created_at`, `updated_at`.
- Refresh when `expires_at` is within 1 h. Persist the returned `refresh_token` in the same transaction every time.
- Don't keep the `athlete` summary beyond `athlete_id`.
- Strava's own docs suggest storing access and refresh tokens in separate tables; that is optional.

**Disconnect**

- `strava-disconnect` calls `POST /oauth/revoke` with Basic auth and the refresh token, then deletes the row. Use revoke now rather than the legacy endpoint.
- Clear or keep `strava_activity_id` according to the decision below.

**Webhook**

- Add one public Edge Function `strava-webhook`, deployed with no JWT verification.
- It answers the `hub.challenge` GET, checks `hub.verify_token` (a `supabase secrets` value), and acknowledges POSTs within 2 s.
- On `object_type=athlete` with `updates.authorized=="false"`, delete that athlete's `strava_connections` row.
- Create the subscription once by hand; this is an owner setup step.
- **Decision for the owner:** also request `activity:read` so `delete` events can clear `strava_activity_id` within 48 h (Policy §6.3)? This is extra scope, but it keeps "View on Strava" honest.

**UI and branding**

- Use the official "Connect with Strava" asset (orange or white, 48 pt tall) in Settings → Strava.
- On Session detail, use a "View on Strava" text link, bold or `#FC5200`, opening `https://www.strava.com/activities/{id}`.
- Optionally show "Compatible with Strava" in About.
- Never put "Strava" in the app's name or icon.
- Before connecting, show a consent note naming what is uploaded (Sessions: exercises, Sets, reps, weight, time) and how to disconnect.
- Disconnect deletes tokens; confirm that to the user.

**Owner setup**

- An active **Strava subscription** is needed to create the API app.
- Store the client ID and secret in `supabase secrets`.
- Set the callback domain.
- Self-upgrade to capacity 10 only if anyone besides the owner will connect.

**Changes to make in docs**

- *README §12*:
  - Step 3: "via `POST /uploads` with a `data_type=json` file (Strava's 'Strength Training (Limited)' format); sets carry `exercise_type`, `repetitions`, `weight` (kg)".
  - Step 4: muscle groups are **not** sent; Strava derives them from `exercise_type`.
  - Step 6: `/oauth/revoke`.
  - Add the webhook function and the subscription prerequisite.
  - Replace "single athlete / app review" with "capacity 1 → self-upgrade to 10 → review above 10".
- *ADR-0004*: the "verify at M4 start" consequence is resolved. Add that the upload uses the JSON file format and that a webhook function is required for deauthorization.
- *Open questions*:
  - #2 resolved (the JSON upload and appendix list).
  - #3 stays open, now citing the staff-acknowledged but unresolved forum thread [S9]. Change the plan text: "muscle groups are still in the Strava payload" is not true.
  - New items: dumbbell/bodyweight weight semantics, and whether long-term storage of `strava_activity_id` is acceptable.

---

## Sources

- **S1** Strava API v3 swagger: <https://developers.strava.com/swagger/swagger.json>, plus `sport_type.json`, `upload.json` and `activity.json` under the same path. Also <https://developers.strava.com/docs/reference/>.
- **S2** Strava V3 API Changelog, entries 2026-04-23, 2026-05-21, 2026-06-01, 2026-09-01: <https://developers.strava.com/docs/changelog/>
- **S3** Uploading to Strava (FIT set messages, JSON strength format, Supported Exercises, upload status): <https://developers.strava.com/docs/uploads/>
- **S4** Authentication (mobile OAuth, scopes, token exchange and refresh, deauthorize, revoke): <https://developers.strava.com/docs/authentication/>
- **S5** Getting Started (single-player mode, subscription requirement, webhook requirement): <https://developers.strava.com/docs/getting-started/>
- **S6** Rate Limits and Athlete Capacity: <https://developers.strava.com/docs/rate-limits/>
- **S7** Strava API Brand Guidelines (rev. 2025-09-29): <https://developers.strava.com/guidelines/>
- **S8** Strava API Policy (2026), effective 2026-06-01: <https://www.strava.com/legal/api_policy>
- **S9** Community Hub, "Add Muscle group via APi" (2026-07-03..07). Replies by Strava Community Manager Emily_A: <https://communityhub.strava.com/developers-api-7/add-muscle-group-via-api-13631>
- **S10** Community Hub, "An Update To Our Developer Program" by Strava Community Manager Elliott, 2026-06-01: <https://communityhub.strava.com/insider-journal-9/an-update-to-our-developer-program-13428>
- **S11** Strava Support, "Muscle Map for Strength Activities": <https://support.strava.com/en-us/articles/15401529-muscle-map-for-strength-activities>
- **S12** Strava Support, "Strength Training": <https://support.strava.com/en-us/articles/15401547-strength-training>
- **S13** Strava Press, "Strava Overhauls Strength Experience…" (2026-05-21): <https://press.strava.com/articles/strava-overhauls-strength-experience-with-expanded-partner-ecosystem-new-workout-log-and-muscle-maps>
- **S14** Strava API Agreement (2026), effective 2026-06-01: <https://www.strava.com/legal/api>
- **S15** Webhook Events API: <https://developers.strava.com/docs/webhooks/>
- **S16** Garmin FIT SDK profile, Profile Version 21.217.0 (`set` message 225, `exercise_category`, `*_exercise_name`, `sport`, `sub_sport`): <https://github.com/garmin/fit-javascript-sdk/blob/main/src/profile.js>; SDK home <https://developer.garmin.com/fit/>
- Not used as evidence: a non-staff reply in <https://communityhub.strava.com/developers-api-7/how-to-get-strength-training-sets-with-api-13665> says there is no public endpoint for *reading* sets back. Unverified, and M4 doesn't need it.

---

## Appendix: Strava `exercise_type` identifiers

Copied from "Supported Exercises" at <https://developers.strava.com/docs/uploads/> on 2026-10-03. There are 656 identifiers; the group headings are Strava's.

**Bench Press** (28): `BENCH_PRESS_GENERIC`, `BARBELL_BENCH_PRESS`, `DUMBBELL_BENCH_PRESS`, `INCLINE_DUMBBELL_BENCH_PRESS`, `INCLINE_BARBELL_BENCH_PRESS`, `CLOSE_GRIP_BARBELL_BENCH_PRESS`, `WIDE_GRIP_BARBELL_BENCH_PRESS`, `SINGLE_ARM_CABLE_CHEST_PRESS`, `DECLINE_DUMBBELL_BENCH_PRESS`, `NEUTRAL_GRIP_DUMBBELL_BENCH_PRESS`, `NEUTRAL_GRIP_DUMBBELL_INCLINE_BENCH_PRESS`, `FLOOR_BENCH_PRESS`, `CHEST_PRESS`, `DUMBBELL_FLOOR_PRESS`, `BARBELL_FEET_UP_BENCH_PRESS`, `MACHINE_DECLINE_BENCH_PRESS`, `SMITH_MACHINE_INCLINE_BENCH_PRESS`, `MACHINE_INCLINE_CHEST_PRESS`, `MACHINE_CHEST_PRESS`, `MACHINE_ISOLATERAL_CHEST_PRESS`, `DUMBBELL_SQUEEZE_PRESS`, `PLATE_PRESS`, `SVEND_PRESS_PLATE_SQUEEZE`, `SINGLE_ARM_DUMBBELL_BENCH_PRESS`, `BARBELL_FLOOR_PRESS`, `SINGLE_ARM_DUMBBELL_FLOOR_PRESS`, `CLOSE_GRIP_DUMBBELL_CHEST_PRESS`, `PAUSED_BENCH_PRESS`

**Calf Raise** (16): `CALF_RAISE_GENERIC`, `STANDING_CALF_RAISE`, `SEATED_CALF_RAISE`, `SINGLE_LEG_STANDING_CALF_RAISE`, `WALKING_CALF_RAISES`, `BENT_KNEE_CALF_RAISE`, `DOUBLE_LEG_CALF_RAISE_ON_STEP`, `FLOATING_HEEL_DROP`, `MACHINE_CALF_EXTENSION`, `MACHINE_CALF_PRESS`, `SINGLE_LEG_BARBELL_CALF_RAISE`, `DUMBBELL_DOUBLE_LEG_CALF_RAISE_ON_STEP`, `SINGLE_LEG_DUMBBELL_STANDING_CALF_RAISE`, `BENT_KNEE_DUMBBELL_CALF_RAISE`, `DUMBBELL_WALKING_CALF_RAISES`, `SEATED_DUMBBELL_CALF_RAISE`

**Cardio** (17): `CARDIO_GENERIC`, `JUMP_ROPE`, `JUMPING_JACKS`, `CARDIO_CORE_CRAWL`, `SKI_MOGULS`, `BATTLE_ROPES`, `ROWING_MACHINE`, `SLED_PUSH`, `HIGH_KNEES`, `WALL_BALL`, `SKI_ERG`, `ASSAULT_BIKE`, `BURPEE_BROAD_JUMP`, `DOUBLE_UNDERS`, `STAIRMASTER`, `RUNNING`, `AGILITY_LADDER`

**Carry** (7): `CARRY_GENERIC`, `BAR_HOLDS`, `FARMERS_WALK`, `OVERHEAD_CARRY`, `FARMERS_CARRY`, `DEAD_HANG`, `SUITCASE_CARRY`

**Chop** (7): `CHOP_GENERIC`, `CROSS_CHOP_TO_KNEE`, `HALF_KNEELING_ROTATIONAL_CHOP`, `STANDING_ROTATIONAL_CHOP`, `CABLE_WOODCHOP`, `DOWN_TO_UP_CABLE_TWIST`, `UP_TO_DOWN_CABLE_TWIST`

**Core** (64): `CORE_GENERIC`, `SWIMMING`, `LOWER_LIFT`, `RUSSIAN_TWIST`, `BARBELL_ROLLOUT`, `SIDE_BEND`, `HALF_TURKISH_GET_UP`, `MODIFIED_FRONT_LEVER`, `GHD_BACK_EXTENSIONS`, `OVERHEAD_WALK`, `CAT_COW`, `THE_HUNDRED`, `CABLE_CORE_PRESS`, `CABLE_SIDE_BEND`, `KETTLEBELL_WINDMILL`, `SWISS_BALL_JACKKNIFE`, `BICYCLE_CRUNCH`, `HOLLOW_ROCK`, `LEG_EXTENSIONS`, `REVERSE_CRUNCH`, `HANGING_KNEE_RAISE`, `CABLE_CRUNCH`, `CRUNCH`, `TURKISH_GET_UP`, `DEADBUG`, `STRAIGHT_LEG_RAISE`, `FIGURE_OF_8S`, `SWISSBALL_STIR_POT`, `CRUNCH_AND_PRESS`, `DIAGONAL_TOE_TAP`, `TRAVELLING_PRESS_UP_WALK_OUT`, `TOE_SCRUNCHES`, `BIRD_DOG`, `HIP_DROP`, `BANDED_DEADBUG`, `STANDING_MARCH`, `BICYCLE_CRUNCH_RAISED_LEGS`, `DECLINE_CRUNCH`, `WEIGHTED_DECLINE_CRUNCH`, `DRAGON_FLAG`, `ELBOW_TO_KNEE`, `HEEL_TAPS`, `LYING_KNEE_RAISE`, `OBLIQUE_CRUNCH`, `FRONT_LEVER_HOLD`, `FRONT_LEVER_RAISE`, `PALLOF_PRESS`, `AB_WHEEL_ROLLOUT`, `AB_CRUNCH_MACHINE`, `MEDICINE_BALL_CRUNCH`, `LEG_LIFTS`, `FLUTTER_KICKS`, `GHD_SIT_UP`, `TOES_TO_BAR`, `WEIGHTED_TOE_TAPS`, `DUMBBELL_RUSSIAN_TWIST`, `MODIFIED_PRESS_UP_POSITION_SHOULDER_TAP`, `DUMBBELL_SIDE_BEND`, `SIDE_PLANK_HIP_FLEXION`, `BANDED_SIDE_PLANK_HIP_FLEXION`, `BANDED_SIDE_PLANK_LEG_RAISE`, `REVERSE_PLANK`, `PLANK_SHOULDER_TAP`, `BANDED_BICYCLE`

**Curl** (36): `CURL_GENERIC`, `DUMBBELL_HAMMER_CURL`, `BARBELL_BICEPS_CURL`, `CABLE_BICEPS_CURL`, `BARBELL_REVERSE_WRIST_CURL`, `BARBELL_WRIST_CURL`, `CABLE_HAMMER_CURL`, `INCLINE_DUMBBELL_BICEPS_CURL`, `STANDING_DUMBBELL_BICEPS_CURL`, `EZ_BAR_PREACHER_CURL`, `STANDING_EZ_BAR_BICEPS_CURL`, `KETTLEBELL_BICEPS_CURL`, `DUMBBELL_REVERSE_WRIST_CURL`, `BANDED_HAMSTRING_CURL`, `DUMBBELL_WRIST_CURL`, `TWENTY_ONES_BICEP_CURL`, `MACHINE_BICEP_CURL`, `SUSPENSION_BICEP_CURL`, `CONCENTRATION_CURL`, `CROSS_BODY_HAMMER_CURL`, `DRAG_CURL`, `CABLE_OVERHEAD_CURL`, `DUMBBELL_PINWHEEL_CURL`, `PLATE_CURL`, `BARBELL_REVERSE_CURL`, `ROPE_CABLE_CURL`, `DUMBBELL_ZOTTMAN_CURL`, `BARBELL_BEHIND_THE_BACK_BICEP_WRIST_CURL`, `SEATED_PALMS_UP_WRIST_CURL`, `BARBELL_SEATED_WRIST_EXTENSION`, `WRIST_ROLLER`, `PREACHER_CURL_MACHINE`, `SPIDER_CURL`, `CABLE_CURL`, `REVERSE_CABLE_CURLS`, `BAYESIAN_CURL`

**Deadlift** (26): `DEADLIFT_GENERIC`, `BARBELL_DEADLIFT`, `DUMBBELL_DEADLIFT`, `BARBELL_STRAIGHT_LEG_DEADLIFT`, `SUMO_DEADLIFT`, `RACK_PULL`, `TRAP_BAR_DEADLIFT`, `SINGLE_LEG_STRAIGHT_LEG_DEADLIFT`, `STRAIGHT_LEG_DEADLIFT`, `KB_STRAIGHT_LEG_DEADLIFT`, `SL_DB_RDL_KNEE_DRIVE`, `CONVENTIONAL_DEADLIFTS`, `DUMBBELL_ROMANIAN_DEADLIFTS`, `ROMANIAN_DEADLIFTS`, `SINGLE_LEG_ROMANIAN_DEADLIFTS`, `STAGGERED_RDLS`, `CABLE_RDL`, `BARBELL_ROMANIAN_DEADLIFT`, `SNATCH_GRIP_DEADLIFT`, `KETTLEBELL_DEADLIFT`, `SL_RDL_KNEE_DRIVE`, `SINGLE_LEG_DUMBBELL_ROMANIAN_DEADLIFTS`, `BARBELL_STAGGERED_RDLS`, `SINGLE_LEG_DOUBLE_DUMBBELL_ROMANIAN_DEADLIFTS`, `SINGLE_LEG_BARBELL_ROMANIAN_DEADLIFTS`, `SINGLE_LEG_BODYWEIGHT_ROMANIAN_DEADLIFTS`

**Flye** (14): `FLYE_GENERIC`, `DUMBBELL_FLYE`, `CABLE_CROSSOVER`, `INCLINE_DUMBBELL_FLYE`, `KETTLEBELL_FLYE`, `DUMBBELL_CHEST_FLY`, `BAND_CHEST_FLY`, `SUSPENSION_CHEST_FLY`, `PEC_DECK_BUTTERFLY`, `LOW_CABLE_FLY_CROSSOVERS`, `INCLINE_REVERSE_FLY`, `INCLINE_CABLE_FLY`, `DUMBBELL_REAR_DELT_FLY`, `MACHINE_CHEST_FLY`

**Hip Raise** (26): `HIP_RAISE_GENERIC`, `BARBELL_HIP_THRUST_ON_FLOOR`, `CLAMS`, `SINGLE_LEG_HIP_RAISE`, `BARBELL_HIP_THRUST_WITH_BENCH`, `HIP_RAISE`, `ABDUCTOR_SIDE_LEG_RAISE`, `STEP_DOWN`, `RAISED_LEG_HIP_THRUST`, `SINGLE_LEG_GLUTE_BRIDGE`, `STAGGERED_HIP_THRUST`, `BARBELL_HIP_THRUST`, `GLUTE_BRIDGE`, `LATERAL_WALK`, `THRUSTER`, `HIP_THRUST`, `SL_ISO_HAMSTRING_HOLD`, `GLUTE_BRIDGE_HAM_WALKOUT`, `BARBELL_PARTIAL_GLUTE_BRIDGE`, `DUMBBELL_SINGLE_LEG_HIP_THRUST`, `MACHINE_GLUTE_KICKBACK`, `GLUTE_KICKBACK_ON_FLOOR`, `DUMBBELL_HIP_THRUST`, `PLATE_HIP_THRUST`, `BARBELL_SINGLE_LEG_HIP_THRUST`, `SINGLE_LEG_GLUTE_BRIDGE_ABDUCTION`

**Hip Stability** (15): `HIP_STABILITY_GENERIC`, `FIRE_HYDRANT_KICKS`, `PRONE_HIP_INTERNAL_ROTATION`, `QUADRUPED`, `SIDE_LYING_LEG_RAISE`, `STANDING_ADDUCTION`, `STANDING_HIP_ABDUCTION`, `LATERAL_WALKS_WITH_BAND_AT_ANKLES`, `FIRE_HYDRANTS`, `MACHINE_HIP_ABDUCTION`, `MACHINE_HIP_ADDUCTION`, `DONKEY_KICKS`, `CABLE_KICKBACK`, `CABLE_HIP_ABDUCTION`, `HIP_AIRPLANE`

**Hip Swing** (5): `KETTLEBELL_SWING`, `HIP_SWING_GENERIC`, `STEP_OUT_SWING`, `SINGLE_ARM_DUMBBELL_SWING`, `SINGLE_ARM_KETTLEBELL_SWING`

**Hyperextension** (6): `HYPEREXTENSION_GENERIC`, `BACK_EXTENSION_WITH_OPPOSITE_ARM_AND_LEG_REACH`, `BACK_EXTENSION`, `SUPERMAN_FROM_FLOOR`, `MACHINE_BACK_EXTENSION`, `REVERSE_HYPER`

**Lateral Raise** (20): `LATERAL_RAISE_GENERIC`, `FRONT_RAISE`, `BAR_MUSCLE_UP`, `MUSCLE_UP`, `WALL_SLIDE`, `FORTY_FIVE_DEGREE_CABLE_EXTERNAL_ROTATION`, `RING_DIP`, `RING_MUSCLE_UP`, `ROPE_CLIMB`, `BAND_PULLAPARTS`, `OVERHEAD_PLATE_RAISE`, `PLATE_FRONT_RAISE`, `CABLE_REAR_DELT_REVERSE_FLY`, `MACHINE_REAR_DELT_REVERSE_FLY`, `KETTLEBELL_AROUND_THE_WORLD`, `KETTLEBELL_HALO`, `HANDSTAND_HOLD`, `CABLE_LATERAL_RAISE`, `CABLE_REAR_DELT_FLY`, `SEATED_DUMBBELL_LATERAL_RAISE`

**Leg Curl** (10): `LEG_CURL_GENERIC`, `GOOD_MORNING`, `SLIDING_LEG_CURL`, `NORDIC_CURL`, `GLUTE_HAM_RAISE`, `MACHINE_LEG_CURL_SEATED`, `CABLE_GOOD_MORNING`, `STANDING_LEG_CURL`, `MACHINE_SINGLE_LEG_CURL_SEATED`, `BARBELL_GOOD_MORNING`

**Leg Raise** (6): `LEG_RAISE_GENERIC`, `HANGING_LEG_RAISE`, `LYING_STRAIGHT_LEG_RAISE`, `KNEE_DRIVE`, `STEP_UPS`, `LEG_RAISE_PARALLEL_BARS`

**Lunge** (28): `LUNGE_GENERIC`, `WALKING_LUNGE`, `BARBELL_REVERSE_LUNGE`, `BARBELL_BULGARIAN_SPLIT_SQUAT`, `BARBELL_LUNGE`, `SIDE_LUNGE`, `OVERHEAD_LUNGE`, `REVERSE_LUNGE`, `STATIC_LUNGE`, `BARBELL_OVERHEAD_LUNGE`, `REAR_LEG_RAISED_LUNGE`, `FRONT_LEG_RAISED_LUNGE`, `BANDED_SIDE_LUNGE`, `LUNGE_HOLD_CALF_RAISE`, `LUNGE_AND_PRESS`, `DUMBBELL_WALKING_LUNGES`, `LATERAL_LUNGE`, `SMITH_MACHINE_LUNGE`, `BARBELL_SPLIT_SQUAT`, `SKATER_LUNGE`, `SANDBAG_LUNGE`, `OVERHEAD_PLATE_LUNGE`, `SINGLE_ARM_DUMBBELL_OVERHEAD_LUNGE`, `WALKING_LUNGE_TWIST`, `DUMBBELL_REVERSE_LUNGE`, `CURTSY_LUNGE`, `DUMBBELL_SPLIT_SQUAT`, `KETTLEBELL_LUNGE`

**Olympic Lift** (37): `OLYMPIC_LIFT_GENERIC`, `CLEAN`, `BARBELL_HANG_POWER_CLEAN`, `BARBELL_HANG_SQUAT_CLEAN`, `BARBELL_POWER_CLEAN`, `BARBELL_POWER_SNATCH`, `BARBELL_SQUAT_CLEAN`, `BARBELL_HANG_POWER_SNATCH`, `BARBELL_HANG_PULL`, `BARBELL_HIGH_PULL`, `BARBELL_SNATCH`, `BARBELL_SPLIT_JERK`, `CLEAN_AND_JERK`, `PUSH_JERK`, `SINGLE_ARM_HANG_SNATCH`, `SPLIT_JERK`, `SQUAT_CLEAN_AND_JERK`, `DUMBBELL_CLEAN`, `DUMBBELL_HANG_PULL`, `ONE_HAND_DUMBBELL_SPLIT_SNATCH`, `SINGLE_ARM_DUMBBELL_SNATCH`, `SINGLE_ARM_KETTLEBELL_SNATCH`, `SINGLE_ARM_CLEAN_AND_PRESS`, `SINGLE_ARM_SNATCH`, `DOUBLE_ARM_CLEAN_AND_PRESS`, `DOUBLE_ARM_SNATCH`, `KETTLEBELL_CLEAN`, `BARBELL_HANG_SQUAT_SNATCH`, `BEHIND_THE_NECK_JERK`, `SNATCH_BALANCE`, `MUSCLE_SNATCH`, `MUSCLE_CLEAN`, `CLUSTER`, `DUMBBELL_THRUSTERS`, `DOUBLE_ARM_CLEAN_AND_PRESS_BARBELL`, `DUMBBELL_DOUBLE_ARM_SNATCH`, `DEVIL_PRESS`

**Plank** (16): `PLANK_GENERIC`, `MOUNTAIN_CLIMBER`, `PLANK_WITH_ARM_RAISE`, `CROSS_BODY_MOUNTAIN_CLIMBER`, `BEAR_CRAWL`, `SIDE_PLANK`, `SIDEPLANK_HIP_FLEXORS`, `SIDE_PLANK_LEG_RAISE`, `SL_COPENHAGEN_PLANK`, `LL_COPENHAGEN_PLANK`, `PLANK_TWIST`, `PLANK_PULL_THROUGH`, `PLANK_ON_SWISSBALL`, `SWISSBALL_HIGH_PLANK`, `PLANK_HOLD`, `SIDE_PLANK_HOLD`

**Plyo** (22): `PLYO_GENERIC`, `BODY_WEIGHT_JUMP_SQUAT`, `ALTERNATING_JUMP_LUNGE`, `CROSS_KNEE_STRIKE`, `DEPTH_JUMP`, `LATERAL_LEAP_AND_HOP`, `MEDICINE_BALL_OVERHEAD_THROWS`, `MEDICINE_BALL_SLAM`, `BOX_JUMP`, `FULL_STAR_JUMPS`, `POGO_JUMPS`, `HURDLE_HOPS`, `SL_BOX_JUMP`, `DL_SKIPPING`, `BOX_JUMP_DOWN_TUCK_JUMP`, `SEATED_START_BOX_JUMP`, `BALL_SLAMS`, `LATERAL_BOX_JUMP`, `BOX_JUMP_DOWN`, `BROAD_JUMP`, `BOX_JUMP_OVER`, `LATERAL_MEDICINE_BALL_SLAM`

**Pull Up** (18): `PULL_UP_GENERIC`, `LAT_PULLDOWN`, `CLOSE_GRIP_CHIN_UP`, `STRAIGHT_ARM_PULLDOWN`, `ASSISTED_CHIN_UP`, `WEIGHTED_CHIN_UP`, `NEGATIVE_PULL_UP`, `RING_PULL_UP`, `GIRONDA_STERNUM_PULL_UP`, `WIDE_PULL_UP`, `CABLE_LAT_PULLDOWN_CLOSE_GRIP`, `SINGLE_ARM_LAT_PULLDOWN`, `UNDERHAND_LAT_PULLDOWN`, `NEUTRAL_GRIP_LAT_PULLDOWN`, `NEUTRAL_GRIP_PULL_UP`, `CHEST_TO_BAR_PULL_UP`, `MACHINE_ASSISTED_PULL_UP`, `ARCHER_PULL_UP`

**Push Up** (15): `PUSH_UP_GENERIC`, `DECLINE_PUSH_UP`, `DIAMOND_PUSH_UP`, `HANDSTAND_PUSH_UP`, `INCLINE_PUSH_UP`, `ONE_ARM_PUSH_UP`, `MILITARY_PRESS_UP`, `MODIFIED_PUSH_UP`, `PLANK_TO_PUSH_UP`, `CLAP_PUSH_UPS`, `MODIFIED_SHOULDER_FOCUSED_PRESS_UP`, `MODIFIED_MILITARY_PRESS_UP`, `PIKE_PUSH_UP`, `ARCHER_PUSH_UP`, `WALL_PUSH_UP`

**Row** (30): `ROW_GENERIC`, `SEATED_CABLE_ROW`, `DUMBBELL_ROW`, `FACE_PULL`, `RENEGADE_ROW`, `REVERSE_GRIP_BARBELL_ROW`, `T_BAR_ROW`, `KETTLEBELL_ROW`, `ROLL_DOWN`, `BENT_OVER_ROW`, `SWISSBALL_BACK_EXTENSION`, `SUPERMAN`, `BENT_OVER_BARBELL_ROW`, `BENT_OVER_DUMBBELL_ROW`, `MACHINE_ISOLATERAL_HIGH_ROW`, `LANDMINE_ROW`, `SUSPENSION_LOW_ROW`, `MACHINE_SEATED_ROW`, `DUMBBELL_PULLOVER`, `MACHINE_PULLOVER`, `MACHINE_CHEST_SUPPORTED_ROW`, `SEAL_ROW`, `MEADOWS_ROW`, `SMITH_MACHINE_ROW`, `CHEST_SUPPORTED_ROW`, `SLED_PULL`, `RING_ROW`, `MACHINE_SINGLE_ARM_SEATED_ROW`, `INVERTED_ROW`, `GORILLA_ROW`

**Shoulder Press** (22): `SHOULDER_PRESS_GENERIC`, `OVERHEAD_BARBELL_PRESS`, `BARBELL_PUSH_PRESS`, `ARNOLD_PRESS`, `OVERHEAD_DUMBBELL_PRESS`, `STANDING_SINGLE_ARM_SHOULDER_PRESS`, `FLOOR_SEATED_SINGLE_ARM_SHOULDER_PRESS`, `STANDING_DOUBLE_ARM_SHOULDER_PRESS`, `FLOOR_SEATED_DOUBLE_ARM_SHOULDER_PRESS`, `PUSH_PRESS`, `STANDING_BARBELL_PRESS`, `SEATED_BARBELL_PRESS`, `BARBELL_BEHIND_THE_HEAD_SHOULDER_PRESS`, `PRESS_UP_POSITION_SHOULDER_TAP`, `SHOULDER_FOCUSED_PRESS_UP`, `DUMBBELL_PUSH_PRESS`, `SMITH_MACHINE_OVERHEAD_PRESS`, `MACHINE_SEATED_SHOULDER_PRESS`, `LANDMINE_SQUAT_AND_PRESS`, `SEATED_DUMBBELL_SHOULDER_PRESS`, `Z_PRESS`, `MACHINE_SINGLE_ARM_SEATED_SHOULDER_PRESS`

**Shoulder Stability** (8): `SHOULDER_STABILITY_GENERIC`, `FLOOR_I_RAISE`, `FLOOR_T_RAISE`, `FLOOR_Y_RAISE`, `INCLINE_L_RAISE`, `INCLINE_W_RAISE`, `CABLE_PULL_APART`, `WALL_WALK`

**Shrug** (9): `SHRUG_GENERIC`, `BARBELL_SHRUG`, `BARBELL_UPRIGHT_ROW`, `SCAPULAR_RETRACTION`, `SERRATUS_SHRUG`, `JUMP_SHRUG`, `CABLE_UPRIGHT_ROW`, `DUMBBELL_SHRUG`, `KETTLEBELL_UPRIGHT_ROW`

**Sit Up** (6): `SIT_UP_GENERIC`, `V_UP`, `THE_TEASER`, `PRESS_UP_POSITION_DIAGONAL_TOE_TAP`, `PRESS_UP_POSITION_WITH_SINGLE_ARM_EXTENSION`, `PRESS_UP_POSITION_WALK_OUT`

**Squat** (40): `SQUAT_GENERIC`, `BARBELL_BACK_SQUAT`, `GOBLET_SQUAT`, `LEG_PRESS`, `BARBELL_FRONT_SQUAT`, `BARBELL_SQUAT_SNATCH`, `BARBELL_STEP_UP`, `OVERHEAD_SQUAT`, `STEP_UP`, `PISTOL_SQUAT`, `SUMO_SQUAT`, `THRUSTERS`, `ZERCHER_SQUAT`, `KETTLEBELL_SQUAT`, `BARBELL_SQUAT`, `LOPSIDED_SQUAT`, `KB_FRONT_RACKED_SQUAT`, `STEP_UP_AND_KNEE_DRIVE`, `QUAD`, `SQUAT_TO_CALF_RAISE`, `DUMBBELL_BULGARIAN_SPLIT_SQUATS`, `DUMBBELL_GOBLET_SQUATS`, `GOBLET_SQUATS`, `WALL_SIT`, `BARBELL_BOX_SQUAT`, `ASSISTED_PISTOL_SQUATS`, `MACHINE_LEG_PRESS`, `MACHINE_HACK_SQUAT`, `MACHINE_SINGLE_LEG_PRESS`, `BELT_SQUAT`, `SMITH_MACHINE_SQUAT`, `MACHINE_LEG_EXTENSION`, `AIR_SQUAT`, `COSSACK_SQUAT`, `HEEL_ELEVATED_SQUAT`, `DUMBBELL_SQUAT`, `PENDULUM_SQUAT`, `SISSY_SQUAT`, `DUCK_WALK`, `SPANISH_SQUAT`

**Total Body** (6): `TOTAL_BODY_GENERIC`, `BURPEE`, `SQUAT_THRUSTS`, `STANDING_T_ROTATION_BALANCE`, `BURPEE_OVER_THE_BAR`, `TIRE_FLIP`

**Triceps Extension** (25): `TRICEPS_EXTENSION_GENERIC`, `TRICEPS_PRESSDOWN`, `SKULL_CRUSHER`, `BENCH_DIP`, `DUMBBELL_KICKBACK`, `BODY_WEIGHT_DIP`, `OVERHEAD_DUMBBELL_TRICEPS_EXTENSION`, `SEATED_BARBELL_OVERHEAD_TRICEPS_EXTENSION`, `TRICEP_DIP`, `CABLE_OVERHEAD_TRICEPS_EXTENSION`, `FLOOR_TRICEPS_DIP`, `CHEST_DIP`, `ASSISTED_CHEST_DIP`, `WEIGHTED_CHEST_DIP`, `SEATED_DIP_MACHINE`, `SEATED_TRICEPS_PRESS`, `DUMBBELL_SINGLE_ARM_TRICEP_EXTENSION`, `CABLE_SINGLE_ARM_TRICEPS_PUSHDOWN`, `DUMBBELL_SKULLCRUSHER`, `DUMBBELL_WIDEELBOW_TRICEPS_PRESS`, `MACHINE_TRICEP_EXTENSION`, `CABLE_TRICEPS_PUSHDOWN`, `STRAIGHT_LEG_BENCH_DIP`, `CHAIR_DIPS`, `JM_PRESS`

**Warm Up** (63): `WARM_UP_GENERIC`, `OPPOSITE_ARM_AND_LEG_BALANCE`, `WALKOUT`, `QUADRUPED_ROCKING`, `NECK_TILTS`, `ANKLE_CIRCLES`, `ARM_CIRCLES`, `FORWARD_AND_BACKWARD_LEG_SWINGS`, `LATERAL_DUCK_UNDER`, `REACH_ROLL_AND_LIFT`, `SLEEPER_STRETCH`, `THORACIC_ROTATION`, `WALKING_HIGH_KICKS`, `WALKING_HIGH_KNEES`, `WALKING_KNEE_HUGS`, `INVERTED_HAMSTRING_STRETCH`, `STRETCH`, `HAMSTRING_WALKOUT`, `HEEL_WALKS`, `TOE_WALKS`, `SIDE_LEG_SWINGS`, `STANDING_QUAD_STRETCH`, `PIGEON_POSE`, `STANDING_HAMSTRING_STRETCH`, `LYING_HAMSTRING_STRETCH`, `KNEELING_HIP_FLEXOR_STRETCH`, `COBRA`, `THREAD_THE_NEEDLE_STRETCH`, `SIDE_LYING_QUAD_STRETCH`, `PRONE_QUAD_STRETCH`, `TOES_AGAINST_WALL_CALF_STRETCH`, `SOLEUS_STRETCH`, `WALL_CHEST_STRETCH`, `HIGH_ARM_WALL_CHEST_STRETCH`, `LAT_STRETCH`, `CROSS_BODY_SHOULDER_STRETCH`, `OVERHEAD_TRICEP_STRETCH`, `KNEELING_HIP_FLEXOR_STRETCH_TWIST`, `STANDING_HIP_CIRCLES`, `STANDING_LEG_CIRCLES`, `LEGS_WIDE_DIAGONAL_TOE_TAPS`, `HAMSTRING_SCOOPS`, `SHOULDER_ROTATIONS`, `STANDING_PIGEON_POSE`, `LYING_SPINAL_TWIST`, `LYING_PIRIFORMIS_STRETCH`, `CALF_BIASED_HAMSTRING_SCOOP`, `WALL_BICEP_STRETCH`, `LYING_HIP_ROCKS`, `CROSS_BODY_ARM_SWING`, `DIAGONAL_CROSS_BODY_ARM_SWING`, `BANDED_TOE_RAISE`, `NINETY_NINETY_HIP_ROLLS`, `DIAGONAL_LEG_SWINGS`, `RESISTANCE_BAND_GENERIC`, `QUADRUPED_REACH_THROUGHS`, `PENDULUM_LEG_SWING`, `WORLDS_GREATEST_STRETCH`, `BANDED_CLAMS`, `BOSU_BALL_GENERIC`, `HEEL_DROP_CALF_STRETCH`, `CHILDS_POSE_LAT_STRETCH`, `SEATED_HAMSTRING_STRETCH`

**Hip Thrust** (5): `MACHINE_SINGLE_LEG_HIP_THRUST`, `RAISED_LEG_BARBELL_HIP_THRUST`, `DUMBBELL_STAGGERED_HIP_THRUST`, `FROG_PUMP`, `MACHINE_HIP_THRUST`

**Lower Leg** (1): `TIBIALIS_RAISE`

**Quad Extension** (2): `MACHINE_SINGLE_LEG_QUAD_EXTENSION`, `BANDED_QUAD_EXTENSION`

