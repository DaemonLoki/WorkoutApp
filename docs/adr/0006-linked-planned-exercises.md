# Linked Planned Exercises share one Target

Planned Exercises are independent by default, so Squat 3×12 and Squat 5×5 progress separately. When the same Exercise is added to a second Workout, the app offers to link it to the existing one instead, because the owner usually trains an Exercise with one Target everywhere. Linked Planned Exercises share Target, Weight Step and Rest (every edit and every accepted Step Up/Down is written to all of them), and progression reads their combined history. Linking is a `linkID` shared by the group rather than a separate "shared Target" record, so each Planned Exercise stays a complete, self-contained row for sync and the web dashboard.

## Consequences

- Writes to a linked Planned Exercise must go through `TrainingLog` (it propagates to the group); setting fields directly would let the group drift apart.
- At most one pending suggestion exists per link group.
- Unlinking leaves each Planned Exercise with the current values, independent from then on.
