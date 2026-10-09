# A 3D Muscle Map with RealityKit

Researched 2026-10-09. The question: can the Muscle Map be a 3D, gender-neutral figure rendered with RealityKit, with Muscle Groups lit in the orange Emphasis steps? And could that figure one day perform the Exercises? This builds on the 2D plan in README §7, §9 and §16 M7 and on [design/muscle-map/](../../design/muscle-map/README.md), which are not repeated here. Sources are listed at the end, and each `[S…]` / `[U…]` label links to its URL or SDK path. Each claim carries one of three labels: **confirmed** (developer.apple.com docs, the Xcode 27.0 SDK interfaces in `/Applications/Xcode-27.0.0.app`, WWDC session pages, Apple Developer Forums replies by Apple staff, official licence texts), **unverified** (secondary sources: third-party skills, blogs, App Store listings, forum posts by non-staff, my own estimates), or **not documented**.

## Summary and verdict

**Possible on iPhone, impossible on the Watch, and not wise as a replacement for the 2D map.**

1. **iPhone: technically possible with system frameworks.** iOS 27 has everything needed: `RealityView` with a `.virtual` camera, `realityViewCameraControls(.orbit)`, per-entity material swaps, taps on entities, skeletal animation and `AccessibilityComponent` (**confirmed** [S1, S2, S5–S10]). It adds no third-party code dependency. It does add a third-party *asset*, and that needs the owner's approval and a licence check (§4).
2. **Watch: no RealityKit at all.** The watchOS 27 SDK has no `RealityKit.framework`, and every `RealityView` API is marked `@available(watchOS, unavailable)`. The only 3D framework left on watchOS is SceneKit, which Apple has deprecated (**confirmed** [S1, S4, S12]). So the Watch, and every widget and complication, needs the 2D map anyway.
3. **The 2D map can't go away.** Compact rows (~44 pt), the Next Up card and the Watch need 2D Shapes for legibility, cost and accessibility (§3, §6). A 3D figure can only ever *add* a hero view.
4. **The 3D figure clashes with two design rules.** First, the Muscle Map rule says "never a flip: hiding half the body hides half the answer" (README §9), but a 3D figure shows one side at a time unless two figures are rendered. Second, lit 3D shading turns the three solid colour steps into gradients, so "light/medium/strong" gets harder to read. The fix is unlit materials, which in turn look flat (§6).
5. **Animated Exercises are a separate, large project.** 93 Exercises × one clip each, mostly with equipment props (barbell, bench, cable). Mixamo has few gym lifts, and its licence forbids shipping the raw files (**unverified** [U2, U3]). The effort is realistically 200–750 hours of animation work, plus 10–25 MB of app size (estimate, §5). A wrong demonstration of form is also a real risk in a fitness app.

**Recommendation:** ship M7 as planned (option **a**, 2D everywhere) and keep the door open for option **b** (hybrid) at no cost now:

- Use the 18 `MuscleGroup` rawValues as the canonical region IDs everywhere, including SVG path IDs in `generate.py`. They would later name the mesh parts.
- Keep Emphasis and selection in Core and in a view-agnostic `MuscleMap` API, which nothing renders into yet.

Revisit 3D only after a 1–2 day spike (§7.3) proves three things: the colour steps stay legible, no camera prompt appears, and the asset licence is clean. Option **c** (author the anatomy in 3D, project it to the 2D paths) is worth doing only if the owner later wants a 3D hero, because it keeps both renderings consistent.

---

## 1. RealityKit in a SwiftUI iPhone app

**`RealityView` on iOS: confirmed** [S1, S5]. It has been available since iOS 18, and its `make` closure is `async`. While content loads it shows a placeholder, which can be customised. It "does not size itself based on the RealityKit content" [S5]. On iOS the closure receives `RealityViewCameraContent`, which has `camera`, `cameraTarget`, `environment` and `renderingEffects`. Since iOS 26 it also has `animate(body:completion:)` [S1].

**Camera: confirmed** [S1, S6]. `RealityViewCamera` has exactly two values on iOS 27: `.virtual` ("displays virtual RealityKit content") and `.spatialTracking` ("virtual RealityKit content and camera passthrough"). WWDC24's sample code still used `.worldTracking` [S13]; the iOS 27 SDK no longer has that name.

- **Which camera is the default on iOS: not documented** [S6]. The reference skill says the AR camera is the default and that a camera permission is needed (**unverified** [U1]). The WWDC24 sample, by contrast, sets world tracking explicitly [S13].
- Either way, OnlyWorkout would set `content.camera = .virtual`. The spike must confirm that no camera prompt ever appears (§7.3). A camera prompt for a muscle picture would also violate the "ask only in context" rules in [onboarding-and-permissions.md](onboarding-and-permissions.md).

**Camera controls: confirmed** [S1, S7]. `.realityViewCameraControls(_:)` takes `.none`, `.tilt`, `.pan`, `.orbit` or `.dolly`. Apple: "use a drag gesture … with iOS and iPadOS devices to … orbit … a virtual camera" [S7]. It has been available since iOS 18 and is unavailable on watchOS and tvOS.

- A forum post reports wrong orbit targets if `cameraTarget` changes mid-orbit (**unverified** [U4]).
- `ManipulationComponent` (grab and rotate an entity) is visionOS-only (**confirmed** [S2]).
- `Model3D`, the simple SwiftUI view for showing a USDZ, is **unavailable on iOS**: `@available(iOS, unavailable)` [S1]. An Apple engineer suggests filing feedback for it [S18]. So iOS needs a `RealityView` even for a static model.

**Lighting: confirmed** [S1, S2, S13].

- `ImageBasedLightComponent` plus `ImageBasedLightReceiverComponent` (iOS 18) provide image-based lighting.
- `DirectionalLight`, `PointLight` and `SpotLight` have been available since iOS 13. Spot and directional lights cast shadows [S13].
- On iOS, `RealityViewCameraContent.environment` offers only `.default` and `.skybox(_:)` [S1].
- The reference skill's `content.environment.lighting.resource = …` does not exist in the iOS 27 SDK interface (**confirmed** absent [S1]; the skill is mostly about AR [U1]).

**Materials: confirmed** [S2, S9].

- Available materials: `UnlitMaterial` (iOS 13), `PhysicallyBasedMaterial` (iOS 15), `SimpleMaterial`, and `ShaderGraphMaterial` (iOS 18), which is loaded from a Reality Composer Pro package or MaterialX.
- A `ShaderGraphMaterial` has named parameters that can be changed at runtime with `setParameter(name:value:)` [S9].
- Runtime highlighting works by reassigning `ModelComponent.materials`: one material per submesh, i.e. per material index [S2, S9]. For example, `entity.findEntity(named: "frontDelts")` finds the part, and its materials are then replaced with the "strong" step [S2].

**Loading: confirmed** [S2, S5].

- `ModelEntity(named:in:)` and `Entity(named:in:)` are `async throws` and load a USDZ or a Reality Composer Pro package from a bundle.
- `findEntity(named:)` looks entities up by name.
- Apple's tip: "Load your content asynchronously to avoid introducing a hang" [S5].

**Taps on entities: confirmed** [S1, S2, S18].

- `TapGesture().targetedToAnyEntity()` (iOS 18) and `targetedToEntity(where:)` handle taps. The tapped entity needs both `InputTargetComponent` and `CollisionComponent` [S18].
- `GestureComponent(_:)` attaches a SwiftUI gesture to an entity (iOS 26).
- `RealityViewCameraContent.hitTest(point:in:query:mask:)` hit-tests manually.
- This would implement README §9's "tap a region on a full map".

**Animation: confirmed** [S2, S10].

- `availableAnimations` lists the clips imported from a file, and `playAnimation(_:transitionDuration:startsPaused:)` plays one [S10].
- For skeletal work there are `SkeletalPosesComponent`, `IKComponent` and `AnimationLibraryComponent` (all iOS 18), plus `FromToByAnimation`, `AnimationGroup` and `BlendTreeAnimation` [S2].
- WWDC26 adds mesh level of detail and "high quality character rendering", but nothing new for skeletal animation [S15].

**Snapshots for list rows: confirmed that it is possible, but only with Metal plumbing.**

- `ImageRenderer` only rasterises views SwiftUI draws itself. Anything composited by Core Animation layers comes out as a placeholder [S11], and a `RealityView` is such a view (inference, **unverified**).
- `RealityRenderer` (iOS 18) renders a RealityKit scene "in an existing Metal workflow" [S8]. Its `CameraOutput.Descriptor.singleProjection(colorTexture:)` takes an `MTLTexture` [S2]. A row thumbnail would therefore need its own off-screen Metal texture, a GPU→CPU read-back and a cache keyed by Emphasis.
- `ARView.snapshot(saveToHDR:completion:)` exists only on the UIKit `ARView` [S3], and the app is SwiftUI-only.

**Accessibility: confirmed** [S2, S3].

- `AccessibilityComponent` (iOS 17) offers `label`, `value`, `traits` (iOS), `customContent`, `systemActions` and `customActions`.
- **Not documented:** whether VoiceOver reliably navigates entities inside a `RealityView` on iOS. The safe plan is the one in README §9: the whole view is one accessibility element whose label is the text summary.
- Reduce Motion has no RealityKit-specific handling (**not documented**). The app must read `accessibilityReduceMotion` itself and skip auto-rotation, fill-in and Exercise animations. The HIG warns against rotating content and sustained oscillation (written for visionOS) [S20].

## 2. watchOS

**No RealityKit on watchOS 27: confirmed** [S1, S4].

- `Platforms/WatchOS.platform/…/WatchOS.sdk/System/Library/Frameworks` contains no `RealityKit.framework` and no `RealityFoundation.framework`.
- In the iOS interface, `RealityView`, `RealityViewCameraContent`, the camera controls and the entity gestures are all marked `@available(watchOS, unavailable)` [S1].
- SceneKit is present on watchOS, but "SceneKit is deprecated, use RealityKit instead" (deprecated in all 26.0 SDKs) [S12, S14].
- **Consequence:** the Watch, the Live Activity and the widgets keep the 2D `Shape` map. A 3D figure on iPhone means two renderings to keep visually consistent (see option c).

## 3. Performance, size and launch cost

- **Many `RealityView`s in a `List`: not documented.** There is no Apple guidance on it, and I found no forum thread about it. Each `RealityView` hosts its own RealityKit scene and Metal-backed layer (inference from [S5, S8], **unverified**). Thirty Exercise rows would mean thirty scenes being created and torn down while scrolling, each loading the figure asynchronously behind a placeholder. That is the wrong tool for a 44 pt glyph, which 2D `Shape`s draw for almost nothing.
- **One hero `RealityView`** (Exercise detail, Session Summary) is the normal use and fine. WWDC26 adds mesh level of detail and points to RealityKit Trace in Instruments for profiling [S15].
- **USDZ is stored uncompressed:** "a zero compression, unencrypted zip archive" [S22]. The App Store compresses the download, but the installed size counts the full file.
- **Figure size (estimate, unverified):**
  - A low-poly, rigged, untextured human (≈ 5–15 k triangles, ~50–65 joints, 19 flat material slots) is about 1–3 MB as USDZ.
  - The current 2D anatomy is a few kilobytes of path data.
  - Textures (normal or ambient-occlusion maps) add 1–5 MB each at 2048².
- **Launch cost:** none if the figure is loaded lazily inside the detail or Summary screen; RealityKit only starts with the first `RealityView`. The Session Summary needs care, though: its map fills in right after the celebration (README §9), so the entity must be preloaded during the Session, or there will be a placeholder frame (**unverified**, spike).

## 4. Where the figure would come from, and licences

**Apple: no human asset found.**

- Apple's RealityKit samples ship robots and props (BOT-anist, and the motion-capture robot in "Capturing body motion in 3D" [S26]). I found no gender-neutral human in Apple's sample code (**not documented**).
- The licence of each sample's assets is set by that sample's own licence file (**unverified** [U9]).
- Reality Composer Pro 3 is a separate download, still labelled beta, and it mentions "generative intelligence to help with asset creation" [S16]. An Apple engineer: "Use of generated assets is covered by the Reality Composer Pro software license agreement … make your own determination about IP rights" [S17].
- The terms of the RCP content library for shipping apps are **not documented** on any page I could reach. Read the RCP licence before using either the content library or generated assets.

**Mixamo (Adobe): unverified** [U2, U3].

- Adobe's help page says its characters and animations are royalty-free for personal and commercial projects, "including … creating video games" [U2].
- The older staff FAQ says "the only thing you can't do is distribute the raw character and animation files" [U3].
- The licence question is whether a USDZ inside an app bundle counts as "raw files" (anyone can extract it from the `.ipa`). The common reading is no, because the file is part of a product, but Adobe's terms don't say so explicitly. Get that in writing, or avoid Mixamo files as shipped assets.
- Mixamo's characters are stylised, not anatomical, and have no muscle regions.

**MakeHuman / MPFB (Blender add-on): confirmed CC0** [S23].

- The bundled assets ("base mesh and proxies … targets … poses") are CC0 1.0.
- The project "makes no claim whatsoever over output", including exports through the Blender importer [S23]. This is the cleanest licence for a neutral base body.
- It is a skin mesh with a skeleton, so the 18 regions still have to be painted onto it by hand.

**BodyParts3D / Z-Anatomy: confirmed CC BY-SA** [S24, S25].

- Z-Anatomy is CC BY-SA 4.0 and derives from BodyParts3D (CC BY-SA 2.1 Japan) [S25].
- Share-alike: a modified mesh must be shared under BY-SA too [S24 §3(b)].
- The "no downstream restrictions" clause forbids applying "Effective Technological Measures … if doing so restricts exercise of the Licensed Rights" [S24 §2(a)(5)]. App Store FairPlay encryption sits uneasily with that clause (**unverified**; get a legal opinion).
- The meshes are hundreds of individual anatomical muscles, not 18 stylised regions, and they aren't rigged.
- Verdict: avoid this source.

**Commissioning an artist** (Blender, a MakeHuman base or from scratch) gives a work-for-hire licence and exactly the style wanted: flat, friendly, gender-neutral, and matching the icon's rounded vocabulary. The cost is **unverified**; get a quote.

**Authoring the regions (either works in RealityKit, confirmed [S2, S9]):**

| Approach | How | Pros | Cons |
|---|---|---|---|
| **Material slots / submeshes** | Split the skinned mesh into 19 parts (18 regions + neutral body), each named with the `MuscleGroup` rawValue (`chest`, `frontDelts`, … `calves`); swap `ModelComponent.materials` per Emphasis step | Plain Swift, no shader; tap targets come for free (each part gets a collision shape) | Hard seams between regions; 19 draw calls (trivial) |
| **Region-ID mask + ShaderGraph** | One mesh; vertex colour or a 1-channel ID texture encodes the region; a Reality Composer Pro ShaderGraph looks up 18 step parameters | One draw call; soft or outlined borders; the cross-fade can animate parameters | Needs Reality Composer Pro and a shader; tapping needs hit-test → UV → region lookup |

Either way, the 18 rawValues are the contract between data and artwork. That costs nothing to adopt now.

## 5. Animating the Exercises (future)

What it takes (estimates **unverified** unless cited):

- **One clip per Exercise:** 93 in the planned catalog (README §17). Most need **props and contact**: a barbell in both hands, a bench, a cable handle, a pull-up bar. That means IK or careful keyframing, not just a body clip.
- **Sources:**
  1. Stock mocap packs (e.g. a 134-clip calisthenics pack on Fab, retargetable to Mixamo-style rigs [U8]). Bodyweight moves are easy to find; barbell and cable lifts are rare.
  2. Mixamo. I found only scattered fitness clips such as "Air Squat" (**unverified**), and the licence caveat from §4 applies.
  3. Self-capture. ARKit body tracking drives a rigged character from the rear camera, on A12 and later [S26]. Quality is fine for a prototype but not for showing correct form.
  4. A commissioned animator.
- **Retargeting** happens in the authoring tool (Mixamo, Blender), not at runtime. RealityKit plays clips that already fit the skeleton (`availableAnimations` [S10]). It can blend between them (`BlendTreeAnimation`) and correct poses with IK (`IKComponent`) [S2].
- **Reality Composer Pro** can edit animation and timelines [S16], but it is no motion-capture tool.
- **Size:** a 3 s loop, ~55 joints, 30 fps comes to ≈ 50–250 KB per clip, so ≈ 5–25 MB for 93 clips (estimate). On-demand download would keep the app small but needs a hosting decision.
- **Effort:** sourcing or retargeting and cleaning up a stock clip takes ≈ 2–4 h; a custom keyframed clip with props takes ≈ 4–8 h. That is **≈ 200–750 h** for the catalog, plus design and QA of every clip's form. Custom Exercises would never get a clip.
- **Risk:** a demonstration of wrong form is worse than none. Every clip needs review by someone qualified.
- **Other apps (unverified):**
  - Muscle & Motion sells "3D animations" of 1,200+ Exercises as its core product [U7].
  - Fitbod's recovery view lets people "swipe … to rotate the avatar and view the front or back" [U5]; it isn't clear whether this is true 3D.
  - Hevy uses a 2D body chart of Sets per Muscle Group [U6].
  - The pattern: trackers use 2D maps; 3D animation is a product of its own.

## 6. Design fit

- **HIG:** I found no HIG guidance on non-AR 3D content in iOS apps (**not documented**). The AR page only says to avoid offering AR features on unsupported devices [S21].
- **Liquid Glass belongs to the navigation layer:** "Don't use Liquid Glass in the content layer" [S19]. A `RealityView` is content, so the two don't conflict. Glass bars refract the figure as they would any content.
- **Front and back at once:** README §9 forbids flipping. A 3D hero would need either two figures, front and back side by side (two entities in one scene, same camera, cheap), or orbit as an *extra* on top of a default two-figure view. An orbit-only figure reintroduces the "hidden half" problem.
- **Colour steps:**
  - The steps are solid colours per appearance with defined lightness (design README). Lit PBR materials vary in brightness across the curved surface, so a "strong" deltoid in shadow can read as "medium".
  - Options: use `UnlitMaterial` for regions with baked ambient occlusion or an outline for form, or keep lighting very flat. Either way, the spike must compare legibility with the 2D Mosaic.
- **At 44 pt:** a 3D figure has fewer pixels per muscle than the 2D Mosaic, because perspective, shading and silhouette eat contrast. A Push and a Pull Workout are "told apart at a glance" (M7 Done-when) more easily in flat 2D. **Unverified** (design judgement).
- **Motion:** auto-rotation or idle animation counts as "motion for the sake of motion" [S20]. Keep the figure still unless the user drags it, and under Reduce Motion skip the fill-in and any Exercise clip.

## 7. Options and recommendation

### 7.1 Options

| Option | What | Effort (estimate) | Risks | Approvals |
|---|---|---|---|---|
| **a. 2D everywhere** (current M7) | `Shape`s from `generate.py` on iPhone, Watch, widgets | as planned | none new | none |
| **b. Hybrid** | 2D in rows, cards, Next Up, Progress, Watch; one interactive 3D figure (front + back, orbit, tap to select) in the Exercise detail and the Session Summary hero | asset: 4–8 days self-made (MakeHuman + Blender) or a commission; code: 4–6 days (RealityView, materials from `DesignTokens`, selection, accessibility, preload, Reduce Motion); two renderings to keep in step | colour-step legibility; a camera-prompt surprise; asset licence; Summary placeholder flash; ~1–3 MB | owner: the asset and its licence (CC0 MakeHuman, or work-for-hire); no code dependency |
| **c. 3D source → 2D projection** | The figure is authored once in Blender; an orthographic front and back render of each named region is vectorised into the paths `generate.py` emits; runtime stays 2D (plus b's hero, optionally) | +3–5 days on top of the asset | vectorised paths need cleanup to stay small and smooth at 44 pt | same as b |
| **d. Full 3D** | 3D everywhere on iPhone | large | impossible on Watch and widgets; one scene per row; rows less legible | — (rejected) |
| **Animated Exercises** | One clip per Exercise in the detail | 200–750 h + review | wrong form; 5–25 MB; Custom Exercises without clips; licence of mocap sources | owner + legal review of every source |

### 7.2 What M7 should do now (no extra cost)

1. **The rawValues are the region IDs.** In `generate.py` and the emitted Swift, key every path by the `MuscleGroup` rawValue (`frontDelts`, not "front_delts" or "shoulder-front"). A later mesh uses the same names for its parts, so `findEntity(named: group.rawValue)` works without a mapping table.
2. **Keep the `MuscleMap` API renderer-agnostic.** Its input is `[MuscleGroup: EmphasisStep]` plus the selection, and the colours come from `DesignTokens`. A future `MuscleFigure3D` then takes the same input and the same text summary. The data model and sync stay untouched; 3D is purely a view.
3. **Keep the colour steps as tokens with explicit sRGB values.** `UnlitMaterial(color:)` could use them as they are.
4. **Don't add 3D to M7.** Note "3D hero (option b)" as a post-1.2 idea; this document is its research.

### 7.3 Spike (1–2 days, throwaway branch, not merged)

Goal: decide b or c with evidence. Steps:

1. **Asset (½ day).** MakeHuman → MPFB in Blender: a neutral body, a low-poly proxy, the default skeleton. Paint 18 regions as material slots named with the rawValues, plus `body`. Export USDZ and note its size.
2. **View (½ day).** One `RealityView` with `content.camera = .virtual`, two instances of the figure side by side (front and back), `.realityViewCameraControls(.orbit)` and one `DirectionalLight` plus IBL. Push Day Emphasis comes from `SampleData`, with the steps applied as `UnlitMaterial` and then as `PhysicallyBasedMaterial` for comparison. A `TapGesture().targetedToAnyEntity()` selects a region (`InputTargetComponent` + `CollisionComponent`), and the view is one accessibility element carrying the summary.
3. **Measure (½ day)** on an iPhone 18 Pro device, light and dark:
   - Does any camera permission prompt appear? It must not.
   - Time to first frame in the detail; memory (RealityKit Trace).
   - Can the three steps be told apart at 120 pt and 240 pt, in both materials? Compare side by side with the 2D Mosaic.
   - Is the Push vs Pull distinction as clear as in 2D?
   - Does a `List` with 10 tiny `RealityView`s scroll smoothly? This is meant only to confirm option d is a bad idea.
4. **Optional (½ day):** for option c, an orthographic render of region masks, vectorised into one region's path, to check smoothness at 44 pt.
5. **Exit criteria:**
   - Go for b: the steps are legible, there is no prompt, first frame < 300 ms, and the asset licence is clean.
   - Go for c: the 3D figure looks better than the hand-drawn anatomy.
   - Otherwise stay with a.

---

## Sources

Primary, Apple SDK (Xcode 27.0, `/Applications/Xcode-27.0.0.app/Contents/Developer/Platforms/…`):

- **S1** `iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/_RealityKit_SwiftUI.framework/Modules/_RealityKit_SwiftUI.swiftmodule/arm64e-apple-ios.swiftinterface`. `RealityView` (l. 386), `RealityViewCameraContent` (l. 555), `RealityViewCamera` `.virtual`/`.spatialTracking` (l. 618–633), `RealityViewEnvironment` (l. 637), `realityViewCameraControls` (l. 602), `Model3D` iOS-unavailable (l. 720–728), `targetedToAnyEntity` (l. 807), `hitTest` (l. 307).
- **S2** `…/RealityFoundation.framework/Modules/RealityFoundation.swiftmodule/arm64e-apple-ios.swiftinterface`. `RealityRenderer` + `CameraOutput` (l. 2021), `CameraControls` (l. 13019), `AccessibilityComponent` (l. 13508), `ShaderGraphMaterial.setParameter` (l. 15004), `SkeletalPosesComponent`, `IKComponent`, `AnimationLibraryComponent`, `BlendTreeAnimation`, `ImageBasedLightComponent`, `ManipulationComponent` (iOS-unavailable), `GestureComponent`, `findEntity(named:)`, `playAnimation`.
- **S3** `…/RealityKit.framework/Modules/RealityKit.swiftmodule/arm64e-apple-ios.swiftinterface`. `ARView.snapshot` (l. 319), `AccessibilityComponent.traits` (iOS).
- **S4** `WatchOS.platform/Developer/SDKs/WatchOS.sdk/System/Library/Frameworks`: no RealityKit or RealityFoundation; SceneKit present.

Primary, Apple documentation, sessions and forums:

- **S5** RealityView: <https://developer.apple.com/documentation/realitykit/realityview>
- **S6** RealityViewCamera: <https://developer.apple.com/documentation/realitykit/realityviewcamera>
- **S7** realityViewCameraControls(_:): <https://developer.apple.com/documentation/swiftui/view/realityviewcameracontrols(_:)>
- **S8** RealityRenderer: <https://developer.apple.com/documentation/realitykit/realityrenderer>
- **S9** ShaderGraphMaterial: <https://developer.apple.com/documentation/realitykit/shadergraphmaterial>
- **S10** Entity.availableAnimations: <https://developer.apple.com/documentation/realitykit/entity/availableanimations>
- **S11** ImageRenderer: <https://developer.apple.com/documentation/swiftui/imagerenderer>
- **S12** SceneKit (deprecated): <https://developer.apple.com/documentation/scenekit>
- **S13** WWDC24 10103, Discover RealityKit APIs for iOS, macOS and visionOS: <https://developer.apple.com/videos/play/wwdc2024/10103/>
- **S14** WWDC25 288, Bring your SceneKit project to RealityKit: <https://developer.apple.com/videos/play/wwdc2025/288/>
- **S15** WWDC26 279, Explore advances in RealityKit: <https://developer.apple.com/videos/play/wwdc2026/279/>
- **S16** Reality Composer Pro: <https://developer.apple.com/reality-composer-pro/>
- **S17** Forums 831751, licensing of RCP-generated assets (Apple staff reply, June 2026): <https://developer.apple.com/forums/thread/831751>
- **S18** Forums 788524, "Alternatives to SceneView" (Apple staff: RealityView + gestures; Model3D on iOS → Feedback): <https://developer.apple.com/forums/thread/788524>
- **S19** HIG Materials (Liquid Glass): <https://developer.apple.com/design/human-interface-guidelines/materials>
- **S20** HIG Motion: <https://developer.apple.com/design/human-interface-guidelines/motion>
- **S21** HIG Augmented reality: <https://developer.apple.com/design/human-interface-guidelines/augmented-reality>
- **S26** Capturing body motion in 3D (ARKit sample): <https://developer.apple.com/documentation/arkit/capturing-body-motion-in-3d>

Primary, specifications and licences:

- **S22** OpenUSD usdz specification: <https://openusd.org/release/spec_usdz.html>
- **S23** MakeHuman LICENSE.md (assets CC0, output unclaimed): <https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md>
- **S24** CC BY-SA 4.0 legal code: <https://creativecommons.org/licenses/by-sa/4.0/legalcode.en>
- **S25** Z-Anatomy README (CC BY-SA 4.0; BodyParts3D CC BY-SA 2.1 JP): <https://github.com/Z-Anatomy/Models-of-human-anatomy>

Secondary (unverified):

- **U1** The owner's reference skill, dpearson2699/swift-ios-skills `realitykit` (AR-focused, iOS 26 / Swift 6.3, PolyForm Perimeter licence; read, not installed): <https://www.skills.sh/dpearson2699/swift-ios-skills/realitykit>, <https://github.com/dpearson2699/swift-ios-skills/blob/main/skills/realitykit/SKILL.md>, `references/realitykit-patterns.md`
- **U2** Adobe, Mixamo common questions (seen via search; the page returned 403 to the fetcher): <https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html>
- **U3** Adobe Community, Mixamo FAQ: licensing, royalties, ownership (staff post, 2022-09-29): <https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400>
- **U4** Forums 825543, RealityView camera target error while orbiting: <https://developer.apple.com/forums/thread/825543>
- **U5** Fitbod help, Muscle Recovery: <https://help.fitbod.me/hc/en-us/articles/360006269014-Muscle-Recovery>
- **U6** Hevy, muscle group workout chart: <https://www.hevyapp.com/features/muscle-group-workout-chart/>
- **U7** Muscle & Motion: Strength (App Store): <https://apps.apple.com/ca/app/id1302056349>
- **U8** Fab, calisthenics animation pack (retargetable to Mixamo rigs): <https://www.fab.com/listings/0ea7586c-8832-4b78-b718-bf0f8ac58ce8>
- **U9** Apple Sample Code License (not read in full): <https://developer.apple.com/support/downloads/terms/apple-sample-code/Apple-Sample-Code-License.pdf>

[S5]: https://developer.apple.com/documentation/realitykit/realityview
[S6]: https://developer.apple.com/documentation/realitykit/realityviewcamera
[S7]: https://developer.apple.com/documentation/swiftui/view/realityviewcameracontrols(_:)
[S8]: https://developer.apple.com/documentation/realitykit/realityrenderer
[S9]: https://developer.apple.com/documentation/realitykit/shadergraphmaterial
[S10]: https://developer.apple.com/documentation/realitykit/entity/availableanimations
[S11]: https://developer.apple.com/documentation/swiftui/imagerenderer
[S12]: https://developer.apple.com/documentation/scenekit
[S13]: https://developer.apple.com/videos/play/wwdc2024/10103/
[S14]: https://developer.apple.com/videos/play/wwdc2025/288/
[S15]: https://developer.apple.com/videos/play/wwdc2026/279/
[S16]: https://developer.apple.com/reality-composer-pro/
[S17]: https://developer.apple.com/forums/thread/831751
[S18]: https://developer.apple.com/forums/thread/788524
[S19]: https://developer.apple.com/design/human-interface-guidelines/materials
[S20]: https://developer.apple.com/design/human-interface-guidelines/motion
[S21]: https://developer.apple.com/design/human-interface-guidelines/augmented-reality
[S22]: https://openusd.org/release/spec_usdz.html
[S23]: https://github.com/makehumancommunity/makehuman/blob/master/LICENSE.md
[S24]: https://creativecommons.org/licenses/by-sa/4.0/legalcode.en
[S25]: https://github.com/Z-Anatomy/Models-of-human-anatomy
[S26]: https://developer.apple.com/documentation/arkit/capturing-body-motion-in-3d
[U1]: https://github.com/dpearson2699/swift-ios-skills/blob/main/skills/realitykit/SKILL.md
[U2]: https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
[U3]: https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400
[U4]: https://developer.apple.com/forums/thread/825543
[U5]: https://help.fitbod.me/hc/en-us/articles/360006269014-Muscle-Recovery
[U6]: https://www.hevyapp.com/features/muscle-group-workout-chart/
[U7]: https://apps.apple.com/ca/app/id1302056349
[U8]: https://www.fab.com/listings/0ea7586c-8832-4b78-b718-bf0f8ac58ce8
[U9]: https://developer.apple.com/support/downloads/terms/apple-sample-code/Apple-Sample-Code-License.pdf
