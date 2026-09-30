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
One entry from a fixed list of body regions (e.g. Chest, Lats, Quads) that an Exercise trains.
_Avoid_: Body part, muscle

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
_Avoid_: Goal, rep range, prescription

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

### Progression

**Weight Step**:
The amount a Planned Exercise's weight changes by in one adjustment (e.g. 2.5 kg for a barbell, 1 kg for dumbbells).
_Avoid_: Increment, jump

**Target Hit**:
A Session in which every planned Set of a Planned Exercise reached at least the Target reps at the planned weight; extra reps and extra Sets still count, a changed weight does not.
_Avoid_: Success, completed, passed

**Step Up**:
The app's suggestion, after a Target Hit, to raise a Planned Exercise's weight by one Weight Step; if declined it is offered again after the next Target Hit.
_Avoid_: Raise, bump, progression, level up

**Step Down**:
The app's suggestion to lower a Planned Exercise's weight by one Weight Step, either after a Stall or after a Layoff.
_Avoid_: Deload, reduce, regression

**Stall**:
Three consecutive Sessions of a Planned Exercise at the same weight that miss the Target without beating the previous Session's total reps.
_Avoid_: Plateau, failure

**Layoff**:
More than 21 days since a Planned Exercise was last performed.
_Avoid_: Break, gap, detraining
