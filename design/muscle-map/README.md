# Muscle Map

The drawn, gender-neutral figure that shows which Muscle Groups an Exercise, a Workout or recent Sessions train (M7, README §7). **Status: chosen — E · Glass Mosaic** (the refinement of A · Mosaic; DaemonLoki/WorkoutApp#39).

## E · Glass Mosaic (chosen)

`concepts/e-glass-mosaic.svg`, drawn by `mosaic.py` (anatomy v2), shows Push and Pull Day as Workout-editor header cards, Exercise rows and a Next Up card, in light and dark.

- **The figure is made of its muscles.** Each Muscle Group is drawn as its natural heads (two pec plates, a three-row six-pack, two quad heads, two hamstring and calf heads, the three Delts, shoulder-blade plates for Upper Back), all lit together. Head, hands, knees, feet and the hip crease are quieter tiles, so the body is never drawn as an outline.
- **Tiles in the app's own materials.** Soft rounded pebbles with an even gap in the card colour (the icon's rounded vocabulary), a vertical gradient per tile, and a faint top sheen at full size, like Liquid Glass.
- **Orange as progress.** Three solid gradient steps of the accent (Most, Some, A little). Strong Emphasis also gets a soft orange glow, the same "progress moment" as the Step Up accept. Dark mode has its own steps; the faintest is a warm amber, not mud.
- **Sizes have different jobs.** Full maps (header, detail, Summary, Progress) show front and back, with sheen and glow. A compact row map (~50 pt) shows only the view that carries more Emphasis (Face Pull → back, Bench Press → front), without effects, because one larger figure reads better than two tiny ones. Gaps stay a fixed number of points at every size (1.6 full, 0.8 compact).
- `mosaic.py` becomes the source of the SwiftUI shapes in M7 (DaemonLoki/WorkoutApp#40).

Regenerate: `python3 design/muscle-map/mosaic.py design/muscle-map/concepts`.

## First concepts (A–D)

`generate.py` draws all four from one anatomy (front and back, 200 × 420 each, right half mirrored, one path per Muscle Group), so picking a concept picks a *rendering*, not new artwork. Each sheet shows Push, Pull and Leg Day in light and dark, plus the small sizes used in list rows (~44 pt) and cards (~100 pt).

| File | Concept | Strengths | Weaknesses |
|---|---|---|---|
| `concepts/a-mosaic.svg` | **A · Mosaic**: every muscle a solid tile, hairline gaps in the background colour, untrained muscles grey | Reads as anatomy at every size; untrained muscles stay visible, so Gaps are obvious (M8 needs that) | Busiest of the four |
| `concepts/b-silhouette.svg` | **B · Silhouette**: one soft, undivided body; only trained muscles appear | Calmest; focus pops out | Untrained muscles are invisible, so gaps are harder to see |
| `concepts/c-line-art.svg` | **C · Line art**: outline plus hairline muscle contours; trained muscles filled | Most "drawn human", elegant at large sizes | Hairlines vanish below ~80 pt; outlines fight the fills in dark mode |
| `concepts/d-capsules.svg` | **D · Capsules**: abstract rounded strokes, the icon's vocabulary | Most distinctive, fits the Step Up plate icon, legible on the Watch | Abstract: reads as a figure, less as muscles |

Regenerate A–D after changing a shape: `python3 design/muscle-map/generate.py design/muscle-map/concepts`, then preview with `qlmanage -t -s 1240 -o /tmp design/muscle-map/concepts/*.svg`.

## Encoding (applies to every concept)

- **Load per Muscle Group** = Σ Sets × (1.0 if primary, 0.5 if secondary), normalised to the largest group. A pure `MuscleLoad` function in `OnlyWorkoutCore` computes it (planned Sets for a Workout; logged non-extra and extra Sets for Sessions).
- **Three intensity steps** of the accent, plus none: ≥ 0.75 strong, ≥ 0.45 medium, > 0 light. Sequential, one hue: more load is more orange.
- **Solid colours per appearance, not opacity**, so gaps stay crisp. They are mixed from `AccentColor` over the neutral body and live in `DesignTokens`. Draft values, by OKLab lightness:

  | Step | Light (on `#E5E5EA`) | Dark (on `#2C2C2E`) |
  |---|---|---|
  | none | `#E5E5EA` L 0.92 | `#2C2C2E` L 0.29 |
  | light | `#ECC7A8` L 0.85 | `#704A29` L 0.44 |
  | medium | `#F5A55E` L 0.79 | `#AF6625` L 0.58 |
  | strong | `#FF7A00` L 0.72 | `#FF8A1F` L 0.75 |

  Both ramps are monotonic. In dark mode the strong step is also the brightest. The light ramp's steps are close (ΔL ≈ 0.07), so tune them on a device; a darker strong step in light mode is the likely fix.
- **Never colour alone**: every map has a text alternative ("Mostly Chest, Front Delts and Triceps"), and the large maps have a legend of the three steps. VoiceOver reads the text, not the drawing. Increase Contrast adds a 1 pt outline to trained muscles.
- **Orange stays meaningful**: no other orange element sits next to a map (README §9).

## Motion (from `apple-design` and `emil-design-eng`)

| Moment | Frequency | Treatment |
|---|---|---|
| Exercise added or removed in the Workout editor | often | Changed muscles cross-fade to their new step (`DesignTokens.Motion.valueChange`, ~200 ms ease-out). No movement, no haptic: it's feedback, not an event. |
| Map appears (Exercise detail, Summary) | per screen | No entrance animation; it's content. |
| Session Summary | once per Session | Trained muscles fill in step by step after the celebration, in the stagger rhythm (~60 ms). Reduce Motion: a single cross-fade. |
| Tap a muscle (large maps only) | rare | Selects it: a 1 pt outline plus its name and Sets in a caption. Tap again or elsewhere to clear. Responds on touch-down. |

No flipping between front and back: full maps always show both side by side, because hiding half the body hides half the answer. Compact maps show the one view that carries more Emphasis (see E).
