# Handoff: FLOOR-FIX (Nov 11 2026, branch `ws/floor-fix` from `int-54` at cc2191b9)

Scheduled worker run, nobody watching. Not merged, not baked, not published, nothing uploaded.

## What changed

- **`prototypes/godot-mall/project/scripts/mall_runtime.gd`**: the floor's specular share `floor_spec` goes from
  0.25 to **0** (the `@export` default and the FLOOR shader's uniform default), with the comments updated.
  This is the fix `design/godot-floor-lighting-diagnosis.md` §5 recommended. The floor no longer reflects the
  hall/court ReflectionProbes (the hard-edged patch near Woolworth) or the sky (the glow ahead of the camera by
  Sound Shop / Lane Bryant). `?floorspec=0.25` on the web still shows the old look.
- **New QA tools:** `tools/qa/floor_walk.gd` (local walk, shots per floor_spec value, optional grey-floor pass)
  and `tools/qa/floor_webwalk.py` (the same two walks on a web export, with frame times).
- **Docs:** `design/godot-floor-lighting-diagnosis.md` §7 "Fix shipped"; a note in `design/godot-bake-quality.md`
  where it said the default stays 0.25.
- **Evidence:** `production/qa/evidence/wsFLOORFIX-*.jpg` (9 files): both spots, both years, local and web,
  plus one sheet of the other interior wings.

**Where the change lives: a shared runtime shader. No wing rebuild, no rebake, no stand-in recapture.** No
`gen/` file or `wing*.tscn` is in this branch's diff. The next export picks it up.

## Result

- Woolworth court walk (H4 toward C2): the hard-edged patches are gone in both years. Hard-edge score on the
  grey-floor pass, 8 steps: before 8-171 (1990s) and 4-206 (2026); after 2-8 in both.
- Sound Shop / Lane Bryant corridor (H2): the glow on the far floor is gone in both years. The baked skylight
  pools are still there and stay put.
- The floor reads matte with the mirror's faint reflection of the room. It is a little darker (about 4-11 grey
  levels of 255 on the floor part of the frame).
- **Web fps cost: none measured.** Mean frame time before / after on the four web walks: 2506 / 2521,
  2126 / 2114, 1340 / 1315, 1091 / 1054 ms (SwiftShader on 2 CPUs; -3 % to +0.6 %, noise).

## Tests

- MENU UNIT OK (64 checks). SHOP TEST OK (200 checks). INTERACT TEST OK wing 1 (8 checks) and wing 2 (19 checks).
- movetest on the web export, wings 1 and 2, 1990s and 2026: 0 errors at every camera, MOVED in all four.
- The 8 web walk loads: 0 console errors.

## Calls I made

1. **Took the diagnosis's first fix (floor_spec 0) as is.** It removes both effects with the smallest change and
   needs no rebake. The bake-quality note said the default would stay 0.25 until Steven had tried `?floorspec=0`;
   the brief told me to implement the fix, so I read that as his answer.
2. **Did not add a new sheen.** The brief allowed a soft sheen only if it does not move with the view. The
   floor mirror already is one and I left it at its strength. Raising it is a taste call; the options are in
   the diagnosis doc §7 for Steven.
3. **Left roughness, probes, the Environment's sky reflection, lights and lightmaps alone.** Not needed at 0.
4. **Kept `?floorspec=`** so the old look can be compared on the live build.
5. **Tested with the Demo 53 lightmaps, not unbaked.** The brief asked for an unbaked web export; the lightmaps
   were on `godot-build`, and the diagnosis showed an unlit run adds its own moving shadow line (§4) that would
   muddy the comparison. Evidence files say `baked`. Wing 1's lightmap is Demo 52's, on int-54's scenes.
6. **Local frames are every 0.5 m, not every 0.5 s.** The software renderer runs about 0.3 fps, so the script
   places the player and shoots; 0.5 m is about a third of a second of walking.
7. **Web walks use the desktop pack at 960x540**, holding W for 0.6 s between frames (as the diagnosis did).
8. **Exported wings 1 and 2 only** (both years) for the web checks, to `.scratch/builds/floorfix` (not committed).
   Wings 4-6 were shot locally, one pose each, 1990s only.
9. **Before and after come from the same load** (the script sets the uniform to 0.25, then 0), so the only
   difference between rows is the value under test. Shoppers keep walking between rows.

## Known gaps

- Seen only on software renderers (llvmpipe, SwiftShader). Not checked on a real GPU or an iPhone.
- Steven's clip is not in the repo or on `refs`; the walks follow the brief's description.
- Day bake only (the clock is day-only). Night not shot.
- Sears, Dillard's and the cinema lobby have their own floor materials, not this shader. One pose each showed
  nothing wrong; they were not walked.
- The fps figures can only show a large cost; a small one would be hidden at 0.5-1 fps. None is expected
  (one uniform's value).

## Rebake / rebuild needs

None.

## For the director at integration

- Shared file touched: `scripts/mall_runtime.gd`, three small hunks near the top (the export, the shader
  uniform and its comment, the `SPECULAR` line's comment) and one comment above `_floor_spec()`.
- If Steven finds the floor too flat on his phone: `strength` on the Runtime node (mirror) is the knob that
  cannot bring the patches back.

## Open for Steven

1. Look at the two spots on a real screen after the next publish: gone? Compare with `?floorspec=0.25`.
2. Is matte-plus-mirror polished enough, or should the mirror be stronger?
