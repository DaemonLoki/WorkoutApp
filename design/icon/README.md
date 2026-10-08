# App icon

**Chosen: A, the Step Up plate** (DaemonLoki/WorkoutApp#24): a weight plate with a Step Up chevron, white on the app's orange (`AccentColor`, `#FF7A00`). It names the app's one big idea, progression, and the ring sits concentric with the Watch's round mask.

The app uses `AppIcon.icon` (Icon Composer's format) in `OnlyWorkout/Resources/` and `OnlyWorkoutWatch/Resources/`; the build setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` picks it up. Both copies must stay identical.

| File | What |
|---|---|
| `a-step-up-plate/plate.svg` | Layer: the ring (r 304, stroke 104), transparent background |
| `a-step-up-plate/chevron.svg` | Layer: the chevron (stroke 96, round caps), a little above centre so it looks centred |
| `a-step-up-plate/background.svg` | The orange as a flat file, for places that need one image (web, App Store Connect previews) |
| `a-step-up-plate/preview.svg` | All three combined |
| `concepts/` | The four concepts the icon was chosen from |

In `AppIcon.icon/icon.json` the background is an automatic gradient of the accent orange, and the chevron and plate are separate groups, so Liquid Glass gives them depth; both have a neutral shadow and 40 % translucency.

## Changing it

Open `OnlyWorkout/Resources/AppIcon.icon` in **Icon Composer** (Xcode → Open Developer Tool → Icon Composer). Check the Default, Dark, Tinted and Clear appearances and the round watchOS preview, adjust glass, shadow or translucency per group, save, and copy the result over `OnlyWorkoutWatch/Resources/AppIcon.icon`. Update the SVGs here if a layer's shape changes. No Strava logo or name in the icon (Strava brand guidelines).
