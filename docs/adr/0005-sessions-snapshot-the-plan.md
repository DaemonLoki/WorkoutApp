# Sessions snapshot the plan instead of referencing it

A Session and its Session Exercises copy the Workout name, Exercise name and Target (sets, reps, weight) at the moment they are performed, and keep the plan ids only as optional back-references. Editing or deleting a Workout, Planned Exercise or Exercise therefore never rewrites history, and statistics and the future web dashboard can read a Session without joining against a plan that may have changed. The cost is some duplicated data, which is negligible for a single user.
