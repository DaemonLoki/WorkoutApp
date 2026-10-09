# OnlyWorkout

A personal strength-training tracker for iPhone and Apple Watch that plans gym visits, guides them set by set, and bakes progressive overload into every exercise.

## Language

### Planning

**Exercise**:
A single movement, such as Pull-up or Squat, tagged with the muscle groups it trains.
_Avoid_: Workout, movement, lift

**Exercise Catalog**:
The built-in list of common Exercises shipped with the app; any Exercise the user creates on top of it is a **Custom Exercise**.
_Avoid_: Library, database, presets

**Muscle Group**:
One entry from a fixed list of body regions (e.g. Chest, Lats, Front Delts, Quads) that an Exercise trains; an Exercise's Muscle Groups are its prime movers.
_Avoid_: Body part, muscle, Shoulders (now Front, Side and Rear Delts)

**Secondary Muscle Group**:
A Muscle Group an Exercise trains meaningfully as a helper but not as a prime mover (e.g. Triceps in Bench Press); it counts for less than a Muscle Group.
_Avoid_: Synergist, stabiliser, assisting muscle

**Emphasis**:
How strongly an Exercise, a Workout or a period of Sessions trains each Muscle Group relative to the others, derived from Sets and shown in three steps.
_Avoid_: Load, volume, intensity, focus

**Muscle Map**:
The drawn, gender-neutral figure (front and back) that shows Emphasis by highlighting Muscle Groups.
_Avoid_: Body map, heat map, muscle chart

**Focus**:
The optional kind of a Workout (Push, Pull, Legs, Upper Body, Lower Body, Full Body, Arms, Core), which says which Muscle Groups it should train.
_Avoid_: Goal, workout type, split, category

**Gap**:
A Muscle Group a Workout's Focus calls for that none of its Planned Exercises trains.
_Avoid_: Missing muscle, hole, imbalance

**Workout**:
A named, reusable plan (e.g. "Pull Day") made of an ordered list of Planned Exercises.
_Avoid_: Routine, template, program, day

**Planned Exercise**:
An Exercise placed in a specific Workout, carrying its own Target, Rest duration and Weight Step; the same Exercise in two Workouts is two Planned Exercises, independent unless linked.
_Avoid_: Workout exercise, slot, entry

**Linked Planned Exercises**:
Planned Exercises of the same Exercise in different Workouts that share one Target, Weight Step and Rest; any change to one (an edit, a Step Up, a Step Down) applies to all, and their Sessions count as one history for progression.
_Avoid_: Shared exercise, synced exercise, copy

**Rotation**:
The fixed order in which Workouts are cycled; the Workout after the most recently performed one is "next up", regardless of weekday.
_Avoid_: Schedule, split, calendar

**Superset**:
Two Planned Exercises within a Workout performed alternately (A1, B1, A2, B2, …) with Rest after each pair.
_Avoid_: Circuit, pairing, alternating exercises

**Target**:
The fixed number of Sets, the fixed number of reps per Set, and the current weight of a Planned Exercise.
_Avoid_: Goal (that word alone is never used; see Training Goal), rep range, prescription

**Each Side**:
How reps are counted for a one-sided Exercise (e.g. Split Squat): the Target's reps are done with each side.
_Avoid_: Per leg, per arm, unilateral reps

**Added Weight**:
For bodyweight Exercises (e.g. Pull-up), the weight recorded is only what is added on top of the body (belt, vest); 0 kg means bodyweight alone.
_Avoid_: Load, total weight

### Performing

**Session**:
One real-world performance of a Workout at the gym, from start to finish; a Session keeps its own copy of the names and Targets it was performed with, so later edits to the Workout never rewrite history.
_Avoid_: Workout, training, visit

**Next Up**:
The Workout the Rotation proposes for the next Session.
_Avoid_: Today's workout, scheduled workout

**Set**:
One working round of one Exercise within a Session, recorded as reps × weight; warm-up rounds are never Sets. A planned Set can be skipped (e.g. the machine is taken): it isn't performed and isn't owed again.
_Avoid_: Round, rep (a rep is a single repetition inside a Set)

**Rest**:
The timed pause after a Set (or after a Superset pair) before the next one starts.
_Avoid_: Break, pause

**Rest Timer**:
Whether a Session times Rest at all; it can be turned off per Workout and in Settings, and when off the next Set follows right away.
_Avoid_: Auto-rest, rest mode

### Progression

**Weight Step**:
The amount a Planned Exercise's weight changes by in one adjustment (e.g. 2.5 kg for a barbell, 1 kg for dumbbells).
_Avoid_: Increment, jump

**Target Hit**:
A Session in which every planned Set of a Planned Exercise reached at least the Target reps at the planned weight; extra reps and extra Sets still count, a changed weight does not.
_Avoid_: Success, completed, passed

**Step Up**:
The app's suggestion, after a Target Hit, to raise a Planned Exercise's Target by one Weight Step or by one rep per Set, whichever the user picks; if declined it is offered again after the next Target Hit.
_Avoid_: Raise, bump, progression, level up

**Step Down**:
The app's suggestion to lower a Planned Exercise's weight by one Weight Step (or, at 0 kg, its reps by one), either after a Stall or after a Layoff.
_Avoid_: Deload, reduce, regression

**Stall**:
Three consecutive Sessions of a Planned Exercise at the same Target that miss it without beating the previous Session's total reps.
_Avoid_: Plateau, failure

**Layoff**:
More than 21 days since a Planned Exercise was last performed.
_Avoid_: Break, gap, detraining

### Recommending

**Recommendation**:
An Exercise, Workout or Rotation the app proposes from a Focus or a Training Goal, always with its reason; nothing changes until the user adds it.
_Avoid_: Suggestion (reserved for Step Up and Step Down), AI pick, template

**Starter Rotation**:
A ready-made Rotation (Full Body; Upper Body and Lower Body; or Push, Pull and Legs) offered to a new user for one Equipment Access; once added, its Workouts are ordinary Workouts.
_Avoid_: Template, program, plan, split

**Blueprint**:
The ordered list of Needs that makes up a good Workout of one Focus, from which the app recommends Exercises.
_Avoid_: Template, slot list, program

**Need**:
One entry of a Blueprint, such as "a horizontal pull" or "Rear Delts", filled by one Exercise the user's Equipment Access allows.
_Avoid_: Slot, movement pattern, position

**Training Goal**:
What a person trains for (Overall Health, Bigger Arms, Athleticism, Running, Cycling), used only to shape a recommended Rotation.
_Avoid_: Goal, program, plan, objective

**Weekly Sessions**:
How many Sessions a week someone means to train, used only to shape a recommended Rotation; the app never tracks it.
_Avoid_: Frequency, schedule, training days

**Equipment Access**:
Which Equipment someone can train with (Full Gym, Dumbbells & Bench, Bodyweight Only), so Recommendations only use Exercises they can do.
_Avoid_: Gym profile, equipment filter, setup
