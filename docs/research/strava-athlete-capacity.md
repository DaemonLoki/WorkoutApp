# Strava athlete capacity for a public release

Researched 2026-10-08. This continues [strava-api.md](strava-api.md) (upload format, OAuth, webhooks, brand basics), which is not repeated here. Sources are listed at the end, and each `[S…]` label links to its URL. Each claim carries one of three labels: **confirmed** (developers.strava.com, the Strava API Agreement or Policy, Strava's Developer Program form, or a post by a Strava Community Manager), **unverified** (found only in secondary sources: forum posts by non-staff, GitHub issues), or **not documented**.

## Summary and verdict

**README §14 is correct but incomplete.** "Capacity 1 → self-upgrade to 10 → review beyond 10" is confirmed [S1, S2, S4]. Three facts are missing:

1. **Strava only reviews apps that have already filled all 10 slots.** Applications from apps below 10/10 "will be denied" [S3].
2. **Neither approval, the capacity granted nor the timing is guaranteed.** Approved capacity "may be lower than requested" [S3], and Strava makes "no fixed review-time commitment" [S6 §3.6]. The Standard tier tops out at 9,999 athletes; 10,000+ is the separate Extended Access tier [S4, S6 §3.3].
3. **The owner's Strava subscription is a standing requirement.** It is needed to create and keep the app, and there is no API fee on top [S2, S4 Q6, S5]. Today nothing requires users to subscribe, but the Policy lets Strava add that [S6 §3.3].

**Beyond capacity:** Strava blocks the athlete before OnlyWorkout gets a code [S1]. Strava's docs don't describe the error. Secondary sources show Strava's own error page: "Error 403: Limit of connected athletes exceeded" (**unverified**, [U1, U2]). In OnlyWorkout, that athlete sees Strava's error page in the sign-in sheet and taps Cancel, and the app then silently ignores the cancel. If the error came from the token exchange instead, the app would show "Please try again later", which is wrong too. Neither path tells the user the truth.

**Rate limits are not the bottleneck.** OnlyWorkout makes about 3–4 Strava requests per uploaded Session. At 10 athletes that is about 1% of the daily budget. Even at the 10-athlete limits, about 1,000 uploads a day would fit (see §2).

**Recommendation:** combine options (b), (c) and (d), in this order:

1. Test the over-capacity behaviour on the owner's app.
2. Gate "Connect with Strava" on the server and handle a full app gracefully.
3. Self-upgrade to 10 and fill the slots with TestFlight testers.
4. Submit the Developer Program form.
5. Release on the App Store with Strava visible but gated, and open the gate as Strava raises capacity.

The ordered checklist is in §5.

---

## 1. Capacity tiers, upgrade and review

**Tiers: confirmed** [S1, S2, S4, S5, S6 §3.3]

| Level | Athletes | How to get there | Subscription for the developer | Rate limits |
|---|---|---|---|---|
| New API app ("Single Player Mode") | **1**, the owner | default | required | 200 / 15 min, 2,000 / day overall; 100 / 1,000 non-upload [S1] |
| Standard, self-upgraded | **10** | button in the API Settings dashboard, "no formal review" [S1, S5] | required | 400 / 15 min, 4,000 / day overall; 200 / 2,000 read [S1] |
| Standard, reviewed | **11 – 9,999** | Developer Program form, review "Required" [S4 Q3] | required | "Higher limits" [S4 Q3]; numbers **not documented** |
| Extended Access | **> 10,000** | review, case by case [S6 §3.3(b)] | "N/A", none [S4 Q3, S5] | higher; not documented |

- The FAQ calls the self-upgrade level "Standard Tier … <10 users" and says it is meant for "beta groups or friends and family" [S4 Q3, Q7].
- The 1-athlete column in the FAQ table is "Single User … access your data via MCP" [S4 Q3]. The API docs still state that every new API app starts at capacity 1 [S1, S2], so both describe the same starting point.
- The current capacity and the count of connected athletes are shown in the API Settings dashboard (<https://www.strava.com/settings/api>) [S1, S4 Q5].
- "Until your app has been reviewed, you won't be able to authenticate any additional athletes to your app" [S1].

**What the review requires: confirmed** from the form's own definition [S3] and the rate-limits page [S1].

The form has these fields. All are required unless marked optional.

- First and last name, email, **Company Name** (a person's name is presumably fine for an indie developer; **unverified**).
- API Application Name. Give only the primary app, not staging.
- **Strava Client ID**.
- Additional Apps (optional). The help text warns: "a subscription would be required for **each** of your apps that fall under the Standard Tier as we do not offer multi-tenancy for our API." The Agreement also allows one API token per application only [S7 §1.1]. Keep one Strava app for OnlyWorkout, not a separate staging app.
- **Number of Currently Authenticated Users** ("If your app is not yet available, write 1"). Strava denies applications below 10, so this must be 10.
- Number of Intended Users (optional).
- **Application Description**: the app and its use of Strava API data, checked against the Agreement and Policy. "Lack of compliance can delay a response."
- Support URL (optional on the form; the Policy requires easy-to-find support contact details [S6 §2.4]).
- Checkboxes: **TOS compliance**, **API Policy compliance**, **Brand Guidelines reviewed**.
- **App Images**: "screenshots of ALL places Strava data is shown." The rate-limits page adds the "Connect with Strava" button [S1].

Before the form, the rate-limits page lists three more steps [S1]:

- Show real demand. Strava says apps under 100 users that hit limits usually use the API inefficiently.
- Review the API Agreement (last updated 2026-06-01).
- Comply with the brand guidelines.

**Minimum users: confirmed.** The app must have reached 10/10 on the Standard tier before Strava reviews a request; "Applications that have not met this threshold will be denied" [S3].

**Eligibility: confirmed** [S4 Q10]. Apps must "complement the Strava experience", meet Strava's quality bar, and handle athlete data per the Agreement and Policy. Apps that expose athlete data to third-party AI tools are not approved.

**Timelines: not documented.**

- Strava: "no fixed review-time commitment"; developers hear back if admitted or if more information is needed [S6 §3.6]. Increased access "is not a guarantee" [S1, S3].
- **Unverified** anecdotes from Sept 2026:
  - Someone waiting 10+ days without news [U2: 13915].
  - Someone at 10/10 still waiting [U2: 13980].
  - One developer approved within 7 days of a sixth attempt, after five rejections that gave no reason. They fixed ignored deauthorization webhooks, slow webhook acknowledgements and missing attribution [U3].
- Plan for weeks to months, and for a possible "no".

**Fees: confirmed.**

- No fee for Standard-tier API access beyond the developer's Strava subscription [S4 Q6].
- The Agreement says the API is "currently provided at no charge" but reserves the right to charge later [S7 §3.2–3.3].
- The subscription requirement applies to new developers from 2026-06-01 and existing ones from 2026-06-30 [S5].
- **Not documented:** what happens to a live app if the owner's subscription lapses. Treat a lapse as an outage.

**End users: confirmed** that nothing is published today. The Policy allows Standard-tier subscription requirements to include "specified end users" in future [S6 §3.3]. The FAQ table lists subscription requirements per tier, not per user [S4 Q3]. This is a risk to watch, not a current blocker.

**Legacy capacities: unverified.** Apps approved before June 2026 report a capacity of 999 [U2: 13915, U4]. That figure does not apply to new reviews; the published range is 11–9,999 [S4 Q3].

## 2. Rate limits and what OnlyWorkout uses

**Limits: confirmed** [S1]

- Limits are per application, not per athlete.
- The 15-minute window resets at :00/:15/:30/:45, the day at midnight UTC.
- Over-limit requests get `429` and still count toward the daily limit.
- **Uploads count against the overall limit only.** `POST /uploads`, `POST /activities` and media upload are excluded from the non-upload ("read") limit. `GET /uploads/{id}` polling counts against both.
- Limits for reviewed apps are **not documented** beyond "Higher limits" [S4 Q3].
  - **Unverified:** one developer reports 600 / 15 min and 6,000 / day after approval [U3].
  - The page's example headers show `600,30000`, but they are dated 2020 and only illustrate the format [S1].
- **Not documented:** whether `POST /oauth/token` (exchange and refresh) or `POST /oauth/revoke` count.

**Requests per Session, from `supabase/functions/_shared/strava.ts`:**

| Call | Limit bucket | Count |
|---|---|---|
| `POST /oauth/token` refresh, only when the token expires within the hour (tokens last 6 h) | unknown | ≤ 1 |
| `POST /uploads` | overall only | 1 |
| `GET /uploads/{id}`, once a second until ready, at most 10 | overall + read | typically 1–2 (mean processing < 2 s), at most 10 |

A typical upload costs about 3–4 overall and 2 read requests; the worst case is about 12 overall and 10 read. Opening the app costs no Strava request: `StravaLink.refresh()` calls a Supabase RPC, and `uploadPending()` contacts Strava only for Sessions still waiting to upload.

**One Session per user per day, at the 10-athlete limits** (400 / 4,000 overall; 200 / 2,000 read):

| Users | Uploads / day | Overall / day (typical) | Read / day (typical) | Read / day (worst case) |
|---|---|---|---|---|
| 1 (capacity 1: 2,000 / 1,000) | 1 | 4 (0.2 %) | 2 (0.2 %) | 10 |
| 10 | 10 | 40 (1 %) | 20 (1 %) | 100 (5 %) |
| 100 | 100 | 400 (10 %) | 200 (10 %) | 1,000 (50 %) |
| 500 | 500 | 2,000 (50 %) | 1,000 (50 %) | 5,000 (over) |
| 1,000 | 1,000 | 4,000 (limit) | 2,000 (limit) | over |

- At 10 athletes the limits are irrelevant.
- Above about 100 users the read budget for polling is what binds, and gym peaks are bursty: about 100 uploads in one 15-minute window would use the 200 read requests.
- A `429` is already handled: `failure()` answers `rate_limited` (503), the app maps it to `StravaBackendError.unavailable`, and the Session stays queued for the next trigger.
- Cheap headroom once capacity grows:
  - Poll less: wait about 2 s, then at most about 3 polls.
  - Log `X-RateLimit-Usage` / `X-ReadRateLimit-Usage` from `strava-upload`.
- More retries would lean on duplicate detection, which README §15 #4 marks as untested.

## 3. API Agreement and Policy points for a public app

All **confirmed** against the Policy [S6] and Agreement [S7], both effective 2026-06-01. Items already covered in strava-api.md §7 are only listed.

| Rule | OnlyWorkout today | Action |
|---|---|---|
| **No charging** for API access or "related services"; charging for features Strava doesn't provide is allowed if not substantially duplicative [S6 §5.8] | free | If OnlyWorkout ever becomes paid or gets a Pro tier, **never put Strava upload behind the paywall**. |
| **No competing with or imitating Strava** [S6 §5.2, S7]; higher access requires apps that "complement the Strava experience" [S4 Q10] | a strength logger that uploads to Strava; Strava has its own workout log since May 2026, but partner strength apps are the use case it promotes (strava-api.md S13) | Describe OnlyWorkout in the form as a structured-strength source *for* Strava. Not a blocker. |
| **No AI/ML** use of Strava Data or anything derived from it, including context windows [S6 §5.3]; apps exposing athlete data to third-party AI are not approved [S4 Q10] | only the activity ID comes back from Strava | Keep any future LLM feature away from Strava responses. |
| **Display only to that user** [S6 §2.3, §6.1–6.2; S7] | "View on Strava" shows only on the uploader's iPhone | none |
| **No analytics/aggregation** of Strava Data [S6 §5.4] | none | none |
| **No intermediaries or shared tokens** [S6 §5.16, S7 §1.1–1.2] | Supabase functions are our own direct integration (strava-api.md §7) | Keep one client ID; no staging app without its own subscription [S3]. |
| **Consent text, support contact, Strava account links** [S6 §2.1, §2.4] | consent footer in Settings | Add a support URL/contact before public release. |
| **Privacy policy**: GDPR/UK-GDPR compliant, prominently linked, says Strava collects Usage Data [S6 §6.5, §7.3] | none yet (README §14) | Write it before submitting the form. |
| **Deletion** within 30 days of revocation or account deletion, with written confirmation on request [S6 §2.5, §7.4] | `strava-webhook`, `strava-disconnect`, `delete-account` | Already handled. |
| **7-day cache, 48 h for deletions** [S6 §6.2–6.3] | activity ID kept 7 days on device (ADR-0004) | Already handled. |
| **Brand guidelines** (rev. 2025-09-29) [S8] | official button, "View on Strava", "Compatible with Strava" footer | Already handled. "Powered by Strava" is optional, not required where data appears [S8 §1.2, §4]. |
| **Strava may change or end access at any time** [S7 §2.1, §4.2; S6 §3.2, §3.7] | — | Design Strava as an optional extra the app works without. It already is. |

## 4. What a user beyond capacity sees

**Confirmed:** past capacity "you won't be able to authenticate any additional athletes" [S1]. Neither the authentication docs [S9] nor any other Strava page documents the error. The only documented OAuth error is `error=access_denied` on the redirect when the athlete declines [S9].

**Unverified (secondary sources only):**

- The message is "Error 403: Limit of connected athletes exceeded", with the line "This app has exceeded the limit of connected athletes." It is quoted in many forum threads by developers and users [U2] and in a GitHub issue from 2026-07-17 [U1]. One thread quotes it as "Too many athletes" [U2: 10264].
- The GitHub issue says, from a screenshot of a live attempt, that Strava rejects the connection "before the app ever sees the callback" [U1]. So the block is on Strava's authorize page: no redirect, no `code`, and no token exchange for our server to see.
- No source shows a JSON body. No primary source rules out a `403` from `POST /oauth/token` either.
- Athletes who are already connected reportedly keep working; only new connections are blocked [U2: 13915].
- Re-authorizing an athlete who is already connected is not documented. Presumably it doesn't take a new slot.

**Freeing slots: confirmed with a caveat.**

- Strava staff: deauthorized athletes "will be removed from this count and you'll have 'room' in your capacity" [S10, Emily_A, Community Manager, 2025-03-14].
- **Unverified:** users report the count updates with a lag of up to about a day [S10, non-staff replies].
- Every connected athlete holds a slot until they or we revoke. That includes someone who deletes the app without disconnecting.

**What OnlyWorkout does today:**

- **Authorize-page block (most likely).** Strava shows its error page inside the `ASWebAuthenticationSession` sheet in `StravaSection.connect`. The user taps Cancel, and `ASWebAuthenticationSessionError.canceledLogin` is caught as "The user changed their mind." The user gets **no explanation**, and nothing is logged.
- **Token-exchange 403 (possible).** `tokenRequest` in `_shared/strava.ts` throws `StravaError(403, body)`. `failure()` in `_shared/connections.ts` maps every 400/403 to `422 strava_rejected`. `SupabaseBackend+Strava.invokeStrava` turns that into `StravaBackendError.rejected(detail:)`. `StravaSection` falls through to the generic alert "Couldn't Connect to Strava / Please try again later." That message is **wrong for a full app**.
  - `exchangeCode` also throws `StravaError(403, …)` for a missing `activity:write` scope. That case can't happen in practice, because `StravaLink.finishConnecting` checks the scope first. But it puts a second meaning on 403, so the two cases need separating.
- **The app can't tell whether Strava is full.** Nothing tracks capacity: no config table, no flag. `strava_connections` already has one row per connected athlete, though, so the server can count.

**What needs to change** (details in §5, step 2):

- **Primary defence: a gate before the consent page.** The authorize-page block can't be detected after the fact, because a cancel looks the same either way.
  - The server compares the number of rows in `strava_connections` with a capacity the owner sets.
  - When the gate is closed, the app shows "Strava uploads are full for now" instead of the button.
- **Backstop: name the error.** `strava-connect` recognises a token-exchange 403 that mentions the athlete limit and answers its own code. The app then shows the "full" message instead of "try again later."

## 5. Options and recommendation

| Option | For | Against |
|---|---|---|
| **(a)** Ship with Strava hidden until approved | simplest; nobody hits the wall | Strava's review needs 10 connected athletes first, so the testers must come from TestFlight anyway. Apple: betas "don't belong on the App Store" (Guideline 2.2), so no "Beta" label in the App Store build. A feature that appears later via a server switch must be explained in the review notes (2.3.1) [A1]. |
| **(b)** Apply before release, with TestFlight users filling the 10 slots | meets Strava's 10/10 precondition; testers produce real screenshots | no timeline or guarantee [S6 §3.6]; testers each need a Strava account and a Cloud Sync account |
| **(c)** Handle the over-capacity error in `strava-connect` and Settings | honest message; cheap | can't catch the authorize-page block on its own (§4) |
| **(d)** Server-side gate ("connections open" flag plus capacity) | catches the block before Strava's page; the owner opens slots as Strava grants them, no app update | a small migration, RPC and UI state; the count is approximate (Strava's count lags; the owner's own slot counts too) |

**Recommended path: (b) + (c) + (d).** Keep Strava visible in every build. When the gate is closed, the Settings row explains that Strava connections are full for now, and everyone already connected keeps uploading.

- This is not a beta label (Guideline 2.2).
- The feature is documented (2.3.1): add a line to the App Review notes saying Strava capacity is limited by Strava and how the gate works.
- Reviewers who tap a working button won't hit Strava's 403 page (2.1). Keep the gate closed during review, or keep one slot free [A1].

**Ordered checklist**

1. **Confirm the over-capacity behaviour, before self-upgrading.**
   - While the app is still at capacity 1, connect a second Strava account (a test account) from a dev build.
   - Record where the block appears (authorize page or token exchange) and its exact text or JSON.
   - Add the findings to this note and to README §12.
   - If the app is already at 10, do it once the 10 slots are full.
2. **Add the gate and the error handling** (feature branch, test-first):
   1. Migration:
      - Add a one-row `strava_settings` table (or a general `app_settings`) holding `athlete_capacity int`.
      - Add a `security definer` RPC `strava_connect_open()`. It returns true when the caller already has a `strava_connections` row, or when `count(*) < athlete_capacity`. It returns a boolean only, never the count.
      - Add pgTAP tests in `supabase/tests/database`.
   2. `_shared/strava.ts`:
      - A 403 from `/oauth/token` that mentions the connected-athletes limit throws a distinct `AthleteLimitError`.
      - Give the missing-scope case its own error rather than `StravaError(403)`.
   3. `_shared/connections.ts`: `failure()` answers `{ error: "athlete_limit" }` with status 409. Add a Deno test with a stubbed fetch.
   4. `OnlyWorkoutSync`:
      - `StravaBackend` gains `stravaConnectOpen()`.
      - `StravaBackendError` gains `.athleteLimitReached`, mapped in `SupabaseBackend+Strava.invokeStrava`.
      - `StravaLink.Status` gains a "connections full" state that `refresh()` sets for a user who isn't connected.
      - Test against the fake backend.
   5. `StravaSection`:
      - In the full state, show a text row and a footer (new `stravaFullFooter` string) instead of the button.
      - Map `.athleteLimitReached` to a specific alert (`stravaFull…` strings in `SharedUI/Localizable.xcstrings`).
      - Log `canceledLogin` at debug level, so a silent cancel is at least visible in Console.
   6. Optional: log the `X-RateLimit-Usage` headers in `strava-upload`, and cut polling to about 3 polls after a 2 s wait (§2).
3. **Self-upgrade to 10** in <https://www.strava.com/settings/api>.
   - Set `athlete_capacity` to 10. Keep it at 9 if you want one slot in reserve for App Review.
   - Keep the owner's Strava subscription active.
4. **Fill the 10 slots with TestFlight testers.** Ask testers who drop out to disconnect in Settings, so their slot frees up.
5. **Get compliant before applying:**
   - privacy policy covering what goes to Strava and Strava's Usage Data clause [S6 §6.5, §7.3]
   - support URL [S6 §2.4]
   - brand check [S8]
   - working webhook, already verified at M4
6. **Submit the Developer Program form** [S3] once the dashboard shows 10/10:
   - Number of Currently Authenticated Users = 10, plus a realistic intended-user estimate.
   - Description: free strength tracker, upload-only with `activity:write`, no reads, no AI, activity ID cached 7 days, deauthorization webhook.
   - Screenshots: Settings → Strava (button, consent footer, connected state), Session detail (Upload to Strava, Uploaded, View on Strava), and the Custom Exercise Strava picker.
7. **Release on the App Store with the gate closed** (or at 9 with one slot in reserve). Explain the gate in the App Review notes.
8. **When Strava answers:** set `athlete_capacity` to the granted number minus a small margin, because Strava's count lags. If Strava refuses, fix the stated reasons and resubmit; anecdotally, persistence works [U3]. The app stays useful without Strava.
9. **Docs:**
   - Update README §14 with the text below.
   - Record the gate in README §12.
   - An ADR is optional; the gate is easy to reverse.

**Suggested README §14 wording:** "Strava: a new API app connects only its owner (capacity 1); the owner can self-upgrade to 10 athletes without review. Beyond 10 needs Strava's Developer Program review, which Strava only considers once all 10 slots are used; approval, granted capacity (up to 9,999 on the Standard tier) and timing are at Strava's discretion, and the owner's Strava subscription must stay active. A server-side gate hides "Connect with Strava" when capacity is full (docs/research/strava-athlete-capacity.md)."

---

## Sources

Primary (Strava):

- **S1** Rate Limits and Athlete Capacity (incl. "Adjustment Requests"): <https://developers.strava.com/docs/rate-limits/>
- **S2** Getting Started (single-player mode, subscription prerequisite, self-upgrade): <https://developers.strava.com/docs/getting-started/>
- **S3** Strava API Program Submission Form ("Developer Program form", linked from S1/S2): <https://share.hsforms.com/1VXSwPUYqSH6IxK0y51FjHwcnkd8>. Fields, help texts and the confirmation message were read from the form's published definition at <https://forms.hsforms.com/embed/v3/form/21254876/5574b03d-462a-487e-88c4-ad32e751631f/json> on 2026-10-08.
- **S4** Strava API FAQ, by Emily_A (Community Manager), 2026-03-16, Q1–Q11 incl. the tier table: <https://communityhub.strava.com/developers-knowledge-base-14/strava-api-faq-12906>
- **S5** "An Update To Our Developer Program", by Elliott (Community Manager), 2026-06-01: <https://communityhub.strava.com/insider-journal-9/an-update-to-our-developer-program-13428>
- **S6** Strava API Policy (2026), effective 2026-06-01: <https://www.strava.com/legal/api_policy>
- **S7** Strava API Agreement (2026), effective 2026-06-01: <https://www.strava.com/legal/api>
- **S8** Strava API Brand Guidelines, rev. 2025-09-29: <https://developers.strava.com/guidelines/>
- **S9** Authentication: <https://developers.strava.com/docs/authentication/>
- **S10** "Deauthorising an athlete, does it reduce the Strava active connections count?", answer by Emily_A (Community Manager), 2025-03-14: <https://communityhub.strava.com/developers-api-7/deauthorising-an-athlete-does-it-reduce-the-strava-active-connections-count-8848>

Other primary (Apple):

- **A1** App Store Review Guidelines 2.1, 2.2, 2.3.1: <https://developer.apple.com/app-store/review/guidelines/>

Secondary (unverified):

- **U1** GitHub, philippe-ths/ai-running-coach #723, 2026-07-17 (error text; blocked before the callback): <https://github.com/philippe-ths/ai-running-coach/issues/723>
- **U2** Community Hub threads quoting the 403 error, none with a staff explanation of the mechanism:
  - <https://communityhub.strava.com/developers-api-7/help-to-solve-error-403-limit-of-connected-athletes-exceeded-1699> (2024)
  - <https://communityhub.strava.com/developers-api-7/mistake-403-too-many-athletes-10264> (2025)
  - <https://communityhub.strava.com/developers-api-7/quota-increase-request-error-403-limit-of-connected-athletes-exceeded-client-id-147184-12990> (2026-03; Emily_A replied only with a link to S2)
  - <https://communityhub.strava.com/developers-api-7/follow-up-on-athlete-limit-increase-request-ticket-17768-app-id-111286-13915> (2026-09-07; 999 cap; existing users keep working)
  - <https://communityhub.strava.com/developers-api-7/error-403-issue-13980> (2026-09-29; 10/10 Standard)
- **U3** "I got my athlete limit raised after 5 rejections", 2026-09-22 (post-approval limits, rejection causes, 7-day approval): <https://communityhub.strava.com/developers-api-7/i-got-my-athlete-limit-raised-after-5-rejections-in-case-this-helps-anyone-13957>
- **U4** "Will legacy approved apps keep their existing athlete capacity (999)…", 2026-07-04, no staff answer: <https://communityhub.strava.com/developers-api-7/will-legacy-approved-apps-keep-their-existing-athlete-capacity-999-under-the-new-developer-program-13633>

[S1]: https://developers.strava.com/docs/rate-limits/
[S2]: https://developers.strava.com/docs/getting-started/
[S3]: https://share.hsforms.com/1VXSwPUYqSH6IxK0y51FjHwcnkd8
[S4]: https://communityhub.strava.com/developers-knowledge-base-14/strava-api-faq-12906
[S5]: https://communityhub.strava.com/insider-journal-9/an-update-to-our-developer-program-13428
[S6]: https://www.strava.com/legal/api_policy
[S7]: https://www.strava.com/legal/api
[S8]: https://developers.strava.com/guidelines/
[S9]: https://developers.strava.com/docs/authentication/
[S10]: https://communityhub.strava.com/developers-api-7/deauthorising-an-athlete-does-it-reduce-the-strava-active-connections-count-8848
[A1]: https://developer.apple.com/app-store/review/guidelines/
[U1]: https://github.com/philippe-ths/ai-running-coach/issues/723
[U3]: https://communityhub.strava.com/developers-api-7/i-got-my-athlete-limit-raised-after-5-rejections-in-case-this-helps-anyone-13957
[U4]: https://communityhub.strava.com/developers-api-7/will-legacy-approved-apps-keep-their-existing-athlete-capacity-999-under-the-new-developer-program-13633
