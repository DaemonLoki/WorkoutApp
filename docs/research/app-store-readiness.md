# App Store readiness: what OnlyWorkout still needs

Researched 2026-10-08 against Apple's primary sources, with the repo on branch `release-readiness-research` (after feedback round 2). Sources are listed at the end and linked inline as [S#](url). Each claim carries one of three labels: **confirmed** (an Apple page, or the Supabase/Strava page that owns the fact), **unverified** (no primary source found, or Apple's wording leaves it open), or **interpretation** (our reading of a confirmed rule).

## Summary

**The app is close, but the binary can't be uploaded yet, and four decisions need the owner.** The privacy-sensitive architecture already matches Apple's rules: Health data stays on device, account deletion revokes the Sign in with Apple token, and the app works without an account. What's missing is mostly packaging and metadata.

Blockers for an upload or a first review:

1. **No app icon images.** Both `AppIcon.appiconset`s (iPhone and Watch) contain only `Contents.json`. An App Store build needs icon imagery [S13](https://developer.apple.com/documentation/xcode/configuring-your-app-icon).
2. **No `PrivacyInfo.xcprivacy` anywhere.** Our own code calls `UserDefaults` in the iPhone app, the Watch app and the Watch widget extension. Since 2024-05-01 App Store Connect rejects uploads that don't declare required-reason APIs [S5](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
3. **No privacy policy or support URL**, and the app links to neither. Both are required metadata. The privacy policy link must also be in the app [S1 §5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.1), [S20](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information). HealthKit apps need a privacy policy in any case [S10](https://developer.apple.com/documentation/healthkit/protecting-user-privacy).
4. **Strava can't serve the public as configured.** The Strava API app has athlete capacity 1. A self-upgrade raises it to 10, and above that Strava must review the app ([strava-api.md §6](strava-api.md#6-rate-limits-athlete-capacity-review)). So neither App Review nor most users could connect. Before submitting, either get Strava's approval or hide Strava in the release.

Smaller items:

- `ITSAppUsesNonExemptEncryption` is missing.
- The Health purpose string doesn't mention active energy.
- The Supabase Free plan pauses inactive projects, and App Review needs the backend live.
- Screenshots, age rating, App Privacy answers, the medical-device declaration and DSA trader status are all still owner tasks in App Store Connect.
- **Interpretation risk:** guideline 5.1.1(v) bars storing "tokens to social networks off of the device". Strava tokens live in Supabase (which Strava's OAuth flow needs, because refreshing uses the client secret). Whether App Review treats Strava as a "social network" is **unverified**.

---

## Checklist

Status: **done**, **partial**, **missing**, or **owner** (an App Store Connect, website or account task with no code).

### Build & binary

| Requirement | Status in repo | What to do |
|---|---|---|
| Built with Xcode 26+ / iOS 26 SDK since 2026-04-28; from April 2027 the iOS 27 / watchOS 27 SDK and target iOS 15+ [S17](https://developer.apple.com/news/upcoming-requirements/), [S18](https://developer.apple.com/app-store/submitting/) | **done**: local Xcode 27.0 (27A266a), deployment targets iOS 27 / watchOS 27 | Nothing. |
| App icon imagery for the App Store; a single 1024×1024 image is enough, dark/tinted variants optional [S13](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) | **missing**: `OnlyWorkout/Resources/Assets.xcassets/AppIcon.appiconset` declares three 1024 slots (any, dark, tinted) with no files; the Watch `AppIcon.appiconset` declares one with no file | Owner designs the icon; add the PNGs (or an Icon Composer `.icon`). Icons must suit a 4+ rating and match across iPhone and Watch [S1 §2.3.8](https://developer.apple.com/app-store/review/guidelines/#2.3.8). Never use Strava's logo in it ([strava-api.md §7](strava-api.md#7-brand-guidelines-and-api-terms)). |
| `ITSAppUsesNonExemptEncryption`, or answer the export questionnaire on every upload [S11](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption) | **missing** in `Config/OnlyWorkout-Info.plist` | Add `ITSAppUsesNonExemptEncryption = NO`. The app's only cryptography: HTTPS through `URLSession` (supabase-swift), plus CryptoKit SHA-1/SHA-256 hashing for catalog UUIDs and the Sign in with Apple nonce. On Apple platforms swift-crypto doesn't compile BoringSSL; its `Package.swift` limits that to Linux/Android/Windows/WASI/OpenBSD. Apple: OS-provided HTTPS is "typically" exempt [S11](https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations). Whether a year-end self-classification report applies is **unverified** (Apple says one "might" be required). |
| Version numbers | **partial**: `MARKETING_VERSION = 0.1`, `CURRENT_PROJECT_VERSION = 1` | Set 1.0 for release; bump the build number on every upload. |
| No hidden or dormant features [S1 §2.3.1](https://developer.apple.com/app-store/review/guidelines/#2.3.1) | **partial**: the `-sampleData` launch argument seeds a Workout in release builds too (only reachable via launch arguments) | Optional: wrap `-sampleData` in `#if DEBUG`. |
| Background modes used only for their purpose [S1 §2.5.4](https://developer.apple.com/app-store/review/guidelines/#2.5.4) | **done**: `workout-processing` on iPhone and Watch, used by `HKWorkoutSession` | Nothing. |
| Layout on iPhone Duo: apps built with the iOS 27 SDK resize on it, and "fixed orientations … can break layouts" [S27](https://developer.apple.com/iphone-duo/prepare/) | **unverified**: the iPhone app is portrait-only (`UISupportedInterfaceOrientations_iPhone`) | Not a review requirement. Try the Session screen on an iPhone Duo simulator if one exists. |

### Privacy: manifests

Apple's rule: "For each executable or dynamic library in an app that uses a required reason API, the bundle that includes the executable … needs to include a privacy manifest" [S5](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api). `OnlyWorkoutKit` modules link statically into each target, so their API use counts for that target.

| Bundle | Required-reason APIs found (grep) | Manifest needed | Reasons [S6](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) |
|---|---|---|---|
| iPhone app `OnlyWorkout` | `UserDefaults.standard` (`AppModel`, `@AppStorage` in `SettingsView`), `UserDefaults` in `OnlyWorkoutSync/CloudSync` | **missing** | `NSPrivacyAccessedAPICategoryUserDefaults`: `CA92.1` ("only accessible to the app itself") |
| Watch app `OnlyWorkoutWatch` | `UserDefaults.standard` (`WatchModel`); `UserDefaults(suiteName:)` for the App Group (`NextUpStore`) | **missing** | UserDefaults: `CA92.1` and `1C8F.1` ("same App Group") |
| Watch widget extension `OnlyWorkoutWatchWidgets` | `UserDefaults(suiteName:)` (`NextUpWidget`) | **missing** | UserDefaults: `1C8F.1` |
| iPhone widget extension `OnlyWorkoutWidgets` | none | not required | Optional empty manifest for completeness. |

None of our code uses file-timestamp, system-boot-time, disk-space or active-keyboard APIs.

Each manifest also sets `NSPrivacyTracking = false`. The iPhone manifest lists `NSPrivacyCollectedDataTypes` matching the nutrition label below: `NSPrivacyCollectedDataTypeFitness`, `…EmailAddress`, `…UserID` and `…OtherUserContent`, each linked, not tracking, purpose `NSPrivacyCollectedDataTypePurposeAppFunctionality` [S8](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests). The Xcode project uses synchronized folders, so a `PrivacyInfo.xcprivacy` placed in `OnlyWorkout/Resources/` (and the matching Watch folders) joins the target with no project edit (AGENTS.md).

**Third-party SDKs: confirmed**

- **supabase-swift is not on Apple's list** of "SDKs that require a privacy manifest and signature" [S7](https://developer.apple.com/support/third-party-SDK-requirements/). Its resolved dependencies aren't on it either. The list includes "BoringSSL / openssl_grpc", but swift-crypto only builds BoringSSL off Apple platforms and ships its own `PrivacyInfo.xcprivacy` in every target. Signatures are required only for listed SDKs used as binary dependencies; ours are all source packages.
- **supabase-swift v2.55.3 (pinned, released 2026-09-29) ships no privacy manifest.**
  - A manifest landed on `main` on 2026-09-17: [PR #1354](https://github.com/supabase/supabase-swift/pull/1354), `Sources/Helpers/PrivacyInfo.xcprivacy`, declaring `NSPrivacyAccessedAPICategoryFileTimestamp` / `C617.1` for `FileManager.attributesOfItem` in Storage uploads.
  - v2 releases are cut from `release/v2`, which doesn't have the file [S9](https://github.com/supabase/supabase-swift/releases/tag/v2.55.3).
  - Apple: a third-party SDK "can't rely on the privacy manifest files for apps that link" it [S5](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api).
  - We don't use Supabase Storage. Whether App Store Connect's scan still flags it is **unverified**. Upload a TestFlight build and watch for an App Store Connect email naming a missing API category. If one names FileTimestamp, bump supabase-swift once a release includes the manifest, or (as a stopgap) add `C617.1` to the iPhone manifest.

### Privacy: App Privacy answers and policy

| Requirement | Status | What to do |
|---|---|---|
| App Privacy ("nutrition label") answers in App Store Connect [S3](https://developer.apple.com/app-store/app-privacy-details/) | **owner** | Enter the draft [below](#draft-app-privacy-answers). |
| Privacy Policy URL, "required for all apps" [S21](https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy) | **owner** | Publish a page, e.g. on `onlyworkout.stefanblos.com` (already the Strava callback domain). |
| Privacy policy linked "within the app in an easily accessible manner" [S1 §5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) | **missing**: Settings' last section shows the version and "No ads, no tracking…" but no link | Add a Privacy Policy `Link` (and Support, see below) to that section; strings into `SharedUI/Localizable.xcstrings`. |
| Policy content: what is collected, how, all uses; third parties give equal protection; retention/deletion; how to revoke consent or request deletion [S1 §5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) | **owner** | See [policy content](#privacy-policy-content). |
| Explicit permission before sharing personal data with a third party [S1 §5.1.2(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.2) | **done**: Strava is opt-in via Strava's consent page; `stravaConsentFooter` names what is uploaded and that Health data is never sent | Nothing. |
| Data minimisation [S1 §5.1.1(iii)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) | **partial**: `CloudSyncSection` requests the `.email` scope, and `supabase/config.toml` has `email_optional = false`, but nothing in the app uses the email | Owner decision. Drop `.email` from `requestedScopes` and set `email_optional = true` locally and in the hosted Auth settings; then Email Address leaves the label. Whether Supabase's hosted Apple provider accepts sign-in without an email is **unverified**; try it on a device first. |

### Accounts

| Requirement | Status | What to do |
|---|---|---|
| Account deletion inside the app, deleting "the entire account record, along with associated personal data", easy to find, typically in account settings [S1 §5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#5.1.1), [S2](https://developer.apple.com/support/offering-account-deletion-in-your-app/) | **done**: Settings → Cloud Sync → Delete Account → `DeleteAccountView` → `delete-account` deletes the auth user, and every row goes by `on delete cascade`, incl. `strava_connections` | Test it once end-to-end against the **hosted** project; M3 tested it on the local stack only (README §16). |
| Sign in with Apple apps "should use the Sign in with Apple REST API to revoke user tokens" [S2](https://developer.apple.com/support/offering-account-deletion-in-your-app/), [S23](https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens) | **done**: `delete-account` swaps a fresh authorization code at `/auth/token`, then calls `/auth/revoke` with `token_type_hint` and fails the deletion if revocation fails | Make sure the hosted project has `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`, `APPLE_CLIENT_ID` (README §10). Apple also recommends a server-to-server notification endpoint (required only for new Services IDs in Korea) [S2](https://developer.apple.com/support/offering-account-deletion-in-your-app/); optional here. |
| No login required without significant account-based features [S1 §5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) | **done**: local-first, and Cloud Sync is opt-in | Say so in the review notes. |
| Login Services [S1 §4.8](https://developer.apple.com/app-store/review/guidelines/#4.8) | **done / n.a.**: 4.8 applies only to third-party or social logins for the primary account; the only login is Sign in with Apple, and Strava OAuth isn't the primary account | Nothing. |
| "Mechanism to revoke social network credentials … from within the app"; "may not store credentials or tokens to social networks off of the device" [S1 §5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) | **partial**: Disconnect Strava revokes in-app. Tokens sit in Supabase `strava_connections`, which ADR-0004 needs because refresh uses the client secret | **Interpretation:** the examples are Facebook, WeChat, Weibo and X; whether Strava counts is **unverified**. Explain the server-side token in the review notes; if App Review objects, see ADR-0004 for alternatives. |
| Demo account, or "turn on your back-end service" [S1 §2.1(a)](https://developer.apple.com/app-store/review/guidelines/#2.1) | **owner** | No demo account needed: reviewers can use Sign in with Apple. The backend must be live, and Supabase "pauses Free Plan projects that show low activity over a 7-day period" [S26](https://supabase.com/docs/guides/platform/free-project-pausing). Upgrade to Pro, or make sure there is traffic during review. |
| Support contact: "Make sure your app and its Support URL include an easy way to contact you" [S1 §1.5](https://developer.apple.com/app-store/review/guidelines/#1.5); the Support URL "must lead to actual contact information" [S20](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) | **missing** in app and metadata | Support page with an email address; link it next to the privacy policy in Settings. |

### HealthKit

| Requirement | Status | What to do |
|---|---|---|
| `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` [S10](https://developer.apple.com/documentation/healthkit/protecting-user-privacy) | **partial**: both are set (build settings, iPhone and Watch). The share string says "shows your heart rate", but `WorkoutRecorder` also reads active energy and writes heart rate and energy samples with each workout | Mention calories in both strings, e.g. "OnlyWorkout shows your heart rate and calories while you train." |
| HealthKit only for health/fitness, and that use "clear in both your marketing text and your user interface" [S10](https://developer.apple.com/documentation/healthkit/protecting-user-privacy); APIs' integration indicated "in their app description" [S1 §2.5.1](https://developer.apple.com/app-store/review/guidelines/#2.5.1) | **partial**: UI done (`HealthExplanationView` before the system sheet; Settings → Apple Health) | Owner: the App Store description must mention Apple Health. |
| No HealthKit data to third parties without permission (and only to health/fitness services), none for ads or data brokers [S10](https://developer.apple.com/documentation/healthkit/protecting-user-privacy), [S1 §5.1.2(vi), §5.1.3(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.3) | **done**: heart rate and energy are not in any SwiftData model, the Supabase schema or `StravaUpload` (grep) | Keep it so (AGENTS.md). |
| No personal health information in iCloud [S1 §5.1.3(ii)](https://developer.apple.com/app-store/review/guidelines/#5.1.3) | **done**: no iCloud entitlement; `ModelConfiguration` uses no CloudKit | Nothing. |
| Clinical Health Records only if used [S10](https://developer.apple.com/documentation/healthkit/setting-up-healthkit) | **done**: `com.apple.developer.healthkit.access` is empty | Nothing. |

### Apple Watch, widgets, Live Activities

| Requirement | Status | What to do |
|---|---|---|
| Watch screenshots, an icon, and a description that "includes the app's functionality on Apple Watch" [S14](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-watchos-app-information) | **owner** (icon **missing**, see above) | Screenshots: any one Watch size, e.g. 416×496 (Series 10–12) [S12](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications). |
| Watch app bundled with the iPhone app | **done**: `WKCompanionAppBundleIdentifier = com.stefanblos.OnlyWorkouts`, `WKRunsIndependentlyOfCompanionApp = NO` | Nothing. A Session still runs without the iPhone nearby; this flag only means the Watch app is installed through the iPhone app. |
| Widgets, extensions and notifications "related to the content and functionality of your app"; no ads in them [S1 §2.5.16, §2.5.18](https://developer.apple.com/app-store/review/guidelines/#2.5.16) | **done** | Nothing. |
| Live Activities and push not used to spam; push not required to function [S1 §4.5.3–4.5.4](https://developer.apple.com/app-store/review/guidelines/#4.5.3) | **done**: Live Activity only during a Session; rest-end notifications are local | Nothing. No other review rule for Live Activities, widgets or watchOS was found in the guidelines (**confirmed absence** in the 2026-06-08 text). |

### App Store Connect metadata

| Requirement | Status | What to do |
|---|---|---|
| Name ≤30 chars, subtitle ≤30, no trademarked terms in metadata or keywords [S1 §2.3.7](https://developer.apple.com/app-store/review/guidelines/#2.3.7), [S21](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information) | **owner** | "OnlyWorkout" fits. Keep "Strava" out of name, subtitle and keywords; the description may say "Compatible with Strava" ([strava-api.md §7](strava-api.md#7-brand-guidelines-and-api-terms)). Name availability is **unverified**. |
| Description, keywords, Support URL, copyright, screenshots: all required [S20](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) | **owner** | Screenshots must show the app in use [S1 §2.3.3](https://developer.apple.com/app-store/review/guidelines/#2.3.3). |
| iPhone screenshots [S12](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications) | **owner** | Apple's page is inconsistent. Its summary requires "iPhone with Dynamic Island (medium display)", i.e. 1206×2622 from an iPhone 18 Pro; its table marks the large display (6.9", 1320×2868 from an iPhone 18 Pro Max) as the fallback chain. **Upload both sizes** to be safe. 1–10 per size, PNG/JPEG, no alpha. |
| Age rating questionnaire, new system since 2026-01-31 [S17](https://developer.apple.com/news/upcoming-requirements/), [S15](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions) | **owner** | Answer None/No everywhere except **Health or Wellness Topics** ("self-care or lifestyle recommendations … exercise recommendations"). Step Up / Step Down suggestions arguably qualify, which gives **9+**; answering honestly is required [S1 §2.3.6](https://developer.apple.com/app-store/review/guidelines/#2.3.6). Medical or Treatment Information: None. Unrestricted Web Access: No (only Strava's consent page in `ASWebAuthenticationSession`). |
| Regulated medical device declaration, required for apps in the EU/EEA, UK or US with category Health & Fitness or Medical [S16](https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status) | **owner** | Category Health & Fitness, then declare **No**. |
| Digital Goods and Services questionnaire, if shown [S25](https://developer.apple.com/help/app-store-connect/manage-app-information/complete-the-digital-goods-and-services-questionnaire) | **owner** | Answer No (free, no purchases). |
| App Review contact and notes [S20](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) | **owner** | Notes: no login needed; Cloud Sync via Sign in with Apple is optional; Health permission is asked at the first Session; how to start a Session on the Watch; Strava status (see Legal). |
| Accessibility Nutrition Labels: voluntary for now, mandatory later [S24](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels) | **partial**: Dynamic Type, Reduce Motion and 44 pt targets are by design; 19 `accessibility*` modifiers in code; no VoiceOver pass was done for this note | Optional: do a VoiceOver/Larger Text pass over the common tasks (start a Session, log a Set, edit a Workout) before claiming support. |
| Localisation | **done**: English only, every string in `Localizable.xcstrings` | Primary language English. |

### TestFlight

| Requirement | Status | What to do |
|---|---|---|
| External testers need TestFlight App Review ("The first build you submit requires a full review"), up to 10,000 testers [S22](https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers) | **owner** | Internal testing (the owner's devices) stays as today. |
| Beta App Description (required) and Feedback Email [S22](https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information) | **owner** | Fill in before inviting external testers. |
| Export compliance per build | **missing** (see the `ITSAppUsesNonExemptEncryption` row) | The plist key removes the per-build prompt [S11](https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption). |

### Legal & business

| Requirement | Status | What to do |
|---|---|---|
| EU DSA trader status: declared for every account; apps without it were removed from the EU store since 2025-02-17 [S17](https://developer.apple.com/news/upcoming-requirements/), [S19](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements) | **owner** | Self-assess. Apple: a hobbyist "with no intention of commercializing" an app "may not be considered a trader". A trader must publish a verified address, phone number and email on the product page. Alternatively, leave the EU out of availability. Apple gives no legal advice; this note doesn't either. |
| Third-party services: permitted under their terms; "Authorization must be provided upon request" [S1 §5.2.2](https://developer.apple.com/app-store/review/guidelines/#5.2.2); trademarks only with permission [S1 §5.2.1](https://developer.apple.com/app-store/review/guidelines/#5.2.1) | **partial**: official "Connect with Strava" asset, "View on Strava", "Compatible with Strava" (`stravaConnectedFooter`) | Strava's brand guidelines give that permission ([strava-api.md §7](strava-api.md#7-brand-guidelines-and-api-terms)). |
| Strava athlete capacity: 1 now, 10 after self-upgrade, Strava review above 10 ([strava-api.md §6](strava-api.md#6-rate-limits-athlete-capacity-review)) | **missing** for public release | **Owner decision.** Either (a) apply to Strava's Developer Program before release, or (b) ship 1.0 with Strava hidden (Settings section and Session detail upload) and add it once approved. In the meantime, a reviewer who can't connect may flag the feature as broken under [S1 §2.1](https://developer.apple.com/app-store/review/guidelines/#2.1) (**interpretation**). |
| Strava's API Policy: privacy policy GDPR-compliant and states that Strava collects Usage Data ([strava-api.md §7](strava-api.md#7-brand-guidelines-and-api-terms)) | **owner** | Covered in the policy content below. |

---

## Draft App Privacy answers

Based on what the code sends off the device. Apple's rules for these answers [S3](https://developer.apple.com/app-store/app-privacy-details/):

- "Collect" means transmitting data off the device so it can be accessed "for a period longer than what is necessary to service the transmitted request in real time".
- Data processed only on device isn't collected.
- Opt-in Cloud Sync doesn't qualify for optional disclosure: "data collected on an ongoing basis after an initial request for permission must be disclosed".
- "Personal Data" counts as linked to the user.

**Do you or your third-party partners collect data from this app? Yes.**

| Category → type | Collected | What, exactly | Linked to user | Tracking | Purpose |
|---|---|---|---|---|---|
| Health & Fitness → **Fitness** | Yes | Workouts, Planned Exercises, Exercises, Sessions, Session Exercises, Sets (reps, weight, times) and Progression Suggestions, synced to Supabase with Cloud Sync; Sessions uploaded to Strava when connected | Yes | No | App Functionality |
| User Content → **Other User Content** | Yes (conservative) | Free-text Workout and Custom Exercise names; Apple says to mark this for "generic free form text fields" | Yes | No | App Functionality |
| Identifiers → **User ID** | Yes | The Supabase user ID; the Apple account identifier Supabase Auth keeps for the Apple identity; the Strava athlete ID in `strava_connections` | Yes | No | App Functionality |
| Contact Info → **Email Address** | Yes, **unless** the `.email` scope is dropped | The Sign in with Apple email (possibly a private relay address), stored by Supabase Auth | Yes | No | App Functionality |
| Health & Fitness → **Health** | **No** | Heart rate and active energy are read from HealthKit and only shown on device; they are not in SwiftData models, the Supabase schema or Strava uploads | n/a | n/a | n/a |
| Everything else (Location, Contacts, Financial, Purchases, Browsing/Search History, Usage Data, Diagnostics, Sensitive Info, Device ID, …) | No | No analytics or crash SDK. Crash reports Apple collects aren't ours to disclose: "You are not responsible for disclosing data collected by Apple" | | | |

**Tracking: No.** Nothing is linked with third-party data for advertising or shared with a data broker [S3](https://developer.apple.com/app-store/app-privacy-details/).

**Unverified:** Supabase may keep sign-in metadata such as IP address or user agent in its Auth tables or logs. That isn't one of Apple's data types, but the privacy policy should mention it once the owner checks the hosted project.

### Privacy policy content

What [S1 §5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.1) requires, filled in for OnlyWorkout:

1. **Who**: the owner as controller, with a contact email (the same as the Support URL).
2. **On the device only**: everything works without an account. Health data the app reads (heart rate, active energy) and writes (strength workouts in Apple Health) never leaves the iPhone or Watch. The Watch and iPhone exchange plans and Sessions directly (WatchConnectivity).
3. **Cloud Sync (optional, Sign in with Apple)**:
   - What goes to Supabase: the Workouts, Exercises, Sessions, Sets and progression records listed above, the Apple account identifier, and (if kept) the email.
   - Why: backup and restore across devices.
   - The processor: Supabase, with the hosting region the owner picked (**unverified** here).
   - No ads, no analytics, no selling, no tracking.
4. **Strava (optional)**:
   - What is uploaded per Session: exercise types, Sets, reps, weights, start time and duration. Never Health data.
   - What is stored: Strava's OAuth tokens and athlete ID in Supabase, readable only by the server functions. Strava's activity ID for 7 days on the uploading iPhone.
   - How to disconnect: in Settings, or on Strava.
   - Strava's own policy applies to data on Strava, and Strava collects Usage Data (required statement, [strava-api.md §7](strava-api.md#7-brand-guidelines-and-api-terms)).
5. **Third parties**: Supabase and Strava only, each under terms at least as protective as the policy [S1 §5.1.1(i)](https://developer.apple.com/app-store/review/guidelines/#5.1.1).
6. **Retention and deletion**:
   - Cloud data is kept until the user deletes the account in Settings, which deletes it immediately along with the Strava connection, and revokes the Apple sign-in.
   - Signing out keeps the cloud copy.
   - Local data stays on the device until the app is deleted.
   - Explain how to withdraw consent: sign out, disconnect Strava, change Health access in the Health app.
7. **Rights** (GDPR): access, correction, deletion, portability, complaint to a supervisory authority.

---

## Next steps

### Owner (outside the code), in order

1. **Decide Strava for 1.0**: apply to Strava's Developer Program, or ship with Strava hidden. Everything below depends on it.
2. **Decide on the email scope** (drop it, or keep it and disclose Email Address).
3. **Design the app icon** (1024×1024; optional dark and tinted variants).
4. **Publish a privacy policy page and a support page** with a contact email.
5. **Supabase hosted project**:
   - Keep it live during review (Pro plan, or guaranteed activity).
   - Confirm the four `APPLE_*` secrets.
   - Turn off the email provider if only Apple sign-in is used. (Not an App Review rule; the local `config.toml` has `[auth.email] enable_signup = true`.)
   - Run Delete Account once against it on a device.
6. **App Store Connect app record**, with bundle ID `com.stefanblos.OnlyWorkouts`, primary category Health & Fitness:
   - medical device declaration: No
   - age rating questionnaire (expect 9+)
   - App Privacy answers (above)
   - Digital Goods: No
   - DSA trader status
   - pricing: free; availability
7. **Metadata**: description mentioning Apple Health and the Apple Watch, subtitle, keywords (no "Strava"), Support URL, Privacy Policy URL, copyright, iPhone screenshots (1206×2622 and 1320×2868) and Watch screenshots (e.g. 416×496).
8. **TestFlight**: upload a build, check for App Store Connect emails about missing API reasons, and run internal testing. For external testers: Beta App Description and Feedback Email, then TestFlight App Review.
9. **Submit** with review notes: no login needed, optional Sign in with Apple, Health permission at the first Session, the Watch flow, and Strava's status (incl. why tokens live on the server).

### In code (can start now)

1. Add `PrivacyInfo.xcprivacy` to `OnlyWorkout/Resources/` (UserDefaults `CA92.1`; collected data types as in the draft), the Watch app (`CA92.1`, `1C8F.1`) and the Watch widget extension (`1C8F.1`). Optionally add an empty one to `OnlyWorkoutWidgets/`.
2. Add `ITSAppUsesNonExemptEncryption = NO` to `Config/OnlyWorkout-Info.plist`.
3. Settings: add Privacy Policy and Support links to the last section (strings with symbol keys in `SharedUI/Localizable.xcstrings`); URLs once the owner has them.
4. Purpose strings: mention calories/active energy in `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription` (iPhone and Watch build settings).
5. If the owner drops the email: remove `.email` from `requestedScopes` in `CloudSyncSection`, and set `email_optional = true` in `supabase/config.toml`.
6. If Strava is hidden for 1.0: one switch that hides Settings → Strava, the Session detail upload, and the Strava Exercise picker in the Custom Exercise editor.
7. `MARKETING_VERSION = 1.0`. Optionally put `-sampleData` behind `#if DEBUG`.
8. Add the icon PNGs to both `AppIcon.appiconset`s once they exist.
9. Watch supabase-swift for a v2 release containing `Sources/Helpers/PrivacyInfo.xcprivacy`, and bump the package then.

---

## Sources

- **S1** App Review Guidelines, last updated 2026-06-08 (§1.5, 2.1, 2.3.1, 2.3.3, 2.3.6–2.3.8, 2.5.1, 2.5.4, 2.5.16, 2.5.18, 4.5.3–4.5.4, 4.8, 5.1.1, 5.1.2, 5.1.3, 5.2.1–5.2.2): <https://developer.apple.com/app-store/review/guidelines/>
- **S2** Offering account deletion in your app: <https://developer.apple.com/support/offering-account-deletion-in-your-app/>
- **S3** App privacy details on the App Store (definition of "collect", optional disclosure, data types, purposes, tracking): <https://developer.apple.com/app-store/app-privacy-details/>
- **S4** Privacy manifest files: <https://developer.apple.com/documentation/bundleresources/privacy-manifest-files>
- **S5** Describing use of required reason API (enforced since 2024-05-01; per-bundle rule; SDKs can't rely on the app's manifest): <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>
- **S6** `NSPrivacyAccessedAPIType` (API categories and reason codes `CA92.1`, `1C8F.1`, `C617.1`, …): <https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype>
- **S7** Third-party SDK requirements (list of SDKs that require a privacy manifest and signature): <https://developer.apple.com/support/third-party-SDK-requirements/>
- **S8** Describing data use in privacy manifests, and `NSPrivacyCollectedDataType`: <https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests>
- **S9** supabase-swift: release v2.55.3 (2026-09-29, from `release/v2`) <https://github.com/supabase/supabase-swift/releases/tag/v2.55.3>; PR #1354 "declare the file-timestamp required-reason API in a privacy manifest" (merged 2026-09-17) <https://github.com/supabase/supabase-swift/pull/1354>
- **S10** HealthKit, Protecting user privacy (purpose strings, use clear in marketing text and UI, no ads, third-party sharing, privacy policy): <https://developer.apple.com/documentation/healthkit/protecting-user-privacy>; Setting up HealthKit: <https://developer.apple.com/documentation/healthkit/setting-up-healthkit>
- **S11** Complying with encryption export regulations: <https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations>; `ITSAppUsesNonExemptEncryption`: <https://developer.apple.com/documentation/bundleresources/information-property-list/itsappusesnonexemptencryption>
- **S12** Screenshot specifications (iPhone and Apple Watch sizes, required sizes): <https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications>
- **S13** Configuring your app icon (single 1024×1024 image; App Store icon required): <https://developer.apple.com/documentation/xcode/configuring-your-app-icon>
- **S14** Add watchOS app information: <https://developer.apple.com/help/app-store-connect/create-an-app-record/add-watchos-app-information>
- **S15** Age ratings values and definitions: <https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions>
- **S16** Declare regulated medical device status: <https://developer.apple.com/help/app-store-connect/manage-app-information/declare-regulated-medical-device-status>
- **S17** Upcoming requirements (SDK minimum since 2026-04-28, age rating since 2026-01-31, DSA, approved API reasons): <https://developer.apple.com/news/upcoming-requirements/>
- **S18** Submitting to the App Store (April 2027 minimums, iPhone Duo): <https://developer.apple.com/app-store/submitting/>
- **S19** Manage EU Digital Services Act trader requirements: <https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements>
- **S20** Platform version information (description, keywords, Support URL, copyright, review notes, sign-in): <https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information>
- **S21** App information (name, subtitle, privacy policy URL): <https://developer.apple.com/help/app-store-connect/reference/app-information/app-information>; App privacy (Privacy Policy URL "required for all apps"): <https://developer.apple.com/help/app-store-connect/reference/app-information/app-privacy>
- **S22** Invite external testers: <https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers>; Provide test information: <https://developer.apple.com/help/app-store-connect/test-a-beta-version/provide-test-information>
- **S23** Sign in with Apple REST API, Revoke tokens: <https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens>
- **S24** Overview of Accessibility Nutrition Labels: <https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels>
- **S25** Complete the Digital Goods and Services questionnaire: <https://developer.apple.com/help/app-store-connect/manage-app-information/complete-the-digital-goods-and-services-questionnaire>
- **S26** Supabase, Project Pausing (Free Plan, 7-day low-activity window): <https://supabase.com/docs/guides/platform/free-project-pausing>
- **S27** Prepare your app for iPhone Duo: <https://developer.apple.com/iphone-duo/prepare/>
- Strava facts (capacity, brand guidelines, API Policy) are not re-researched here; they come from [strava-api.md](strava-api.md) and its sources S5–S8 there.
- Repo audit (2026-10-08, grep/find, no build): `Config/*.plist`, `Config/*.entitlements`, `OnlyWorkout.xcodeproj/project.pbxproj` build settings, all four `Assets.xcassets`, `SharedUI/Localizable.xcstrings`, `OnlyWorkout/Features/Settings/*`, `supabase/functions/delete-account/index.ts`, `supabase/config.toml`, `supabase/migrations/*`, `Packages/OnlyWorkoutKit/Package.resolved` and the checked-out packages under `Packages/OnlyWorkoutKit/.build/checkouts`.
