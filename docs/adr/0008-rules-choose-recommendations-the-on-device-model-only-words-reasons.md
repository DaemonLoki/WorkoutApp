# Rules choose every Recommendation; Apple's on-device model only words the reason

The Smart Workout Builder (M8) recommends Exercises, Workouts and Rotations. Which Exercises, Targets and Supersets it recommends is decided by deterministic rules in `OnlyWorkoutCore`, written test-first:

- **Blueprints per Focus.** Each Focus has an ordered list of Needs, and each Need lists candidate Exercises for every level of Equipment Access.
- **Coverage per Focus.** Each Focus defines which Muscle Groups it requires, which drives Gaps.
- **Targets.** A table sets the Target per Training Goal and Need role.
- **Splits.** A table maps Weekly Sessions to a Rotation.

The sources for all of this are in [docs/research/training-templates.md](../research/training-templates.md).

Every Recommendation carries a reason. The rules produce it as structured facts and reason codes. A handwritten String Catalog template always works. On iPhones with Apple Intelligence, Apple's on-device Foundation Models framework may instead word the same facts as one or two sentences, labelled as written by Apple Intelligence. This amends the README non-goal "AI coaching or generated text": generated text is now allowed for that one sentence, and nowhere else.

## Considered options

- **Rules only, handwritten reasons**: fully deterministic. The owner wanted reasons that read less like templates on devices that can do better.
- **The model picks Exercises (guided generation over the catalog), rules validate**: flexible, but untestable, non-deterministic across OS model updates (three versions in a year), unavailable on the Watch, and without Apple Intelligence on roughly half the devices. Nothing it would add can't be expressed as a Blueprint.

## Consequences

- **Never trusted, so never relied on.** Model output is never stored, synced or used for a decision. It is checked in code (length; no digits beyond the facts; no deny-listed terms like injuries or diets). Any failure, unavailability, refusal or timeout silently shows the template. The templates are the primary experience; tests never assert model text.
- **One importer.** A new iOS-only package module, `OnlyWorkoutIntelligence`, is the only importer of `FoundationModels`. That mirrors "`OnlyWorkoutSync` is the only importer of supabase-swift" and keeps Core free of Apple frameworks.
- **Clean input.** The model is given only app-owned values: Training Goal, Focus, Muscle Group and catalog Exercise names. It never sees Workout or Custom Exercise names (untrusted text), Health data or Strava Data (whose API terms forbid AI use).
- **Off switch.** Settings gets "Write reasons with Apple Intelligence" (on by default, hidden on ineligible devices), as the HIG asks: identify AI text and let people turn it off.
- **No claims.** Recommendations never make health claims. In particular they never say strength training prevents running injuries, because the evidence doesn't support it (training-templates.md §6).
