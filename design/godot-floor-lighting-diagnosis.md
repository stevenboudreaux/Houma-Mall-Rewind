# Godot mall: the floor patches that move with the camera (workstream FLOOR-LIGHT, Nov 9 2026)

A diagnosis spike. Nothing in the game changed; the fix is for the director to schedule in Wave B.
**Nov 11 2026: the fix is in, on `ws/floor-fix` (§7 "Fix shipped").**

**The two causes**

- **(a) The hard-edged lighter/darker boundary on the plank and checker floors is the floor reflecting
  the hall/court ReflectionProbes.** The floor shader's `SPECULAR = floor_spec` (0.25) at `ROUGHNESS = 0.35`
  picks up the probe's cube picture, and its hard lines move as the view direction changes.
- **(b) The soft hot spot ahead of the camera in the checker corridors is the same specular term
  reflecting the sky.** In H2 (Sound Shop / Lane Bryant) the floor gets nothing from its hall probe, so it
  reflects the day `Environment`'s procedural sky (`reflected_light_source = SKY`). That glow stays at the
  same place on screen as you walk.

Both go away with `floor_spec = 0` (`?floorspec=0` on the live game). That is the knob ws/bake-look added on
Nov 4, which Steven was to try first. No rebake. No fps cost.

**Not the cause:** the sun and its shadow cascades, SSAO, SSIL, SDFGI, VoxelGI, the floor mirror, the talk
lights, and the lightmap or its UV2. Details are in §3.

## 1. What was tested, and where

Steven's clip (Screen_Recording_11.16.34) is not in the repo or on the `refs` branch (latest Nov 4), so
these shots reproduce the brief's description, not the clip itself. I could not check exactly which
patch he saw (see §6).

| | Where | How |
|---|---|---|
| **Live** | https://stevenboudreaux.github.io/Houma-Mall-Rewind/ = Demo 53 (R2 build `20261109-1100-67654e7b`, source `0b07b54`), 1995, wing 1, desktop pack | Headless Chromium (Playwright, SwiftShader WebGL2), 960x540, `?cam=` start pose, then hold **W** for 0.6 s, release, and screenshot (SwiftShader runs at about 2-5 fps). Each run uses one variant: as shipped, `?refl=0` or `?floorspec=0`. **Frame 00 is the exact same pose in every variant**, so subtracting two frame-00 shots isolates one term. 0 console errors. |
| **Local** | Godot 4.7.2, Compatibility / `opengl3` (the web build's renderer), under xvfb. `wing1.tscn` with the **Demo 53 baked day lightmap** from `godot-build`. Player, Runtime and NPCs run as in the game, at `set_clock(12, 1)`, the shipped default. | A scratch SceneTree script (not committed) walks the player 0.5 m (or 0.25 m) per step, waits 12 frames and saves the screen. One load runs every toggle in turn: apply it, shoot the walk, revert it. A **"flat"** pre-toggle replaces the floor's terrazzo colour with plain grey (a test-only edit of the shader string), so the shot shows only lighting and reflections. NPCs are hidden for the flat runs. About 1 fps on llvmpipe. |

The walks (WALK_CAM-style start poses; yaw 0 faces -z):
- **(a) H4 at Woolworth, toward the Shoe Dept. court (C2):** start `-7,16,0,-14`, walking -z along the plank
  lane beside Woolworth's front (x = -10).
- **(b) H2, Kay-Bee / Sound Shop / Lane Bryant:** start `-4,-44,0,-10`, walking -z toward Sears.

**Both runs show both effects** (it is the same renderer and the same shader):
- Live: frame-00 differences show the hard lines in the floor's specular share at H4/C2
  (`wsFLOOR-a-before-after-live.jpg`) and the forward glow in H2 (`wsFLOOR-b-before-after-live.jpg`).
- Local: the flat-floor walks show both effects plainly (§2).

The patch shapes differ in detail between the two runs, because SwiftShader WebGL and llvmpipe GL sample
the low-resolution probe cube differently. Whether Steven's clip came from the web or a local run doesn't
change the diagnosis. There is one exception: a local run **without the lightmaps** (§4).

## 2. Findings

### (a) Hard-edged boundary on the plank and checker floors: the ReflectionProbes

Every hall and court has a box-projected `ReflectionProbe` (`tools/build_mall.gd` finish(), `UPDATE_ONCE`,
intensity 0.9). The floor shader (`scripts/mall_runtime.gd` FLOOR) sets `ROUGHNESS = 0.35` and
`SPECULAR = floor_spec` (0.25). At that gloss the floor shows a fairly sharp mip of the probe's cube.

With the terrazzo pattern flattened, the H4/C2 walk shows straight-edged pale and dark wedges across the
plank lane and the checker. Their shape changes at every 0.25-0.5 m step. Scoring hard edges as the
share of floor pixels with a step of 4 or more grey levels (x1000, per step):

| Toggle (flat floor, H4/C2 walk) | step 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| as shipped | 40.9 | 47.0 | 103.1 | 135.3 | 64.3 | 24.5 |
| **floor_spec 0** | **0** | **0** | **0** | **0** | | |
| **all ReflectionProbes hidden** | **0** | **0** | **0** | **0** | | |
| **hall/court probes hidden (store probes kept)** | **0** | **0** | **0** | **0** | **0** | **0** |
| store-interior probes hidden | 40.0 | 45.4 | 103.6 | 135.2 | 63.2 | 23.2 |
| only the probe whose box holds the camera | 40.8 | 47.0 | 103.2 | 135.7 | 64.7 | 24.6 |
| box projection off | 40.9 | 48.0 | 106.2 | 172.6 | 103.8 | 67.0 |
| blend distance 1 to 4 m | 40.9 | 46.9 | 103.2 | 135.7 | 64.8 | 24.6 |
| roughness 0.6 | 39.2 | 45.7 | 99.6 | 158.6 | 65.7 | 25.3 |
| **roughness 0.9** | **0** | **0** | **0** | **0** | **0** | **0** |
| sun hidden / sun shadow off / 1 cascade (orthogonal) | 40.9 | 103.1 | 64.2 | 43.0 | | |
| Env sky reflection off | 39.2 | 101.9 | 83.3 | 59.1 | | |
| floor mirror off | 40.8 | 102.5 | 64.6 | 43.4 | | |

(The 4-step rows were shot at 0.5 m steps, the 6-step rows at 0.25 m, so only step 0 is the same pose.)

**Cause (a).** The edges are in the floor's reflection of its own hall/court probe. Only removing that
reflection removes them: probe share 0, hall probes hidden, or roughness 0.9, which drops to a mip where the
cube is a smooth blur. They do not come from switching between probes or from a probe box edge: keeping only
the camera's own probe or widening the blend changes nothing. The sun, its cascades and the mirror also
change nothing. Box projection makes them less bad, not gone. The probe's cube is a low-resolution picture of
the room, captured once from the middle of the hall: ceiling, vault, store fronts, the dark grille openings.
Its sharp boundaries map onto the floor through the reflection vector, which depends on where you stand, so
they slide or jump as you walk. The same effect was row 2 of `design/godot-bake-quality.md` ("a probe box edge
shows as a hard-edged pale rectangle on the floor"); this spike adds that the edges move with the camera.
I could not tell from these shots whether a given edge is a cube-face seam or a sharp feature of the captured
room. Both disappear with the same fix.

Evidence:
- `production/qa/evidence/wsFLOOR-a-before-after-live.jpg`: the live as-shipped / `?floorspec=0` pair at
  the same pose; their difference x6, with the hard straight line across the plank lane and checker; the same
  term at the same pose locally.
- `production/qa/evidence/wsFLOOR-a-local-walk-toggles-flatfloor.jpg`: four steps of the flat-floor walk for
  as shipped, floor_spec 0, probes hidden, sun hidden, 1 cascade, mirror off.

### (b) Soft hot spot ahead of the camera on the checker corridors: the sky reflection

In H2 the floor's specular share is the **sky**, not the hall probe.
- **Hiding every ReflectionProbe changes the H2 floor by 0.00 grey levels.** The probe is not reaching that
  floor at all; see §6 Q2.
- Turning off the Environment's reflected light (`reflected_light_source` SKY to DISABLED) removes the same
  amount as `floor_spec 0`: a floor mean of 7.1 vs 6.9 levels, with the same map.

The day sky is `ProceduralSkyMaterial` at energy 1.3, with a pale horizon (#CFE0EE). Seen on a gloss-0.35
floor at walking angles, it gives a soft bright glow on the checker a few metres ahead. Its brightest point
stays at the same screen spot, (454,270), (448,274), (445,277) and (455,272), over 1.5 m of walking: it
travels with the camera. The checker's dark tiles take a larger share of the mirror than the light ones,
and the pale tiles keep their contrast, so on the H2 checker it reads as a hot spot more than on the planks.

| Toggle (H2 walk) | floor change | the forward glow |
|---|---|---|
| **floor_spec 0** | −6.9 grey (whole spec share) | **gone** |
| **Env sky reflection off** | −7.1 | **gone** |
| all ReflectionProbes hidden | 0.00 | stays |
| floor mirror off (live `?refl=0` and local) | +1.7 / +1.8 (the mirror only darkens) | stays |
| sun hidden / shadow off / 1 cascade / sun in sky off | 0.00 | stays |
| roughness 0.9 | spec share spread flat | gone as a spot (still a haze) |
| talk rig after 10 open/close cycles | ~0 (NPC motion only) | stays |

**Not to confuse with (b): the skylight pools.** The big bright blob on the right of the H2 floor is the baked
sunlight through the skylight wells, which are every 12 m in H2. It stays in every toggle and grows as you
walk up to it, so it is fixed to the floor. When Steven walks continuously, the sky glow sits in front of each
pool and passes over it. That may be why the pool seems to move with him; I can't check without his clip.

Evidence:
- `production/qa/evidence/wsFLOOR-b-before-after-live.jpg`: the live as-shipped / `?floorspec=0` /
  `?refl=0` shots at the same pose, and the as-shipped minus floorspec=0 difference x4, which brightens toward
  a band ahead.
- `production/qa/evidence/wsFLOOR-b-local-walk-toggles-flatfloor.jpg`: four steps for as shipped,
  floor_spec 0, sky reflection off and probes hidden, plus the spec-share map, whose peak doesn't move.

## 3. Ruled out (one toggle at a time, same frames)

- **Directional shadow and cascades.** The day `Sun` is `light_bake_mode = STATIC`, `shadow_enabled`,
  `PARALLEL_4_SPLITS` with splits 0.1 / 0.2 / 0.5 and max distance 100 m. On the lightmapped floor the
  renderer skips it, as a static light should. Sun hidden, shadow off and a single orthogonal cascade all
  change the floor by 0.00. Cascade edges appear only when the lightmap is missing (§4).
- **SSAO / SSIL / SDFGI / VoxelGI.** The project is `gl_compatibility` on desktop and mobile. That renderer
  has none of them, `gen/env_day.tres` sets none, and wing1 has no VoxelGI node. Glow is on (threshold 1.2)
  but was not a suspect: it doesn't change per position.
- **The floor mirror** (`mall_runtime.gd`, a mirrored camera at half resolution). It only darkens the floor
  slightly, by about 1.7 grey levels; it has no edges or spot of its own.
- **The talk-mode light rig** (Nov 8, `scripts/story/talk_camera.gd`). After 10 `begin()`/`end()` cycles:
  TalkKey and TalkFill are `visible=false` at energy 0.0, cull mask = layer 20 only, the player camera is
  current, and no meshes are left on layer 20. The walk afterwards matches the baseline. The rig cannot
  light the floor: it lights layer 20 only, and only while talking.
- **The lightmap itself.** `Static/H2_fl` and `Static/C2_fl` are `GI_MODE_STATIC`, have UV2, one surface
  each (`floorz_*`, with the runtime ShaderMaterial override), and `LightmapGI` holds `res://wing1_day.lmbake`.
  The floors are lightmapped, not on dynamic GI.
- **Store-interior probes** (intensity 0.6, boxes reach the floor plane). Hiding them changes nothing in
  either walk.

## 4. One more way to get (a): a local run without the lightmaps

If the project is opened without the `godot-build` lightmaps, the `LightmapGI` has no data. Then the static
sun lights the floor in real time with its 4-split shadows. A hard shadow line then sweeps forward with the
camera at every step: the classic cascade look, in `wsFLOOR-nolightmap-sun-cascade-line.jpg` (local,
lightmap_off). The floor also turns very bright, about 83 grey levels over the baked look.

If Steven's clip was a local run and the whole floor looked washed bright, this is it. The fix is to fetch
the lightmaps (CLAUDE-CLOUD.md setup step 3), not to change the game. A baked run, local or live, does not
do this.

## 5. Recommended fixes (Wave B; not committed here)

**(a) and (b) together:** turn the floor's specular share off. The floor keeps its polish from the mirror.
This is the default ws/bake-look proposed and Steven had not yet approved (bake-quality §5 Q1).

```
scripts/mall_runtime.gd   @export var floor_spec := 0.25      ->  := 0.0
scripts/mall_runtime.gd   uniform float floor_spec = 0.25;    ->  = 0.0;   (FLOOR shader)
scripts/mall_runtime.gd   comments "Demo 51: 0.25" / "0.25 = Demo 51" -> "0 since FLOOR-LIGHT; ?floorspec=0.25 for the old look"
```

**(b) only, if Steven wants to keep the probe gloss:** stop interior wings reflecting the outdoor sky.

```
tools/build_mall.gd  make_env():  env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
                     -> REFLECTION_SOURCE_DISABLED for interior wings; wing 3 (the outside) keeps SKY.
                     gen/env_day.tres is shared by every wing, so make an env_day_interior.tres (or set it at
                     run time in mall_runtime.gd _ready when the scene isn't wing 3).
```

This alone does not fix (a). Where a probe does reach the floor (C2/H4), its hard edges stay.

**Not recommended:** roughness 0.9 removes both but turns the polish to haze. Box projection, blend distance
and cascade settings do nothing here.

| Fix | Rebake? | Web fps cost |
|---|---|---|
| floor_spec 0 (runtime shader uniform) | **no** (no lightmap or mesh change, no rebuild) | **none expected**: one uniform's value, no pass added or removed. Not measured; SwiftShader frame rates (2-5 fps) can't show a difference this small. |
| Interior env without sky reflection | **no** rebake. A rebuild only if done in `build_mall.gd` (the env is saved there); done at run time, not even that. | none expected (if anything slightly cheaper) |
| GI mode or UV2 on the floors | not needed: the floors are already static and lightmapped | n/a |

Checking after the fix: the two walks above, live with `?floorspec=0.25` vs the new default. In H4 and C2,
no hard-edged wedges should move across the plank lane. In H2, no glow should stay a few metres ahead. The
skylight pools must stay where they are.

## 6. Open questions

1. **For Steven:** was Screen_Recording_11.16.34 the web build or a local run, and did the floor look much
   brighter than the live game? If it was local and very bright, §4 applies as well.
2. **For whoever does Wave B:** why does the H2 floor get nothing from its 76.5 m hall probe (hiding all
   probes: 0.00 change) while C2/H4 do? It doesn't matter if floor_spec goes to 0. If Steven keeps the gloss,
   find out first, or H2 will keep showing the sky.
3. These shots are software-rendered (SwiftShader / llvmpipe). On a real GPU the probe cube is the same size,
   so expect the same edges, perhaps a little crisper.

## 7. Fix shipped (workstream FLOOR-FIX, Nov 11 2026, branch `ws/floor-fix`)

**What changed.** The §5 recommendation, nothing more: the floor's specular share is 0.

```
scripts/mall_runtime.gd   @export var floor_spec := 0.25   ->  := 0.0
scripts/mall_runtime.gd   uniform float floor_spec = 0.25; ->  = 0.0;    (FLOOR shader)
```

`?floorspec=0.25` on the web still gives the Demo 51-53 look, for comparison. Roughness (0.35), the floor
mirror (strength 0.6), the probes, the Environment, the lights and the lightmaps are untouched.

**Where it lives.** In the runtime floor shader that `mall_runtime.gd` puts on every `floorz_*` surface when a
wing loads. It is shared by every wing and both years, so **no wing rebuild and no rebake**; the next export
carries it. No `gen/` file or `wing*.tscn` changed (none stores `floor_spec`).

**What the floor looks like now.** Matte tile with the mirror's faint reflection of the hall on top (shop
fronts, ceiling lights; strongest on the dark tiles and at shallow angles). The mirror is a real reflection of
the room, so it stays put on the things it reflects; it does not slide. The baked skylight pools stay where
they are. The floor is a little darker overall, because the specular share was adding light: about 4-11 grey
levels (of 255) less on the floor part of the frame at the two spots.

**Checked** (all with the Demo 53 day lightmaps from `godot-build`; software renderers, see gaps):

| | Before (floor_spec 0.25) | After (0) |
|---|---|---|
| (a) H4 at Woolworth toward court C2, grey-floor pass, hard-edge score x1000 over 8 steps of 0.5 m, 1990s | 7.7, 90.5, 115.5, 168.9, 171.4, 140.2, 41.5, 132.7 | 7.7, 6.0, 2.1, 4.0, 3.4, 4.2, 4.1, 5.2 |
| same, 2026 | 3.7, 99.4, 122.0, 206.1, 192.1, 151.8, 44.2, 154.9 | 3.7, 2.9, 3.2, 3.3, 3.2, 2.2, 5.3, 6.2 |
| (b) H2 Kay-Bee / Sound Shop / Lane Bryant, grey-floor pass | a pale glow on the far floor in every frame, the same place on screen | gone; only the baked skylight pool, which grows as you walk up to it |

(The score is the share of pixels in the bottom third of the frame with a step of 4 or more grey levels to a
neighbour; the few that remain after are the floor's edge against the shop fronts and shoppers' feet.)

- **Local** (Godot 4.7.2, `opengl3` under xvfb, `tools/qa/floor_walk.gd`): the game as it ships (Player,
  Runtime, shoppers, noon), a frame every 0.5 m, 8 frames per walk, each walk shot at 0.25 and at 0 in the same
  load, once with the real floor and once with it painted grey. Strips (every second frame):
  `production/qa/evidence/wsFLOORFIX-a-woolworth-court-{1990s,2026}-local-baked.jpg`,
  `wsFLOORFIX-b-soundshop-corridor-{1990s,2026}-local-baked.jpg`.
- **Web** (an export of this branch, headless Chromium / SwiftShader, `tools/qa/floor_webwalk.py`): the same two
  start poses, hold W 0.6 s between frames, `?floorspec=0.25` against the build's default. Strips:
  `wsFLOORFIX-{a-woolworth-court,b-soundshop-corridor}-{1990s,2026}-web.jpg`. 0 console errors in all 8 loads.
- **Other interior wings**, one pose each, before and after: wing 2 (court C3 both years, hall H5), wing 4
  (Sears), wing 5 (Dillard's), wing 6 (cinema lobby): `wsFLOORFIX-other-wings-local-baked.jpg`. Wing 2's mall
  floors change the same way as wing 1's. The rooms' own floors (Sears, Dillard's, the cinema carpet) are other
  materials and did not change (frame difference 0.0-0.6 grey levels, which is the shoppers moving).

**Web fps cost: none measured.** Mean frame time over each web walk, before / after: 1990s (a) 2506 / 2521 ms,
(b) 2126 / 2114 ms; 2026 (a) 1340 / 1315 ms, (b) 1091 / 1054 ms. That is -3 % to +0.6 %, inside the noise of
SwiftShader on a 2-CPU box; it is one uniform's value, no pass added or removed.

**Sheen: what was kept, and options left for Steven** (taste; nothing decided here). The brief asked for a
soft sheen that does not move with the view if one could be had, else matte. The mirror is that sheen and is
unchanged. If the floor now reads too flat on a real screen:
1. raise the mirror (`strength` 0.6 on the Runtime node; no rebake, no rebuild). It reflects the real room, so
   it cannot slide, but more of it shows the shop fronts upside down in the tile;
2. `?floorspec=0.1`: a weaker version of the old gloss. The patches come back in proportion, so this is a
   trade, not a fix;
3. leave it matte (as shipped here).

**Gaps.**
- Software rendering only (llvmpipe, SwiftShader). Not seen on a real GPU or an iPhone; §6 Q3 still applies.
- Steven's clip is still not in the repo or on `refs`, so the walks follow the brief's description of it.
- Day bake only (the clock is day-only for now, `scripts/lighting.json`). The night Environment has no sky
  glow to reflect, and the probes are the same nodes, so the same fix covers it; not shot.
- The rooms that are their own wings (4-6) have floors that are not `floorz_*`. One pose each showed nothing
  wrong; they were not walked. If a patch moves in Sears or Dillard's, that is a separate material.
- §6 Q2 (why H2's floor gets nothing from its hall probe) is moot at 0 and was not chased.
