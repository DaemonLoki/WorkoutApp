# Onboarding and permissions (M6)

Researched 2026-10-09 against the owner's M6 decisions: a first-launch tour of about 4 pages built from live components, then setup (Apple Health, notifications, "Restore with Cloud Sync" or "Start fresh"), ending in the Workout editor. iPhone only. Sources are listed at the end, and each `[S…]` label links to its URL. Each claim carries one of three labels: **confirmed** (developer.apple.com documentation, the Human Interface Guidelines (HIG), the App Review Guidelines or a WWDC session), **unverified** (secondary sources only, e.g. developer forum posts by non-staff, or our reading of a rule), or **not documented**.

## Summary and verdict

**The plan works, but the setup step must not be one page with several buttons.** Five findings change the design:

1. **A pre-permission screen may have exactly one button, titled like "Continue" or "Next", and no way out.** The HIG says: "Include only one button and make it clear that it opens the system alert." It also says not to offer "a way for people to leave the screen … without viewing the system alert — like offering an option to close or cancel" [S3]. In March 2026 App Review rejected a pre-prompt with a "Not Now" button under 5.1.1(iv) (**unverified**, forum report [U1]). So Health and notifications each get their own single-button page, and people decline in the system sheet itself. "Skip" belongs on the tour pages only.
2. **Asking for Apple Health in onboarding goes against a HIG "should", but no App Review rule forbids it.** The HealthKit HIG says to request access "only when you need it … not immediately after your app launches" [S4]. The Onboarding HIG says to put a permission request in onboarding only if the app needs it "before it can function" [S1]. OnlyWorkout works without Health. The App Review Guidelines contain no rule against an in-onboarding request [S10]; 5.1.1(iv) only bars manipulating or forcing consent. **Verdict:** acceptable if the Health page comes after the tour has shown what Health adds, uses one neutral button and never blocks the app on a "no". The risk is a softer approval rate, not a rejection (**unverified**: our reading).
3. **The existing fallback only covers people who never reached the Health page.** HealthKit shows its sheet once per set of types. After any answer, even "all off", `statusForAuthorizationRequest` returns `.unnecessary`, and the sheet never appears again [S11, S12]. So the explanation at the first Session start shows only if onboarding was quit before the Health page, or skipped past it. A denial is final; the app can only point to Settings or the Health app.
4. **Rest-end notifications use `.timeSensitive` without the Time Sensitive capability.** Apple: "To configure Time Sensitive notifications, enable the associated capability via Xcode" [S21]. `Config/OnlyWorkout.entitlements` has no such entry, so today's Rest alerts probably arrive as ordinary ones and don't break through Focus (the fallback behaviour is **not documented**). Provisional authorization is no alternative: provisional notifications appear "only … in the notification center's history", with no banner or sound [S17].
5. **The Sign in with Apple button must keep a system title.** The only allowed titles are "Sign in with Apple", "Sign up with Apple" and "Continue with Apple" [S5]. "Restore with Cloud Sync" can be the page heading, not the button label.

**Replay:** Apple only says that a tutorial people skipped must not reappear by itself, and should be easy to find later "in a help, account, or settings area" [S1]. Settings → About fits that exactly (**confirmed**).

---

## 1. HIG: onboarding, launching, permissions

**Onboarding: confirmed** [S1] (page last changed 2024-06-10)

- The ideal is no onboarding: "people can understand your app … simply by experiencing it". If there is one, make it "fast, fun, and optional", and show it after launching completes.
- **Teach through interactivity.** People retain more "when they can actually perform the task". WWDC17's "Love at First Launch" says the same: "Teach through interactive experiences", and "Always lead with great content" [S22].
- Make it brief and "doesn't require people to memorize a lot of information"; teaching too much overwhelms.
- **Skipping and replay.** "Consider making it optional. If you let people skip the tutorial … don't present it again on subsequent launches, but make sure it's easy for people to find if they want to view it later", for example in "a help, account, or settings area".
- Teach the app, not the system or the device.
- **No licence agreements**: "Let the App Store display agreements and disclaimers."
- Postpone nonessential setup; provide reasonable defaults. OnlyWorkout's defaults are already good: Rest Timer on, Start Sessions on Apple Watch on.
- **Permissions in onboarding:** "If your app … needs access to private data or resources before it can function, consider integrating the permission request into your onboarding flow … Otherwise, present a permission request when people first access the specific function".
- Consider context-specific tips (TipKit) instead of one flow.

**Launching: confirmed** [S2]

- Launch instantly. The launch screen should be nearly identical to the first screen, so no logo or text on it.
- A splash graphic, if any, belongs at the start of onboarding.

**Privacy → Requesting permission: confirmed** [S3] (page last changed 2023-06-21)

- "Request permission only when your app clearly needs access … Ideally, wait … until people actually use an app feature that requires access."
- "Avoid requesting permission at launch unless the data or resource is required for your app to function."
- **Purpose strings:** "a brief, complete sentence that's straightforward, specific", in sentence case, active voice, ending with a period.
- **Pre-alert screens** ("custom screen or window before the system alert"):
  - Show one only "if it's essential to provide additional details".
  - "Include only one button and make it clear that it opens the system alert."
  - Don't title it "Allow". Its button may look like the alert's allow button, and that is manipulation. Use "a term like 'Continue' or 'Next'".
  - "Don't include additional actions … don't provide a way for people to leave the screen or window without viewing the system alert — like offering an option to close or cancel."
  - The list of covered resources ("camera, microphone, location, contact, calendar, and tracking") doesn't name Health or notifications. It starts with "including", so we apply it to both (**unverified**: our reading).
- Prohibited designs that "will cause rejection" are listed for tracking prompts: incentives, a screen that "looks like a request", an image of the alert, and annotations around it.

**HealthKit HIG: confirmed** [S4]

- "Request access to health data only when you need it", e.g. weight access when people log weight, "but not immediately after your app launches".
- "Avoid adding custom screens that replicate the standard permission screen's behavior or content." So the Health page has no toggles and no list of data types.
- "Manage health data sharing solely through the system's privacy settings." So the app has no in-app Health on/off switch.
- In UI text, say "Apple Health", never "HealthKit".
- Use only Apple's Apple Health icon, with the name "Apple Health" next to it. Never mimic it, never use it as a button.
  - `HealthExplanationView` shows a red `heart.text.square.fill`. That arguably mimics the Health icon (**unverified**: our reading).
  - Prefer the official icon from Apple Design Resources, or a neutral symbol.
- Don't show Health app screenshots.
- Keep ring-like elements clearly distinct from Activity rings. This matters for a Rest ring shown on a Watch.

## 2. Apple Health authorization

**`requestAuthorization(toShare:read:)`: confirmed** [S11]

- The sheet appears only for "a new data type (a type of data that the user hasn't previously granted or denied permission for in this app)". "If the user has already chosen to grant or prohibit access to all of the types specified, HealthKit returns the request without prompting the user."
- On watchOS 6+, the sheet appears on the Watch itself.
- Missing usage keys crash the app. Both keys are set in the iPhone and Watch targets (`project.pbxproj`).
- After any answer, the app is listed in Health → Sources.
- The sheet now has a **second screen** where people choose a recent window or their full history [S14]. OnlyWorkout reads heart rate and energy only live, during a Session, so either choice works (**unverified**: our reading).

**Status checks: confirmed** [S12, S13, S14]

- `getRequestStatusForAuthorization(toShare:read:)` (async form: `statusForAuthorizationRequest`, already used by `WorkoutRecorder.needsAuthorization()`) answers one question: would a request show the sheet? `.shouldRequest` means yes, `.unnecessary` means no.
- `authorizationStatus(for:)` reports **share** status only (`.sharingAuthorized` / `.sharingDenied` / `.notDetermined`).
- Read status is never disclosed: "your app cannot determine whether or not a user has granted permission to read data."
- So after onboarding, the app can know whether workouts can be saved (`WorkoutRecorder.canSaveWorkouts`), but not whether heart rate can be read.

**SwiftUI `.healthDataAccessRequest(store:shareTypes:readTypes:trigger:completion:)`: confirmed** [S16, S14]

- Available on iOS 17+ and watchOS 10.2+. It needs `import HealthKitUI` as well as SwiftUI.
- The request runs "when you modify the trigger's value", and the completion runs "on a background queue".
- Apple's own sample triggers it in `.onAppear`, which the HIG discourages for an app like ours.
- **It adds nothing here.** `WorkoutRecorder.requestAuthorization()` already owns the store and the type sets. The modifier would duplicate both and need a hop back to the main actor.
- Keep calling the recorder. Make the call only once no sheet is mid-dismissal (the `AppModel` comment notes that HealthKit "fails silently" otherwise).

**App Review: confirmed** [S10] (guidelines last updated 2026-06-08)

- **5.1.1(iv)** "Apps must respect the user's permission settings and not attempt to manipulate, trick, or force people to consent to unnecessary data access … Where possible, provide alternative solutions for users who don't grant consent."
- **5.1.1(ii)**: purpose strings must "clearly and completely describe your use of the data".
- **5.1.1(iii)** data minimisation. OnlyWorkout requests only the workout type, heart rate and active energy.
- **2.5.1**: HealthKit is for "health and fitness purposes" and the integration must be stated in the app description.
- **5.1.3(i)/(ii)**: no advertising use, disclose the health data collected, no health data in iCloud; HealthKit apps also need a privacy policy [S15]. Already met; see [app-store-readiness.md](app-store-readiness.md).
- **Not documented:** the guidelines say nothing about the button wording on pre-permission screens. That rule lives in the HIG [S3] and reaches App Review through 5.1.1(iv). The rejection quoted in [U1] reads: "The user should always proceed to the permission request after the message."

**Watch and iPhone permissions:** Apple documented shared iPhone/Watch HealthKit authorization in 2016. A 2022 forum report says single-target Watch apps get **independent** permissions on real devices (**unverified**, [U2]). OnlyWorkout's Watch app is that kind of target. So never assume a grant on the Watch covers the iPhone. Check the iPhone's own request status.

## 3. Notifications

**Explicit request: confirmed** [S17, S18]

- The first `requestAuthorization(options:)` shows the alert. "Subsequent authorization requests don't prompt the person."
- Ask "in a context that helps people understand why", e.g. "after the person schedules a first task". That beats "automatically requesting authorization on first launch".
- An onboarding page explaining Rest alerts is a context; a cold launch-time prompt is not.
- Before scheduling, check `getNotificationSettings`. `RestNotifier.schedule` doesn't today; the system simply drops the notification if it isn't allowed (**unverified**).

**Provisional (`.provisional`): confirmed, and the wrong tool** [S17, S20]. It grants without asking. Notifications are then "delivered quietly — they don't interrupt the person with a sound or banner, or appear on the lock screen". A Rest-end alert that doesn't make a sound is useless.

**Time Sensitive: confirmed** [S6, S19, S21]

- Time Sensitive is meant for events "happening now or will happen within an hour". It breaks through Focus and scheduled summaries, but not the Ring/Silent switch.
- The first time one arrives, the system explains it and offers to turn it off.
- Configuring it needs the Xcode capability [S21]; the entitlement key `com.apple.developer.usernotifications.time-sensitive` is **unverified** (Apple's entitlement page didn't resolve).
- `UNAuthorizationOptions.timeSensitive` is **deprecated** [S20], so don't request it; the capability plus `interruptionLevel` is the mechanism.
- A forum report says Time Sensitive started working only after a fresh install (**unverified**, [U3]). That doesn't affect onboarding, which runs on a fresh install.
- Not `.critical`: that needs an Apple-approved entitlement and is meant for health-and-safety emergencies [S6].

**App Review 4.5.4: confirmed** [S10]: push "must not be required for the app to function". Rest works without notifications (in-app ring, Live Activity), so declining is harmless.

## 4. Sign in with Apple in onboarding

**HIG: confirmed** [S5]

- "Ask people to sign in only in exchange for value", e.g. to "synchronize data". "Delay sign-in as long as possible".
- Restore is the one moment where signing in on first launch clearly pays off.
- Button titles: "Sign in with Apple", "Sign up with Apple" or "Continue with Apple" only. Use the system button (`SignInWithAppleButton`, as `CloudSyncSection` does).
- Make it "no smaller than other sign-in buttons", minimum 140 × 30 pt, margin ≥ 1/10 of its height.
- Use the black style on light backgrounds and white on dark. A capsule corner radius is allowed.
- "As soon as Sign in with Apple completes, welcome people to their new account" and show that they are signed in.

**Guidelines: confirmed** [S10]

- **4.8** applies only to third-party or social logins for a primary account. Sign in with Apple is the only login, so 4.8 is met.
- **5.1.1(v)** "If your app doesn't include significant account-based features, let people use it without a login." So "Start fresh" must have equal standing and must never be hidden behind the sign-in.
- **Not documented:** Apple has no specific guidance on "restore" flows.

## 5. SwiftUI implementation notes (iOS 27)

WWDC26's "What's new in SwiftUI" adds no onboarding, paging or permission API [S23]. Everything below uses existing API.

- **Presentation: swap the root content.**
  - Decide once in `OnlyWorkoutApp.init`/`AppModel.init`, before `PhoneWatchLink` can deliver records. Show onboarding when it isn't marked complete and the store has no Workouts and no Sessions. Catalog Exercises don't count.
  - Render `OnboardingView` instead of the `TabView`, with no presentation animation. A `fullScreenCover` bound to `true` at launch is presented after the first frame, which risks a flash of Today (**unverified**).
  - Keep `RootView`'s Session cover and sheets on a container around both, so a Watch-started Session still shows during onboarding.
  - For **replay** from Settings → About, present the tour as a `fullScreenCover` from the Settings sheet [S24]. Show the tour pages only, with Done, and no setup pages.
- **Persisting:** `@AppStorage("hasCompletedOnboarding")` (UserDefaults, covered by the `CA92.1` reason in `PrivacyInfo.xcprivacy`) [S24].
  - Mark it complete at the end and on Skip-to-setup completion, not on first appearance.
  - On a device with data but no flag, e.g. the owner's phone updating from a pre-M6 build, set it silently.
- **Paging:**
  - `TabView(selection:)` with `.tabViewStyle(.page(indexDisplayMode: .always))` and `.indexViewStyle(.page(backgroundDisplayMode: .always))` gives system page dots with built-in accessibility [S24, S9]. The HIG puts page dots centred at the bottom and says not to colour them.
  - `ScrollView` + `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)` gives more control, but the page indicator must then be built by hand [S24].
  - Use the TabView for the tour. Run the **setup steps as a plain step state** (no swipe). That way a swipe can't leave a pre-permission page, which would break the single-button rule above.
- **Reduce Motion** (`\.accessibilityReduceMotion`: "avoid large animations") [S24, S8]:
  - Replace slides with fades, and drop the `numericText` roll and the glow pulse.
  - Show each demo's end state. Animations play once per page visit, never in a loop.
  - "Make motion optional": the caption alone must carry the message [S7].
  - Don't play haptics in autoplay; only when the person taps.
- **Interactivity over autoplay** [S1, S7]:
  - Let people tap the real Done in the Set demo and accept the Step Up card. Autoplay starts only after a short idle.
  - Any animation stops when the page changes ("Let people cancel motion").
- **Live components with sample data:** `SetView`, `RestView`/`RestRing`, `OfferCard` and `NextUpCard` already take plain values and closures, so they can be fed demo values without a `TrainingLog`. Wrap them in `.allowsHitTesting` and `.accessibilityElement(children: .combine)` where they are only illustrative, so VoiceOver doesn't announce a "Skip" that does nothing.
- **Dynamic Type:** give each page a vertical `ScrollView`, pin the primary button with `.safeAreaInset(edge: .bottom)`, and let captions wrap.
  - At accessibility sizes the demo may need a `ViewThatFits` fallback: a static end state or a smaller excerpt.
- **VoiceOver:**
  - Always show a visible **Next** button; don't rely on swipe alone.
  - On page change, move focus to the page title with `@AccessibilityFocusState`.
  - The three-finger scroll gesture should page a page-style `TabView` (**unverified**).
- **Testing:**
  - `-uiTesting` seeds a Workout, so the "fresh install" rule already skips onboarding. Also check the flag explicitly, so a future change to the seed can't break the Session-flow UI test.
  - AGENTS.md keeps a single UI test. Verify onboarding with previews (each page, Reduce Motion, accessibility sizes).
  - For manual runs, add a `#if DEBUG`-only `-onboarding` launch argument (no hidden switches in release, guideline 2.3.1).

## 6. Recommendation for OnlyWorkout

**Flow** (iPhone only; the Watch keeps its empty state):

| # | Page | Live component, motion | Covers |
|---|---|---|---|
| 1 | "Get stronger, one step at a time" | Next Up card for a sample "Push Day": Planned Exercises with Targets, a Superset bracket; rows fade in | minimal, progressive overload; Exercise Catalog → Workouts; Supersets |
| 2 | "Log a Set with one tap" | `SetView` → Done (press scale, reps/weight `numericText`) → Rest ring starts | Sets, Rest timers |
| 3 | "Step Up when you're ready" | `OfferCard` slides in (`.smooth`), accept → 60 → 62.5 kg roll + orange glow | automatic Step Up after a Target Hit |
| 4 | "On your iPhone or Apple Watch" | Rest ring in a simple watch-shaped frame (not product imagery, **not documented** whether Apple bezels may be used in-app); below, three rows: Apple Health, Strava, Cloud Sync | iPhone or Watch; Health + Strava; sync |
| 5 | "Restore or start fresh" | Heading "Already use OnlyWorkout?"; system `SignInWithAppleButton` (`.continue` or `.signIn`), **Start Fresh** button of equal width; footer: Cloud Sync is optional, can be turned on later in Settings | reinstall restore |
| 6 | Apple Health | One-line benefit ("Save every Session to Apple Health and see your heart rate when you train with Apple Watch."), one button **Continue** → system sheet | Health |
| 7 | Rest alerts | "Get an alert when Rest is over, even with OnlyWorkout in the background.", one button **Continue** → system alert | notifications |
| → | Today, with the Workout editor pushed ("Create your first Workout") | via Today's existing `newWorkout` navigation | |

**Ordering:**

- Tour first: value before any request [S1, S22].
- Then restore. A pull started here keeps running while people answer pages 6–7, so the end screen can depend on its result.
- Then Health, then notifications.
- **Skip** (toolbar, pages 1–4 only) jumps to page 5. The tour is optional; the setup steps aren't skipped, because each is a choice or one Continue tap.

**Wording rules for pages 6–7:**

- One button, "Continue", in the same prominent style as elsewhere. Never "Allow", "Enable" or "Turn On".
- No close, back, "Not now" or swipe [S3, U1].
- Say what the person gets, in one sentence. Don't repeat the purpose string or imitate the sheet [S4].
- Write "Apple Health", never "HealthKit".
- A red heart glyph that imitates the Health icon is out; use the official Apple Health icon with its name, or a neutral symbol [S4].

**Edge cases:**

- **Health already decided** (`statusForAuthorizationRequest == .unnecessary`, e.g. after a restore the system remembered): skip page 6. A screen whose only button does nothing is pointless.
  - If share is denied, Settings → Apple Health should already say how to change it in the Health app.
  - Notifications work the same way: if already determined, skip page 7.
- **Health on the Watch:** don't infer anything from the Watch. Per-device independence is likely [U2]. The Watch asks on its own at its first Session (`WatchModel`).
- **Restore while the Watch has data:** the Watch sends its plan and 14 days of Sessions as soon as the link activates. That can happen mid-onboarding, even with Start Fresh.
  - Records keep their IDs and the merge is per record, so a later cloud pull merges instead of duplicating.
  - The iPhone's first `publishToWatch()` sends a near-empty snapshot. Merging by record with tombstones means absent records aren't deleted on the Watch (**unverified**: our reading of §10; worth one manual test with a paired simulator).
- **The editor must not open on a restored plan:** decide the destination at the very end. If `log.workouts()` isn't empty (restore or Watch), land on Today; otherwise push the editor.
  - Restore runs `CloudSync.signIn` (push, then pull). Show "Restoring…" on page 5, then let people continue while it finishes.
  - Afterwards call `AppModel.syncWithCloud()`, so the Watch gets the restored plan and Strava's state refreshes. The Strava connection lives on the server and survives the reinstall.
- **Sign-in fails or is cancelled:** stay on page 5 with the existing `signInFailed` alert (not shown for a cancel); Start Fresh still works.
  - Extract the button logic from `CloudSyncSection` into one shared view, so the nonce handling isn't duplicated.
- **App quit mid-onboarding:** with no Workouts it reappears next launch, which is fine. If a restore already pulled Workouts, it doesn't reappear, and the Health explanation at the first Session start is the fallback (§2).
- **Strava capacity gate closed:** page 4 should say "upload to Strava" without promising it, because Settings may show "Full for now" (README §12).
- **UI test:** unaffected as long as `-uiTesting` skips onboarding (§5).

**Follow-ups outside onboarding:**

- Add the Time Sensitive Notifications capability to the iPhone target (§3).
- Update README §11 ("Permission is requested at the first Session start") and the App Review notes in `docs/release/app-store-listing.md` ("Apple Health access is requested before the first Session").
- Optionally gate `RestNotifier.schedule` on `getNotificationSettings`.

---

## Sources

Primary (Apple):

- **S1** HIG, Onboarding (changed 2024-06-10): <https://developer.apple.com/design/human-interface-guidelines/onboarding>
- **S2** HIG, Launching: <https://developer.apple.com/design/human-interface-guidelines/launching>
- **S3** HIG, Privacy → Requesting permission, Pre-alert screens (changed 2023-06-21): <https://developer.apple.com/design/human-interface-guidelines/privacy>
- **S4** HIG, HealthKit (privacy protection, Apple Health icon, editorial guidelines, Activity rings): <https://developer.apple.com/design/human-interface-guidelines/healthkit>
- **S5** HIG, Sign in with Apple (offering, button titles, sizes): <https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple>
- **S6** HIG, Managing notifications (interruption levels, Time Sensitive): <https://developer.apple.com/design/human-interface-guidelines/managing-notifications>
- **S7** HIG, Motion: <https://developer.apple.com/design/human-interface-guidelines/motion>
- **S8** HIG, Accessibility (Reduce Motion): <https://developer.apple.com/design/human-interface-guidelines/accessibility>
- **S9** HIG, Page controls: <https://developer.apple.com/design/human-interface-guidelines/page-controls>
- **S10** App Review Guidelines, last updated 2026-06-08 (2.5.1, 4.5.4, 4.8, 5.1.1(ii)–(v), 5.1.3): <https://developer.apple.com/app-store/review/guidelines/>
- **S11** `HKHealthStore.requestAuthorization(toShare:read:)`: <https://developer.apple.com/documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:)>
- **S12** `getRequestStatusForAuthorization(toShare:read:completion:)`: <https://developer.apple.com/documentation/healthkit/hkhealthstore/getrequeststatusforauthorization(toshare:read:completion:)>
- **S13** `authorizationStatus(for:)`: <https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationstatus(for:)>
- **S14** Authorizing access to health data (SwiftUI modifier, limited history screen): <https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data>
- **S15** HealthKit, Protecting user privacy: <https://developer.apple.com/documentation/healthkit/protecting-user-privacy>
- **S16** `healthDataAccessRequest(store:shareTypes:readTypes:trigger:completion:)`: <https://developer.apple.com/documentation/swiftui/view/healthdataaccessrequest(store:sharetypes:readtypes:trigger:completion:)>
- **S17** Asking permission to use notifications (in context, provisional): <https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications>
- **S18** `UNUserNotificationCenter.requestAuthorization(options:completionHandler:)`: <https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)>
- **S19** `UNNotificationInterruptionLevel.timeSensitive`: <https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive>
- **S20** `UNAuthorizationOptions` (`provisional`; `timeSensitive` deprecated): <https://developer.apple.com/documentation/usernotifications/unauthorizationoptions>
- **S21** WWDC21 10091, Send communication and Time Sensitive notifications: <https://developer.apple.com/videos/play/wwdc2021/10091/>
- **S22** WWDC17 816, Love at First Launch: <https://developer.apple.com/videos/play/wwdc2017/816/>
- **S23** WWDC26 269, What's new in SwiftUI: <https://developer.apple.com/videos/play/wwdc2026/269/>
- **S24** SwiftUI reference: `TabViewStyle.page` <https://developer.apple.com/documentation/swiftui/tabviewstyle/page>, `scrollTargetBehavior(_:)` <https://developer.apple.com/documentation/swiftui/view/scrolltargetbehavior(_:)>, `accessibilityReduceMotion` <https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion>, `AppStorage` <https://developer.apple.com/documentation/swiftui/appstorage>, `fullScreenCover(isPresented:onDismiss:content:)` <https://developer.apple.com/documentation/swiftui/view/fullscreencover(ispresented:ondismiss:content:)>

Secondary (unverified):

- **U1** "App Rejected – Guideline 5.1.1(iv) – Location Permission Pre-Prompt With 'Not Now' Button", Apple Developer Forums, March 2026, no staff answer: <https://developer.apple.com/forums/thread/817672>
- **U2** HealthKit permissions independent for iPhone and single-target Watch apps on devices, Apple Developer Forums, 2022: <https://developer.apple.com/forums/thread/715238>
- **U3** "Time sensitive push only works after reinstall", Apple Developer Forums: <https://developer.apple.com/forums/thread/691183>

[S1]: https://developer.apple.com/design/human-interface-guidelines/onboarding
[S2]: https://developer.apple.com/design/human-interface-guidelines/launching
[S3]: https://developer.apple.com/design/human-interface-guidelines/privacy
[S4]: https://developer.apple.com/design/human-interface-guidelines/healthkit
[S5]: https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple
[S6]: https://developer.apple.com/design/human-interface-guidelines/managing-notifications
[S7]: https://developer.apple.com/design/human-interface-guidelines/motion
[S8]: https://developer.apple.com/design/human-interface-guidelines/accessibility
[S9]: https://developer.apple.com/design/human-interface-guidelines/page-controls
[S10]: https://developer.apple.com/app-store/review/guidelines/
[S11]: https://developer.apple.com/documentation/healthkit/hkhealthstore/requestauthorization(toshare:read:)
[S12]: https://developer.apple.com/documentation/healthkit/hkhealthstore/getrequeststatusforauthorization(toshare:read:completion:)
[S13]: https://developer.apple.com/documentation/healthkit/hkhealthstore/authorizationstatus(for:)
[S14]: https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data
[S15]: https://developer.apple.com/documentation/healthkit/protecting-user-privacy
[S16]: https://developer.apple.com/documentation/swiftui/view/healthdataaccessrequest(store:sharetypes:readtypes:trigger:completion:)
[S17]: https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications
[S18]: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/requestauthorization(options:completionhandler:)
[S19]: https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
[S20]: https://developer.apple.com/documentation/usernotifications/unauthorizationoptions
[S21]: https://developer.apple.com/videos/play/wwdc2021/10091/
[S22]: https://developer.apple.com/videos/play/wwdc2017/816/
[S23]: https://developer.apple.com/videos/play/wwdc2026/269/
[S24]: https://developer.apple.com/documentation/swiftui/tabviewstyle/page
[U1]: https://developer.apple.com/forums/thread/817672
[U2]: https://developer.apple.com/forums/thread/715238
[U3]: https://developer.apple.com/forums/thread/691183
