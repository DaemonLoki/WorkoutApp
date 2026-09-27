## How should it work?

- I want to be able to track my workouts in the most simple way
- I can configure my workouts with the following settings:
  - type of workout (e.g. pull-ups, squats, etc.)
  - number of current repetitions
  - current weight
- I can configure different workouts for different days
- When going to the gym I want to be able to start the workout and it will allow me to go through them one-by-one (maybe have the option to do 2 in an alternating way)
- I want to be able to use my Apple Watch for tracking and controlling the entire app (confirm that I finished a workout, have the complete information for the next workout)
- Progressive overload should be baked in
  - I want to see if I can reach e.g. 3 sets with 12 reps with the current weight
  - if I can, I want the app to ask me to increase the weight for future sessions
- I want to have clear statistics on all the workouts I've done with each exercise being shown, together with my progression over time (with neat filtering like time, etc.)
- It should have integration with:
  - Apple health: using workouts from there so it automatically syncs
  - Ideally have an integration with Strava so that it has the workouts + muscle groups configured there

## Technical details

- It should be a native iOS app
- I want the database to be accessible from other tech (e.g. a web app to see a dashboard there)
- It should work offline (syncing with the database should optionally happen at a later point)
- The app should work on the Apple Watch even when I don't have my phone with me
- Focus on a clean, minimal implementation that is perfect for this use-case and doesn't try to be more than needed

## Design

- Minimal, but functional
- Beautiful
- Enjoyable to use
- Motivational features
  - nice animations when done with a workout
  - give me motivational messages when there's progression
