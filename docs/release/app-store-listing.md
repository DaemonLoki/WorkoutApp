# App Store listing and App Review notes (1.0)

Drafts for App Store Connect, to paste in (DaemonLoki/WorkoutApp#25, used by #29). Limits and rules come from [docs/research/app-store-readiness.md](../research/app-store-readiness.md). Keep "Strava" out of the name, subtitle and keywords; "Compatible with Strava" may appear in the description.

## App information

| Field | Value |
|---|---|
| Name (≤30) | OnlyWorkout |
| Subtitle (≤30) | Strength training, set by set |
| Bundle ID | `com.stefanblos.OnlyWorkouts` |
| Primary category | Health & Fitness |
| Secondary category | none |
| Price | Free, no in-app purchases |
| Privacy Policy URL | https://stefanblos.com/onlyworkout/privacy/ |
| Support URL | https://stefanblos.com/onlyworkout/support/ |
| Copyright | 2026 Stefan Blos |
| Version | 1.0 |

**Keywords** (≤100 characters, comma-separated, no spaces; 94 characters):

```
gym,weightlifting,lifting,progressive overload,workout log,strength,sets,reps,barbell,dumbbell
```

**Promotional text** (≤170):

> Plan your Workouts, log every Set with one tap on your iPhone or Apple Watch, and let OnlyWorkout tell you when it's time to add weight.

**Description:**

> OnlyWorkout is the simplest way to track strength training. Plan your Workouts once, then go through each Session set by set and log every Set with a single tap.
>
> PROGRESSIVE OVERLOAD, BUILT IN
> Every exercise has a fixed Target, like 3 × 8 at 60 kg. Hit it and OnlyWorkout offers a Step Up next time. Stall for three Sessions, or come back after more than three weeks, and it suggests a Step Down. You always decide.
>
> RUNS ON YOUR WRIST
> The Apple Watch app runs whole Sessions on its own, even with your iPhone left in the locker: log Sets, follow the rest timer, accept a Step Up. Start on the iPhone and the Session moves to your Watch; the iPhone shows it live.
>
> MADE FOR THE GYM FLOOR
> • Workouts in a rotation, independent of weekdays: OnlyWorkout always knows what's next
> • Supersets that alternate two exercises
> • A rest timer with a Live Activity on the Lock Screen and in the Dynamic Island
> • Progress charts per exercise, filtered by muscle group
> • A history of every Session
>
> APPLE HEALTH
> Each Session is saved to Apple Health as a strength workout, with heart rate and calories from your Apple Watch. Your Health data stays on your devices.
>
> YOURS, AND PRIVATE
> No account needed, no ads, no tracking. Optional Cloud Sync with Sign in with Apple backs up your training log. Delete your account at any time in Settings.
>
> COMPATIBLE WITH STRAVA
> Connect Strava to upload each finished Session as a Weight Training activity with every exercise, Set, rep and weight.

**What's New** (first release): leave empty.

## App Privacy answers

Data collected: **Yes**. For each type below: linked to the user, **not** used for tracking, purpose **App Functionality** only.

| Category | Data type | Why |
|---|---|---|
| Health & Fitness | Fitness | The training log synced with Cloud Sync and uploaded to Strava when connected |
| User Content | Other User Content | Workout and Custom Exercise names (free text) |
| Identifiers | User ID | The Supabase account ID, Apple's Sign in with Apple identifier, the Strava athlete ID |

Not collected: Health (heart rate and calories stay on device), Contact Info (the app doesn't request the email; DaemonLoki/WorkoutApp#21), Location, Usage Data, Diagnostics, and every other type. Tracking: **No**.

## Age rating questionnaire

Answer None/No to everything except:

- **Health or Wellness Topics**: Yes (Step Up / Step Down suggestions are exercise recommendations). Expected rating 9+.
- Medical or Treatment Information: None.
- Unrestricted Web Access: No (only Strava's consent page, in a sign-in sheet).
- User-Generated Content shared with others: No.

## Other App Store Connect declarations

- **Regulated medical device**: No.
- **Digital Goods and Services questionnaire** (if shown): No.
- **Export compliance**: handled by `ITSAppUsesNonExemptEncryption = NO` in the Info.plist.
- **Content rights**: no third-party content apart from Strava's official "Connect with Strava" button, used under Strava's brand guidelines.
- **EU DSA trader status**: owner decision (DaemonLoki/WorkoutApp#29).

## App Review notes

> OnlyWorkout works without an account. To try it: under Workouts, create a Workout and add a few Exercises from the built-in catalog; then start it from Today, log Sets with "Done", and finish the Session. Apple Health access is requested before the first Session; declining it doesn't block anything.
>
> Optional features:
> • Cloud Sync (Settings → Cloud Sync) uses Sign in with Apple; Delete Account is in the same section. It deletes all cloud data and revokes the Sign in with Apple token.
> • Apple Watch: the Watch app runs a full Session without the iPhone. With "Start Sessions on Apple Watch" on (Settings), starting on the iPhone moves the Session to the Watch.
> • Strava (Settings → Strava, needs Cloud Sync): uploads finished Sessions to the user's Strava account. Strava limits how many athletes an app may connect until Strava has reviewed it, and our app is in that review. When every place is taken, Settings shows Strava as "Full for now" instead of the Connect button. This is controlled on our server, so no app update is needed when Strava raises the limit. Strava's OAuth tokens are kept on our server (Supabase), not on the device, because refreshing them needs our Strava client secret, which must never ship in the app. Users can disconnect in Settings, which revokes the tokens at Strava and deletes them.
>
> Health data (heart rate, calories) is only shown on device and saved to Apple Health; it is never sent to our server or to Strava.

Before submitting, make sure the hosted Supabase project isn't paused (DaemonLoki/WorkoutApp#27).

## TestFlight

**Beta App Description:**

> OnlyWorkout tracks strength training on iPhone and Apple Watch: plan Workouts, log every Set with one tap, and get Step Up suggestions when you hit your Target. Please try a full Session, on the Watch if you have one, and connect Strava if there is a free place.

**Feedback email:** stefan.blos@gmail.com

## Screenshots

- iPhone: 1206×2622 (iPhone 18 Pro) and 1320×2868 (iPhone 18 Pro Max). Suggested screens: Today with Next Up, a Set during a Session, the rest timer, a Step Up card, a Progress chart, the Session summary.
- Apple Watch: e.g. 416×496 (Series 10–12, 46 mm). Suggested screens: a Set, the rest ring, the summary.
