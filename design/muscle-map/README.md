# Muscle Map

The drawn, gender-neutral figure that shows which Muscle Groups an Exercise, a Workout or recent Sessions train (M7, README §7). **Status: concepts drafted, owner picks one** (DaemonLoki/WorkoutApp#39).

## Concepts

`generate.py` draws all four from one anatomy (front and back, 200 × 420 each, right half mirrored, one path per Muscle Group), so picking a concept picks a *rendering*, not new artwork. Each sheet shows Push, Pull and Leg Day in light and dark, plus the small sizes used in list rows (~44 pt) and cards (~100 pt).

| File | Concept | Strengths | Weaknesses |
|---|---|---|---|
| `concepts/a-mosaic.svg` | **A · Mosaic**: every muscle a solid tile, hairline gaps in the background colour, untrained muscles grey | Reads as anatomy at every size; untrained muscles stay visible, so Gaps are obvious (M8 needs that) | Busiest of the four |
| `concepts/b-silhouette.svg` | **B · Silhouette**: one soft, undivided body; only trained muscles appear | Calmest; focus pops out | Untrained muscles are invisible, so gaps are harder to see |
| `concepts/c-line-art.svg` | **C · Line art**: outline plus hairline muscle contours; trained muscles filled | Most "drawn human", elegant at large sizes | Hairlines vanish below ~80 pt; outlines fight the fills in dark mode |
| `concepts/d-capsules.svg` | **D · Capsules**: abstract rounded strokes, the icon's vocabulary | Most distinctive, fits the Step Up plate icon, legible on the Watch | Abstract: reads as a figure, less as muscles |

Regenerate after changing a shape: `python3 design/muscle-map/generate.py design/muscle-map/concepts`, then preview with `qlmanage -t -s 1240 -o /tmp design/muscle-map/concepts/*.svg`.

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

No flipping between front and back: both are always shown side by side, because hiding half the body hides half the answer.
