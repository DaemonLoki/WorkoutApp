# Foundation Models for Recommendation reasons

Researched 2026-10-09. The question: how should the "Smart Workout Builder" use Apple's on-device Foundation Models framework on iOS 27? The owner has already fixed the design. Deterministic rules choose every Exercise. The model only writes the reason that every Recommendation carries (CONTEXT.md, "Recommending"), from structured facts the rules produce. Without the model, handwritten templates are used. Sources are listed at the end, and each `[…]` label links to its URL. Each claim carries one of three labels:

- **confirmed**: developer.apple.com documentation, the Xcode 27.0 SDK interface, WWDC session transcripts, the HIG, the App Review Guidelines, App Store Connect help, Apple Support, or an Apple DTS engineer.
- **unverified**: secondary sources only.
- **not documented**.

## Summary and verdict

**The design fits the framework well. Apple's own guidance describes this pattern:** fixed facts in, a short text out, and a non-AI fallback [F5, F12, H1]. iOS 27 changes a few details that the plan must account for:

1. **There is a new on-device model in iOS 27,** and it changes with OS updates. Apple has shipped three versions so far: 26.0–26.3, 26.4 and 27.0. Apple says to "test your prompts with the new model" after each one [F2, F3]. Even greedy sampling is deterministic only "for a given version" of the model [W2]. So tests can never assert exact model text.
2. **Error handling moved.** `LanguageModelSession.GenerationError` is deprecated in 27.0 [F7, X1]. Catch these instead:
   - `LanguageModelError`: `guardrailViolation`, `refusal`, `contextSizeExceeded`, `unsupportedLanguageOrLocale`, `rateLimited`, `timeout`, …
   - `SystemLanguageModel.Error.assetsUnavailable`
   - `LanguageModelSession.Error.concurrentRequests`
3. **Custom adapters are gone.** `SystemLanguageModel.Adapter` was deprecated in 26.4 and is *obsoleted* in iOS 27 [X1]. The only built-in specialisation left is `UseCase.contentTagging` [F3]. We need neither.
4. **The on-device model is unavailable on watchOS.** `SystemLanguageModel` is `@available(watchOS, unavailable)` [X1]. The framework itself is on watchOS 27, but only for Private Cloud Compute and custom models [F1, W8]. The reason text is iPhone-only, which is all we need.
5. **Use guided generation even for a single string.** With `@Generable` output, a refusal is thrown as `LanguageModelError.refusal`. With plain-string output, a refusal comes back as ordinary text ("Sorry, I can't help…"), and Apple says you "might not be able to programmatically determine" which one you got [F12]. That text would end up shown as the reason.
6. **App Store impact is small.** No age-rating question targets AI [A2]. Apple only says to weigh AI features when estimating sensitive content [A3]. Text generated and shown on device is not "collected" for the privacy label [A4]. One HIG rule needs a design decision: "Clearly identify when and where you use AI" [H1].

**Recommendation** (details in §6):

- Add a small iOS-only package module, `OnlyWorkoutIntelligence`, that is the only importer of `FoundationModels`. It sits behind a `ReasonWriter` protocol that the app target owns.
- Core produces the facts (`RecommendationFacts`) and the reason codes the templates use.
- Use one fresh `LanguageModelSession` per Recommendation, with greedy sampling, a one-field `@Generable` output and a length check.
- Every failure, refusal, timeout and unavailability reason falls back to the String Catalog template, silently.

---

## 1. API on iOS 27 (and what changed since iOS 26)

**Availability: confirmed** [F3, F4, F5, X1]

- `SystemLanguageModel.default.availability` is `.available` or `.unavailable(reason)`. There is also a shortcut, `isAvailable`. `SystemLanguageModel` is `Observable`, so SwiftUI updates when availability changes [F3].
- The `UnavailableReason` cases are `deviceNotEligible`, `appleIntelligenceNotEnabled` and `modelNotReady` ("downloading or … other system reasons") [F4, F5].
  - The enum is **not `@frozen`** in the SDK [X1], so a `switch` over it needs `@unknown default`.
  - **Not documented:** which reason a supported iPhone reports in China mainland, or when the device language and Siri language don't match. Both block Apple Intelligence [D1].
- Apple's UI advice per reason [W3]:
  - Not eligible: hide the feature.
  - Not enabled: say why it is unavailable; the user may opt in.
  - Not ready: try again later.
- The model "can take some time" to download after Apple Intelligence is turned on [F5].
- Availability can also change mid-request. If the user turns Apple Intelligence off while the app is running, the request throws `SystemLanguageModel.Error.assetsUnavailable` [F20].

**Sessions, instructions, prompts: confirmed** [F5, F6, W1, W4]

- `LanguageModelSession(model:tools:instructions:)` holds a transcript. For single-turn use, "create a new session each time you call the model" [F5].
- Instructions come from the developer and take priority over prompts. Apple says that protection against prompt injection is "by no means bullet proof" [W1]. Never put user input into instructions [F12, W4].
- One request at a time per session. A second call throws `LanguageModelSession.Error.concurrentRequests` (new in 27) [F19]. Check `isResponding` first [F19, W1].
- New in 27: dynamic profiles, `ContextOptions` (reasoning level, PCC only), `usage` token accounting, `transcriptErrorHandlingPolicy`, and image attachments [F1, F2, W5, W6]. None of these are needed here.

**Guided generation: confirmed** [F13, W1]

- `@Generable` structs and enums plus `@Guide(description:)` and value guides use constrained decoding. Apple says that "guarantees structural correctness" [W1].
- Properties are generated in declaration order [F13].
- `GenerationGuide` has `pattern`, `anyOf`, `constant`, `range`, `minimum`/`maximum` and the array counts. **There is no string-length guide** [F21]. Control length through instructions and a `@Guide` description, then check the length in code.
- Schemas and guide descriptions cost tokens [F9, F15].

**Streaming: confirmed** [F6, W1, W3]

- `streamResponse(…)` returns a `ResponseStream` of `Snapshot`s. They are snapshots of `PartiallyGenerated`, a mirror of the type with every property optional, not token deltas.
- Apple suggests SwiftUI animations and content transitions to "hide latency" [W1, W3].

**Prewarm: confirmed** [F14, W3]

- `prewarm(promptPrefix:)` loads resources ahead of a request. Use it only when there is "a window of at least 1 second" before `respond`.
- It is not guaranteed, especially in the background or under load.
- Call it "just after the user gives a strong hint" that a request will follow [W3].

**Context window: confirmed, with a conflict**

- The documentation says 4,096 tokens per session, shared by instructions, prompts, schema and output [F5, F9]. An Apple panelist confirmed 4,096 for iOS 27 [W9].
- The WWDC26 "What's new" demo prints `contextSize` as `8192` [W5].
- So read `contextSize` and use `tokenCount(for:)` at runtime. Both were added in 26.4 and are back-deployed [F2, F3].
- Our request needs about 300 tokens, so the limit is irrelevant here. Exceeding it throws `LanguageModelError.contextSizeExceeded` [F7].

**Generation options: confirmed** [F8, W2, X1]

- `GenerationOptions(samplingMode:temperature:maximumResponseTokens:)`. The iOS 26 `sampling:` initializer and property are deprecated in favour of `samplingMode`.
- `.greedy` "always produces the same output for a given input" [F8], but only per model version [W2]. `.random(top:seed:)` and `.random(probabilityThreshold:seed:)` also exist.
- Use `maximumResponseTokens` only as a guard against runaway output. A hard cap can cut text mid-sentence: Apple's example is "A cat is a small." [F8, F9].

**Use cases and adapters: confirmed** [F3, X1]

- `SystemLanguageModel(useCase: .general | .contentTagging, guardrails:)`.
- Adapters are obsoleted in 27 (see the Summary).
- The new `variant` property reports `core3` or `coreAdvanced3` (AFM 3 Core / Core Advanced) [F22]. **Not documented:** which iPhones get which variant.

**Guardrails and errors: confirmed** [F7, F12, F20, X1]

- Guardrails check both the input and the output. `Guardrails.default` is the standard level. `.permissiveContentTransformations` applies to string output only and is not relevant here.
- Apple says 26.4 reduced false positives and 27 improves them further [F2, W5].
- `LanguageModelError` (27.0, non-exhaustive) has these cases: `contextSizeExceeded`, `rateLimited` (carries a `resetDate`), `refusal`, `timeout`, `guardrailViolation`, `unsupportedCapability`, `unsupportedTranscriptContent`, `unsupportedGenerationGuide`, `unsupportedLanguageOrLocale`.
- The iOS 26 `decodingFailure` case has **no documented** iOS 27 equivalent. Catch everything else generically.
- For a feature the user didn't explicitly ask for, Apple says a guardrail error "you can simply ignore" [W4]. That matches a silent template fallback.

**Languages: confirmed** [F11, D1]

- Use `supportsLocale(_:)`, which defaults to `Locale.current` and accounts for "app-specific settings" and language fallbacks. Prefer it over `supportedLanguages`.
- Apple Intelligence languages in iOS 27: English, Danish, Dutch, French, German, Italian, Norwegian, Portuguese, Spanish, Swedish, Turkish, Vietnamese, Chinese, Japanese and Korean [D1].
- Apple suggests stating the output language in the instructions: "You MUST respond in U.S. English." [F11].
- **Not documented:** whether `Locale.current` reflects the app's own localization when the device language is one the app doesn't ship. Our app is English-only.

## 2. Devices, simulator, testing seams, tooling

**Devices: confirmed** [D1]

- iPhone 15 Pro and 15 Pro Max, all iPhone 16 models and later, and iPhone Air, on iOS 27.
- Storage: up to 8 GB, or up to 14 GB on iPhone 17 Pro, 17 Pro Max and Air.
- Devices bought in China mainland don't get Apple Intelligence.
- Apple Watch features need a paired eligible iPhone [D1]. The on-device model API is iPhone-only for us anyway [X1].
- The framework "doesn't contribute [to] your app size" [W9].

**Simulator: confirmed for iOS 26, unverified for 27** [D2]

- The Simulator has no model of its own. It uses the Mac's model, so Apple Intelligence must be on in macOS System Settings. Apple DTS gave this answer for macOS Tahoe, Feb 2026.
- Forum users report iPhone simulators still saying "not enabled" on some Xcode 26.x builds. That is **unverified**; no fix from Apple appears in the thread.
- Profile on a real iPhone. A simulator on an M-series Mac "may yield faster results than an older iPhone" [W3].

**Forcing unavailability: confirmed** [W3, W8]

- The Xcode scheme setting is at Scheme > Run/Debug > Options. It was called "Foundation Models Availability" in 2025 and is "Simulate Apple Foundation Models Availability" in Xcode 27.
- It forces states such as Device Not Eligible regardless of the hardware. This is how to check every fallback in the simulator.

**Test seam: our design** (Apple only advises "a fallback experience" and separating "your model from your user experience" [F5, H1]):

- Put a protocol in front of the model. This is the main seam.
- The iOS 27 `LanguageModel` protocol could back a session with a fake model [F17]. But it is designed for model providers (an executor and a generation channel) and is far heavier than a one-method protocol. Not recommended.

**Tooling: confirmed** [F2, F15, F18, W1, W7]

- `#Playground` in Xcode iterates on prompts and shows token counts.
- Instruments has a Foundation Models template (Product > Profile). It shows the lanes Session, Request, Model Inference and Model Loading, plus time to first token and token metrics. Trace files store prompts and responses unencrypted.
- The new Evaluations framework (iOS 27 / Xcode 27) runs datasets through a feature and scores the responses.
- `logFeedbackAttachment(…)` produces Feedback Assistant reports.

## 3. Latency, performance and UI

- **Latency figures: not documented.** Apple says a response "may take a few seconds" [F5]. Every token of instructions and prompt "adds extra latency", and longer outputs take longer [W2]. Asking for "three sentences" or "a single sentence" speeds things up [F5, W4]. **Confirmed.**
- **Apple's UI guidance: confirmed** [H1, F14, W1, W3, W7]:
  - Design a loading experience, or generate in the background while the person does something else.
  - Prefer specific progress text over a vague "Processing…".
  - Stream, so partial results appear sooner.
  - Prewarm on a strong signal, at least 1 s ahead.
- **Background work: confirmed.** `rateLimited` arises from too many requests in a short window. Under iOS 26 it occurred only in the background [F7, F23]. An Apple panelist said background responses are the same but "might take a little longer" [W9]. The on-device model has no daily quota; quotas apply only to PCC [W8].
- **For us:** the rules finish instantly, so the Recommendation (Exercises, Workouts) is shown at once. Only the reason line waits for the model:
  1. Show a redacted placeholder line while the reason is generated.
  2. Prewarm when the builder screen appears. The user spends more than 1 s picking a Training Goal, Weekly Sessions and Equipment Access.
  3. Stream the single field in.
  4. After a time budget (our choice, about 4 s; Apple gives no figure), cancel and show the template.

## 4. Responsible use and disclosure

**HIG Generative AI (updated 2026-06-08): confirmed** [H1]

- Clearly identify when and where you use AI. Never imply that AI text was written by a human.
- Make sure the experience is still great without generative features, and when people opt out.
- Scope requests narrowly to limit hallucinations. Avoid asking for facts.
- Let people refine, revert or give feedback on outputs. Adapt this to our scale (§6).
- Factor processing time into the design.
- Separate the model from the UX so the model can be swapped later.

**Safety article: confirmed** [F12]

- Two built-in layers: a model trained for sensitive topics, and guardrails. Add app-specific layers on top.
- Prefer fixed inputs. Bounded input gives "the highest level of safety".
- An optional deny list checks both input and output.
- Do a risk assessment: feature, harm, severity, mitigation.
- Keep a prompt and safety test set, and re-run it on every model update.
- Give people a way to report harmful content.

**Acceptable Use Requirements: confirmed** [P1]

- 20 prohibited uses. Relevant to us:
  - No "inaccurate or dangerous outputs" in high-risk domains, including medical (item 12).
  - No circumventing guardrails (item 16).
  - No content that harms mental health through dependency (item 7).
- **No disclosure requirement** beyond not removing AI-content labels or watermarks (item 19).
- **No fitness-specific rule** is documented.
- **For us:** the instructions must forbid medical, injury, pain, nutrition and weight-loss claims. That also keeps the text clear of Guideline 1.4.1 (medical scrutiny) [A1].

## 5. App Store implications

| Area | Finding | Status |
|---|---|---|
| Review Guidelines (last updated 2026-06-08) [A1] | **No AI-specific rule applies.** 4.7 covers chatbots offered as software outside the binary; ours is a system API. 5.1.2(i) requires disclosure and consent for sharing personal data "with third-party AI"; nothing leaves the device here. 2.5.1: use APIs for their intended purpose and "indicate that integration" in the app description, so mention Apple Intelligence reasons in the description. 1.4.1: avoid health claims. | **confirmed** text; that 5.1.2(i) doesn't cover the on-device Apple model is our reading |
| Age rating questionnaire (2025+, required since 2026-01-31) [A2, A3] | Categories: In-App Controls, Capabilities, Mature Themes, Medical or Wellness, Sexuality or Nudity, Violence, Chance-Based Activities. **No question asks about AI, chatbots or generated content.** Apple: weigh "AI assistants and chatbot functionality" when judging how often sensitive content appears. **Health or Wellness Topics** ("exercise recommendations") is already the likely answer for the rule-based Recommendations and Step Up/Down (app-store-readiness.md: 9+). A short, guardrailed reason doesn't change any answer. | **confirmed** questionnaire; the "no change" conclusion is ours |
| Privacy nutrition label [A4] | Data "processed only on device is not 'collected'". Derived data sent off device "should be considered separately". **Keep the generated reason out of SwiftData sync and Supabase**: Recommendations aren't stored until added (CONTEXT.md), so the reason is ephemeral. No label change. | **confirmed** |
| PCC | Needs an application, a network connection and per-user quotas [W5, W8]. Not needed. | **confirmed** |

## 6. Recommendation for OnlyWorkout

**Architecture**

```
OnlyWorkoutCore (pure)                 OnlyWorkoutIntelligence (new, iOS only)       OnlyWorkout app target
RecommendationFacts  ─────────────▶    FoundationModelsReasonWriter: ReasonWriter    ReasonWriter protocol + ReasonProvider (@Observable)
ReasonCode[] (for templates)           (imports FoundationModels; @Generable type)   TemplateReasonWriter (Localizable.xcstrings)
```

- **Core** stays free of Apple frameworks and is test-first:
  - `RecommendationFacts` (Sendable, Equatable): Training Goal, Weekly Sessions, Equipment Access, the Focus of each Workout, the Muscle Groups covered, any Gap closed, the number of Exercises, and Catalog Exercise names.
  - `[ReasonCode]`: which rules fired, e.g. `.matchesTrainingGoal`, `.fitsWeeklySessions(n)`, `.closesGap(MuscleGroup)`.
  - Both come from the same rule run, so the template and the model describe the same decision.
- **`OnlyWorkoutIntelligence`** is a new package target, linked only by the iPhone app:
  - The Package declares `.watchOS(.v27)` and `.macOS(.v27)`, so wrap the target in `#if os(iOS) || os(macOS)` (`SystemLanguageModel` is unavailable on watchOS [X1]). macOS lets `swift test` run opt-in model tests on a Mac with Apple Intelligence.
  - It is the sole importer of `FoundationModels`, mirroring the "sole importer of supabase-swift" rule.
  - It contains:
    - `@Generable struct GeneratedReason { @Guide(description: "One or two short sentences") var text: String }`
    - the fixed instructions
    - a facts-to-prompt formatter
    - error mapping
- **`ReasonWriter`** lives in the app target, or in the new module if it is easier to test there:
  - Signature: `func reason(for facts: RecommendationFacts) -> AsyncThrowingStream<String, Error>`.
  - `ReasonProvider` decides, in order:
    1. the user setting
    2. `availability`
    3. `supportsLocale()`
    4. the model, under a time budget
  - On any `throw`, on cancellation, and when validation fails, it uses `TemplateReasonWriter`.
  - Previews and tests inject fakes.

**Model input**

- Short labelled lines built only from app-owned values, for example:
  - `Training Goal: Bigger Arms`
  - `Weekly Sessions: 3`
  - `Workouts: Push (chest, shoulders, triceps), Pull (…)`
  - `Closes Gap: rear delts`
- Leave out user-typed text: Workout names and Custom Exercise names. They are untrusted input [F12]. Never put any of it in the instructions.
- Never include Health data (AGENTS.md) or Strava Data. The Strava Policy bans AI use of Strava Data, including in context windows (strava-athlete-capacity.md §3).

**Instructions** (fixed and versioned in code as `reasonPromptVersion = 1`; not in the user-facing catalog):

- A role: "You write the one-line reason for a strength-training plan the app already chose."
- "Use only the facts given."
- "One or two sentences, under 40 words."
- "Do not mention injuries, pain, medical conditions, nutrition, weight loss or numbers not in the facts."
- "You MUST respond in U.S. English."
- Optionally, two or three short examples (Apple suggests 2–15 simple ones [F10]).
- Options: `GenerationOptions(samplingMode: .greedy, maximumResponseTokens: ~120)`. The token cap is a guard only; the instructions do the real length control.

**Output checks in code** (Apple's deny-list pattern [F12]):

- The text is non-empty and at most about 240 characters.
- It contains no digits beyond those in the facts.
- It contains no deny-listed terms ("injur", "pain", "doctor", "diet", "lose weight", …).
- Any failure means the template is used. This also catches hallucinated numbers.

**Disclosure and control (HIG [H1])**

- Mark model-written reasons with a small secondary label, e.g. a `sparkles` glyph plus "Written on device by Apple Intelligence". New `xcstrings` key; check the trademark wording with Apple's marketing guidelines (**not researched**).
- Add a Settings toggle, "Write reasons with Apple Intelligence", default on. Hide it when the device is not eligible.
- No feedback button is needed for a single-user app at first. Note this in the risk assessment.

**Fallback matrix:** use the template in every one of these cases, and never show an error alert. The reason is not something the user asked for [W4].

- unavailable: any reason, including `@unknown`
- the toggle is off
- `supportsLocale() == false`
- `LanguageModelError` (any case)
- `SystemLanguageModel.Error.assetsUnavailable`
- `LanguageModelSession.Error`
- the time budget runs out
- validation fails

**Tests**

- **Core** (Swift Testing, `tdd`):
  - The facts and reason codes for each rule.
  - Every `ReasonCode` has a template. A test in the app target walks all cases against `Localizable.xcstrings`.
- **`ReasonProvider`** against a fake writer and a fake availability source: available → model text; each unavailable reason → template; each error → template; timeout → template; over-long output, digits not in the facts, or a deny-listed term → template; toggle off → template.
- **Opt-in model tests** on a Mac or device, disabled when `SystemLanguageModel.default.isAvailable` is false, run on a fixed set of about 20 facts. Check length, English, banned terms, and that every Muscle Group mentioned appears in the facts. Optionally write this as an Evaluations-framework suite [F18]. Re-run on every OS model update [F2, F16].
- **Manual:**
  - The Xcode availability override, for each state [W3].
  - An Instruments trace on the oldest eligible iPhone (15 Pro) for time to first token.
  - Previews with fake writers for loading, model text and template.

**Risks**

| Risk | Mitigation |
|---|---|
| Text claims something the rules didn't decide | Facts-only prompt, greedy sampling, digit and term checks, short output |
| Guardrail false positive (e.g. "Push", "Pull", "explosive") | Silent fallback; rephrase the fixed instructions; Apple says 26.4/27 reduced false positives [F2] |
| A model update changes tone or quality | Versioned prompt, opt-in evaluation suite, re-run on each iOS x.y [F16] |
| Slow on older devices | Prewarm, streaming, a time budget, and the template as the safety net |
| Simulator gaps | Test real generation on a device; the simulator is only for the fallback paths |
| Only about half of users get the feature (eligible devices, Apple Intelligence on, outside China mainland) | Templates must read well on their own; they are the primary experience, the model is a bonus |

**Docs to touch when implementing:**

- README: the Recommendations section and §13 structure, for the new module.
- AGENTS.md: the module list, and the `swift-format` paths in AGENTS.md and CI.
- CONTEXT.md: Recommendation already says "always with its reason". Avoid "AI pick".
- An ADR only if the owner wants the "model writes reasons, never chooses" boundary recorded. It is cheap to reverse, so it is probably not needed.

---

## Sources

Apple documentation (developer.apple.com; read via the `tutorials/data/documentation/…json` endpoints on 2026-10-09):

- **F1** Foundation Models (overview, platforms incl. watchOS 27): <https://developer.apple.com/documentation/foundationmodels>
- **F2** Foundation Models updates (June 2026, March 2026, Feb 2026): <https://developer.apple.com/documentation/updates/foundationmodels>
- **F3** SystemLanguageModel (model versions, availability, contextSize, variant): <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel>
- **F4** Availability.UnavailableReason: <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason>
- **F5** Generating content and performing tasks with Foundation Models: <https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models>
- **F6** LanguageModelSession: <https://developer.apple.com/documentation/foundationmodels/languagemodelsession>
- **F7** LanguageModelError and its rateLimited case: <https://developer.apple.com/documentation/foundationmodels/languagemodelerror>
- **F8** GenerationOptions and SamplingMode.greedy: <https://developer.apple.com/documentation/foundationmodels/generationoptions>, <https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode-swift.struct/greedy>
- **F9** Managing the context window: <https://developer.apple.com/documentation/foundationmodels/managing-the-context-window>
- **F10** Prompting an on-device foundation model: <https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model>
- **F11** Supporting languages and locales with Foundation Models: <https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models>
- **F12** Improving the safety of generative model output: <https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output>
- **F13** Generating Swift data structures with guided generation: <https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation>
- **F14** prewarm(promptPrefix:): <https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm(promptprefix:)>
- **F15** Analyzing the runtime performance of your Foundation Models app: <https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app>
- **F16** Updating prompts for new model versions: <https://developer.apple.com/documentation/foundationmodels/updating-prompts-for-new-model-versions>
- **F17** LanguageModel protocol: <https://developer.apple.com/documentation/foundationmodels/languagemodel>
- **F18** Evaluations framework: <https://developer.apple.com/documentation/evaluations>
- **F19** LanguageModelSession.Error.concurrentRequests and isResponding: <https://developer.apple.com/documentation/foundationmodels/languagemodelsession/error/concurrentrequests>
- **F20** SystemLanguageModel.Error.assetsUnavailable: <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/error/assetsunavailable(_:)>
- **F21** GenerationGuide: <https://developer.apple.com/documentation/foundationmodels/generationguide>
- **F22** SystemLanguageModel.Variant: <https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/variant-swift.struct>
- **F23** GenerationError.rateLimited (iOS 26, deprecated): <https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited(_:)>
- **X1** Xcode 27.0 SDK interfaces, read locally: `iPhoneOS27.0.sdk/…/FoundationModels.swiftmodule/arm64e-apple-ios.swiftinterface` and the watchOS 27.0 one. They show `SystemLanguageModel` as `@available(watchOS, unavailable)`, `Adapter` as `deprecated: 26.4, obsoleted: 27.0`, a non-frozen `UnavailableReason`, and `sampling` alongside `samplingMode`.

WWDC sessions:

- **W1** WWDC25 286 Meet the Foundation Models framework: <https://developer.apple.com/videos/play/wwdc2025/286/>
- **W2** WWDC25 301 Deep dive into the Foundation Models framework: <https://developer.apple.com/videos/play/wwdc2025/301/>
- **W3** WWDC25 259 Code-along: Bring on-device AI to your app: <https://developer.apple.com/videos/play/wwdc2025/259/>
- **W4** WWDC25 248 Explore prompt design & safety for on-device foundation models: <https://developer.apple.com/videos/play/wwdc2025/248/>
- **W5** WWDC26 241 What's new in the Foundation Models framework: <https://developer.apple.com/videos/play/wwdc2026/241/>
- **W6** WWDC26 242 Build agentic app experiences with the Foundation Models framework: <https://developer.apple.com/videos/play/wwdc2026/242/>
- **W7** WWDC26 243 Debug and profile agentic app experiences with Instruments: <https://developer.apple.com/videos/play/wwdc2026/243/>
- **W8** WWDC26 319 Build with the new Apple Foundation Model on Private Cloud Compute: <https://developer.apple.com/videos/play/wwdc2026/319/>
- **W9** WWDC26 8121 Coding Intelligence, Machine Learning & AI Group Lab (panel answers): <https://developer.apple.com/videos/play/wwdc2026/8121/>

Design, policy and App Store:

- **H1** HIG: Generative AI (change log 2026-06-08): <https://developer.apple.com/design/human-interface-guidelines/generative-ai>
- **P1** Acceptable Use Requirements for the Foundation Models Framework: <https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/>
- **A1** App Review Guidelines (last updated 2026-06-08), 1.4.1, 2.3.6, 2.5.1, 4.7, 5.1.2(i): <https://developer.apple.com/app-store/review/guidelines/>
- **A2** Age ratings values and definitions: <https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions>
- **A3** "Updated age ratings in App Store Connect", 2025-07-24: <https://developer.apple.com/news/?id=ks775ehf>
- **A4** App privacy details on the App Store: <https://developer.apple.com/app-store/app-privacy-details/>
- **D1** Apple Support, "How to get the next generation of Apple Intelligence", published 2026-09-14: <https://support.apple.com/en-us/121115>
- **D2** Developer Forums thread 815397, answer by an Apple DTS Engineer (Feb 2026), plus user follow-ups (unverified): <https://developer.apple.com/forums/thread/815397>

[F1]: https://developer.apple.com/documentation/foundationmodels
[F2]: https://developer.apple.com/documentation/updates/foundationmodels
[F3]: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel
[F4]: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason
[F5]: https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models
[F6]: https://developer.apple.com/documentation/foundationmodels/languagemodelsession
[F7]: https://developer.apple.com/documentation/foundationmodels/languagemodelerror
[F8]: https://developer.apple.com/documentation/foundationmodels/generationoptions
[F9]: https://developer.apple.com/documentation/foundationmodels/managing-the-context-window
[F10]: https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model
[F11]: https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models
[F12]: https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output
[F13]: https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation
[F14]: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm(promptprefix:)
[F15]: https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app
[F16]: https://developer.apple.com/documentation/foundationmodels/updating-prompts-for-new-model-versions
[F17]: https://developer.apple.com/documentation/foundationmodels/languagemodel
[F18]: https://developer.apple.com/documentation/evaluations
[F19]: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/error/concurrentrequests
[F20]: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/error/assetsunavailable(_:)
[F21]: https://developer.apple.com/documentation/foundationmodels/generationguide
[F22]: https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/variant-swift.struct
[F23]: https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited(_:)
[W1]: https://developer.apple.com/videos/play/wwdc2025/286/
[W2]: https://developer.apple.com/videos/play/wwdc2025/301/
[W3]: https://developer.apple.com/videos/play/wwdc2025/259/
[W4]: https://developer.apple.com/videos/play/wwdc2025/248/
[W5]: https://developer.apple.com/videos/play/wwdc2026/241/
[W6]: https://developer.apple.com/videos/play/wwdc2026/242/
[W7]: https://developer.apple.com/videos/play/wwdc2026/243/
[W8]: https://developer.apple.com/videos/play/wwdc2026/319/
[W9]: https://developer.apple.com/videos/play/wwdc2026/8121/
[H1]: https://developer.apple.com/design/human-interface-guidelines/generative-ai
[P1]: https://developer.apple.com/apple-intelligence/acceptable-use-requirements-for-the-foundation-models-framework/
[A1]: https://developer.apple.com/app-store/review/guidelines/
[A2]: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions
[A3]: https://developer.apple.com/news/?id=ks775ehf
[A4]: https://developer.apple.com/app-store/app-privacy-details/
[D1]: https://support.apple.com/en-us/121115
[D2]: https://developer.apple.com/forums/thread/815397
