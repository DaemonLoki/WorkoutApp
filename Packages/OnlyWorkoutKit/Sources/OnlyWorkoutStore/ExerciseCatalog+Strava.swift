import OnlyWorkoutCore

extension ExerciseCatalog.Entry {
    /// The Strava exercise type a catalog Exercise is uploaded as (docs/research/strava-api.md).
    public var stravaExerciseType: String? {
        ExerciseCatalog.stravaExerciseTypes[key]
    }
}

extension ExerciseCatalog {
    static let stravaExerciseTypes: [String: String] = [
        "barbell-bench-press": "BARBELL_BENCH_PRESS",
        "incline-dumbbell-press": "INCLINE_DUMBBELL_BENCH_PRESS",
        "dumbbell-bench-press": "DUMBBELL_BENCH_PRESS",
        "machine-chest-press": "MACHINE_CHEST_PRESS",
        "cable-fly": "CABLE_CROSSOVER",
        "push-up": "PUSH_UP_GENERIC",
        "dip": "CHEST_DIP",
        "pull-up": "PULL_UP_GENERIC",
        "chin-up": "CLOSE_GRIP_CHIN_UP",
        "lat-pulldown": "LAT_PULLDOWN",
        "seated-cable-row": "SEATED_CABLE_ROW",
        "barbell-row": "BENT_OVER_BARBELL_ROW",
        "one-arm-dumbbell-row": "DUMBBELL_ROW",
        "chest-supported-row": "MACHINE_CHEST_SUPPORTED_ROW",
        "face-pull": "FACE_PULL",
        "deadlift": "BARBELL_DEADLIFT",
        "back-extension": "BACK_EXTENSION",
        "overhead-press": "OVERHEAD_BARBELL_PRESS",
        "seated-dumbbell-press": "SEATED_DUMBBELL_SHOULDER_PRESS",
        "lateral-raise": "LATERAL_RAISE_GENERIC",
        "rear-delt-fly": "MACHINE_REAR_DELT_REVERSE_FLY",
        "dumbbell-shrug": "DUMBBELL_SHRUG",
        "barbell-curl": "BARBELL_BICEPS_CURL",
        "dumbbell-curl": "STANDING_DUMBBELL_BICEPS_CURL",
        "hammer-curl": "DUMBBELL_HAMMER_CURL",
        "triceps-pushdown": "CABLE_TRICEPS_PUSHDOWN",
        "overhead-triceps-extension": "CABLE_OVERHEAD_TRICEPS_EXTENSION",
        "skull-crusher": "SKULL_CRUSHER",
        "back-squat": "BARBELL_BACK_SQUAT",
        "front-squat": "BARBELL_FRONT_SQUAT",
        "goblet-squat": "GOBLET_SQUAT",
        "leg-press": "MACHINE_LEG_PRESS",
        "romanian-deadlift": "BARBELL_ROMANIAN_DEADLIFT",
        "bulgarian-split-squat": "DUMBBELL_BULGARIAN_SPLIT_SQUATS",
        "walking-lunge": "DUMBBELL_WALKING_LUNGES",
        "leg-extension": "MACHINE_LEG_EXTENSION",
        "leg-curl": "LEG_CURL_GENERIC",
        "hip-thrust": "BARBELL_HIP_THRUST",
        "hip-adduction": "MACHINE_HIP_ADDUCTION",
        "standing-calf-raise": "STANDING_CALF_RAISE",
        "seated-calf-raise": "SEATED_CALF_RAISE",
        "hanging-leg-raise": "HANGING_LEG_RAISE",
        "cable-crunch": "CABLE_CRUNCH",
        "ab-wheel-rollout": "AB_WHEEL_ROLLOUT",
    ]
}
