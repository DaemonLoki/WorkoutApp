# App icon

Concepts for DaemonLoki/WorkoutApp#24, white glyphs on the app's orange (`AccentColor`, `#FF7A00`), 1024×1024:

| File | Idea |
|---|---|
| `concepts/a-plate-step-up.svg` | A weight plate with a Step Up chevron: the app's progression in one mark |
| `concepts/b-barbell.svg` | A barbell with two plates per side |
| `concepts/c-rising-plates.svg` | Three plates rising like a progress chart |
| `concepts/d-dumbbell.svg` | A diagonal dumbbell |

No Strava logo or name in the icon (Strava brand guidelines).

## From the chosen concept to the app

1. Split the chosen SVG into layers: the background (the orange) and the glyph (white shapes, transparent background), each 1024×1024.
2. Open **Icon Composer** (Xcode → Open Developer Tool → Icon Composer), drop the glyph in as a layer, and set the orange as the background fill. Check the Default, Dark, Tinted and Clear appearances and the round watchOS preview; adjust Liquid Glass and shadow per layer.
3. Save as `AppIcon.icon` into `OnlyWorkout/Resources/` and `OnlyWorkoutWatch/Resources/` (synchronized folders: the files join their targets), delete the empty `AppIcon.appiconset`s, and keep the build setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`.
