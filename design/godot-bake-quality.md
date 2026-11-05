# Godot mall: floor look and lightmap bake quality (ws/bake-look, Nov 4 2026)

**Asked (Steven, Nov 4):** "the floors pixelate", worst in 2026 at the main entrance, plus other bake
oddities. The packs no longer have to fit GitHub Pages (they are on Cloudflare R2,
`design/godot-build-hosting.md` "Packs on R2"), so lightmap density can go up.
**Evidence from Steven:** a 20 s recording of Demo 51 (`refs/new/bake_issues_d51/` on the `refs` branch,
f01-f21). Dark and pale mottling on the tan brick border along the shuttered fronts (f10), stair-stepped
edges and blockiness on the checker, more across the Dillard's hall and the green court. The shuttered
fronts and Claire's place the clip in **2026** (H3, the main entrance hall: units s34-s38 on its south
side are vacant grilles in `layout_2026.json` only).

## 1. What causes it (diagnosis)

Shots: native Godot 4.7.2 (Compatibility renderer, OpenGL 3, the same renderer as the web build) of
`wing1_2026.tscn` and `wing1.tscn` with the **Demo 51 lightmaps** from `godot-build` (b9f6d2c3), the same
scenes as the published build (int-51, 4d09e185). Every shot is taken with one thing switched at a time
(the floor shader's edge filtering, the floor mirror, the ReflectionProbes, a white material to show the
lightmap alone). The public R2 build could not be shot here: on the box's software WebGL it loaded for
13 minutes and drew black ("WebGL: too many errors"), so the comparisons are native.

| # | Cause | What it looks like | Evidence | Fix | Rebake? |
|---|---|---|---|---|---|
| 1 | **Floor shader edges not filtered.** `scripts/mall_runtime.gd` FLOOR picks the band, the dark border strip, the brick lane and H3's medallions with hard `if / else` tests, so each edge snaps to whole pixels. The checker and grout lines were already filtered (`fwidth`). | Stair steps along the dark border strip and the medallions; they crawl when you walk. Worst in H3 (the only hall with medallions = the main entrance hall), both years. | `bakelook-aa-band-zoom.jpg` (3x zoom, before/after) | **Done (runtime, no rebake):** the edges are blended over one pixel's footprint (`inside()` / `near()`); `aa_on = 0` restores the old hard edges. | no |
| 2 | **ReflectionProbes on the floor.** Every hall and court has a box-projected `ReflectionProbe` (`build_mall.gd` finish(), `UPDATE_ONCE`, intensity 0.9). The floor shader sets `SPECULAR = 0.25`, `ROUGHNESS = 0.35`, so the floor also shows the probe's low-resolution cube picture of the room: the grille slats (dark bars every 0.18 m) and shop sills come back as pale and dark horizontal streaks and blotches, and a probe box edge shows as a hard-edged pale rectangle on the floor. | Steven's f10: the pale, broken-up patches on the brick lane at the foot of the grilles. | `bakelook-probes-f10.jpg`, `bakelook-probes-main.jpg` | **Knob added, default unchanged** (`floor_spec`, 0.25 = Demo 51; `?floorspec=0` in the game URL to try it). Proposed default 0: the floor keeps its polish from the mirror. **Needs Steven's yes** (it removes a reflection). | no |
| 3 | **Lightmap density.** Own halls and courts bake at 0.156 m per texel (measured from `wing1_day.lmbake`: TEXEL 0.16 since Demo 1, "fast bake for demos", never raised); the other wing's halls and courts (stand-ins) at 0.36-0.40 m. | Soft, low-frequency light pools; light and shadow at the foot of the fronts spread over ~0.3 m; across the seam (Dillard's hall and court seen from wing 1) the shading is coarser still. **Not the mottling:** the floor charts are clean (relative texel noise 0.5-1.1 %, smooth when shown alone). | `bakelook-lightmap-floor-charts.jpg`, `bakelook-lightmap-only.jpg` | **Raise** (`tools/bake_quality.json` profile `nov4`, active). | yes, all inside wings |
| 4 | The floor mirror (`mall_runtime.gd`, a mirrored camera at half resolution, no MSAA, 9-tap blur) | in the native shots a slight haze and no streaks of its own; on the web it runs at half the canvas, so it may add to the grille streaks there (not reproduced here) | `bakelook-probes-*.jpg` | none yet: check with the existing **`?refl=0`** (works on the live Demo 51) | no |

**How sure (row 2 vs row 4):** the native shots show the floor's probe share as hard-edged pale washes
and streaks that vanish with `floor_spec 0`; removing the probes instead only swaps in the sky's
reflection (a grey-blue wash, `bakelook-probes-main.jpg`). They do not reproduce the exact broken-up
pattern of Steven's f10, which was recorded in the browser. Both suspects are reflections of the grilles,
neither is the lightmap. On the live Demo 51, `?refl=0` switches the mirror off; if f10's patches stay,
they are the probes (row 2) and `?floorspec=0` (next build) removes them.

**Ruled out:**
- *Screen-space reflections:* the Compatibility renderer has none; the floor's reflections are the
  mirror (4) and the probes (2).
- *Texture filtering / mipmaps / anisotropy:* the floor has no texture; it is drawn by the shader in
  world space (`project.godot` anisotropic level 3 doesn't apply to it). The lightmap is magnified on
  the floor, so its missing mipmaps don't matter.
- *Lightmap noise / denoiser:* Ultra (2048 rays per texel, 2048 probe rays, Godot defaults), 3 bounces,
  JNLM denoiser at 0.25: the floor charts come out smooth (see 3).
- *UV2 seams:* each hall/court floor is one quad, one chart (the floor boxes in the atlas are
  e.g. H3 153 x 77 texels, C2 141 x 101, H2 77 x 477); no seam crosses a floor.
- *Lightmap compression:* VRAM compressed (BC6H on desktop, ASTC on phones), 8 bits per texel, no
  visible blocks at 0.156 m in these shots. Kept.

**Squeezes made for GitHub Pages (git log, `tools/export_web.sh`, `tools/build_mall.gd`):** TEXEL 0.16
(Demo 1, never raised); arcade machines x1.5 (Oct 5: "a fine one doubled the download"); stand-in
halls and courts x2.5 (Oct 7, the two-wing split); outside x4, the lot x10, ex_far x6 (Oct 24);
the lion's textures as lossy WebP (Nov 2, not floors). `export_web.sh` does nothing to lightmaps.
`max_texture_size` 4096 was never binding: Godot packs each atlas at the smallest power of two that
fits the largest chart (1024 wide for wings 1-3, 512 for 4-5) and adds layers.

### Demo 51 lightmaps (measured from `godot-build` b9f6d2c3)

| Lightmap | Atlas | Texels | In the pack (BC6H / ASTC) |
|---|---|---|---|
| wing1_day | 6 x 1024² | 6.3 M | 6.3 MB |
| wing1_2026_day | 2 x 1024² | 2.1 M | 2.1 MB |
| wing2_day | 5 x 1024² | 5.2 M | 5.2 MB |
| wing2_2026_day | 3 x 1024² | 3.1 M | 3.1 MB |
| wing3_day / _2026 | 3 x 1024² | 3.1 M | 3.1 MB |
| wing4_day / _2026 | 4 x 512² | 1.0 M | 1.0 MB |
| wing5_day / _2026 | 3 x 512² | 0.8 M | 0.8 MB |

Where wing 1's (1995) texels go (chart area, `tools/qa` charts dump in the session; 70 % of the atlas
is charts): shops (shells, fixtures, merchandise) 63 %, own halls and courts 20 % (their floors 3 %),
props 14 %, stand-ins 2.4 %. So making the floors 2.6x finer costs little; making everything 1.6x finer
is what costs.

## 2. Proposal: profile `nov4` (`tools/bake_quality.json`)

| Group | Demo 51 | nov4 | nov4_lite (fallback) |
|---|---|---|---|
| own halls, courts, storefronts, shops (TEXEL) | 0.16 m | **0.10 m** | 0.12 m |
| own hall and court floors (own mesh `<zone>_fl`) | 0.16 m (in the zone mesh) | **0.06 m** | 0.08 m |
| props, lanterns (x0.6) | 0.096 m | 0.06 m | 0.072 m |
| arcade machines (x1.5) | 0.24 m | 0.15 m | 0.18 m |
| Sears / Dillard's rooms (x1.25, ceilings x2) | 0.20 / 0.32 m | 0.125 / 0.20 m | 0.15 / 0.24 m |
| stand-ins (the other wing's halls and courts) | 0.40 m | **0.16 m** | 0.20 m |
| wing 3 (the outside) | as Demo 51 | **unchanged** (override) | unchanged |
| LightmapGI | Ultra, 3 bounces, JNLM 0.25, max 4096, probes subdiv 4 | same | same |

Ray counts and the denoiser stay: the noise is not the problem (section 1, row 3), and more rays would
double the bake time.

### Predicted lightmap size, pack growth and Mac bake time (nov4)

From the wing 1 chart dump: every group scales by (old texel / new texel)², the floors by
(0.156 / 0.06)² = 6.8, stand-ins by 6.25. Wing 1 (1995): 4.42 M chart texels → about 12.3 M (x2.8).
The other wings are scaled by the same x2.8 (their mix of groups is similar; 4 and 5 are mostly room
and stand-in texels, about x3). Atlases at ~70 % fill; floors at 0.06 m make H2's floor chart
200 x 1267 texels, so wings 1 / 2 move to 2048-wide layers.

| Scene | Demo 51 lightmap | nov4 lightmap (est.) | Each pack grows (desktop and mobile) | Mac bake, Ultra (est.) |
|---|---|---|---|---|
| wing1 | 6.3 MB | ~18 MB | +~12 MB | ~6 → ~15 min |
| wing1_2026 | 2.1 MB | ~6 MB | +~4 MB | ~10 min |
| wing2 | 5.2 MB | ~15 MB | +~10 MB | ~14 min |
| wing2_2026 | 3.1 MB | ~9 MB | +~6 MB | ~11 min |
| wing4 / wing4_2026 | 1.0 MB | ~3 MB | +~2 MB | ~6 min each |
| wing5 / wing5_2026 | 0.8 MB | ~2.5 MB | +~1.7 MB | ~5 min each |
| wing3 / wing3_2026 | 3.1 MB | unchanged | 0 | no rebake |

Total: ~+43 MB across the eight inside packs (each pack exists twice, desktop and mobile: ~+86 MB on R2);
eight day bakes ≈ 75-80 min instead of ~45. These are estimates (±30 %): the Mac's `.autobake_done`
lists each bake's seconds; please send it back so this table can be corrected. nov4_lite is about half
the growth.

**Risks.** (a) Phone memory: if a phone's WebGL can't take the ASTC HDR lightmap as is, Godot unpacks it
to 16-bit floats (8 bytes per texel): wing 1 would hold ~140 MB of lightmap instead of ~50 MB today. Check
wing 1 on the iPhone after the rebake; if it struggles, set `"active": "nov4_lite"`, rebuild, rebake.
(b) The Mac's bake memory grows with the texels (~2.8x); a bake that fails shows `FAILED` in
`.autobake_done`.

## 3. What is on the branch (all reversible)

- `tools/bake_quality.json` + `tools/bake_quality.gd`: the bake settings as data. `"active"` picks the
  profile (`d51`, `nov4`, `nov4_lite`); `--bake-profile=<name>` on `build_mall.gd` or
  `MALL_BAKE_PROFILE=<name>` overrides it; `wings` holds per-scene overrides (`wing3` keeps Demo 51).
  `d51` is exactly the constants build_mall.gd had. A profile coarser or lower than `d51` anywhere is
  refused (falls back to `d51`) unless it says `"allow_lower": true`, which needs Steven's yes and
  before/after shots.
- `tools/build_mall.gd`: reads the profile in `build()`; per-group texels from the JSON's `rules`
  (replacing the if/elif chain in `finish()`); `LightmapGI` settings from the profile; with a
  `floor_texel`, each own hall and court floor becomes its own static mesh `<zone>_fl` (same material,
  so the runtime floor shader and the mirror find it as before).
- `scripts/mall_runtime.gd` FLOOR shader: anti-aliased band, border, brick-lane, court-border and
  medallion edges (`aa_on`, 1); `floor_spec` (the probes' share, default 0.25 = Demo 51) and
  `?floorspec=` on the web.
- `tools/qa/bake_quality_test.gd`: d51 = the old constants, nov4 never coarser, wing 3 unchanged,
  a lower profile refused.

**Revert:** `"active": "d51"` (or `--bake-profile=d51`), rebuild, and the Demo 51 lightmaps fit again;
`aa_on = 0` and `floor_spec = 0.25` are the old floor.

## 4. Steps on the Mac (integration session)

The scenes must be rebuilt with the active profile **before** the bake (the profile changes every
inside mesh's UV2, so the Demo 51 lightmaps no longer fit those scenes):

1. Cloud / integration: build the twelve scenes as usual (`build_mall.gd -- --wing=N [--year=2026]`);
   each build prints `bake profile nov4: ...`. Run `godot --headless --path . --script
   res://tools/qa/bake_quality_test.gd` → `BAKE QUALITY OK`. Commit the scenes.
2. Mac, project folder:
   ```
   echo "wing1:day wing1_2026:day wing2:day wing2_2026:day wing4:day wing4_2026:day wing5:day wing5_2026:day" > .autobake
   ```
   then open the project (≈ 75-80 min; wing 3 and wing 6 are not baked). Send back `.autobake_done`.
3. Bring back `wing{1,2,4,5}{,_2026}_day.{exr,exr.import,lmbake}` (the `.exr.import` matters: its
   `slices/vertical` follows the new layer count).
4. Stand-ins: `tools/capture_standin.sh 4`, `4 2026`, `5`, `5 2026`, then `1`, `1 2026`, `2`, `2 2026`.
5. Export, look (main entrance H3 both years, the grilles, the seam toward Dillard's, `?floorspec=0`
   vs default), then publish as usual.

## 5. Questions for Steven

1. **Floor and probes:** take the probes off the floor (`floor_spec` 0)? Compare in the game with
   `?floorspec=0` and look at `bakelook-probes-f10.jpg`. (No rebake either way.)
2. nov4 (bigger) or nov4_lite? nov4 adds ~12 MB to wing 1's download and ~1.5 h of baking per full
   rebake instead of ~45 min.
3. Your clip shows the 2026 hall; is the 1995 hall as bad for you? (Causes 1 and 2 are in both years.)
